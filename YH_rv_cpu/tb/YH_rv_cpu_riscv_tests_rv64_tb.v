`timescale 1ns / 1ps

module YH_rv_cpu_riscv_tests_rv64_tb;

// Thin RV64 wrapper around the shared riscv-tests bench.
YH_rv_cpu_riscv_tests_tb #(
    .XLEN(64)
) dut ();

endmodule
