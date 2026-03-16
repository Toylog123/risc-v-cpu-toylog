`include "toylog_cpu_defs.vh"

module toylog_cpu #(
    parameter [31:0] RESET_VECTOR = 32'h0000_0000
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    output wire [31:0] dmem_addr,
    input  wire [31:0] dmem_rdata,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        trap,
    output wire [31:0] debug_pc
);

reg [31:0] pc_r;
reg        trap_r;

reg        if_id_valid_r;
reg [31:0] if_id_pc_r;
reg [31:0] if_id_instruction_r;

reg        id_ex_valid_r;
reg [31:0] id_ex_pc_r;
reg [31:0] id_ex_pc4_r;
reg [4:0]  id_ex_rs1_addr_r;
reg [4:0]  id_ex_rs2_addr_r;
reg [4:0]  id_ex_rd_addr_r;
reg        id_ex_rs1_en_r;
reg        id_ex_rs2_en_r;
reg        id_ex_rd_en_r;
reg        id_ex_illegal_r;
reg [31:0] id_ex_rs1_value_r;
reg [31:0] id_ex_rs2_value_r;
reg [31:0] id_ex_imm_r;
reg [3:0]  id_ex_alu_op_r;
reg        id_ex_alu_src1_pc_r;
reg        id_ex_alu_src2_imm_r;
reg        id_ex_branch_r;
reg [2:0]  id_ex_branch_funct3_r;
reg        id_ex_jump_r;
reg        id_ex_jalr_r;
reg        id_ex_load_r;
reg        id_ex_store_r;
reg [1:0]  id_ex_wb_sel_r;
reg [1:0]  id_ex_mem_size_r;
reg        id_ex_mem_unsigned_r;
reg        id_ex_is_lui_r;

reg        ex_mem_valid_r;
reg [31:0] ex_mem_pc4_r;
reg [4:0]  ex_mem_rd_addr_r;
reg        ex_mem_rd_en_r;
reg [1:0]  ex_mem_wb_sel_r;
reg        ex_mem_load_r;
reg        ex_mem_store_r;
reg [1:0]  ex_mem_mem_size_r;
reg        ex_mem_mem_unsigned_r;
reg [31:0] ex_mem_exec_result_r;
reg [31:0] ex_mem_mem_addr_r;
reg [31:0] ex_mem_store_data_r;
reg [3:0]  ex_mem_store_wstrb_r;

reg        mem_wb_valid_r;
reg [31:0] mem_wb_pc4_r;
reg [4:0]  mem_wb_rd_addr_r;
reg        mem_wb_rd_en_r;
reg [1:0]  mem_wb_wb_sel_r;
reg [31:0] mem_wb_exec_result_r;
reg [31:0] mem_wb_load_data_r;

wire [31:0] if_pc_next;

wire [31:0] id_pc4;
wire [4:0]  id_rs1_addr;
wire [4:0]  id_rs2_addr;
wire [4:0]  id_rd_addr;
wire        id_rs1_en;
wire        id_rs2_en;
wire        id_rd_en;
wire        id_illegal;
wire [31:0] id_imm;
wire [3:0]  id_alu_op;
wire        id_alu_src1_pc;
wire        id_alu_src2_imm;
wire        id_branch;
wire [2:0]  id_branch_funct3;
wire        id_jump;
wire        id_jalr;
wire        id_load;
wire        id_store;
wire [1:0]  id_wb_sel;
wire [1:0]  id_mem_size;
wire        id_mem_unsigned;
wire        id_is_lui;
wire [31:0] id_rs1_value;
wire [31:0] id_rs2_value;

wire [31:0] rs1_rdata;
wire [31:0] rs2_rdata;

wire        stall_fetch;
wire        stall_decode;
wire        bubble_execute;
wire [1:0]  forward_a_sel;
wire [1:0]  forward_b_sel;

reg [31:0] ex_rs1_forwarded;
reg [31:0] ex_rs2_forwarded;

wire [31:0] ex_exec_result;
wire [31:0] ex_mem_addr;
wire [31:0] ex_store_data;
wire [3:0]  ex_store_wstrb;
wire        ex_redirect_en;
wire [31:0] ex_redirect_pc;
wire        ex_exception;

wire [31:0] mem_load_data;
wire [31:0] wb_data;

wire [31:0] ex_mem_forward_data;

assign trap = trap_r;
assign debug_pc = pc_r;
assign ex_mem_forward_data =
    (ex_mem_wb_sel_r == `TOYLOG_CPU_WB_PC4) ? ex_mem_pc4_r : ex_mem_exec_result_r;

toylog_cpu_if_stage u_if_stage (
    .pc_current  (pc_r),
    .redirect_en (ex_redirect_en),
    .redirect_pc (ex_redirect_pc),
    .imem_addr   (imem_addr),
    .pc_next     (if_pc_next),
    .pc_plus_4   ()
);

toylog_cpu_regfile u_regfile (
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

toylog_cpu_id_stage u_id_stage (
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
    .is_lui        (id_is_lui),
    .rs1_value     (id_rs1_value),
    .rs2_value     (id_rs2_value)
);

toylog_cpu_hazard_unit u_hazard_unit (
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
    .stall_fetch    (stall_fetch),
    .stall_decode   (stall_decode),
    .bubble_execute (bubble_execute),
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

toylog_cpu_ex_stage u_ex_stage (
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
    .is_lui        (id_ex_is_lui_r),
    .illegal       (id_ex_illegal_r),
    .exec_result   (ex_exec_result),
    .mem_addr      (ex_mem_addr),
    .store_data    (ex_store_data),
    .store_wstrb   (ex_store_wstrb),
    .redirect_en   (ex_redirect_en),
    .redirect_pc   (ex_redirect_pc),
    .exception     (ex_exception)
);

toylog_cpu_mem_stage u_mem_stage (
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

toylog_cpu_wb_stage u_wb_stage (
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

        if_id_valid_r <= 1'b0;
        if_id_pc_r <= 32'h0000_0000;
        if_id_instruction_r <= 32'h0000_0013;

        id_ex_valid_r <= 1'b0;
        id_ex_pc_r <= 32'h0000_0000;
        id_ex_pc4_r <= 32'h0000_0000;
        id_ex_rs1_addr_r <= 5'd0;
        id_ex_rs2_addr_r <= 5'd0;
        id_ex_rd_addr_r <= 5'd0;
        id_ex_rs1_en_r <= 1'b0;
        id_ex_rs2_en_r <= 1'b0;
        id_ex_rd_en_r <= 1'b0;
        id_ex_illegal_r <= 1'b0;
        id_ex_rs1_value_r <= 32'h0000_0000;
        id_ex_rs2_value_r <= 32'h0000_0000;
        id_ex_imm_r <= 32'h0000_0000;
        id_ex_alu_op_r <= `TOYLOG_CPU_ALU_ADD;
        id_ex_alu_src1_pc_r <= 1'b0;
        id_ex_alu_src2_imm_r <= 1'b0;
        id_ex_branch_r <= 1'b0;
        id_ex_branch_funct3_r <= 3'b000;
        id_ex_jump_r <= 1'b0;
        id_ex_jalr_r <= 1'b0;
        id_ex_load_r <= 1'b0;
        id_ex_store_r <= 1'b0;
        id_ex_wb_sel_r <= `TOYLOG_CPU_WB_ALU;
        id_ex_mem_size_r <= `TOYLOG_CPU_MEM_W;
        id_ex_mem_unsigned_r <= 1'b0;
        id_ex_is_lui_r <= 1'b0;

        ex_mem_valid_r <= 1'b0;
        ex_mem_pc4_r <= 32'h0000_0000;
        ex_mem_rd_addr_r <= 5'd0;
        ex_mem_rd_en_r <= 1'b0;
        ex_mem_wb_sel_r <= `TOYLOG_CPU_WB_ALU;
        ex_mem_load_r <= 1'b0;
        ex_mem_store_r <= 1'b0;
        ex_mem_mem_size_r <= `TOYLOG_CPU_MEM_W;
        ex_mem_mem_unsigned_r <= 1'b0;
        ex_mem_exec_result_r <= 32'h0000_0000;
        ex_mem_mem_addr_r <= 32'h0000_0000;
        ex_mem_store_data_r <= 32'h0000_0000;
        ex_mem_store_wstrb_r <= 4'b0000;

        mem_wb_valid_r <= 1'b0;
        mem_wb_pc4_r <= 32'h0000_0000;
        mem_wb_rd_addr_r <= 5'd0;
        mem_wb_rd_en_r <= 1'b0;
        mem_wb_wb_sel_r <= `TOYLOG_CPU_WB_ALU;
        mem_wb_exec_result_r <= 32'h0000_0000;
        mem_wb_load_data_r <= 32'h0000_0000;
    end else if (!trap_r) begin
        mem_wb_valid_r <= ex_mem_valid_r;
        mem_wb_pc4_r <= ex_mem_pc4_r;
        mem_wb_rd_addr_r <= ex_mem_rd_addr_r;
        mem_wb_rd_en_r <= ex_mem_rd_en_r;
        mem_wb_wb_sel_r <= ex_mem_wb_sel_r;
        mem_wb_exec_result_r <= ex_mem_exec_result_r;
        mem_wb_load_data_r <= mem_load_data;

        if (ex_exception && id_ex_valid_r) begin
            trap_r <= 1'b1;
            pc_r <= pc_r;
            if_id_valid_r <= 1'b0;
            id_ex_valid_r <= 1'b0;
            ex_mem_valid_r <= 1'b0;
        end else begin
            if (ex_redirect_en || !stall_fetch) begin
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
            ex_mem_exec_result_r <= ex_exec_result;
            ex_mem_mem_addr_r <= ex_mem_addr;
            ex_mem_store_data_r <= ex_store_data;
            ex_mem_store_wstrb_r <= ex_store_wstrb;

            if (ex_redirect_en) begin
                if_id_valid_r <= 1'b0;
                id_ex_valid_r <= 1'b0;
            end else if (stall_decode) begin
                if_id_valid_r <= if_id_valid_r;
                if_id_pc_r <= if_id_pc_r;
                if_id_instruction_r <= if_id_instruction_r;
                id_ex_valid_r <= 1'b0;
            end else begin
                if_id_valid_r <= 1'b1;
                if_id_pc_r <= pc_r;
                if_id_instruction_r <= imem_rdata;

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
                id_ex_is_lui_r <= id_is_lui;
            end
        end
    end
end

endmodule
