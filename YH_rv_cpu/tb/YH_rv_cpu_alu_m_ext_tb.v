// YH_rv_cpu_alu_m_ext_tb.v - M扩展ALU测试
`timescale 1ns / 1ps
`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_alu_m_ext_tb;
reg clk;
reg [5:0] alu_op;
reg [31:0] lhs, rhs;
wire [31:0] result;

YH_rv_cpu_alu #(
    .XLEN(32)
) dut (
    .alu_op(alu_op),
    .lhs(lhs),
    .rhs(rhs),
    .result(result),
    .eq(),
    .lt(),
    .ltu()
);

always #5 clk = ~clk;

integer pass_count = 0;
integer fail_count = 0;

task check;
    input [31:0] expected;
    input [31:0] actual;
    input [127:0] desc;
    begin
        if (expected === actual) begin
            $display("[PASS] %s: 0x%h", desc, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s: expected=0x%h, actual=0x%h", desc, expected, actual);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    $display("========================================");
    $display("M扩展ALU单元测试");
    $display("========================================");

    clk = 0;

    // TEST 1: MUL 5 * 3 = 15
    alu_op = `YH_rv_cpu_ALU_MUL;
    lhs = 32'd5;
    rhs = 32'd3;
    #10;
    check(32'd15, result, "MUL 5*3");

    // TEST 2: MULH (-2) * (-3) 高位 = 0
    alu_op = `YH_rv_cpu_ALU_MULH;
    lhs = 32'hFFFFFFFE;
    rhs = 32'hFFFFFFFD;
    #10;
    check(32'd0, result, "MULH (-2)*(-3)");

    // TEST 3: MULHU 0xFFFFFFFF * 2 高位
    alu_op = `YH_rv_cpu_ALU_MULHU;
    lhs = 32'hFFFFFFFF;
    rhs = 32'd2;
    #10;
    check(32'h00000001, result, "MULHU 0xFFFFFFFF*2");

    // TEST 4: MULHSU (-1) * 2 高位 = 0xFFFFFFFF
    alu_op = `YH_rv_cpu_ALU_MULHSU;
    lhs = 32'hFFFFFFFF;
    rhs = 32'd2;
    #10;
    check(32'hFFFFFFFF, result, "MULHSU (-1)*2");

    // TEST 5: DIV 10 / 3 = 3
    alu_op = `YH_rv_cpu_ALU_DIV;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd3, result, "DIV 10/3");

    // TEST 6: DIVU 10 / 3 = 3
    alu_op = `YH_rv_cpu_ALU_DIVU;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd3, result, "DIVU 10/3");

    // TEST 7: REM 10 % 3 = 1
    alu_op = `YH_rv_cpu_ALU_REM;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd1, result, "REM 10%3");

    // TEST 8: REMU 10 % 3 = 1
    alu_op = `YH_rv_cpu_ALU_REMU;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd1, result, "REMU 10%3");

    // TEST 9: DIV 10 / 0 = 0xFFFFFFFF
    alu_op = `YH_rv_cpu_ALU_DIV;
    lhs = 32'd10;
    rhs = 32'd0;
    #10;
    check(32'hFFFFFFFF, result, "DIV 10/0");

    // TEST 10: REM 10 % 0 = 10
    alu_op = `YH_rv_cpu_ALU_REM;
    lhs = 32'd10;
    rhs = 32'd0;
    #10;
    check(32'd10, result, "REM 10%0");

    // TEST 11: DIV (-10) / 3 = -3
    alu_op = `YH_rv_cpu_ALU_DIV;
    lhs = 32'hFFFFFFF6;
    rhs = 32'd3;
    #10;
    check(32'hFFFFFFFD, result, "DIV (-10)/3");

    $display("========================================");
    $display("测试完成: %0d/%0d 通过", pass_count, pass_count + fail_count);
    if (fail_count == 0) begin
        $display("结果: 全部通过!");
    end else begin
        $display("结果: %0d 个失败", fail_count);
    end
    $display("========================================");
    $finish;
end
endmodule
