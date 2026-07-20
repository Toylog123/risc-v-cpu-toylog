`timescale 1ns / 1ps

module YH_rv_cpu_ex_mem_load_ready_forward_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
reg  [31:0] imem_rdata_r;
wire        imem_rvalid;
reg         imem_rvalid_r;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
reg  [31:0] dmem_rdata_r;
wire        dmem_rvalid;
reg         dmem_rvalid_r;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:31];
reg [7:0]  dmem [0:255];
integer cycle;
integer idx;
integer timeout_cycles;
integer ex_mem_load_hazard_cycles;
integer ex_mem_load_stall_cycles;
integer ex_mem_load_ready_stall_cycles;
integer stall_decode_cycles;
reg     require_no_ex_mem_load_ready_stall;

assign imem_rdata = imem_rdata_r;
assign imem_rvalid = imem_rvalid_r;
assign dmem_rdata = dmem_rdata_r;
assign dmem_rvalid = dmem_rvalid_r;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
    .RESET_VECTOR(32'h0000_0000)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
    .imem_req  (imem_req),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_read_req(dmem_read_req),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
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

function [31:0] rv32_j;
    input signed [20:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    integer word_index;
    if (!rst_n) begin
        imem_rvalid_r <= 1'b0;
        imem_rdata_r <= 32'h0000_0013;
        dmem_rvalid_r <= 1'b0;
        dmem_rdata_r <= 32'h0000_0000;
    end else begin
        imem_rvalid_r <= imem_req;
        imem_rdata_r <= imem[imem_addr[31:2]];

        dmem_rvalid_r <= dmem_read_req;
        word_index = {dmem_addr[31:2], 2'b00};
        dmem_rdata_r <= {
            dmem[word_index + 3],
            dmem[word_index + 2],
            dmem[word_index + 1],
            dmem[word_index + 0]
        };
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.u_hazard_unit.ex_mem_load_use_hazard) begin
            ex_mem_load_hazard_cycles <= ex_mem_load_hazard_cycles + 1;
        end
        if (dut.u_hazard_unit.ex_mem_load_use_hazard && dut.stall_decode) begin
            ex_mem_load_stall_cycles <= ex_mem_load_stall_cycles + 1;
        end
        if (dut.u_hazard_unit.ex_mem_load_use_hazard && dut.stall_decode && dmem_rvalid) begin
            ex_mem_load_ready_stall_cycles <= ex_mem_load_ready_stall_cycles + 1;
        end
        if (dut.stall_decode) begin
            stall_decode_cycles <= stall_decode_cycles + 1;
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 12) &&
            (dut.u_regfile.regs[3] == 32'd42) &&
            (dut.u_regfile.regs[4] == 32'd1) &&
            (dut.u_regfile.regs[6] == 32'd43)) begin
            if (require_no_ex_mem_load_ready_stall && (ex_mem_load_ready_stall_cycles != 0)) begin
                $fatal(1,
                    "FAIL: observed EX/MEM ready load-use stall cycles=%0d total_ex_mem_load_stall_cycles=%0d hazard_match_cycles=%0d stall_decode_cycles=%0d",
                    ex_mem_load_ready_stall_cycles,
                    ex_mem_load_stall_cycles,
                    ex_mem_load_hazard_cycles,
                    stall_decode_cycles);
            end

            $display(
                "PASS: ex/mem ready load forward diagnostic completed at PC=%h cycles=%0d ex_mem_load_hazard_cycles=%0d ex_mem_load_stall_cycles=%0d ex_mem_load_ready_stall_cycles=%0d stall_decode_cycles=%0d require_no_ex_mem_load_ready_stall=%0d",
                debug_pc,
                cycle,
                ex_mem_load_hazard_cycles,
                ex_mem_load_stall_cycles,
                ex_mem_load_ready_stall_cycles,
                stall_decode_cycles,
                require_no_ex_mem_load_ready_stall);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d x3=%h x4=%h x6=%h ex_mem_load_hazard_cycles=%0d ex_mem_load_stall_cycles=%0d ex_mem_load_ready_stall_cycles=%0d",
                debug_pc,
                cycle,
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[4],
                dut.u_regfile.regs[6],
                ex_mem_load_hazard_cycles,
                ex_mem_load_stall_cycles,
                ex_mem_load_ready_stall_cycles);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    timeout_cycles = 120;
    ex_mem_load_hazard_cycles = 0;
    ex_mem_load_stall_cycles = 0;
    ex_mem_load_ready_stall_cycles = 0;
    stall_decode_cycles = 0;
    require_no_ex_mem_load_ready_stall = 1'b0;

    if ($test$plusargs("require_no_ex_mem_load_ready_stall")) begin
        require_no_ex_mem_load_ready_stall = 1'b1;
    end
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 120;
    end

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end
    for (idx = 0; idx < 256; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011); // addi x1, x0, 0
    imem[1] = rv32_i(12'sd0, 5'd1, 3'b010, 5'd3, 7'b0000011); // lw x3, 0(x1)
    imem[2] = rv32_i(12'sd1, 5'd0, 3'b000, 5'd4, 7'b0010011); // independent
    imem[3] = rv32_i(12'sd1, 5'd3, 3'b000, 5'd6, 7'b0010011); // addi x6, x3, 1
    imem[4] = rv32_j(21'sd0, 5'd0, 7'b1101111); // park

    dmem[0] = 8'h2a;
    dmem[1] = 8'h00;
    dmem[2] = 8'h00;
    dmem[3] = 8'h00;

    #20;
    rst_n = 1'b1;
end

endmodule
