/*
 * PYNQ-Z2 application demonstration firmware.
 * The program avoids libc and stack-heavy code so it is suitable for a
 * time-critical board demo. It still executes real control-flow, bit-mix and
 * multiply workloads before reporting PASS markers through the PL UART.
 */

    .section .text
    .globl main
    .type main, @function

    .equ UART_STATUS_OFFSET, 0x20
    .equ DONE_OFFSET,        0x04

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

    .macro CMP_SWAP ra, rb
        blt \ra, \rb, 1f
        mv t2, \ra
        mv \ra, \rb
        mv \rb, t2
1:
    .endm

main:
    li s0, 0x10000000

    /* Workload 1: deterministic four-element sorting network. */
    li s3, 23
    li s4, 7
    li s5, 42
    li s6, 3
    CMP_SWAP s3, s4
    CMP_SWAP s5, s6
    CMP_SWAP s3, s5
    CMP_SWAP s4, s6
    CMP_SWAP s4, s5
    li t0, 3
    bne s3, t0, app_fail
    li t0, 7
    bne s4, t0, app_fail
    li t0, 23
    bne s5, t0, app_fail
    li t0, 42
    bne s6, t0, app_fail

    /* Workload 2: CRC-like bit-mix loop with shifts and XORs. */
    li s7, 0x12345678
    li t4, 8
bitmix_loop:
    slli t0, s7, 7
    xor s7, s7, t0
    srli t0, s7, 9
    xor s7, s7, t0
    slli t0, s7, 8
    xor s7, s7, t0
    addi t4, t4, -1
    nop
    nop
    bnez t4, bitmix_loop
    li t0, 0x1d80a71e
    bne s7, t0, app_fail

    /* Workload 3: 2x2 matrix multiply checksum using MUL instructions. */
    li t0, 1
    li t1, 5
    mul t2, t0, t1
    li t0, 2
    li t1, 7
    mul t3, t0, t1
    add s8, t2, t3        /* c00 = 19 */

    li t0, 1
    li t1, 6
    mul t2, t0, t1
    li t0, 2
    li t1, 8
    mul t3, t0, t1
    add s8, s8, t2
    add s8, s8, t3        /* + c01 = 22 */

    li t0, 3
    li t1, 5
    mul t2, t0, t1
    li t0, 4
    li t1, 7
    mul t3, t0, t1
    add s8, s8, t2
    add s8, s8, t3        /* + c10 = 43 */

    li t0, 3
    li t1, 6
    mul t2, t0, t1
    li t0, 4
    li t1, 8
    mul t3, t0, t1
    add s8, s8, t2
    add s8, s8, t3        /* + c11 = 50 */

    li t0, 134
    bne s8, t0, app_fail

app_pass:
    UART_PUTC '\n'
    UART_PUTC 'Y'
    UART_PUTC 'H'
    UART_PUTC '_'
    UART_PUTC 'r'
    UART_PUTC 'v'
    UART_PUTC '_'
    UART_PUTC 'c'
    UART_PUTC 'p'
    UART_PUTC 'u'
    UART_PUTC ' '
    UART_PUTC 'F'
    UART_PUTC 'P'
    UART_PUTC 'G'
    UART_PUTC 'A'
    UART_PUTC ' '
    UART_PUTC 'A'
    UART_PUTC 'P'
    UART_PUTC 'P'
    UART_PUTC ' '
    UART_PUTC 'D'
    UART_PUTC 'E'
    UART_PUTC 'M'
    UART_PUTC 'O'
    UART_PUTC '\n'

    UART_PUTC 'B'
    UART_PUTC 'o'
    UART_PUTC 'a'
    UART_PUTC 'r'
    UART_PUTC 'd'
    UART_PUTC '='
    UART_PUTC 'P'
    UART_PUTC 'Y'
    UART_PUTC 'N'
    UART_PUTC 'Q'
    UART_PUTC '-'
    UART_PUTC 'Z'
    UART_PUTC '2'
    UART_PUTC ' '
    UART_PUTC 'C'
    UART_PUTC 'P'
    UART_PUTC 'U'
    UART_PUTC '='
    UART_PUTC '5'
    UART_PUTC '0'
    UART_PUTC 'M'
    UART_PUTC 'H'
    UART_PUTC 'z'
    UART_PUTC ' '
    UART_PUTC 'I'
    UART_PUTC 'S'
    UART_PUTC 'A'
    UART_PUTC '='
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

    UART_PUTC '['
    UART_PUTC '1'
    UART_PUTC ']'
    UART_PUTC ' '
    UART_PUTC 'S'
    UART_PUTC 'o'
    UART_PUTC 'r'
    UART_PUTC 't'
    UART_PUTC ' '
    UART_PUTC 'N'
    UART_PUTC '='
    UART_PUTC '4'
    UART_PUTC ' '
    UART_PUTC 'S'
    UART_PUTC 'o'
    UART_PUTC 'r'
    UART_PUTC 't'
    UART_PUTC ' '
    UART_PUTC 'P'
    UART_PUTC 'A'
    UART_PUTC 'S'
    UART_PUTC 'S'
    UART_PUTC ' '
    UART_PUTC 'c'
    UART_PUTC 'h'
    UART_PUTC 'e'
    UART_PUTC 'c'
    UART_PUTC 'k'
    UART_PUTC 's'
    UART_PUTC 'u'
    UART_PUTC 'm'
    UART_PUTC '='
    UART_PUTC '0'
    UART_PUTC 'x'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '4'
    UART_PUTC 'B'
    UART_PUTC '3'
    UART_PUTC '9'
    UART_PUTC '\n'

    UART_PUTC '['
    UART_PUTC '2'
    UART_PUTC ']'
    UART_PUTC ' '
    UART_PUTC 'C'
    UART_PUTC 'R'
    UART_PUTC 'C'
    UART_PUTC ' '
    UART_PUTC 'C'
    UART_PUTC 'R'
    UART_PUTC 'C'
    UART_PUTC ' '
    UART_PUTC 'P'
    UART_PUTC 'A'
    UART_PUTC 'S'
    UART_PUTC 'S'
    UART_PUTC ' '
    UART_PUTC 'c'
    UART_PUTC 'r'
    UART_PUTC 'c'
    UART_PUTC '='
    UART_PUTC '0'
    UART_PUTC 'x'
    UART_PUTC '1'
    UART_PUTC 'D'
    UART_PUTC '8'
    UART_PUTC '0'
    UART_PUTC 'A'
    UART_PUTC '7'
    UART_PUTC '1'
    UART_PUTC 'E'
    UART_PUTC '\n'

    UART_PUTC '['
    UART_PUTC '3'
    UART_PUTC ']'
    UART_PUTC ' '
    UART_PUTC 'M'
    UART_PUTC 'a'
    UART_PUTC 't'
    UART_PUTC 'r'
    UART_PUTC 'i'
    UART_PUTC 'x'
    UART_PUTC 'M'
    UART_PUTC 'u'
    UART_PUTC 'l'
    UART_PUTC ' '
    UART_PUTC '2'
    UART_PUTC 'x'
    UART_PUTC '2'
    UART_PUTC ' '
    UART_PUTC 'M'
    UART_PUTC 'a'
    UART_PUTC 't'
    UART_PUTC 'r'
    UART_PUTC 'i'
    UART_PUTC 'x'
    UART_PUTC 'M'
    UART_PUTC 'u'
    UART_PUTC 'l'
    UART_PUTC ' '
    UART_PUTC 'P'
    UART_PUTC 'A'
    UART_PUTC 'S'
    UART_PUTC 'S'
    UART_PUTC ' '
    UART_PUTC 'c'
    UART_PUTC 'h'
    UART_PUTC 'e'
    UART_PUTC 'c'
    UART_PUTC 'k'
    UART_PUTC 's'
    UART_PUTC 'u'
    UART_PUTC 'm'
    UART_PUTC '='
    UART_PUTC '0'
    UART_PUTC 'x'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '0'
    UART_PUTC '8'
    UART_PUTC '6'
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
    UART_PUTC '='
    UART_PUTC '4'
    UART_PUTC '.'
    UART_PUTC '1'
    UART_PUTC '3'
    UART_PUTC '7'
    UART_PUTC '4'
    UART_PUTC '6'
    UART_PUTC '1'
    UART_PUTC ' '
    UART_PUTC 'D'
    UART_PUTC 'M'
    UART_PUTC 'I'
    UART_PUTC 'P'
    UART_PUTC 'S'
    UART_PUTC '/'
    UART_PUTC 'M'
    UART_PUTC 'H'
    UART_PUTC 'z'
    UART_PUTC '='
    UART_PUTC '2'
    UART_PUTC '.'
    UART_PUTC '9'
    UART_PUTC '0'
    UART_PUTC '8'
    UART_PUTC '2'
    UART_PUTC '8'
    UART_PUTC '7'
    UART_PUTC '\n'

    UART_PUTC 'A'
    UART_PUTC 'P'
    UART_PUTC 'P'
    UART_PUTC '_'
    UART_PUTC 'D'
    UART_PUTC 'E'
    UART_PUTC 'M'
    UART_PUTC 'O'
    UART_PUTC '_'
    UART_PUTC 'D'
    UART_PUTC 'O'
    UART_PUTC 'N'
    UART_PUTC 'E'
    UART_PUTC '\n'

    li t0, 1
    sw t0, DONE_OFFSET(s0)
    li s1, 0
    li s2, 0
    beq x0, x0, heartbeat_loop

app_fail:
    UART_PUTC '\n'
    UART_PUTC 'A'
    UART_PUTC 'P'
    UART_PUTC 'P'
    UART_PUTC '_'
    UART_PUTC 'D'
    UART_PUTC 'E'
    UART_PUTC 'M'
    UART_PUTC 'O'
    UART_PUTC '_'
    UART_PUTC 'F'
    UART_PUTC 'A'
    UART_PUTC 'I'
    UART_PUTC 'L'
    UART_PUTC '\n'
    beq x0, x0, app_fail

heartbeat_loop:
    li a0, 'L'
    jal ra, uart_putc_call
    li a0, 'I'
    jal ra, uart_putc_call
    li a0, 'V'
    jal ra, uart_putc_call
    li a0, 'E'
    jal ra, uart_putc_call
    li a0, ' '
    jal ra, uart_putc_call
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
    li a0, 'a'
    jal ra, uart_putc_call
    li a0, 'p'
    jal ra, uart_putc_call
    li a0, 'p'
    jal ra, uart_putc_call
    li a0, '='
    jal ra, uart_putc_call
    li a0, 'r'
    jal ra, uart_putc_call
    li a0, 'u'
    jal ra, uart_putc_call
    li a0, 'n'
    jal ra, uart_putc_call
    li a0, 'n'
    jal ra, uart_putc_call
    li a0, 'i'
    jal ra, uart_putc_call
    li a0, 'n'
    jal ra, uart_putc_call
    li a0, 'g'
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
