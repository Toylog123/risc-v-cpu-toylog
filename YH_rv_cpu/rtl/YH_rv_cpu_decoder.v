`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_decoder (
    input  wire [31:0] instruction,
    output wire [4:0]  rs1_addr,
    output wire [4:0]  rs2_addr,
    output wire [4:0]  rd_addr,
    output reg         rs1_en,
    output reg         rs2_en,
    output reg         rd_en,
    output reg         illegal,
    output reg  [31:0] imm,
    output reg  [3:0]  alu_op,
    output reg         alu_src1_pc,
    output reg         alu_src2_imm,
    output reg         branch,
    output reg  [2:0]  branch_funct3,
    output reg         jump,
    output reg         jalr,
    output reg         load,
    output reg         store,
    output reg  [1:0]  wb_sel,
    output reg  [1:0]  mem_size,
    output reg         mem_unsigned,
    output reg         is_lui,
    output reg         csr_valid,
    output reg  [1:0]  csr_cmd,
    output reg         csr_use_imm,
    output reg  [11:0] csr_addr,
    output reg         ecall,
    output reg         ebreak,
    output reg         mret
);

wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
wire [31:0] imm_b = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
wire [31:0] imm_u = {instruction[31:12], 12'b0};
wire [31:0] imm_j = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

assign rd_addr  = instruction[11:7];
assign rs1_addr = instruction[19:15];
assign rs2_addr = instruction[24:20];

always @* begin
    rs1_en       = 1'b0;
    rs2_en       = 1'b0;
    rd_en        = 1'b0;
    illegal      = 1'b0;
    imm          = 32'h0000_0000;
    alu_op       = `YH_rv_cpu_ALU_ADD;
    alu_src1_pc  = 1'b0;
    alu_src2_imm = 1'b0;
    branch       = 1'b0;
    branch_funct3 = 3'b000;
    jump         = 1'b0;
    jalr         = 1'b0;
    load         = 1'b0;
    store        = 1'b0;
    wb_sel       = `YH_rv_cpu_WB_ALU;
    mem_size     = `YH_rv_cpu_MEM_W;
    mem_unsigned = 1'b0;
    is_lui       = 1'b0;
    csr_valid    = 1'b0;
    csr_cmd      = `YH_rv_cpu_CSR_RW;
    csr_use_imm  = 1'b0;
    csr_addr     = instruction[31:20];
    ecall        = 1'b0;
    ebreak       = 1'b0;
    mret         = 1'b0;

    case (opcode)
        `YH_rv_cpu_OPCODE_LUI: begin
            rd_en  = 1'b1;
            is_lui = 1'b1;
            imm    = imm_u;
        end

        `YH_rv_cpu_OPCODE_AUIPC: begin
            rd_en        = 1'b1;
            imm          = imm_u;
            alu_src1_pc  = 1'b1;
            alu_src2_imm = 1'b1;
        end

        `YH_rv_cpu_OPCODE_JAL: begin
            rd_en  = 1'b1;
            jump   = 1'b1;
            wb_sel = `YH_rv_cpu_WB_PC4;
            imm    = imm_j;
        end

        `YH_rv_cpu_OPCODE_JALR: begin
            rd_en        = 1'b1;
            rs1_en       = 1'b1;
            jump         = 1'b1;
            jalr         = 1'b1;
            wb_sel       = `YH_rv_cpu_WB_PC4;
            alu_src2_imm = 1'b1;
            imm          = imm_i;
            if (funct3 != 3'b000) begin
                illegal = 1'b1;
            end
        end

        `YH_rv_cpu_OPCODE_BRANCH: begin
            rs1_en        = 1'b1;
            rs2_en        = 1'b1;
            branch        = 1'b1;
            branch_funct3 = funct3;
            imm           = imm_b;
            if ((funct3 == 3'b010) || (funct3 == 3'b011)) begin
                illegal = 1'b1;
            end
        end

        `YH_rv_cpu_OPCODE_LOAD: begin
            rd_en        = 1'b1;
            rs1_en       = 1'b1;
            load         = 1'b1;
            alu_src2_imm = 1'b1;
            wb_sel       = `YH_rv_cpu_WB_MEM;
            imm          = imm_i;
            case (funct3)
                3'b000: begin
                    mem_size     = `YH_rv_cpu_MEM_B;
                    mem_unsigned = 1'b0;
                end
                3'b001: begin
                    mem_size     = `YH_rv_cpu_MEM_H;
                    mem_unsigned = 1'b0;
                end
                3'b010: begin
                    mem_size     = `YH_rv_cpu_MEM_W;
                    mem_unsigned = 1'b0;
                end
                3'b100: begin
                    mem_size     = `YH_rv_cpu_MEM_B;
                    mem_unsigned = 1'b1;
                end
                3'b101: begin
                    mem_size     = `YH_rv_cpu_MEM_H;
                    mem_unsigned = 1'b1;
                end
                default: illegal = 1'b1;
            endcase
        end

        `YH_rv_cpu_OPCODE_STORE: begin
            rs1_en       = 1'b1;
            rs2_en       = 1'b1;
            store        = 1'b1;
            alu_src2_imm = 1'b1;
            imm          = imm_s;
            case (funct3)
                3'b000: mem_size = `YH_rv_cpu_MEM_B;
                3'b001: mem_size = `YH_rv_cpu_MEM_H;
                3'b010: mem_size = `YH_rv_cpu_MEM_W;
                default: illegal = 1'b1;
            endcase
        end

        `YH_rv_cpu_OPCODE_OP_IMM: begin
            rd_en        = 1'b1;
            rs1_en       = 1'b1;
            alu_src2_imm = 1'b1;
            imm          = imm_i;
            case (funct3)
                3'b000: alu_op = `YH_rv_cpu_ALU_ADD;
                3'b010: alu_op = `YH_rv_cpu_ALU_SLT;
                3'b011: alu_op = `YH_rv_cpu_ALU_SLTU;
                3'b100: alu_op = `YH_rv_cpu_ALU_XOR;
                3'b110: alu_op = `YH_rv_cpu_ALU_OR;
                3'b111: alu_op = `YH_rv_cpu_ALU_AND;
                3'b001: begin
                    alu_op = `YH_rv_cpu_ALU_SLL;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b101: begin
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_SRL;
                    end else if (funct7 == 7'b0100000) begin
                        alu_op = `YH_rv_cpu_ALU_SRA;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        `YH_rv_cpu_OPCODE_OP: begin
            rd_en  = 1'b1;
            rs1_en = 1'b1;
            rs2_en = 1'b1;
            case (funct3)
                3'b000: begin
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_ADD;
                    end else if (funct7 == 7'b0100000) begin
                        alu_op = `YH_rv_cpu_ALU_SUB;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b001: begin
                    alu_op = `YH_rv_cpu_ALU_SLL;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b010: begin
                    alu_op = `YH_rv_cpu_ALU_SLT;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b011: begin
                    alu_op = `YH_rv_cpu_ALU_SLTU;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b100: begin
                    alu_op = `YH_rv_cpu_ALU_XOR;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b101: begin
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_SRL;
                    end else if (funct7 == 7'b0100000) begin
                        alu_op = `YH_rv_cpu_ALU_SRA;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b110: begin
                    alu_op = `YH_rv_cpu_ALU_OR;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b111: begin
                    alu_op = `YH_rv_cpu_ALU_AND;
                    if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        `YH_rv_cpu_OPCODE_SYSTEM: begin
            csr_addr = instruction[31:20];

            if (funct3 == 3'b000) begin
                case (instruction[31:20])
                    12'h000: ecall = 1'b1;
                    12'h001: ebreak = 1'b1;
                    12'h302: mret = 1'b1;
                    default: illegal = 1'b1;
                endcase

                if ((rs1_addr != 5'd0) || (rd_addr != 5'd0)) begin
                    illegal = 1'b1;
                end
            end else begin
                csr_valid = 1'b1;
                rd_en = 1'b1;

                case (funct3)
                    3'b001: begin
                        rs1_en = 1'b1;
                        csr_cmd = `YH_rv_cpu_CSR_RW;
                    end
                    3'b010: begin
                        rs1_en = 1'b1;
                        csr_cmd = `YH_rv_cpu_CSR_RS;
                    end
                    3'b011: begin
                        rs1_en = 1'b1;
                        csr_cmd = `YH_rv_cpu_CSR_RC;
                    end
                    3'b101: begin
                        csr_cmd = `YH_rv_cpu_CSR_RW;
                        csr_use_imm = 1'b1;
                    end
                    3'b110: begin
                        csr_cmd = `YH_rv_cpu_CSR_RS;
                        csr_use_imm = 1'b1;
                    end
                    3'b111: begin
                        csr_cmd = `YH_rv_cpu_CSR_RC;
                        csr_use_imm = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
        end

        default: begin
            illegal = 1'b1;
        end
    endcase
end

endmodule
