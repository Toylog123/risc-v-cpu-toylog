module YH_rv_sync_imem_rom #(
    parameter integer ROM_WORDS = 1024,
    parameter string ROM_INIT_HEX = ""
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_hit,
    input  wire [31:0] word_index,
    output reg  [31:0] rdata,
    output reg         rvalid
);

(* rom_style = "block" *) reg [31:0] rom_mem [0:ROM_WORDS-1];

integer idx;

initial begin
    for (idx = 0; idx < ROM_WORDS; idx = idx + 1) begin
        rom_mem[idx] = 32'h0000_0013;
    end

    if (ROM_INIT_HEX != "") begin
        $readmemh(ROM_INIT_HEX, rom_mem);
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 32'h0000_0013;
        rvalid <= 1'b0;
    end else begin
        rvalid <= req_hit;

        if (req_hit && (word_index < ROM_WORDS)) begin
            rdata <= rom_mem[word_index];
        end else begin
            rdata <= 32'h0000_0013;
        end
    end
end

endmodule
