`timescale 1ns / 1ps

module YH_rv_cpu_coremark_rv32_tb;

// Thin RV32 wrapper around the shared CoreMark bench.
localparam string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex";

YH_rv_cpu_coremark_tb #(
    .XLEN(32),
    .ROM_HEX(ROM_HEX)
) uut ();

endmodule
