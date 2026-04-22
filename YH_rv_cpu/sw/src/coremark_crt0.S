    .section .text.init
    .globl _start

_start:
    # Establish the stack pointer before touching memory or calling C.
    la sp, _stack_top

    # Copy initialized data from ROM into RAM.
    la a0, _data_load_start
    la a1, _data_start
    la a2, _data_end
1:
    bgeu a1, a2, 2f
    lbu t0, 0(a0)
    sb t0, 0(a1)
    addi a0, a0, 1
    addi a1, a1, 1
    j 1b

2:
    # Zero the BSS so CoreMark starts from a clean freestanding runtime state.
    la a0, _bss_start
    la a1, _bss_end
3:
    bgeu a0, a1, 4f
    sb zero, 0(a0)
    addi a0, a0, 1
    j 3b

4:
    # Enter the C benchmark body.
    call main

5:
    # CoreMark is not expected to return in this environment.
    j 5b
