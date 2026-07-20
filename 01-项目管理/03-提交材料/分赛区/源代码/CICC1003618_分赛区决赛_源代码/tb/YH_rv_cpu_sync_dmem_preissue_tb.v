`timescale 1ns / 1ps

module YH_rv_cpu_sync_dmem_preissue_tb;

reg         clk;
reg         rst_n;
wire        trap;
wire [31:0] debug_pc;
wire        uart_tx_valid;
wire [7:0]  uart_tx_data;
wire        done;
wire        timer_irq;

integer cycle;
integer idx;
integer stall_decode_cycles;
integer mem_wait_cycles;
integer timeout_cycles;
reg     require_no_stall_decode;
reg     require_no_mem_wait;
reg     debug_trace;

YH_rv_cpu_soc #(
    .SYNC_IMEM(0),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
    .DMEM_NEGEDGE_READ(0),
    .DMEM_READ_PREISSUE(1),
    .RAM_BASE(32'h0001_0000),
    .ROM_BYTES(256),
    .RAM_BYTES(1024)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .trap         (trap),
    .debug_pc     (debug_pc),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data (uart_tx_data),
    .done         (done),
    .timer_irq    (timer_irq)
);

function [31:0] rv32_i;
    input signed [11:0] imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_i = {imm[11:0], rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_s;
    input signed [11:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
        rv32_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    end
endfunction

function [31:0] rv32_u;
    input [19:0] imm20;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_u = {imm20, rd, opcode};
    end
endfunction

task load_rom_word;
    input integer word_index;
    input [31:0] value;
    integer byte_index;
    begin
        byte_index = word_index * 4;
        dut.rom_mem[byte_index + 0] = value[7:0];
        dut.rom_mem[byte_index + 1] = value[15:8];
        dut.rom_mem[byte_index + 2] = value[23:16];
        dut.rom_mem[byte_index + 3] = value[31:24];
    end
endtask

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.u_cpu.stall_decode) begin
            stall_decode_cycles <= stall_decode_cycles + 1;
        end
        if (dut.u_cpu.mem_wait) begin
            mem_wait_cycles <= mem_wait_cycles + 1;
        end

        if (debug_trace && (cycle < 80)) begin
            $display(
                "TRACE cycle=%0d pc=%h stall=%0d mem_wait=%0d dmem_req=%0d dmem_rvalid=%0d id_ex_pc=%h ex_mem_pc=%h x2=%h x3=%h x4=%h",
                cycle,
                debug_pc,
                dut.u_cpu.stall_decode,
                dut.u_cpu.mem_wait,
                dut.u_cpu.dmem_read_req,
                dut.u_cpu.dmem_rvalid,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.ex_mem_pc4_r - 4,
                dut.u_cpu.u_regfile.regs[2],
                dut.u_cpu.u_regfile.regs[3],
                dut.u_cpu.u_regfile.regs[4]
            );
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 10) &&
            (dut.u_cpu.u_regfile.regs[2] == 32'd41) &&
            (dut.u_cpu.u_regfile.regs[3] == 32'd42) &&
            (dut.u_cpu.u_regfile.regs[4] == 32'd43)) begin
            if (require_no_stall_decode && (stall_decode_cycles != 0)) begin
                $fatal(1,
                    "FAIL: expected zero load-use decode stalls, observed %0d",
                    stall_decode_cycles);
            end
            if (require_no_mem_wait && (mem_wait_cycles != 0)) begin
                $fatal(1,
                    "FAIL: expected zero sync-DMem wait cycles, observed %0d",
                    mem_wait_cycles);
            end

            $display(
                "PASS: sync dmem preissue diagnostic PC=%h cycles=%0d stall_decode=%0d mem_wait=%0d",
                debug_pc,
                cycle,
                stall_decode_cycles,
                mem_wait_cycles);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout PC=%h cycle=%0d stall_decode=%0d mem_wait=%0d x2=%h x3=%h x4=%h",
                debug_pc,
                cycle,
                stall_decode_cycles,
                mem_wait_cycles,
                dut.u_cpu.u_regfile.regs[2],
                dut.u_cpu.u_regfile.regs[3],
                dut.u_cpu.u_regfile.regs[4]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    stall_decode_cycles = 0;
    mem_wait_cycles = 0;
    timeout_cycles = 160;
    require_no_stall_decode = 1'b0;
    require_no_mem_wait = 1'b0;
    debug_trace = 1'b0;

    if ($test$plusargs("require_no_stall_decode")) begin
        require_no_stall_decode = 1'b1;
    end
    if ($test$plusargs("require_no_mem_wait")) begin
        require_no_mem_wait = 1'b1;
    end
    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 160;
    end

    for (idx = 0; idx < 256; idx = idx + 1) begin
        dut.rom_mem[idx] = 8'h13;
    end

    load_rom_word(0, rv32_u(20'h00010, 5'd1, 7'b0110111));                 // x1 = RAM base
    load_rom_word(1, rv32_i(12'sd41, 5'd0, 3'b000, 5'd5, 7'b0010011));      // x5 = 41
    load_rom_word(2, rv32_s(12'sd0, 5'd5, 5'd1, 3'b010, 7'b0100011));       // sw x5, 0(x1)
    load_rom_word(3, rv32_i(12'sd0, 5'd1, 3'b010, 5'd2, 7'b0000011));       // lw x2, 0(x1)
    load_rom_word(4, rv32_i(12'sd1, 5'd2, 3'b000, 5'd3, 7'b0010011));       // x3 = x2 + 1
    load_rom_word(5, rv32_i(12'sd1, 5'd3, 3'b000, 5'd4, 7'b0010011));       // x4 = x3 + 1
    load_rom_word(6, rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011));       // park

    #20;
    rst_n = 1'b1;
end

endmodule
