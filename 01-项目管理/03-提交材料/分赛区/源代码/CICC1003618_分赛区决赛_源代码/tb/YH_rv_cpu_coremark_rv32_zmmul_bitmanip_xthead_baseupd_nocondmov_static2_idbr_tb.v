`timescale 1ns / 1ps

module YH_rv_cpu_coremark_rv32_zmmul_bitmanip_xthead_baseupd_nocondmov_static2_idbr_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex";

YH_rv_cpu_coremark_tb #(
    .XLEN(32),
    .ROM_HEX(ROM_HEX),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_ZBC_EXTENSION(0),
    .ENABLE_ZICOND_EXTENSION(0),
    .ENABLE_XTHEAD_EXTENSION(1),
    .ENABLE_XTHEAD_MUL_EXTENSION(0),
    .ENABLE_XTHEAD_COND_MOVE(0),
    .ENABLE_XTHEAD_ADDSL_EXTENSION(0),
    .ENABLE_XTHEAD_MEMPAIR_EXTENSION(0),
    .ENABLE_XTHEAD_BASE_UPDATE_EXTENSION(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(1),
    .ENABLE_REDIRECT_TARGET_CACHE(0),
    .BRANCH_STATIC_PREDICT_MODE(2),
    .DMEM_NEGEDGE_READ(0)
) uut ();

endmodule
