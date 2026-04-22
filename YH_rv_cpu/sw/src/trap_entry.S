    .section .text.trap
    .globl toylog_trap_handler
    .align 2

toylog_trap_handler:
    # Save the scratch temporaries used by the handler body.
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)

    # Expect an environment call from M-mode and treat anything else as failure.
    csrr t0, mcause
    li t1, 11
    bne t0, t1, trap_fail

    li t0, 0x10000000
    li t1, 't'
    sw t1, 0(t0)

    # Skip the trapping instruction before returning with mret.
    csrr t2, mepc
    addi t2, t2, 4
    csrw mepc, t2

    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 16
    mret

trap_fail:
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
