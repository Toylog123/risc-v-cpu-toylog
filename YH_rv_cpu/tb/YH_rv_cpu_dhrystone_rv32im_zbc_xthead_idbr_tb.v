`timescale 1ns / 1ps

module YH_rv_cpu_dhrystone_rv32im_zbc_xthead_idbr_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_dhrystone.hex";

YH_rv_cpu_dhrystone_tb #(
    .ROM_HEX(ROM_HEX),
    .ENABLE_M_EXTENSION(1),
    .ENABLE_ZMMUL_EXTENSION(0),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_ZBC_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(1),
    .ENABLE_XTHEAD_COND_MOVE(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(1)
) uut ();

endmodule
