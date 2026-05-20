`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_dcache #(
    parameter integer XLEN = 32,
    parameter integer CACHE_SIZE = 4096,
    parameter integer BLOCK_SIZE = 4,
    parameter integer ASSOC = 1,
    parameter integer WRITE_POLICY = 0,
    parameter integer CACHE_ID = 0
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
localparam integer TAG_W = (XLEN > TAG_LSB) ? (XLEN - TAG_LSB) : 1;

wire [BYTE_OFFSET_W-1:0] cpu_byte_offset;
wire [INDEX_W-1:0]       cpu_index;
wire [TAG_W-1:0]         cpu_tag;
wire [XLEN-1:0]          cpu_aligned_addr;

assign cpu_byte_offset = cpu_addr[BYTE_OFFSET_W-1:0];
assign cpu_index = cpu_addr[BYTE_OFFSET_W + INDEX_W - 1:BYTE_OFFSET_W];
assign cpu_tag = cpu_addr[XLEN-1:TAG_LSB];
assign cpu_aligned_addr = {cpu_addr[XLEN-1:BYTE_OFFSET_W], {BYTE_OFFSET_W{1'b0}}};

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

wire cache_hit;
wire load_req;
wire store_req;
wire read_hit;
wire read_miss_start;
wire miss_return;

assign load_req = cpu_req && !cpu_we;
assign store_req = cpu_req && cpu_we && !miss_valid_r;
assign cache_hit = cache_valid[cpu_index] && (cache_tag[cpu_index] == cpu_tag);
assign read_hit = load_req && !miss_valid_r && cache_hit;
assign read_miss_start = load_req && !miss_valid_r && !cache_hit;
assign miss_return = miss_valid_r && mem_rvalid;

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

assign cpu_rvalid = read_hit || miss_return;
assign cpu_wait = read_miss_start || (miss_valid_r && !mem_rvalid);
assign cpu_rdata =
    read_hit ? format_load(cache_data[cpu_index], cpu_byte_offset, cpu_size, cpu_unsigned) :
    miss_return ? format_load(mem_rdata, miss_byte_offset_r, miss_size_r, miss_unsigned_r) :
    {XLEN{1'b0}};

assign mem_addr =
    store_req ? cpu_aligned_addr :
    read_miss_start ? cpu_aligned_addr :
    {miss_addr_r[XLEN-1:BYTE_OFFSET_W], {BYTE_OFFSET_W{1'b0}}};
assign mem_req = read_miss_start || (miss_valid_r && !miss_issued_r);
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
        for (idx = 0; idx < CACHE_WORDS; idx = idx + 1) begin
            cache_valid[idx] <= 1'b0;
            cache_tag[idx] <= {TAG_W{1'b0}};
            cache_data[idx] <= {XLEN{1'b0}};
        end
    end else begin
        if (store_req && cache_hit) begin
            cache_data[cpu_index] <= apply_wstrb(cache_data[cpu_index], cpu_wdata, cpu_wstrb);
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

        if (miss_return) begin
            cache_valid[miss_index_r] <= 1'b1;
            cache_tag[miss_index_r] <= miss_tag_r;
            cache_data[miss_index_r] <= mem_rdata;
            miss_valid_r <= 1'b0;
            miss_issued_r <= 1'b0;
        end
    end
end

endmodule
