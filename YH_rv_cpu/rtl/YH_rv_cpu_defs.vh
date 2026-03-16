`ifndef YH_rv_cpu_DEFS_VH
`define YH_rv_cpu_DEFS_VH

`define YH_rv_cpu_OPCODE_LOAD    7'b0000011
`define YH_rv_cpu_OPCODE_STORE   7'b0100011
`define YH_rv_cpu_OPCODE_BRANCH  7'b1100011
`define YH_rv_cpu_OPCODE_JALR    7'b1100111
`define YH_rv_cpu_OPCODE_JAL     7'b1101111
`define YH_rv_cpu_OPCODE_OP_IMM  7'b0010011
`define YH_rv_cpu_OPCODE_OP      7'b0110011
`define YH_rv_cpu_OPCODE_AUIPC   7'b0010111
`define YH_rv_cpu_OPCODE_LUI     7'b0110111
`define YH_rv_cpu_OPCODE_SYSTEM  7'b1110011

`define YH_rv_cpu_ALU_ADD   4'd0
`define YH_rv_cpu_ALU_SUB   4'd1
`define YH_rv_cpu_ALU_SLT   4'd2
`define YH_rv_cpu_ALU_SLTU  4'd3
`define YH_rv_cpu_ALU_XOR   4'd4
`define YH_rv_cpu_ALU_OR    4'd5
`define YH_rv_cpu_ALU_AND   4'd6
`define YH_rv_cpu_ALU_SLL   4'd7
`define YH_rv_cpu_ALU_SRL   4'd8
`define YH_rv_cpu_ALU_SRA   4'd9

`define YH_rv_cpu_WB_ALU    2'd0
`define YH_rv_cpu_WB_MEM    2'd1
`define YH_rv_cpu_WB_PC4    2'd2

`define YH_rv_cpu_MEM_B     2'd0
`define YH_rv_cpu_MEM_H     2'd1
`define YH_rv_cpu_MEM_W     2'd2

`define YH_rv_cpu_CSR_RW    2'd0
`define YH_rv_cpu_CSR_RS    2'd1
`define YH_rv_cpu_CSR_RC    2'd2

`define YH_rv_cpu_CSR_MSTATUS   12'h300
`define YH_rv_cpu_CSR_MIE       12'h304
`define YH_rv_cpu_CSR_MTVEC     12'h305
`define YH_rv_cpu_CSR_MSCRATCH  12'h340
`define YH_rv_cpu_CSR_MEPC      12'h341
`define YH_rv_cpu_CSR_MCAUSE    12'h342
`define YH_rv_cpu_CSR_MIP       12'h344

`define YH_rv_cpu_MSTATUS_MIE   32'h0000_0008
`define YH_rv_cpu_MSTATUS_MPIE  32'h0000_0080
`define YH_rv_cpu_MIE_MTIE      32'h0000_0080
`define YH_rv_cpu_MIP_MTIP      32'h0000_0080

`define YH_rv_cpu_TRAP_ILLEGAL_INSN      32'd2
`define YH_rv_cpu_TRAP_BREAKPOINT        32'd3
`define YH_rv_cpu_TRAP_LOAD_MISALIGNED   32'd4
`define YH_rv_cpu_TRAP_STORE_MISALIGNED  32'd6
`define YH_rv_cpu_TRAP_ECALL_MMODE       32'd11
`define YH_rv_cpu_TRAP_MTIME_INTERRUPT   32'h8000_0007

`endif
