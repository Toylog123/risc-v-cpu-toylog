`timescale 1ns / 1ps

module YH_rv_cpu_coremark_rv64_tb;

// Thin RV64 wrapper around the shared CoreMark bench.
localparam string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv64.hex";

YH_rv_cpu_coremark_tb #(
    .XLEN(64),
    .ROM_HEX(ROM_HEX)
) uut ();

endmodule
