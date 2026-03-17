`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu #(
    parameter integer XLEN = 32,
    parameter integer IMEM_SYNC = 0,
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}}
) (
    input  wire            clk,
    input  wire            rst_n,
    input  wire            timer_irq,
    output wire [XLEN-1:0] imem_addr,
    input  wire [31:0]     imem_rdata,
    input  wire            imem_rvalid,
    output wire [XLEN-1:0] dmem_addr,
    input  wire [XLEN-1:0] dmem_rdata,
    output wire [XLEN-1:0] dmem_wdata,
    output wire [XLEN/8-1:0] dmem_wstrb,
    output wire            trap,
    output wire [XLEN-1:0] debug_pc
);

reg [XLEN-1:0] pc_r;
reg            trap_r;
reg [XLEN-1:0] fetch_pc_r;
reg            fetch_valid_r;
reg            fetch_drop_response_r;

reg            if_id_valid_r;
reg [XLEN-1:0] if_id_pc_r;
reg [31:0]     if_id_instruction_r;

reg            id_ex_valid_r;
reg [XLEN-1:0] id_ex_pc_r;
reg [XLEN-1:0] id_ex_pc4_r;
reg [4:0]      id_ex_rs1_addr_r;
reg [4:0]      id_ex_rs2_addr_r;
reg [4:0]      id_ex_rd_addr_r;
reg            id_ex_rs1_en_r;
reg            id_ex_rs2_en_r;
reg            id_ex_rd_en_r;
reg            id_ex_illegal_r;
reg [XLEN-1:0] id_ex_rs1_value_r;
reg [XLEN-1:0] id_ex_rs2_value_r;
reg [XLEN-1:0] id_ex_imm_r;
reg [3:0]      id_ex_alu_op_r;
reg            id_ex_alu_src1_pc_r;
reg            id_ex_alu_src2_imm_r;
reg            id_ex_branch_r;
reg [2:0]      id_ex_branch_funct3_r;
reg            id_ex_jump_r;
reg            id_ex_jalr_r;
reg            id_ex_load_r;
reg            id_ex_store_r;
reg [1:0]      id_ex_wb_sel_r;
reg [1:0]      id_ex_mem_size_r;
reg            id_ex_mem_unsigned_r;
reg            id_ex_word_op_r;
reg            id_ex_is_lui_r;
reg            id_ex_csr_valid_r;
reg [1:0]      id_ex_csr_cmd_r;
reg            id_ex_csr_use_imm_r;
reg [11:0]     id_ex_csr_addr_r;
reg            id_ex_ecall_r;
reg            id_ex_ebreak_r;
reg            id_ex_mret_r;

reg            ex_mem_valid_r;
reg [XLEN-1:0] ex_mem_pc4_r;
reg [4:0]      ex_mem_rd_addr_r;
reg            ex_mem_rd_en_r;
reg [1:0]      ex_mem_wb_sel_r;
reg            ex_mem_load_r;
reg            ex_mem_store_r;
reg [1:0]      ex_mem_mem_size_r;
reg            ex_mem_mem_unsigned_r;
reg [XLEN-1:0] ex_mem_exec_result_r;
reg [XLEN-1:0] ex_mem_mem_addr_r;
reg [XLEN-1:0] ex_mem_store_data_r;
reg [XLEN/8-1:0] ex_mem_store_wstrb_r;

reg            mem_wb_valid_r;
reg [XLEN-1:0] mem_wb_pc4_r;
reg [4:0]      mem_wb_rd_addr_r;
reg            mem_wb_rd_en_r;
reg [1:0]      mem_wb_wb_sel_r;
reg [XLEN-1:0] mem_wb_exec_result_r;
reg [XLEN-1:0] mem_wb_load_data_r;

wire [XLEN-1:0] if_pc_next;

wire [XLEN-1:0] id_pc4;
wire [4:0]      id_rs1_addr;
wire [4:0]      id_rs2_addr;
wire [4:0]      id_rd_addr;
wire            id_rs1_en;
wire            id_rs2_en;
wire            id_rd_en;
wire            id_illegal;
wire [XLEN-1:0] id_imm;
wire [3:0]      id_alu_op;
wire            id_alu_src1_pc;
wire            id_alu_src2_imm;
wire            id_branch;
wire [2:0]      id_branch_funct3;
wire            id_jump;
wire            id_jalr;
wire            id_load;
wire            id_store;
wire [1:0]      id_wb_sel;
wire [1:0]      id_mem_size;
wire            id_mem_unsigned;
wire            id_word_op;
wire            id_is_lui;
wire            id_csr_valid;
wire [1:0]      id_csr_cmd;
wire            id_csr_use_imm;
wire [11:0]     id_csr_addr;
wire            id_ecall;
wire            id_ebreak;
wire            id_mret;
wire [XLEN-1:0] id_rs1_value;
wire [XLEN-1:0] id_rs2_value;

wire [XLEN-1:0] rs1_rdata;
wire [XLEN-1:0] rs2_rdata;

wire            stall_decode;
wire [1:0]      forward_a_sel;
wire [1:0]      forward_b_sel;

reg [XLEN-1:0] ex_rs1_forwarded;
reg [XLEN-1:0] ex_rs2_forwarded;

wire [XLEN-1:0] ex_exec_result;
wire [XLEN-1:0] ex_mem_addr;
wire [XLEN-1:0] ex_store_data;
wire [XLEN/8-1:0] ex_store_wstrb;
wire            ex_redirect_en;
wire            ex_redirect_valid;
wire [XLEN-1:0] ex_redirect_pc;
wire            ex_mem_misaligned;
wire [XLEN-1:0] ex_exec_result_final;
wire [XLEN-1:0] csr_rdata_ex;
wire [XLEN-1:0] csr_write_operand_ex;
wire [XLEN-1:0] csr_write_data_ex;
wire            csr_write_request_ex;
wire            csr_write_en_ex;
wire            csr_read_valid_ex;
wire            csr_write_allowed_ex;
wire            csr_access_illegal_ex;
wire            ex_sync_trap_valid;
wire            ex_trap_valid;
wire [XLEN-1:0] ex_trap_cause;
wire            ex_mret_valid;
wire            ex_interrupt_valid;
wire            ex_control_redirect_valid;
(* max_fanout = 16 *) wire ex_fetch_redirect_valid;
(* max_fanout = 16 *) wire ex_decode_flush_valid;
wire [XLEN-1:0] ex_control_redirect_pc;
wire [XLEN-1:0] csr_mip_value;

wire [XLEN-1:0] mem_load_data;
wire [XLEN-1:0] wb_data;

wire [XLEN-1:0] ex_mem_forward_data;
reg  [XLEN-1:0] csr_mstatus_r;
reg  [XLEN-1:0] csr_mie_r;
reg  [XLEN-1:0] csr_mtvec_r;
reg  [XLEN-1:0] csr_mscratch_r;
reg  [XLEN-1:0] csr_mepc_r;
reg  [XLEN-1:0] csr_mcause_r;

localparam [XLEN-1:0] ZERO_XLEN = {XLEN{1'b0}};

assign trap = trap_r;
assign debug_pc = pc_r;
assign ex_mem_forward_data =
    (ex_mem_wb_sel_r == `YH_rv_cpu_WB_PC4) ? ex_mem_pc4_r : ex_mem_exec_result_r;
assign ex_redirect_valid = id_ex_valid_r && ex_redirect_en;
assign csr_write_operand_ex = id_ex_csr_use_imm_r ? {{(XLEN-5){1'b0}}, id_ex_rs1_addr_r} : ex_rs1_forwarded;
assign csr_write_request_ex =
    id_ex_csr_valid_r &&
    (
        (id_ex_csr_cmd_r == `YH_rv_cpu_CSR_RW) ||
        (csr_write_operand_ex != ZERO_XLEN)
    );
assign csr_write_en_ex = csr_write_request_ex && !csr_access_illegal_ex;
assign csr_write_data_ex =
    (id_ex_csr_cmd_r == `YH_rv_cpu_CSR_RW) ? csr_write_operand_ex :
    (id_ex_csr_cmd_r == `YH_rv_cpu_CSR_RS) ? (csr_rdata_ex | csr_write_operand_ex) :
    (csr_rdata_ex & ~csr_write_operand_ex);
assign csr_mip_value = timer_irq ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_MIP_MTIP} : ZERO_XLEN;
assign ex_trap_cause =
    ex_interrupt_valid ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_MTIME_INTERRUPT} :
    (id_ex_ecall_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_ECALL_MMODE} :
    (id_ex_ebreak_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_BREAKPOINT} :
    (!csr_read_valid_ex && id_ex_csr_valid_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_ILLEGAL_INSN} :
    (id_ex_illegal_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_ILLEGAL_INSN} :
    (id_ex_load_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_LOAD_MISALIGNED} :
    {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_STORE_MISALIGNED};
assign ex_mret_valid = id_ex_valid_r && id_ex_mret_r;
assign ex_interrupt_valid =
    id_ex_valid_r &&
    !ex_mem_misaligned &&
    !id_ex_ecall_r &&
    !id_ex_ebreak_r &&
    !id_ex_mret_r &&
    !id_ex_illegal_r &&
    !csr_access_illegal_ex &&
    (csr_mstatus_r & `YH_rv_cpu_MSTATUS_MIE) != ZERO_XLEN &&
    (csr_mie_r & `YH_rv_cpu_MIE_MTIE) != ZERO_XLEN &&
    timer_irq;
assign ex_sync_trap_valid =
    id_ex_valid_r &&
    (ex_mem_misaligned || id_ex_ecall_r || id_ex_ebreak_r || id_ex_illegal_r || csr_access_illegal_ex);
assign ex_trap_valid = ex_interrupt_valid || ex_sync_trap_valid;
assign ex_control_redirect_valid = ex_trap_valid || ex_mret_valid || ex_redirect_valid;
assign ex_fetch_redirect_valid = ex_control_redirect_valid;
assign ex_decode_flush_valid = ex_control_redirect_valid;
assign ex_control_redirect_pc =
    ex_trap_valid ? csr_mtvec_r :
    ex_mret_valid ? csr_mepc_r :
    ex_redirect_pc;
assign ex_exec_result_final = id_ex_csr_valid_r ? csr_rdata_ex : ex_exec_result;

assign csr_rdata_ex =
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MSTATUS)  ? csr_mstatus_r :
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MIE)      ? csr_mie_r :
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MTVEC)    ? csr_mtvec_r :
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MSCRATCH) ? csr_mscratch_r :
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MEPC)     ? csr_mepc_r :
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MCAUSE)   ? csr_mcause_r :
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MIP)      ? csr_mip_value :
    ZERO_XLEN;

assign csr_read_valid_ex =
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MSTATUS)  ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MIE)      ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MTVEC)    ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MSCRATCH) ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MEPC)     ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MCAUSE)   ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MIP);

assign csr_write_allowed_ex =
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MSTATUS)  ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MIE)      ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MTVEC)    ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MSCRATCH) ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MEPC)     ||
    (id_ex_csr_addr_r == `YH_rv_cpu_CSR_MCAUSE);

assign csr_access_illegal_ex =
    id_ex_csr_valid_r &&
    (
        !csr_read_valid_ex ||
        (csr_write_request_ex && !csr_write_allowed_ex)
    );

YH_rv_cpu_if_stage #(
    .XLEN(XLEN)
) u_if_stage (
    .pc_current  (pc_r),
    .redirect_en (ex_fetch_redirect_valid),
    .redirect_pc (ex_control_redirect_pc),
    .imem_addr   (imem_addr),
    .pc_next     (if_pc_next),
    .pc_plus_4   ()
);

YH_rv_cpu_regfile #(
    .XLEN(XLEN)
) u_regfile (
    .clk       (clk),
    .rst_n     (rst_n),
    .rs1_addr  (id_rs1_addr),
    .rs2_addr  (id_rs2_addr),
    .rs1_rdata (rs1_rdata),
    .rs2_rdata (rs2_rdata),
    .rd_wen    (mem_wb_valid_r && mem_wb_rd_en_r && !trap_r),
    .rd_addr   (mem_wb_rd_addr_r),
    .rd_wdata  (wb_data)
);

YH_rv_cpu_id_stage #(
    .XLEN(XLEN)
) u_id_stage (
    .pc            (if_id_pc_r),
    .instruction   (if_id_instruction_r),
    .rs1_rdata     (rs1_rdata),
    .rs2_rdata     (rs2_rdata),
    .pc4           (id_pc4),
    .rs1_addr      (id_rs1_addr),
    .rs2_addr      (id_rs2_addr),
    .rd_addr       (id_rd_addr),
    .rs1_en        (id_rs1_en),
    .rs2_en        (id_rs2_en),
    .rd_en         (id_rd_en),
    .illegal       (id_illegal),
    .imm           (id_imm),
    .alu_op        (id_alu_op),
    .alu_src1_pc   (id_alu_src1_pc),
    .alu_src2_imm  (id_alu_src2_imm),
    .branch        (id_branch),
    .branch_funct3 (id_branch_funct3),
    .jump          (id_jump),
    .jalr          (id_jalr),
    .load          (id_load),
    .store         (id_store),
    .wb_sel        (id_wb_sel),
    .mem_size      (id_mem_size),
    .mem_unsigned  (id_mem_unsigned),
    .word_op       (id_word_op),
    .is_lui        (id_is_lui),
    .csr_valid     (id_csr_valid),
    .csr_cmd       (id_csr_cmd),
    .csr_use_imm   (id_csr_use_imm),
    .csr_addr      (id_csr_addr),
    .ecall         (id_ecall),
    .ebreak        (id_ebreak),
    .mret          (id_mret),
    .rs1_value     (id_rs1_value),
    .rs2_value     (id_rs2_value)
);

YH_rv_cpu_hazard_unit u_hazard_unit (
    .if_id_rs1_en   (if_id_valid_r && id_rs1_en),
    .if_id_rs2_en   (if_id_valid_r && id_rs2_en),
    .if_id_rs1_addr (id_rs1_addr),
    .if_id_rs2_addr (id_rs2_addr),
    .id_ex_valid    (id_ex_valid_r),
    .id_ex_load     (id_ex_load_r),
    .id_ex_rd_en    (id_ex_rd_en_r),
    .id_ex_rd_addr  (id_ex_rd_addr_r),
    .id_ex_rs1_en   (id_ex_rs1_en_r),
    .id_ex_rs2_en   (id_ex_rs2_en_r),
    .id_ex_rs1_addr (id_ex_rs1_addr_r),
    .id_ex_rs2_addr (id_ex_rs2_addr_r),
    .ex_mem_valid   (ex_mem_valid_r),
    .ex_mem_load    (ex_mem_load_r),
    .ex_mem_rd_en   (ex_mem_rd_en_r),
    .ex_mem_rd_addr (ex_mem_rd_addr_r),
    .mem_wb_valid   (mem_wb_valid_r),
    .mem_wb_rd_en   (mem_wb_rd_en_r),
    .mem_wb_rd_addr (mem_wb_rd_addr_r),
    .stall_decode   (stall_decode),
    .forward_a_sel  (forward_a_sel),
    .forward_b_sel  (forward_b_sel)
);

always @* begin
    ex_rs1_forwarded = id_ex_rs1_value_r;
    ex_rs2_forwarded = id_ex_rs2_value_r;

    case (forward_a_sel)
        2'b01: ex_rs1_forwarded = ex_mem_forward_data;
        2'b10: ex_rs1_forwarded = wb_data;
        default: ex_rs1_forwarded = id_ex_rs1_value_r;
    endcase

    case (forward_b_sel)
        2'b01: ex_rs2_forwarded = ex_mem_forward_data;
        2'b10: ex_rs2_forwarded = wb_data;
        default: ex_rs2_forwarded = id_ex_rs2_value_r;
    endcase
end

YH_rv_cpu_ex_stage #(
    .XLEN(XLEN)
) u_ex_stage (
    .pc            (id_ex_pc_r),
    .rs1_value     (ex_rs1_forwarded),
    .rs2_value     (ex_rs2_forwarded),
    .imm           (id_ex_imm_r),
    .alu_op        (id_ex_alu_op_r),
    .alu_src1_pc   (id_ex_alu_src1_pc_r),
    .alu_src2_imm  (id_ex_alu_src2_imm_r),
    .branch        (id_ex_branch_r),
    .branch_funct3 (id_ex_branch_funct3_r),
    .jump          (id_ex_jump_r),
    .jalr          (id_ex_jalr_r),
    .load          (id_ex_load_r),
    .store         (id_ex_store_r),
    .mem_size      (id_ex_mem_size_r),
    .word_op       (id_ex_word_op_r),
    .is_lui        (id_ex_is_lui_r),
    .exec_result   (ex_exec_result),
    .mem_addr      (ex_mem_addr),
    .store_data    (ex_store_data),
    .store_wstrb   (ex_store_wstrb),
    .redirect_en   (ex_redirect_en),
    .redirect_pc   (ex_redirect_pc),
    .mem_misaligned(ex_mem_misaligned)
);

YH_rv_cpu_mem_stage #(
    .XLEN(XLEN)
) u_mem_stage (
    .load          (ex_mem_load_r),
    .store         (ex_mem_store_r),
    .mem_addr      (ex_mem_mem_addr_r),
    .store_data_in (ex_mem_store_data_r),
    .store_wstrb_in(ex_mem_store_wstrb_r),
    .mem_size      (ex_mem_mem_size_r),
    .mem_unsigned  (ex_mem_mem_unsigned_r),
    .dmem_rdata    (dmem_rdata),
    .dmem_addr     (dmem_addr),
    .dmem_wdata    (dmem_wdata),
    .dmem_wstrb    (dmem_wstrb),
    .load_data     (mem_load_data)
);

YH_rv_cpu_wb_stage #(
    .XLEN(XLEN)
) u_wb_stage (
    .wb_sel      (mem_wb_wb_sel_r),
    .exec_result (mem_wb_exec_result_r),
    .load_data   (mem_wb_load_data_r),
    .pc4         (mem_wb_pc4_r),
    .wb_data     (wb_data)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_r <= RESET_VECTOR;
        trap_r <= 1'b0;
        fetch_pc_r <= ZERO_XLEN;
        fetch_valid_r <= 1'b0;
        fetch_drop_response_r <= 1'b0;

        if_id_valid_r <= 1'b0;
        if_id_pc_r <= ZERO_XLEN;
        if_id_instruction_r <= 32'h0000_0013;

        id_ex_valid_r <= 1'b0;
        id_ex_pc_r <= ZERO_XLEN;
        id_ex_pc4_r <= ZERO_XLEN;
        id_ex_rs1_addr_r <= 5'd0;
        id_ex_rs2_addr_r <= 5'd0;
        id_ex_rd_addr_r <= 5'd0;
        id_ex_rs1_en_r <= 1'b0;
        id_ex_rs2_en_r <= 1'b0;
        id_ex_rd_en_r <= 1'b0;
        id_ex_illegal_r <= 1'b0;
        id_ex_rs1_value_r <= ZERO_XLEN;
        id_ex_rs2_value_r <= ZERO_XLEN;
        id_ex_imm_r <= ZERO_XLEN;
        id_ex_alu_op_r <= `YH_rv_cpu_ALU_ADD;
        id_ex_alu_src1_pc_r <= 1'b0;
        id_ex_alu_src2_imm_r <= 1'b0;
        id_ex_branch_r <= 1'b0;
        id_ex_branch_funct3_r <= 3'b000;
        id_ex_jump_r <= 1'b0;
        id_ex_jalr_r <= 1'b0;
        id_ex_load_r <= 1'b0;
        id_ex_store_r <= 1'b0;
        id_ex_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        id_ex_mem_size_r <= `YH_rv_cpu_MEM_W;
        id_ex_mem_unsigned_r <= 1'b0;
        id_ex_word_op_r <= 1'b0;
        id_ex_is_lui_r <= 1'b0;
        id_ex_csr_valid_r <= 1'b0;
        id_ex_csr_cmd_r <= `YH_rv_cpu_CSR_RW;
        id_ex_csr_use_imm_r <= 1'b0;
        id_ex_csr_addr_r <= 12'h000;
        id_ex_ecall_r <= 1'b0;
        id_ex_ebreak_r <= 1'b0;
        id_ex_mret_r <= 1'b0;

        ex_mem_valid_r <= 1'b0;
        ex_mem_pc4_r <= ZERO_XLEN;
        ex_mem_rd_addr_r <= 5'd0;
        ex_mem_rd_en_r <= 1'b0;
        ex_mem_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        ex_mem_load_r <= 1'b0;
        ex_mem_store_r <= 1'b0;
        ex_mem_mem_size_r <= `YH_rv_cpu_MEM_W;
        ex_mem_mem_unsigned_r <= 1'b0;
        ex_mem_exec_result_r <= ZERO_XLEN;
        ex_mem_mem_addr_r <= ZERO_XLEN;
        ex_mem_store_data_r <= ZERO_XLEN;
        ex_mem_store_wstrb_r <= {(XLEN/8){1'b0}};

        mem_wb_valid_r <= 1'b0;
        mem_wb_pc4_r <= ZERO_XLEN;
        mem_wb_rd_addr_r <= 5'd0;
        mem_wb_rd_en_r <= 1'b0;
        mem_wb_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        mem_wb_exec_result_r <= ZERO_XLEN;
        mem_wb_load_data_r <= ZERO_XLEN;
        csr_mstatus_r <= ZERO_XLEN;
        csr_mie_r <= ZERO_XLEN;
        csr_mtvec_r <= RESET_VECTOR;
        csr_mscratch_r <= ZERO_XLEN;
        csr_mepc_r <= ZERO_XLEN;
        csr_mcause_r <= ZERO_XLEN;
    end else if (!trap_r) begin
        if (IMEM_SYNC != 0) begin
            fetch_pc_r <= pc_r;
            fetch_valid_r <= 1'b1;
            fetch_drop_response_r <= fetch_drop_response_r && !imem_rvalid;
        end else begin
            fetch_pc_r <= ZERO_XLEN;
            fetch_valid_r <= 1'b0;
            fetch_drop_response_r <= 1'b0;
        end

        mem_wb_valid_r <= ex_mem_valid_r;
        mem_wb_pc4_r <= ex_mem_pc4_r;
        mem_wb_rd_addr_r <= ex_mem_rd_addr_r;
        mem_wb_rd_en_r <= ex_mem_rd_en_r;
        mem_wb_wb_sel_r <= ex_mem_wb_sel_r;
        mem_wb_exec_result_r <= ex_mem_exec_result_r;
        mem_wb_load_data_r <= mem_load_data;

        if (ex_trap_valid) begin
            pc_r <= ex_control_redirect_pc;
            if_id_valid_r <= 1'b0;
            id_ex_valid_r <= 1'b0;
            ex_mem_valid_r <= 1'b0;
            if (IMEM_SYNC != 0) begin
                fetch_drop_response_r <= 1'b1;
            end
            csr_mepc_r <= id_ex_pc_r;
            csr_mcause_r <= ex_trap_cause;
            csr_mstatus_r <=
                (csr_mstatus_r & ~(`YH_rv_cpu_MSTATUS_MIE | `YH_rv_cpu_MSTATUS_MPIE)) |
                ((csr_mstatus_r & `YH_rv_cpu_MSTATUS_MIE) << 4);
        end else begin
            if (id_ex_valid_r && id_ex_csr_valid_r && csr_write_en_ex) begin
                case (id_ex_csr_addr_r)
                    `YH_rv_cpu_CSR_MSTATUS: begin
                        csr_mstatus_r <= csr_write_data_ex &
                            (`YH_rv_cpu_MSTATUS_MIE | `YH_rv_cpu_MSTATUS_MPIE);
                    end
                    `YH_rv_cpu_CSR_MIE: begin
                        csr_mie_r <= csr_write_data_ex & `YH_rv_cpu_MIE_MTIE;
                    end
                    `YH_rv_cpu_CSR_MTVEC: begin
                        csr_mtvec_r <= {csr_write_data_ex[XLEN-1:2], 2'b00};
                    end
                    `YH_rv_cpu_CSR_MSCRATCH: begin
                        csr_mscratch_r <= csr_write_data_ex;
                    end
                    `YH_rv_cpu_CSR_MEPC: begin
                        csr_mepc_r <= {csr_write_data_ex[XLEN-1:2], 2'b00};
                    end
                    `YH_rv_cpu_CSR_MCAUSE: begin
                        csr_mcause_r <= csr_write_data_ex;
                    end
                    default: begin
                    end
                endcase
            end

            if (ex_mret_valid) begin
                csr_mstatus_r <=
                    (csr_mstatus_r & ~(`YH_rv_cpu_MSTATUS_MIE | `YH_rv_cpu_MSTATUS_MPIE)) |
                    ((csr_mstatus_r & `YH_rv_cpu_MSTATUS_MPIE) >> 4) |
                    `YH_rv_cpu_MSTATUS_MPIE;
            end

            if (ex_fetch_redirect_valid || !stall_decode) begin
                pc_r <= if_pc_next;
            end

            ex_mem_valid_r <= id_ex_valid_r;
            ex_mem_pc4_r <= id_ex_pc4_r;
            ex_mem_rd_addr_r <= id_ex_rd_addr_r;
            ex_mem_rd_en_r <= id_ex_rd_en_r;
            ex_mem_wb_sel_r <= id_ex_wb_sel_r;
            ex_mem_load_r <= id_ex_load_r;
            ex_mem_store_r <= id_ex_store_r;
            ex_mem_mem_size_r <= id_ex_mem_size_r;
            ex_mem_mem_unsigned_r <= id_ex_mem_unsigned_r;
            ex_mem_exec_result_r <= ex_exec_result_final;
            ex_mem_mem_addr_r <= ex_mem_addr;
            ex_mem_store_data_r <= ex_store_data;
            ex_mem_store_wstrb_r <= ex_store_wstrb;

            if (ex_decode_flush_valid) begin
                if_id_valid_r <= 1'b0;
                id_ex_valid_r <= 1'b0;
                if (IMEM_SYNC != 0) begin
                    fetch_drop_response_r <= 1'b1;
                end
            end else if (stall_decode) begin
                if_id_valid_r <= if_id_valid_r;
                if_id_pc_r <= if_id_pc_r;
                if_id_instruction_r <= if_id_instruction_r;
                id_ex_valid_r <= 1'b0;
            end else begin
                if (IMEM_SYNC != 0) begin
                    if (fetch_valid_r && imem_rvalid && !fetch_drop_response_r) begin
                        if_id_valid_r <= 1'b1;
                        if_id_pc_r <= fetch_pc_r;
                        if_id_instruction_r <= imem_rdata;
                    end else begin
                        if_id_valid_r <= 1'b0;
                        if_id_pc_r <= ZERO_XLEN;
                        if_id_instruction_r <= 32'h0000_0013;
                    end
                end else begin
                    if_id_valid_r <= 1'b1;
                    if_id_pc_r <= pc_r;
                    if_id_instruction_r <= imem_rdata;
                end

                id_ex_valid_r <= if_id_valid_r;
                id_ex_pc_r <= if_id_pc_r;
                id_ex_pc4_r <= id_pc4;
                id_ex_rs1_addr_r <= id_rs1_addr;
                id_ex_rs2_addr_r <= id_rs2_addr;
                id_ex_rd_addr_r <= id_rd_addr;
                id_ex_rs1_en_r <= id_rs1_en;
                id_ex_rs2_en_r <= id_rs2_en;
                id_ex_rd_en_r <= id_rd_en;
                id_ex_illegal_r <= id_illegal;
                id_ex_rs1_value_r <= id_rs1_value;
                id_ex_rs2_value_r <= id_rs2_value;
                id_ex_imm_r <= id_imm;
                id_ex_alu_op_r <= id_alu_op;
                id_ex_alu_src1_pc_r <= id_alu_src1_pc;
                id_ex_alu_src2_imm_r <= id_alu_src2_imm;
                id_ex_branch_r <= id_branch;
                id_ex_branch_funct3_r <= id_branch_funct3;
                id_ex_jump_r <= id_jump;
                id_ex_jalr_r <= id_jalr;
                id_ex_load_r <= id_load;
                id_ex_store_r <= id_store;
                id_ex_wb_sel_r <= id_wb_sel;
                id_ex_mem_size_r <= id_mem_size;
                id_ex_mem_unsigned_r <= id_mem_unsigned;
                id_ex_word_op_r <= id_word_op;
                id_ex_is_lui_r <= id_is_lui;
                id_ex_csr_valid_r <= id_csr_valid;
                id_ex_csr_cmd_r <= id_csr_cmd;
                id_ex_csr_use_imm_r <= id_csr_use_imm;
                id_ex_csr_addr_r <= id_csr_addr;
                id_ex_ecall_r <= id_ecall;
                id_ex_ebreak_r <= id_ebreak;
                id_ex_mret_r <= id_mret;
            end
        end
    end
end

endmodule
