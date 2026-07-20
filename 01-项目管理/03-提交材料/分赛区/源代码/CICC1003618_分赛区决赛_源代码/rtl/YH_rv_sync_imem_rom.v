module YH_rv_sync_imem_rom #(
    parameter integer ROM_WORDS = 1024,
    parameter string ROM_INIT_HEX = "",
    parameter integer OUTPUT_REG = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_hit,
    input  wire [31:0] word_index,
    output wire [31:0] rdata,
    output wire        rvalid
);

(* rom_style = "block" *) reg [31:0] rom_mem [0:ROM_WORDS-1];
reg [31:0] rdata_r;
reg [31:0] rdata_pipe_r;
reg        rvalid_r;
reg        rvalid_pipe_r;
localparam integer ROM_ADDR_W = (ROM_WORDS <= 1) ? 1 : $clog2(ROM_WORDS);
wire                   word_hit;
wire [ROM_ADDR_W-1:0]  word_addr;

integer idx;

assign rdata = (OUTPUT_REG != 0) ? rdata_pipe_r : rdata_r;
assign rvalid = (OUTPUT_REG != 0) ? rvalid_pipe_r : rvalid_r;
assign word_hit = (word_index < ROM_WORDS);
assign word_addr = word_index[ROM_ADDR_W-1:0];

initial begin
    for (idx = 0; idx < ROM_WORDS; idx = idx + 1) begin
        rom_mem[idx] = 32'h0000_0013;
    end

    if (ROM_INIT_HEX != "") begin
        $readmemh(ROM_INIT_HEX, rom_mem);
    end

    rdata_r = 32'h0000_0013;
    rdata_pipe_r = 32'h0000_0013;
    rvalid_r = 1'b0;
    rvalid_pipe_r = 1'b0;
end

always @(posedge clk) begin
    rvalid_r <= req_hit && word_hit;
    rdata_r <= rom_mem[word_addr];

    if (OUTPUT_REG != 0) begin
        rdata_pipe_r <= rdata_r;
        rvalid_pipe_r <= rvalid_r;
    end
end

endmodule
