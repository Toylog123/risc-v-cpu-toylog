    .section .text.timer_irq
    .globl yh_timer_irq_handler
    .align 2

yh_timer_irq_handler:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)

    csrr t0, mcause
    li t1, 0x80000007
    bne t0, t1, timer_irq_fail

    li t0, 0x10000018
    sw zero, 0(t0)

    la t0, irq_seen
    li t1, 1
    sw t1, 0(t0)

    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 16
    mret

timer_irq_fail:
    li t0, 0x10000000
    li t1, 'F'
    sw t1, 0(t0)
    li t0, 0x10000004
    li t1, 1
    sw t1, 0(t0)

1:
    j 1b
