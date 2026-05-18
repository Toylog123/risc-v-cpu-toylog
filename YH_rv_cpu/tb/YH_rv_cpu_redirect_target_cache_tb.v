`timescale 1ns / 1ps

module YH_rv_cpu_redirect_target_cache_tb;

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
wire        dmem_rvalid;
wire        dmem_read_req;
wire        dmem_we;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:1023];
integer idx;
integer cycle;
integer timeout_cycles;
integer redirect_seen_count;
integer alias_redirect_a_count;
integer alias_redirect_b_count;
reg     check_redirect_next;
reg [31:0] check_redirect_pc;
reg     require_no_redirect_bubble;
reg     require_loop_stream;
reg     use_alias_pair;
reg     use_alias_far_pair;
reg     use_alias_very_far_pair;
reg     use_alias_extreme_pair;
reg     use_alias_ultra_pair;
reg     use_alias_mega_pair;
reg     use_alias_giga_pair;
reg     require_alias_cache;
integer stream_check_remaining;
reg [31:0] stream_expected_pc;
reg [31:0] alias_target_b_pc;

assign imem_rdata = imem_rdata_r;
assign imem_rvalid = imem_rvalid_r;
assign dmem_rdata = 32'h0000_0000;
assign dmem_rvalid = dmem_read_req;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
    .LOAD_USE_FAST_FORWARD(1),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_ZICOND_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(1),
    .ENABLE_XTHEAD_COND_MOVE(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(1),
    .RESET_VECTOR(32'h0000_0000)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .timer_irq    (1'b0),
    .imem_req     (imem_req),
    .imem_addr    (imem_addr),
    .imem_rdata   (imem_rdata),
    .imem_rvalid  (imem_rvalid),
    .dmem_addr    (dmem_addr),
    .dmem_rdata   (dmem_rdata),
    .dmem_rvalid  (dmem_rvalid),
    .dmem_ready   (1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_we      (dmem_we),
    .dmem_wdata   (dmem_wdata),
    .dmem_wstrb   (dmem_wstrb),
    .trap         (trap),
    .debug_pc     (debug_pc)
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

always #5 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        imem_rvalid_r <= 1'b0;
        imem_rdata_r <= 32'h0000_0013;
    end else begin
        imem_rvalid_r <= imem_req;
        imem_rdata_r <= imem[imem_addr[31:2]];
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (check_redirect_next) begin
            check_redirect_next <= 1'b0;
            if (require_no_redirect_bubble) begin
                if (!dut.if_id_valid_r || (dut.if_id_pc_r !== check_redirect_pc)) begin
                    $fatal(1,
                        "FAIL: redirect target was not delivered without a bubble at cycle=%0d expected_pc=%h if_id_valid=%0d if_id_pc=%h",
                        cycle,
                        check_redirect_pc,
                        dut.if_id_valid_r,
                        dut.if_id_pc_r);
                end
            end
            if (require_loop_stream) begin
                stream_check_remaining <= 2;
                stream_expected_pc <= check_redirect_pc + 32'd4;
            end
        end

        if (stream_check_remaining > 0) begin
            if (!dut.if_id_valid_r || (dut.if_id_pc_r !== stream_expected_pc)) begin
                $fatal(1,
                    "FAIL: cached loop stream broke at cycle=%0d expected_pc=%h if_id_valid=%0d if_id_pc=%h remaining=%0d",
                    cycle,
                    stream_expected_pc,
                    dut.if_id_valid_r,
                    dut.if_id_pc_r,
                    stream_check_remaining);
            end
            stream_expected_pc <= stream_expected_pc + 32'd4;
            stream_check_remaining <= stream_check_remaining - 1;
        end

        if (use_alias_pair &&
            dut.fetch_control_redirect_valid &&
            (dut.fetch_control_redirect_pc == 32'h0000_0008)) begin
            alias_redirect_a_count <= alias_redirect_a_count + 1;
            if (require_alias_cache && (alias_redirect_a_count > 0) && !dut.redirect_cache_deliver) begin
                $fatal(1,
                    "FAIL: alias target A was evicted instead of delivered from cache cycle=%0d redirects_a=%0d redirects_b=%0d",
                    cycle,
                    alias_redirect_a_count,
                    alias_redirect_b_count);
            end
        end

        if (use_alias_pair &&
            dut.fetch_control_redirect_valid &&
            (dut.fetch_control_redirect_pc == alias_target_b_pc)) begin
            alias_redirect_b_count <= alias_redirect_b_count + 1;
            if (require_alias_cache && (alias_redirect_b_count > 0) && !dut.redirect_cache_deliver) begin
                $fatal(1,
                    "FAIL: alias target B was evicted instead of delivered from cache cycle=%0d redirects_a=%0d redirects_b=%0d",
                    cycle,
                    alias_redirect_a_count,
                    alias_redirect_b_count);
            end
        end

        if (!use_alias_pair && dut.fetch_control_redirect_valid && (dut.fetch_control_redirect_pc == 32'h0000_0004)) begin
            redirect_seen_count <= redirect_seen_count + 1;
            check_redirect_next <= 1'b1;
            check_redirect_pc <= dut.fetch_control_redirect_pc;
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (use_alias_pair && (cycle > 40) && (dut.u_regfile.regs[5] == 32'd42)) begin
            if ((alias_redirect_a_count < 2) || (alias_redirect_b_count < 2)) begin
                $fatal(1,
                    "FAIL: alias cache scenario did not exercise both targets enough redirects_a=%0d redirects_b=%0d",
                    alias_redirect_a_count,
                    alias_redirect_b_count);
            end
            $display(
                "PASS: redirect target alias diagnostic completed at PC=%h cycles=%0d redirects_a=%0d redirects_b=%0d require_alias_cache=%0d",
                debug_pc,
                cycle,
                alias_redirect_a_count,
                alias_redirect_b_count,
                require_alias_cache);
            $finish;
        end

        if (!use_alias_pair && (cycle > 20) && (dut.u_regfile.regs[5] == 32'd42)) begin
            if (redirect_seen_count == 0) begin
                $fatal(1, "FAIL: no loop redirect observed");
            end
            $display(
                "PASS: redirect target cache diagnostic completed at PC=%h cycles=%0d redirects=%0d require_no_redirect_bubble=%0d",
                debug_pc,
                cycle,
                redirect_seen_count,
                require_no_redirect_bubble);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d redirects=%0d x1=%h x2=%h x5=%h",
                debug_pc,
                cycle,
                redirect_seen_count,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[5]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    timeout_cycles = 160;
    redirect_seen_count = 0;
    alias_redirect_a_count = 0;
    alias_redirect_b_count = 0;
    check_redirect_next = 1'b0;
    check_redirect_pc = 32'h0000_0000;
    require_no_redirect_bubble = 1'b0;
    require_loop_stream = 1'b0;
    use_alias_pair = 1'b0;
    use_alias_far_pair = 1'b0;
    use_alias_very_far_pair = 1'b0;
    use_alias_extreme_pair = 1'b0;
    use_alias_ultra_pair = 1'b0;
    use_alias_mega_pair = 1'b0;
    use_alias_giga_pair = 1'b0;
    require_alias_cache = 1'b0;
    stream_check_remaining = 0;
    stream_expected_pc = 32'h0000_0000;
    alias_target_b_pc = 32'h0000_0028;

    if ($test$plusargs("require_no_redirect_bubble")) begin
        require_no_redirect_bubble = 1'b1;
    end
    if ($test$plusargs("require_loop_stream")) begin
        require_loop_stream = 1'b1;
    end
    if ($test$plusargs("alias_pair")) begin
        use_alias_pair = 1'b1;
    end
    if ($test$plusargs("alias_far_pair")) begin
        use_alias_pair = 1'b1;
        use_alias_far_pair = 1'b1;
        alias_target_b_pc = 32'h0000_0048;
    end
    if ($test$plusargs("alias_very_far_pair")) begin
        use_alias_pair = 1'b1;
        use_alias_far_pair = 1'b1;
        use_alias_very_far_pair = 1'b1;
        alias_target_b_pc = 32'h0000_0088;
    end
    if ($test$plusargs("alias_extreme_pair")) begin
        use_alias_pair = 1'b1;
        use_alias_far_pair = 1'b1;
        use_alias_very_far_pair = 1'b1;
        use_alias_extreme_pair = 1'b1;
        alias_target_b_pc = 32'h0000_0108;
    end
    if ($test$plusargs("alias_ultra_pair")) begin
        use_alias_pair = 1'b1;
        use_alias_far_pair = 1'b1;
        use_alias_very_far_pair = 1'b1;
        use_alias_extreme_pair = 1'b1;
        use_alias_ultra_pair = 1'b1;
        alias_target_b_pc = 32'h0000_0208;
    end
    if ($test$plusargs("alias_mega_pair")) begin
        use_alias_pair = 1'b1;
        use_alias_far_pair = 1'b1;
        use_alias_very_far_pair = 1'b1;
        use_alias_extreme_pair = 1'b1;
        use_alias_ultra_pair = 1'b1;
        use_alias_mega_pair = 1'b1;
        alias_target_b_pc = 32'h0000_0408;
    end
    if ($test$plusargs("alias_giga_pair")) begin
        use_alias_pair = 1'b1;
        use_alias_far_pair = 1'b1;
        use_alias_very_far_pair = 1'b1;
        use_alias_extreme_pair = 1'b1;
        use_alias_ultra_pair = 1'b1;
        use_alias_mega_pair = 1'b1;
        use_alias_giga_pair = 1'b1;
        alias_target_b_pc = 32'h0000_0808;
    end
    if ($test$plusargs("require_alias_cache")) begin
        require_alias_cache = 1'b1;
    end

    for (idx = 0; idx < 1024; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    if (use_alias_pair) begin
        imem[0]  = rv32_i(12'sd2, 5'd0, 3'b000, 5'd6, 7'b0010011);  // addi x6, x0, 2
        imem[1]  = rv32_i(12'sd2, 5'd0, 3'b000, 5'd1, 7'b0010011);  // setup A count
        imem[2]  = rv32_i(12'sd1, 5'd2, 3'b000, 5'd2, 7'b0010011);  // A: addi x2, x2, 1
        imem[3]  = rv32_i(-12'sd1, 5'd1, 3'b000, 5'd1, 7'b0010011); // addi x1, x1, -1
        imem[4]  = rv32_b(-13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011); // bne x1, x0, A
        imem[5]  = rv32_i(12'sd2, 5'd0, 3'b000, 5'd3, 7'b0010011);  // setup B count
        if (use_alias_giga_pair) begin
            imem[6]   = rv32_j(21'sd2032, 5'd0, 7'b1101111);            // jump to giga-far B
            imem[514] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011); // B: addi x4, x4, 1
            imem[515] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[516] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[517] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[518] = rv32_b(-13'sd2068, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[519] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[520] = rv32_j(21'sd0, 5'd0, 7'b1101111);               // park
        end else if (use_alias_mega_pair) begin
            imem[6]   = rv32_j(21'sd1008, 5'd0, 7'b1101111);            // jump to mega-far B
            imem[258] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011); // B: addi x4, x4, 1
            imem[259] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[260] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[261] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[262] = rv32_b(-13'sd1044, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[263] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[264] = rv32_j(21'sd0, 5'd0, 7'b1101111);               // park
        end else if (use_alias_ultra_pair) begin
            imem[6]   = rv32_j(21'sd496, 5'd0, 7'b1101111);             // jump to ultra-far B
            imem[130] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011); // B: addi x4, x4, 1
            imem[131] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[132] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[133] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[134] = rv32_b(-13'sd532, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[135] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[136] = rv32_j(21'sd0, 5'd0, 7'b1101111);               // park
        end else if (use_alias_extreme_pair) begin
            imem[6]  = rv32_j(21'sd240, 5'd0, 7'b1101111);             // jump to extreme B
            imem[66] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011); // B: addi x4, x4, 1
            imem[67] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[68] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[69] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[70] = rv32_b(-13'sd276, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[71] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[72] = rv32_j(21'sd0, 5'd0, 7'b1101111);               // park
        end else if (use_alias_very_far_pair) begin
            imem[6]  = rv32_j(21'sd112, 5'd0, 7'b1101111);              // jump to very-far B
            imem[34] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);  // B: addi x4, x4, 1
            imem[35] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[36] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[37] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[38] = rv32_b(-13'sd148, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[39] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[40] = rv32_j(21'sd0, 5'd0, 7'b1101111);                // park
        end else if (use_alias_far_pair) begin
            imem[6]  = rv32_j(21'sd48, 5'd0, 7'b1101111);               // jump to far B
            imem[18] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);  // B: addi x4, x4, 1
            imem[19] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[20] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[21] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[22] = rv32_b(-13'sd84, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[23] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[24] = rv32_j(21'sd0, 5'd0, 7'b1101111);                // park
        end else begin
            imem[6]  = rv32_j(21'sd16, 5'd0, 7'b1101111);               // jump to B
            imem[10] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);  // B: addi x4, x4, 1
            imem[11] = rv32_i(-12'sd1, 5'd3, 3'b000, 5'd3, 7'b0010011); // addi x3, x3, -1
            imem[12] = rv32_b(-13'sd8, 5'd0, 5'd3, 3'b001, 7'b1100011); // bne x3, x0, B
            imem[13] = rv32_i(-12'sd1, 5'd6, 3'b000, 5'd6, 7'b0010011); // addi x6, x6, -1
            imem[14] = rv32_b(-13'sd52, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, setup A
            imem[15] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
            imem[16] = rv32_j(21'sd0, 5'd0, 7'b1101111);                // park
        end
    end else begin
        imem[0] = rv32_i(12'sd3, 5'd0, 3'b000, 5'd1, 7'b0010011);  // addi x1, x0, 3
        imem[1] = rv32_i(12'sd1, 5'd2, 3'b000, 5'd2, 7'b0010011);  // loop: addi x2, x2, 1
        imem[2] = rv32_i(-12'sd1, 5'd1, 3'b000, 5'd1, 7'b0010011); // addi x1, x1, -1
        imem[3] = rv32_b(-13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011); // bne x1, x0, loop
        imem[4] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
        imem[5] = rv32_j(21'sd0, 5'd0, 7'b1101111);                // park
    end

    #20;
    rst_n = 1'b1;
end

endmodule
