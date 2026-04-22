    .section .text.init
    .globl _start

_start:
    # Set up the stack before calling into freestanding C code.
    la sp, _stack_top
    call main

1:
    # main is not expected to return in the bare-metal smoke flow.
    j 1b
