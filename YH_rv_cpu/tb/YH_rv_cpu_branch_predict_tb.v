`timescale 1ns / 1ps

module YH_rv_cpu_branch_predict_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:15];
integer cycle;
integer idx;
integer load_reads;
integer ex_bne_redirects;
integer id_forward_beq_predict_redirects;
integer timeout_cycles;
reg     use_forward_bne;
reg     use_forward_bne_not_taken;
reg     use_forward_beq_train;
reg     require_forward_beq_dynamic_predict;
reg     trace_branch;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rvalid = 1'b1;
assign dmem_rdata =
    use_forward_beq_train ? 32'd1 :
    use_forward_bne_not_taken ? 32'd0 :
    use_forward_bne ? 32'd1 :
    ((load_reads == 0) ? 32'd1 : 32'd0);

YH_rv_cpu #(
    .IMEM_SYNC(0),
    .DMEM_SYNC(0),
    .ENABLE_DYNAMIC_BRANCH_PREDICT(1),
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
    .dmem_ready(1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_we   (),
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

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dmem_read_req) begin
            load_reads <= load_reads + 1;
        end

        if (dut.ex_redirect_valid && dut.id_ex_branch_r && (dut.id_ex_branch_funct3_r == 3'b001)) begin
            ex_bne_redirects <= ex_bne_redirects + 1;
        end
        if (dut.id_branch_predict_redirect_valid &&
            (dut.id_branch_funct3 == 3'b000) &&
            (dut.if_id_pc_r == 32'h0000_0010)) begin
            id_forward_beq_predict_redirects <= id_forward_beq_predict_redirects + 1;
        end

        if (trace_branch &&
            (use_forward_beq_train || dut.branch_bht_update_valid) &&
            ((dut.if_id_pc_r == 32'h0000_0010) || dut.branch_bht_update_valid)) begin
            $display(
                "TRACE cycle=%0d if_id_pc=%h id_branch=%0d ready=%0d exact=%0d pred=%0d bht_hit=%0d dyn=%0d update=%0d upd_pc=%h upd_taken=%0d stall=%0d ex_redir=%0d",
                cycle,
                dut.if_id_pc_r,
                dut.id_branch,
                dut.id_branch_decode_operands_ready,
                dut.id_branch_decode_redirect_valid,
                dut.id_branch_predict_redirect_valid,
                dut.id_branch_bht_hit,
                dut.id_branch_dynamic_predict_taken,
                dut.branch_bht_update_valid,
                dut.branch_bht_update_pc,
                dut.branch_bht_update_taken,
                dut.stall_decode,
                dut.ex_redirect_valid);
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (use_forward_beq_train &&
            (cycle > 20) &&
            (dut.u_regfile.regs[5] == 32'd42)) begin
            if (dut.u_regfile.regs[3] != 32'd0) begin
                $fatal(1, "FAIL: forward BEQ poison path executed x3=%h", dut.u_regfile.regs[3]);
            end
            if (dut.u_regfile.regs[4] != 32'd3) begin
                $fatal(1, "FAIL: expected three forward BEQ target hits, observed x4=%h", dut.u_regfile.regs[4]);
            end
            if (require_forward_beq_dynamic_predict && (id_forward_beq_predict_redirects < 2)) begin
                $fatal(1,
                    "FAIL: repeated forward BEQ did not use dynamic ID prediction enough; redirects=%0d",
                    id_forward_beq_predict_redirects);
            end
            $display(
                "PASS: forward BEQ dynamic predict diagnostic completed cycles=%0d load_reads=%0d id_forward_beq_predict_redirects=%0d require_dynamic=%0d",
                cycle,
                load_reads,
                id_forward_beq_predict_redirects,
                require_forward_beq_dynamic_predict);
            $finish;
        end

        if (!use_forward_beq_train && (cycle > 8) && (dut.u_regfile.regs[2] == 32'd7)) begin
            if (ex_bne_redirects != 0) begin
                $fatal(1,
                    "FAIL: load-dependent bne still redirected in EX ex_bne_redirects=%0d",
                    ex_bne_redirects);
            end
            if (!use_forward_bne && !use_forward_bne_not_taken && (load_reads != 2)) begin
                $fatal(1,
                    "FAIL: expected exactly two load reads before fallthrough, observed %0d",
                    load_reads);
            end
            if ((use_forward_bne || use_forward_bne_not_taken) && (load_reads != 1)) begin
                $fatal(1,
                    "FAIL: expected exactly one load read in forward branch scenario, observed %0d",
                    load_reads);
            end

            $display(
                "PASS: branch predict diagnostic completed cycles=%0d load_reads=%0d ex_bne_redirects=%0d forward_bne=%0d forward_bne_not_taken=%0d",
                cycle,
                load_reads,
                ex_bne_redirects,
                use_forward_bne,
                use_forward_bne_not_taken);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout pc=%h cycle=%0d load_reads=%0d ex_bne_redirects=%0d x1=%h x2=%h",
                debug_pc,
                cycle,
                load_reads,
                ex_bne_redirects,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    load_reads = 0;
    ex_bne_redirects = 0;
    id_forward_beq_predict_redirects = 0;
    timeout_cycles = 80;
    use_forward_bne = 1'b0;
    use_forward_bne_not_taken = 1'b0;
    use_forward_beq_train = 1'b0;
    require_forward_beq_dynamic_predict = 1'b0;
    trace_branch = 1'b0;

    if ($test$plusargs("forward_bne_taken")) begin
        use_forward_bne = 1'b1;
    end
    if ($test$plusargs("forward_bne_not_taken")) begin
        use_forward_bne_not_taken = 1'b1;
    end
    if ($test$plusargs("forward_beq_train")) begin
        use_forward_beq_train = 1'b1;
        timeout_cycles = 140;
    end
    if ($test$plusargs("require_forward_beq_dynamic_predict")) begin
        require_forward_beq_dynamic_predict = 1'b1;
    end
    if ($test$plusargs("trace_branch")) begin
        trace_branch = 1'b1;
    end

    for (idx = 0; idx < 16; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    if (use_forward_beq_train) begin
        imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd10, 7'b0010011); // addi x10,x0,0
        imem[1] = rv32_i(12'sd1, 5'd0, 3'b000, 5'd2, 7'b0010011);  // addi x2,x0,1
        imem[2] = rv32_i(12'sd3, 5'd0, 3'b000, 5'd6, 7'b0010011);  // addi x6,x0,3
        imem[3] = rv32_i(12'sd0, 5'd10, 3'b010, 5'd1, 7'b0000011); // loop: lw x1,0(x10)
        imem[4] = rv32_b(13'sd8, 5'd2, 5'd1, 3'b000, 7'b1100011);  // beq x1,x2,target
        imem[5] = rv32_i(12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011);  // poison
        imem[6] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);  // target: addi x4,x4,1
        imem[7] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6,x6,-1
        imem[8] = rv32_b(-13'sd20, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6,x0,loop
        imem[9] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // done
    end else begin
        imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd10, 7'b0010011); // addi x10,x0,0
        imem[1] = rv32_i(12'sd0, 5'd10, 3'b010, 5'd1, 7'b0000011); // lw x1,0(x10)
    end
    if (!use_forward_beq_train && (use_forward_bne || use_forward_bne_not_taken)) begin
        imem[2] = rv32_b(13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011);  // bne x1,x0,+8
        imem[3] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd2, 7'b0010011);  // fallthrough result
        imem[4] = rv32_i(use_forward_bne_not_taken ? 12'sd99 : 12'sd7, 5'd0, 3'b000, 5'd2, 7'b0010011);
    end else if (!use_forward_beq_train) begin
        imem[2] = rv32_b(-13'sd4, 5'd0, 5'd1, 3'b001, 7'b1100011); // bne x1,x0,-4
        imem[3] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd2, 7'b0010011);  // addi x2,x0,7
    end

    #20;
    rst_n = 1'b1;
end

endmodule
