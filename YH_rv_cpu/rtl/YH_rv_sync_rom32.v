module YH_rv_sync_rom32 #(
    parameter integer ROM_WORDS = 1024,
    parameter string ROM_INIT_HEX = "",
    parameter integer IMEM_OUTPUT_REG = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        imem_req,
    input  wire [31:0] imem_word_index,
    output wire [31:0] imem_rdata,
    output wire        imem_rvalid,
    input  wire        data_req,
    input  wire [31:0] data_word_index,
    output wire [31:0] data_rdata
);

(* rom_style = "block" *) reg [31:0] rom_mem [0:ROM_WORDS-1];
reg [31:0] imem_rdata_r;
reg [31:0] imem_rdata_pipe_r;
reg [31:0] data_rdata_r;
reg        imem_rvalid_r;
reg        imem_rvalid_pipe_r;
localparam integer ROM_ADDR_W = (ROM_WORDS <= 1) ? 1 : $clog2(ROM_WORDS);
wire                   imem_word_hit;
wire [ROM_ADDR_W-1:0]  imem_word_addr;
wire [ROM_ADDR_W-1:0]  data_word_addr;

integer idx;

assign imem_rdata = (IMEM_OUTPUT_REG != 0) ? imem_rdata_pipe_r : imem_rdata_r;
assign imem_rvalid = (IMEM_OUTPUT_REG != 0) ? imem_rvalid_pipe_r : imem_rvalid_r;
assign data_rdata = data_rdata_r;
assign imem_word_hit = (imem_word_index < ROM_WORDS);
assign imem_word_addr = imem_word_index[ROM_ADDR_W-1:0];
assign data_word_addr = data_word_index[ROM_ADDR_W-1:0];

initial begin
    for (idx = 0; idx < ROM_WORDS; idx = idx + 1) begin
        rom_mem[idx] = 32'h0000_0013;
    end

    if (ROM_INIT_HEX != "") begin
        $readmemh(ROM_INIT_HEX, rom_mem);
    end

    imem_rdata_r = 32'h0000_0013;
    imem_rdata_pipe_r = 32'h0000_0013;
    data_rdata_r = 32'h0000_0013;
    imem_rvalid_r = 1'b0;
    imem_rvalid_pipe_r = 1'b0;
end

always @(posedge clk) begin
    imem_rvalid_r <= imem_req && imem_word_hit;
    imem_rdata_r <= rom_mem[imem_word_addr];
    data_rdata_r <= rom_mem[data_word_addr];

    if (IMEM_OUTPUT_REG != 0) begin
        imem_rdata_pipe_r <= imem_rdata_r;
        imem_rvalid_pipe_r <= imem_rvalid_r;
    end
end

endmodule
