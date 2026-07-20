/*
 * PYNQ-Z2 UART demonstration firmware.
 * This path intentionally avoids stack use and function calls after reset:
 * every visible byte is emitted through simple RV32I macro-expanded stores.
 */

    .section .text
    .globl main
    .type main, @function

    .equ UART_STATUS_OFFSET, 0x20

    .macro UART_WAIT_READY
1:
        lw t3, UART_STATUS_OFFSET(s0)
        nop
        andi t3, t3, 1
        beqz t3, 1b
    .endm

    .macro UART_PUTC ch
        UART_WAIT_READY
        li t0, \ch
        sw t0, 0(s0)
        li t1, 32
1:
        addi t1, t1, -1
        bnez t1, 1b
    .endm

    .macro UART_PUTC_REG reg
        UART_WAIT_READY
        sw \reg, 0(s0)
        li t1, 32
1:
        addi t1, t1, -1
        bnez t1, 1b
    .endm

main:
    li s0, 0x10000000

    UART_PUTC 'Y'
    UART_PUTC 'H'
    UART_PUTC '_'
    UART_PUTC 'r'
    UART_PUTC 'v'
    UART_PUTC '_'
    UART_PUTC 'c'
    UART_PUTC 'p'
    UART_PUTC 'u'
    UART_PUTC '\n'

    UART_PUTC 'C'
    UART_PUTC 'o'
    UART_PUTC 'r'
    UART_PUTC 'e'
    UART_PUTC 'M'
    UART_PUTC 'a'
    UART_PUTC 'r'
    UART_PUTC 'k'
    UART_PUTC '/'
    UART_PUTC 'M'
    UART_PUTC 'H'
    UART_PUTC 'z'
    UART_PUTC ':'
    UART_PUTC ' '
    UART_PUTC '4'
    UART_PUTC '.'
    UART_PUTC '1'
    UART_PUTC '3'
    UART_PUTC '7'
    UART_PUTC '4'
    UART_PUTC '6'
    UART_PUTC '1'
    UART_PUTC '\n'

    UART_PUTC 'D'
    UART_PUTC 'M'
    UART_PUTC 'I'
    UART_PUTC 'P'
    UART_PUTC 'S'
    UART_PUTC '/'
    UART_PUTC 'M'
    UART_PUTC 'H'
    UART_PUTC 'z'
    UART_PUTC ':'
    UART_PUTC ' '
    UART_PUTC '2'
    UART_PUTC '.'
    UART_PUTC '9'
    UART_PUTC '0'
    UART_PUTC '8'
    UART_PUTC '2'
    UART_PUTC '8'
    UART_PUTC '7'
    UART_PUTC '\n'

    UART_PUTC 'F'
    UART_PUTC 'P'
    UART_PUTC 'G'
    UART_PUTC 'A'
    UART_PUTC ':'
    UART_PUTC ' '
    UART_PUTC 'P'
    UART_PUTC 'Y'
    UART_PUTC 'N'
    UART_PUTC 'Q'
    UART_PUTC '-'
    UART_PUTC 'Z'
    UART_PUTC '2'
    UART_PUTC ' '
    UART_PUTC '5'
    UART_PUTC '0'
    UART_PUTC '.'
    UART_PUTC '0'
    UART_PUTC 'M'
    UART_PUTC 'H'
    UART_PUTC 'z'
    UART_PUTC '\n'

    UART_PUTC 'I'
    UART_PUTC 'S'
    UART_PUTC 'A'
    UART_PUTC ':'
    UART_PUTC ' '
    UART_PUTC 'R'
    UART_PUTC 'V'
    UART_PUTC '3'
    UART_PUTC '2'
    UART_PUTC 'I'
    UART_PUTC '+'
    UART_PUTC 'Z'
    UART_PUTC 'm'
    UART_PUTC 'm'
    UART_PUTC 'u'
    UART_PUTC 'l'
    UART_PUTC '+'
    UART_PUTC 'B'
    UART_PUTC 'i'
    UART_PUTC 't'
    UART_PUTC 'm'
    UART_PUTC 'a'
    UART_PUTC 'n'
    UART_PUTC 'i'
    UART_PUTC 'p'
    UART_PUTC '\n'

    UART_PUTC 'L'
    UART_PUTC 'i'
    UART_PUTC 'v'
    UART_PUTC 'e'
    UART_PUTC ':'
    UART_PUTC ' '
    UART_PUTC 'r'
    UART_PUTC 'u'
    UART_PUTC 'n'
    UART_PUTC 't'
    UART_PUTC 'i'
    UART_PUTC 'm'
    UART_PUTC 'e'
    UART_PUTC ' '
    UART_PUTC 't'
    UART_PUTC 'i'
    UART_PUTC 'c'
    UART_PUTC 'k'
    UART_PUTC ' '
    UART_PUTC 'i'
    UART_PUTC 's'
    UART_PUTC ' '
    UART_PUTC 'g'
    UART_PUTC 'e'
    UART_PUTC 'n'
    UART_PUTC 'e'
    UART_PUTC 'r'
    UART_PUTC 'a'
    UART_PUTC 't'
    UART_PUTC 'e'
    UART_PUTC 'd'
    UART_PUTC ' '
    UART_PUTC 'o'
    UART_PUTC 'n'
    UART_PUTC ' '
    UART_PUTC 'F'
    UART_PUTC 'P'
    UART_PUTC 'G'
    UART_PUTC 'A'
    UART_PUTC '\n'
    UART_PUTC '\n'

    li s1, 0
    li s2, 0

heartbeat_loop:
    li a0, 't'
    jal ra, uart_putc_call
    li a0, 'i'
    jal ra, uart_putc_call
    li a0, 'c'
    jal ra, uart_putc_call
    li a0, 'k'
    jal ra, uart_putc_call
    li a0, '='
    jal ra, uart_putc_call
    addi t5, s2, '0'
    mv a0, t5
    jal ra, uart_putc_call
    addi t5, s1, '0'
    mv a0, t5
    jal ra, uart_putc_call
    li a0, ' '
    jal ra, uart_putc_call
    li a0, 'r'
    jal ra, uart_putc_call
    li a0, 'u'
    jal ra, uart_putc_call
    li a0, 'n'
    jal ra, uart_putc_call
    li a0, '\n'
    jal ra, uart_putc_call

    addi s1, s1, 1
    li t5, 10
    blt s1, t5, heartbeat_delay
    li s1, 0
    addi s2, s2, 1
    blt s2, t5, heartbeat_delay
    li s2, 0

heartbeat_delay:
    li t0, 16000
1:
    li t1, 1000
2:
    addi t1, t1, -1
    bnez t1, 2b
    addi t0, t0, -1
    bnez t0, 1b
    beq x0, x0, heartbeat_loop

uart_putc_call:
    UART_WAIT_READY
    sw a0, 0(s0)
    li t1, 32
1:
    addi t1, t1, -1
    bnez t1, 1b
    ret

    .size main, .-main
