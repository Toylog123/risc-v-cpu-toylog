`timescale 1ns / 1ps

module YH_rv_cpu_riscv_tests_rv32_tb;

// Thin RV32 wrapper around the shared riscv-tests bench.
YH_rv_cpu_riscv_tests_tb #(
    .XLEN(32)
) dut ();

endmodule
