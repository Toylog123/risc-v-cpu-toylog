`timescale 1ns / 1ps

module YH_rv_cpu_coremark_rv32_zmmul_bitmanip_xthead_noidbr_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex";

YH_rv_cpu_coremark_tb #(
    .XLEN(32),
    .ROM_HEX(ROM_HEX),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(1),
    .ENABLE_XTHEAD_MUL_EXTENSION(0),
    .ENABLE_XTHEAD_COND_MOVE(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(0)
) uut ();

endmodule
