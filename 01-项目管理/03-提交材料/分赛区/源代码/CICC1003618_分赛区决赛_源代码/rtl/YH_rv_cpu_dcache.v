`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_dcache #(
    parameter integer XLEN = 32,
    parameter integer CACHE_ADDR_BITS = 32,
    parameter integer CACHE_SIZE = 4096,
    parameter integer BLOCK_SIZE = 4,
    parameter integer ASSOC = 1,
    parameter integer WRITE_POLICY = 0,
    parameter integer CACHE_ID = 0,
    parameter integer ENABLE_NEXT_PREFETCH = 0,
    parameter integer WORD_ONLY = 0
) (
    input  wire              clk,
    input  wire              rst_n,

    input  wire [XLEN-1:0]   cpu_addr,
    input  wire              cpu_req,
    input  wire              cpu_we,
    input  wire [XLEN-1:0]   cpu_wdata,
    input  wire [XLEN/8-1:0] cpu_wstrb,
    input  wire [1:0]        cpu_size,
    input  wire              cpu_unsigned,
    output wire [XLEN-1:0]   cpu_rdata,
    output wire              cpu_rvalid,
    output wire              cpu_wait,

    input  wire              probe_req,
    input  wire [XLEN-1:0]   probe_addr,
    output wire              probe_hit,

    output wire [XLEN-1:0]   mem_addr,
    output wire              mem_req,
    output wire              mem_we,
    output wire [XLEN-1:0]   mem_wdata,
    output wire [XLEN/8-1:0] mem_wstrb,
    input  wire [XLEN-1:0]   mem_rdata,
    input  wire              mem_rvalid,
    input  wire              mem_ready
);

localparam integer STRB_W = XLEN / 8;
localparam integer BYTE_OFFSET_W = (STRB_W <= 1) ? 1 : $clog2(STRB_W);
localparam integer CACHE_WORDS_RAW = CACHE_SIZE / STRB_W;
localparam integer CACHE_WORDS = (CACHE_WORDS_RAW < 2) ? 2 : CACHE_WORDS_RAW;
localparam integer INDEX_W = (CACHE_WORDS <= 2) ? 1 : $clog2(CACHE_WORDS);
localparam integer TAG_LSB = BYTE_OFFSET_W + INDEX_W;
localparam integer CACHE_ADDR_BITS_CLAMPED =
    (CACHE_ADDR_BITS > XLEN) ? XLEN :
    (CACHE_ADDR_BITS <= TAG_LSB) ? (TAG_LSB + 1) :
    CACHE_ADDR_BITS;
localparam integer TAG_W = CACHE_ADDR_BITS_CLAMPED - TAG_LSB;

wire [BYTE_OFFSET_W-1:0] cpu_byte_offset;
wire [INDEX_W-1:0]       cpu_index;
wire [TAG_W-1:0]         cpu_tag;
wire [XLEN-1:0]          cpu_aligned_addr;
wire [INDEX_W-1:0]       probe_index;
wire [TAG_W-1:0]         probe_tag;
wire [CACHE_ADDR_BITS_CLAMPED-1:0] cpu_cache_addr;
wire [CACHE_ADDR_BITS_CLAMPED-1:0] probe_cache_addr;

assign cpu_byte_offset = cpu_addr[BYTE_OFFSET_W-1:0];
assign cpu_cache_addr = cpu_addr[CACHE_ADDR_BITS_CLAMPED-1:0];
assign probe_cache_addr = probe_addr[CACHE_ADDR_BITS_CLAMPED-1:0];
assign cpu_index = cpu_cache_addr[BYTE_OFFSET_W + INDEX_W - 1:BYTE_OFFSET_W];
assign cpu_tag = cpu_cache_addr[CACHE_ADDR_BITS_CLAMPED-1:TAG_LSB];
assign cpu_aligned_addr = {cpu_addr[XLEN-1:BYTE_OFFSET_W], {BYTE_OFFSET_W{1'b0}}};
assign probe_index = probe_cache_addr[BYTE_OFFSET_W + INDEX_W - 1:BYTE_OFFSET_W];
assign probe_tag = probe_cache_addr[CACHE_ADDR_BITS_CLAMPED-1:TAG_LSB];

(* ram_style = "distributed" *) reg [XLEN-1:0] cache_data [0:CACHE_WORDS-1];
(* ram_style = "distributed" *) reg [TAG_W-1:0] cache_tag [0:CACHE_WORDS-1];
reg cache_valid [0:CACHE_WORDS-1];

reg                  miss_valid_r;
reg                  miss_issued_r;
reg [XLEN-1:0]       miss_addr_r;
reg [INDEX_W-1:0]    miss_index_r;
reg [TAG_W-1:0]      miss_tag_r;
reg [BYTE_OFFSET_W-1:0] miss_byte_offset_r;
reg [1:0]            miss_size_r;
reg                  miss_unsigned_r;
reg                  prefetch_valid_r;
reg                  prefetch_issued_r;
reg [XLEN-1:0]       prefetch_addr_r;
reg [INDEX_W-1:0]    prefetch_index_r;
reg [TAG_W-1:0]      prefetch_tag_r;

wire cache_hit;
wire probe_line_evicted;
wire load_req;
wire store_req;
wire read_hit;
wire read_miss_start;
wire miss_return;
wire prefetch_return;
wire prefetch_busy;
wire prefetch_issue;
wire prefetch_start;
wire [XLEN-1:0] miss_next_addr;
wire [INDEX_W-1:0] miss_next_index;
wire [TAG_W-1:0] miss_next_tag;
wire cache_data_we;
wire [INDEX_W-1:0] cache_data_windex;
wire [XLEN-1:0] cache_data_wdata;

assign load_req = cpu_req && !cpu_we;
assign store_req = cpu_req && cpu_we && !miss_valid_r;
assign cache_hit = cache_valid[cpu_index] && (cache_tag[cpu_index] == cpu_tag);
assign probe_line_evicted = miss_return && (miss_index_r == probe_index) && (miss_tag_r != probe_tag);
assign probe_hit = probe_req && cache_valid[probe_index] && (cache_tag[probe_index] == probe_tag) && !probe_line_evicted;
assign read_hit = load_req && !miss_valid_r && cache_hit;
assign read_miss_start = load_req && !miss_valid_r && !prefetch_busy && !prefetch_return && !cache_hit;
assign miss_return = miss_valid_r && mem_rvalid;
assign prefetch_return = prefetch_valid_r && prefetch_issued_r && mem_rvalid;
assign prefetch_busy = (ENABLE_NEXT_PREFETCH != 0) && prefetch_valid_r && prefetch_issued_r && !prefetch_return;
assign prefetch_issue = (ENABLE_NEXT_PREFETCH != 0) && prefetch_valid_r && !prefetch_issued_r && !cpu_req && !miss_valid_r;
assign miss_next_addr = {miss_addr_r[XLEN-1:BYTE_OFFSET_W], {BYTE_OFFSET_W{1'b0}}} + {{(XLEN-BYTE_OFFSET_W-1){1'b0}}, 1'b1, {BYTE_OFFSET_W{1'b0}}};
assign miss_next_index = miss_next_addr[BYTE_OFFSET_W + INDEX_W - 1:BYTE_OFFSET_W];
assign miss_next_tag = miss_next_addr[CACHE_ADDR_BITS_CLAMPED-1:TAG_LSB];
assign prefetch_start =
    (ENABLE_NEXT_PREFETCH != 0) &&
    miss_return &&
    !(cache_valid[miss_next_index] && (cache_tag[miss_next_index] == miss_next_tag));

function automatic [XLEN-1:0] apply_wstrb;
    input [XLEN-1:0] old_value;
    input [XLEN-1:0] new_value;
    input [STRB_W-1:0] strobe;
    integer b;
    begin
        apply_wstrb = old_value;
        for (b = 0; b < STRB_W; b = b + 1) begin
            if (strobe[b]) begin
                apply_wstrb[b*8 +: 8] = new_value[b*8 +: 8];
            end
        end
    end
endfunction

function automatic [XLEN-1:0] format_load;
    input [XLEN-1:0] raw_word;
    input [BYTE_OFFSET_W-1:0] byte_offset;
    input [1:0] size;
    input unsigned_load;
    reg [XLEN-1:0] shifted;
    begin
        shifted = raw_word >> {byte_offset, 3'b000};
        case (size)
            `YH_rv_cpu_MEM_B:
                format_load = unsigned_load ?
                    {{(XLEN-8){1'b0}}, shifted[7:0]} :
                    {{(XLEN-8){shifted[7]}}, shifted[7:0]};
            `YH_rv_cpu_MEM_H:
                format_load = unsigned_load ?
                    {{(XLEN-16){1'b0}}, shifted[15:0]} :
                    {{(XLEN-16){shifted[15]}}, shifted[15:0]};
            `YH_rv_cpu_MEM_W:
                format_load = unsigned_load ?
                    {{(XLEN-32){1'b0}}, shifted[31:0]} :
                    {{(XLEN-32){shifted[31]}}, shifted[31:0]};
            default:
                format_load = shifted;
        endcase
    end
endfunction

assign cache_data_we = miss_return || prefetch_return || (store_req && cache_hit);
assign cache_data_windex = miss_return ? miss_index_r : prefetch_return ? prefetch_index_r : cpu_index;
assign cache_data_wdata =
    (miss_return || prefetch_return) ? mem_rdata :
    (WORD_ONLY != 0) ? cpu_wdata :
    apply_wstrb(cache_data[cpu_index], cpu_wdata, cpu_wstrb);

assign cpu_rvalid = read_hit || miss_return;
assign cpu_wait = read_miss_start || (miss_valid_r && !mem_rvalid) || ((prefetch_busy || prefetch_return) && cpu_req);
assign cpu_rdata =
    read_hit ? ((WORD_ONLY != 0) ? cache_data[cpu_index] : format_load(cache_data[cpu_index], cpu_byte_offset, cpu_size, cpu_unsigned)) :
    miss_return ? ((WORD_ONLY != 0) ? mem_rdata : format_load(mem_rdata, miss_byte_offset_r, miss_size_r, miss_unsigned_r)) :
    {XLEN{1'b0}};

assign mem_addr =
    store_req ? cpu_aligned_addr :
    read_miss_start ? cpu_aligned_addr :
    prefetch_issue ? prefetch_addr_r :
    {miss_addr_r[XLEN-1:BYTE_OFFSET_W], {BYTE_OFFSET_W{1'b0}}};
assign mem_req = read_miss_start || (miss_valid_r && !miss_issued_r) || prefetch_issue;
assign mem_we = store_req;
assign mem_wdata = cpu_wdata;
assign mem_wstrb = cpu_wstrb;

integer idx;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        miss_valid_r <= 1'b0;
        miss_issued_r <= 1'b0;
        miss_addr_r <= {XLEN{1'b0}};
        miss_index_r <= {INDEX_W{1'b0}};
        miss_tag_r <= {TAG_W{1'b0}};
        miss_byte_offset_r <= {BYTE_OFFSET_W{1'b0}};
        miss_size_r <= 2'b00;
        miss_unsigned_r <= 1'b0;
        prefetch_valid_r <= 1'b0;
        prefetch_issued_r <= 1'b0;
        prefetch_addr_r <= {XLEN{1'b0}};
        prefetch_index_r <= {INDEX_W{1'b0}};
        prefetch_tag_r <= {TAG_W{1'b0}};
        for (idx = 0; idx < CACHE_WORDS; idx = idx + 1) begin
            cache_valid[idx] <= 1'b0;
        end
    end else begin
        if ((ENABLE_NEXT_PREFETCH != 0) && prefetch_valid_r && !prefetch_issued_r && cpu_req) begin
            prefetch_valid_r <= 1'b0;
        end

        if (read_miss_start) begin
            miss_valid_r <= 1'b1;
            miss_issued_r <= 1'b1;
            miss_addr_r <= cpu_addr;
            miss_index_r <= cpu_index;
            miss_tag_r <= cpu_tag;
            miss_byte_offset_r <= cpu_byte_offset;
            miss_size_r <= cpu_size;
            miss_unsigned_r <= cpu_unsigned;
        end else if (miss_valid_r && !miss_issued_r) begin
            miss_issued_r <= 1'b1;
        end

        if (prefetch_issue) begin
            prefetch_issued_r <= 1'b1;
        end

        if (miss_return) begin
            cache_valid[miss_index_r] <= 1'b1;
            miss_valid_r <= 1'b0;
            miss_issued_r <= 1'b0;
            if (prefetch_start) begin
                prefetch_valid_r <= 1'b1;
                prefetch_issued_r <= 1'b0;
                prefetch_addr_r <= miss_next_addr;
                prefetch_index_r <= miss_next_index;
                prefetch_tag_r <= miss_next_tag;
            end
        end

        if (prefetch_return) begin
            cache_valid[prefetch_index_r] <= 1'b1;
            prefetch_valid_r <= 1'b0;
            prefetch_issued_r <= 1'b0;
        end
    end
end

always @(posedge clk) begin
    if (cache_data_we) begin
        cache_data[cache_data_windex] <= cache_data_wdata;
    end

    if (miss_return) begin
        cache_tag[miss_index_r] <= miss_tag_r;
    end

    if (prefetch_return) begin
        cache_tag[prefetch_index_r] <= prefetch_tag_r;
    end
end

endmodule
