#ifndef YH_RV_CPU_RISCV_TEST_H
#define YH_RV_CPU_RISCV_TEST_H

#if __riscv_xlen == 64
#define RVTEST_REG_BYTES 8
#define RVTEST_REG_SHIFT 3
#define RVTEST_REG_L ld
#define RVTEST_REG_S sd
#define RVTEST_SHIFT32 32
#define RVTEST_SHIFT40 40
#define RVTEST_SHIFT48 48
#define RVTEST_SHIFT56 56
#define RVTEST_SEXT8_SHIFT 56
#define RVTEST_SEXT16_SHIFT 48
#define RVTEST_SEXT32_SHIFT 32
#else
#define RVTEST_REG_BYTES 4
#define RVTEST_REG_SHIFT 2
#define RVTEST_REG_L lw
#define RVTEST_REG_S sw
#define RVTEST_SHIFT32 0
#define RVTEST_SHIFT40 0
#define RVTEST_SHIFT48 0
#define RVTEST_SHIFT56 0
#define RVTEST_SEXT8_SHIFT 24
#define RVTEST_SEXT16_SHIFT 16
#define RVTEST_SEXT32_SHIFT 0
#endif

#define RVTEST_RV64U \
  .macro init; \
  .endm

#define RVTEST_RV32U \
  .macro init; \
  .endm

#define RVTEST_RV64M RVTEST_RV64U
#define RVTEST_RV32M RVTEST_RV32U

#define INIT_XREG \
  li x1, 0; \
  li x2, 0; \
  li x3, 0; \
  li x4, 0; \
  li x5, 0; \
  li x6, 0; \
  li x7, 0; \
  li x8, 0; \
  li x9, 0; \
  li x10, 0; \
  li x11, 0; \
  li x12, 0; \
  li x13, 0; \
  li x14, 0; \
  li x15, 0; \
  li x16, 0; \
  li x17, 0; \
  li x18, 0; \
  li x19, 0; \
  li x20, 0; \
  li x21, 0; \
  li x22, 0; \
  li x23, 0; \
  li x24, 0; \
  li x25, 0; \
  li x26, 0; \
  li x27, 0; \
  li x28, 0; \
  li x29, 0; \
  li x30, 0; \
  li x31, 0;

#define TESTNUM t3

#if __riscv_xlen == 64
# define YH_RV_CPU_WRITE_TOHOST(reg) \
    la t0, tohost; \
    sd reg, 0(t0)
#else
# define YH_RV_CPU_WRITE_TOHOST(reg) \
    la t0, tohost; \
    sw reg, 0(t0); \
    sw zero, 4(t0)
#endif

#define RVTEST_CODE_BEGIN \
    .section .text.init; \
    .align 2; \
    .globl _start; \
_start: \
    INIT_XREG; \
    li TESTNUM, 0; \
    la t0, _yh_rv_cpu_trap_frame; \
    csrw mscratch, t0; \
    la t0, _yh_rv_cpu_trap_vector; \
    csrw mtvec, t0; \
    init;

#define RVTEST_CODE_END \
    .align 2; \
    .global _yh_rv_cpu_trap_vector; \
_yh_rv_cpu_trap_vector: \
    csrrw t0, mscratch, t0; \
    RVTEST_REG_S zero, (0 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S ra,   (1 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S sp,   (2 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S gp,   (3 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S tp,   (4 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S t1,   (6 * RVTEST_REG_BYTES)(t0); \
    csrr t1, mscratch; \
    RVTEST_REG_S t1,   (5 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S t2,   (7 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s0,   (8 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s1,   (9 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a0,  (10 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a1,  (11 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a2,  (12 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a3,  (13 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a4,  (14 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a5,  (15 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a6,  (16 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S a7,  (17 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s2,  (18 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s3,  (19 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s4,  (20 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s5,  (21 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s6,  (22 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s7,  (23 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s8,  (24 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s9,  (25 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s10, (26 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S s11, (27 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S t3,  (28 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S t4,  (29 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S t5,  (30 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_S t6,  (31 * RVTEST_REG_BYTES)(t0); \
    csrr t1, mcause; \
    li t2, 4; \
    beq t1, t2, _yh_rv_cpu_trap_load; \
    li t2, 6; \
    beq t1, t2, _yh_rv_cpu_trap_store; \
    j _yh_rv_cpu_trap_fail; \
_yh_rv_cpu_trap_load: \
    csrr t1, mepc; \
    lw t2, 0(t1); \
    srli t3, t2, 15; \
    andi t3, t3, 31; \
    slli t3, t3, RVTEST_REG_SHIFT; \
    add t3, t0, t3; \
    RVTEST_REG_L t5, 0(t3); \
    srai t3, t2, 20; \
    add t5, t5, t3; \
    srli t3, t2, 12; \
    andi t3, t3, 7; \
    li t4, 0; \
    beq t3, t4, _yh_rv_cpu_lb; \
    li t4, 1; \
    beq t3, t4, _yh_rv_cpu_lh; \
    li t4, 2; \
    beq t3, t4, _yh_rv_cpu_lw; \
    li t4, 3; \
    beq t3, t4, _yh_rv_cpu_ld; \
    li t4, 4; \
    beq t3, t4, _yh_rv_cpu_lbu; \
    li t4, 5; \
    beq t3, t4, _yh_rv_cpu_lhu; \
    li t4, 6; \
    beq t3, t4, _yh_rv_cpu_lwu; \
    j _yh_rv_cpu_trap_fail; \
_yh_rv_cpu_lb: \
    lbu t3, 0(t5); \
    slli t3, t3, RVTEST_SEXT8_SHIFT; \
    srai t5, t3, RVTEST_SEXT8_SHIFT; \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_lbu: \
    lbu t5, 0(t5); \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_lh: \
    lbu t3, 0(t5); \
    lbu t4, 1(t5); \
    slli t4, t4, 8; \
    or t3, t3, t4; \
    slli t3, t3, RVTEST_SEXT16_SHIFT; \
    srai t5, t3, RVTEST_SEXT16_SHIFT; \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_lhu: \
    lbu t3, 0(t5); \
    lbu t4, 1(t5); \
    slli t4, t4, 8; \
    or t5, t3, t4; \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_lw: \
    lbu t3, 0(t5); \
    lbu t4, 1(t5); \
    slli t4, t4, 8; \
    or t3, t3, t4; \
    lbu t4, 2(t5); \
    slli t4, t4, 16; \
    or t3, t3, t4; \
    lbu t4, 3(t5); \
    slli t4, t4, 24; \
    or t5, t3, t4; \
    slli t5, t5, RVTEST_SEXT32_SHIFT; \
    srai t5, t5, RVTEST_SEXT32_SHIFT; \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_lwu: \
    lbu t3, 0(t5); \
    lbu t4, 1(t5); \
    slli t4, t4, 8; \
    or t3, t3, t4; \
    lbu t4, 2(t5); \
    slli t4, t4, 16; \
    or t3, t3, t4; \
    lbu t4, 3(t5); \
    slli t4, t4, 24; \
    or t5, t3, t4; \
    slli t5, t5, RVTEST_SEXT32_SHIFT; \
    srli t5, t5, RVTEST_SEXT32_SHIFT; \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_ld: \
    lbu t3, 0(t5); \
    lbu t4, 1(t5); \
    slli t4, t4, 8; \
    or t3, t3, t4; \
    lbu t4, 2(t5); \
    slli t4, t4, 16; \
    or t3, t3, t4; \
    lbu t4, 3(t5); \
    slli t4, t4, 24; \
    or t3, t3, t4; \
    lbu t4, 4(t5); \
    slli t4, t4, RVTEST_SHIFT32; \
    or t3, t3, t4; \
    lbu t4, 5(t5); \
    slli t4, t4, RVTEST_SHIFT40; \
    or t3, t3, t4; \
    lbu t4, 6(t5); \
    slli t4, t4, RVTEST_SHIFT48; \
    or t3, t3, t4; \
    lbu t4, 7(t5); \
    slli t4, t4, RVTEST_SHIFT56; \
    or t5, t3, t4; \
    j _yh_rv_cpu_load_wb; \
_yh_rv_cpu_load_wb: \
    srli t3, t2, 7; \
    andi t3, t3, 31; \
    beqz t3, _yh_rv_cpu_advance_mepc; \
    slli t3, t3, RVTEST_REG_SHIFT; \
    add t3, t0, t3; \
    RVTEST_REG_S t5, 0(t3); \
    j _yh_rv_cpu_advance_mepc; \
_yh_rv_cpu_trap_store: \
    csrr t1, mepc; \
    lw t2, 0(t1); \
    srli t3, t2, 15; \
    andi t3, t3, 31; \
    slli t3, t3, RVTEST_REG_SHIFT; \
    add t3, t0, t3; \
    RVTEST_REG_L t5, 0(t3); \
    srli t3, t2, 7; \
    andi t3, t3, 31; \
    srli t4, t2, 25; \
    slli t4, t4, 5; \
    or t3, t3, t4; \
    srli t4, t3, 11; \
    andi t4, t4, 1; \
    beqz t4, _yh_rv_cpu_store_imm_ok; \
    li t4, -2048; \
    or t3, t3, t4; \
_yh_rv_cpu_store_imm_ok: \
    add t5, t5, t3; \
    srli t3, t2, 20; \
    andi t3, t3, 31; \
    slli t3, t3, RVTEST_REG_SHIFT; \
    add t3, t0, t3; \
    RVTEST_REG_L t3, 0(t3); \
    srli t4, t2, 12; \
    andi t4, t4, 7; \
    li t1, 0; \
    beq t4, t1, _yh_rv_cpu_sb; \
    li t1, 1; \
    beq t4, t1, _yh_rv_cpu_sh; \
    li t1, 2; \
    beq t4, t1, _yh_rv_cpu_sw; \
    li t1, 3; \
    beq t4, t1, _yh_rv_cpu_sd; \
    j _yh_rv_cpu_trap_fail; \
_yh_rv_cpu_sb: \
    sb t3, 0(t5); \
    j _yh_rv_cpu_advance_mepc; \
_yh_rv_cpu_sh: \
    sb t3, 0(t5); \
    srli t4, t3, 8; \
    sb t4, 1(t5); \
    j _yh_rv_cpu_advance_mepc; \
_yh_rv_cpu_sw: \
    sb t3, 0(t5); \
    srli t4, t3, 8; \
    sb t4, 1(t5); \
    srli t4, t3, 16; \
    sb t4, 2(t5); \
    srli t4, t3, 24; \
    sb t4, 3(t5); \
    j _yh_rv_cpu_advance_mepc; \
_yh_rv_cpu_sd: \
    sb t3, 0(t5); \
    srli t4, t3, 8; \
    sb t4, 1(t5); \
    srli t4, t3, 16; \
    sb t4, 2(t5); \
    srli t4, t3, 24; \
    sb t4, 3(t5); \
    srli t4, t3, RVTEST_SHIFT32; \
    sb t4, 4(t5); \
    srli t4, t3, RVTEST_SHIFT40; \
    sb t4, 5(t5); \
    srli t4, t3, RVTEST_SHIFT48; \
    sb t4, 6(t5); \
    srli t4, t3, RVTEST_SHIFT56; \
    sb t4, 7(t5); \
    j _yh_rv_cpu_advance_mepc; \
_yh_rv_cpu_advance_mepc: \
    csrr t1, mepc; \
    addi t1, t1, 4; \
    csrw mepc, t1; \
    RVTEST_REG_L ra,   (1 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L sp,   (2 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L gp,   (3 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L tp,   (4 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L t1,   (6 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L t2,   (7 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s0,   (8 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s1,   (9 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a0,  (10 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a1,  (11 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a2,  (12 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a3,  (13 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a4,  (14 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a5,  (15 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a6,  (16 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L a7,  (17 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s2,  (18 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s3,  (19 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s4,  (20 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s5,  (21 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s6,  (22 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s7,  (23 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s8,  (24 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s9,  (25 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s10, (26 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L s11, (27 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L t3,  (28 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L t4,  (29 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L t5,  (30 * RVTEST_REG_BYTES)(t0); \
    RVTEST_REG_L t6,  (31 * RVTEST_REG_BYTES)(t0); \
    csrrw t0, mscratch, t0; \
    mret; \
_yh_rv_cpu_trap_fail: \
    li TESTNUM, 255; \
    YH_RV_CPU_WRITE_TOHOST(TESTNUM); \
_yh_rv_cpu_trap_fail_loop: \
    j _yh_rv_cpu_trap_fail_loop

#define RVTEST_PASS \
    li TESTNUM, 1; \
    YH_RV_CPU_WRITE_TOHOST(TESTNUM); \
1:  j 1b

#define RVTEST_FAIL \
1:  beqz TESTNUM, 1b; \
    sll TESTNUM, TESTNUM, 1; \
    ori TESTNUM, TESTNUM, 1; \
    YH_RV_CPU_WRITE_TOHOST(TESTNUM); \
2:  j 2b

#define EXTRA_DATA

#define RVTEST_DATA_BEGIN \
    EXTRA_DATA \
    .pushsection .tohost, "aw", @progbits; \
    .align 3; .global tohost; tohost: .dword 0; .size tohost, 8; \
    .align 3; .global fromhost; fromhost: .dword 0; .size fromhost, 8; \
    .align 3; .global _yh_rv_cpu_trap_frame; _yh_rv_cpu_trap_frame: .space (32 * RVTEST_REG_BYTES); \
    .popsection; \
    .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END \
    .align 4; .global end_signature; end_signature:

#define RVMODEL_DATA_BEGIN
#define RVMODEL_DATA_END
#define RVMODEL_HALT

#endif
