`timescale 1ns / 1ps

module YH_rv_cpu_shared_sync_negedge_read_tb;

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
integer mem_wait_cycles;
integer stall_decode_cycles;
integer static_predict_during_stall_cycles;
integer id_redirect_enters_ex_cycles;
integer timeout_cycles;
reg     require_no_mem_wait;
reg     load_branch_static_predict;
reg     require_static_predict_during_stall;
reg     id_redirect_enters_ex;
reg     require_id_redirect_enters_ex;

YH_rv_cpu_soc #(
    .XLEN(32),
    .SYNC_IMEM(1),
    .IMEM_OUTPUT_REG(0),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
    .DMEM_NEGEDGE_READ(1),
    .ROM_BYTES(256),
    .RAM_BYTES(256)
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

function [31:0] rv32_b;
    input signed [12:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
        rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    end
endfunction

function [31:0] rv32_j;
    input signed [20:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    end
endfunction

task load_rom_word;
    input integer word_index;
    input [31:0] value;
    begin
        dut.g_shared_sync_rom.u_sync_rom.rom_mem[word_index] = value;
    end
endtask

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;
        if (dut.u_cpu.mem_wait) begin
            mem_wait_cycles <= mem_wait_cycles + 1;
        end
        if (dut.u_cpu.stall_decode) begin
            stall_decode_cycles <= stall_decode_cycles + 1;
        end
        if (dut.u_cpu.id_branch_predict_redirect_valid &&
            dut.u_cpu.stall_decode &&
            (dut.u_cpu.if_id_pc_r == 32'h0000_0008)) begin
            static_predict_during_stall_cycles <= static_predict_during_stall_cycles + 1;
        end
        if (dut.u_cpu.id_ex_valid_r &&
            dut.u_cpu.id_ex_branch_r &&
            dut.u_cpu.id_ex_branch_predict_taken_r &&
            (dut.u_cpu.id_ex_pc_r == 32'h0000_0004)) begin
            id_redirect_enters_ex_cycles <= id_redirect_enters_ex_cycles + 1;
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (id_redirect_enters_ex &&
            (cycle > 10) &&
            (dut.u_cpu.u_regfile.regs[2] == 32'd42)) begin
            if (dut.u_cpu.u_regfile.regs[5] != 32'd0) begin
                $fatal(1, "FAIL: id redirect poison path executed x5=%h", dut.u_cpu.u_regfile.regs[5]);
            end
            if (require_id_redirect_enters_ex && (id_redirect_enters_ex_cycles == 0)) begin
                $fatal(1, "FAIL: ID redirect did not enter EX for validation");
            end
            $display(
                "PASS: ID redirect EX validation diagnostic completed cycles=%0d id_redirect_enters_ex_cycles=%0d",
                cycle,
                id_redirect_enters_ex_cycles);
            $finish;
        end

        if (!id_redirect_enters_ex &&
            load_branch_static_predict &&
            (cycle > 10) &&
            (dut.u_cpu.u_regfile.regs[2] == 32'd42)) begin
            if (dut.u_cpu.u_regfile.regs[5] != 32'd0) begin
                $fatal(1, "FAIL: load-branch poison path executed x5=%h", dut.u_cpu.u_regfile.regs[5]);
            end
            if (require_static_predict_during_stall && (static_predict_during_stall_cycles == 0)) begin
                $fatal(1,
                    "FAIL: load-dependent static branch did not redirect during stall; stall_decode_cycles=%0d",
                    stall_decode_cycles);
            end
            $display(
                "PASS: load branch static predict diagnostic completed cycles=%0d mem_wait_cycles=%0d stall_decode_cycles=%0d static_predict_during_stall_cycles=%0d",
                cycle,
                mem_wait_cycles,
                stall_decode_cycles,
                static_predict_during_stall_cycles);
            $finish;
        end

        if (!id_redirect_enters_ex &&
            !load_branch_static_predict &&
            (cycle > 10) &&
            (dut.u_cpu.u_regfile.regs[2] == 32'd42) &&
            (dut.u_cpu.u_regfile.regs[3] == 32'd43)) begin
            if (require_no_mem_wait && (mem_wait_cycles != 0)) begin
                $fatal(1,
                    "FAIL: shared sync negedge read still observed mem_wait_cycles=%0d stall_decode_cycles=%0d",
                    mem_wait_cycles,
                    stall_decode_cycles);
            end

            $display(
                "PASS: shared sync negedge read diagnostic completed at PC=%h cycles=%0d mem_wait_cycles=%0d stall_decode_cycles=%0d require_no_mem_wait=%0d",
                debug_pc,
                cycle,
                mem_wait_cycles,
                stall_decode_cycles,
                require_no_mem_wait);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d x2=%h x3=%h mem_wait_cycles=%0d stall_decode_cycles=%0d",
                debug_pc,
                cycle,
                dut.u_cpu.u_regfile.regs[2],
                dut.u_cpu.u_regfile.regs[3],
                mem_wait_cycles,
                stall_decode_cycles);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    mem_wait_cycles = 0;
    stall_decode_cycles = 0;
    static_predict_during_stall_cycles = 0;
    id_redirect_enters_ex_cycles = 0;
    timeout_cycles = 160;
    require_no_mem_wait = 1'b0;
    load_branch_static_predict = 1'b0;
    require_static_predict_during_stall = 1'b0;
    id_redirect_enters_ex = 1'b0;
    require_id_redirect_enters_ex = 1'b0;

    if ($test$plusargs("require_no_mem_wait")) begin
        require_no_mem_wait = 1'b1;
    end
    if ($test$plusargs("load_branch_static_predict")) begin
        load_branch_static_predict = 1'b1;
    end
    if ($test$plusargs("require_static_predict_during_stall")) begin
        require_static_predict_during_stall = 1'b1;
    end
    if ($test$plusargs("id_redirect_enters_ex")) begin
        id_redirect_enters_ex = 1'b1;
    end
    if ($test$plusargs("require_id_redirect_enters_ex")) begin
        require_id_redirect_enters_ex = 1'b1;
    end
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 160;
    end

    for (idx = 0; idx < 64; idx = idx + 1) begin
        load_rom_word(idx, 32'h0000_0013);
    end

    if (id_redirect_enters_ex) begin
        load_rom_word(0, rv32_i(12'sd1, 5'd0, 3'b000, 5'd1, 7'b0010011));  // addi x1, x0, 1
        load_rom_word(1, rv32_b(13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011));  // bne x1, x0, target
        load_rom_word(2, rv32_i(12'sd99, 5'd0, 3'b000, 5'd5, 7'b0010011)); // poison
        load_rom_word(3, rv32_i(12'sd42, 5'd0, 3'b000, 5'd2, 7'b0010011)); // target
        load_rom_word(4, rv32_j(21'sd0, 5'd0, 7'b1101111)); // park
    end else if (load_branch_static_predict) begin
        load_rom_word(0, rv32_i(12'sd64, 5'd0, 3'b000, 5'd10, 7'b0010011)); // addi x10, x0, 64
        load_rom_word(1, rv32_i(12'sd0, 5'd10, 3'b010, 5'd1, 7'b0000011));  // lw x1, 0(x10)
        load_rom_word(2, rv32_b(13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011));  // bne x1, x0, target
        load_rom_word(3, rv32_i(12'sd99, 5'd0, 3'b000, 5'd5, 7'b0010011)); // poison
        load_rom_word(4, rv32_i(12'sd42, 5'd0, 3'b000, 5'd2, 7'b0010011)); // target
        load_rom_word(5, rv32_j(21'sd0, 5'd0, 7'b1101111)); // park
        load_rom_word(16, 32'd1);
    end else begin
        load_rom_word(0, rv32_i(12'sd64, 5'd0, 3'b000, 5'd1, 7'b0010011)); // addi x1, x0, 64
        load_rom_word(1, rv32_i(12'sd0, 5'd1, 3'b010, 5'd2, 7'b0000011));  // lw x2, 0(x1)
        load_rom_word(2, rv32_i(12'sd1, 5'd2, 3'b000, 5'd3, 7'b0010011));  // addi x3, x2, 1
        load_rom_word(3, rv32_j(21'sd0, 5'd0, 7'b1101111)); // park
        load_rom_word(16, 32'd42);
    end

    #20;
    rst_n = 1'b1;
end

endmodule
