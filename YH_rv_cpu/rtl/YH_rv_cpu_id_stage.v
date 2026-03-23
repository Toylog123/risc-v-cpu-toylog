module YH_rv_cpu_id_stage #(
    parameter integer XLEN = 32
) (
    input  wire [XLEN-1:0] pc,
    input  wire [31:0]     instruction,
    input  wire [XLEN-1:0] rs1_rdata,
    input  wire [XLEN-1:0] rs2_rdata,
    output wire [XLEN-1:0] pc4,
    output wire [4:0]      rs1_addr,
    output wire [4:0]      rs2_addr,
    output wire [4:0]      rd_addr,
    output wire            rs1_en,
    output wire            rs2_en,
    output wire            rd_en,
    output wire            illegal,
    output wire [XLEN-1:0] imm,
    output wire [3:0]      alu_op,
    output wire            alu_src1_pc,
    output wire            alu_src2_imm,
    output wire            branch,
    output wire [2:0]      branch_funct3,
    output wire            jump,
    output wire            jalr,
    output wire            load,
    output wire            store,
    output wire [1:0]      wb_sel,
    output wire [1:0]      mem_size,
    output wire            mem_unsigned,
    output wire            word_op,
    output wire            is_lui,
    output wire            csr_valid,
    output wire [1:0]      csr_cmd,
    output wire            csr_use_imm,
    output wire [2:0]      csr_sel,
    output wire            csr_read_valid,
    output wire            csr_write_allowed,
    output wire            ecall,
    output wire            ebreak,
    output wire            mret,
    output wire [XLEN-1:0] rs1_value,
    output wire [XLEN-1:0] rs2_value
);

localparam [XLEN-1:0] PC_STEP = {{(XLEN-3){1'b0}}, 3'd4};

assign pc4 = pc + PC_STEP;
assign rs1_value = rs1_rdata;
assign rs2_value = rs2_rdata;

YH_rv_cpu_decoder #(
    .XLEN(XLEN)
) u_decoder (
    .instruction   (instruction),
    .rs1_addr      (rs1_addr),
    .rs2_addr      (rs2_addr),
    .rd_addr       (rd_addr),
    .rs1_en        (rs1_en),
    .rs2_en        (rs2_en),
    .rd_en         (rd_en),
    .illegal       (illegal),
    .imm           (imm),
    .alu_op        (alu_op),
    .alu_src1_pc   (alu_src1_pc),
    .alu_src2_imm  (alu_src2_imm),
    .branch        (branch),
    .branch_funct3 (branch_funct3),
    .jump          (jump),
    .jalr          (jalr),
    .load          (load),
    .store         (store),
    .wb_sel        (wb_sel),
    .mem_size      (mem_size),
    .mem_unsigned  (mem_unsigned),
    .word_op       (word_op),
    .is_lui        (is_lui),
    .csr_valid     (csr_valid),
    .csr_cmd       (csr_cmd),
    .csr_use_imm   (csr_use_imm),
    .csr_sel       (csr_sel),
    .csr_read_valid(csr_read_valid),
    .csr_write_allowed(csr_write_allowed),
    .ecall         (ecall),
    .ebreak        (ebreak),
    .mret          (mret)
);

endmodule
