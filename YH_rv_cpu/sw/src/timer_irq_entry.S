    .section .text.timer_irq
    .globl yh_timer_irq_handler
    .align 2

yh_timer_irq_handler:
    # Save the scratch temporaries used by the interrupt handler.
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)

    # Only a machine timer interrupt is considered a valid entry for this smoke flow.
    csrr t0, mcause
    li t1, 0x80000007
    bne t0, t1, timer_irq_fail

    li t0, 0x10000018
    sw zero, 0(t0)

    # Record that the interrupt was observed before returning.
    la t0, irq_seen
    li t1, 1
    sw t1, 0(t0)

    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 16
    mret

timer_irq_fail:
    # Publish a visible failure marker for UART/MMIO-based smoke checking.
    li t0, 0x10000000
    li t1, 'F'
    sw t1, 0(t0)
    li t0, 0x10000004
    li t1, 1
    sw t1, 0(t0)

1:
    # Halt here so the bench can observe the failure state.
    j 1b
