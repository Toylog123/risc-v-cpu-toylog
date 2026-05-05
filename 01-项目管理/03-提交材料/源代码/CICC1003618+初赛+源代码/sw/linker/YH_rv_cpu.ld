/*
 * CICC1003618 submission context:
 * File role: sw/linker/YH_rv_cpu.ld is part of the RISC-V software, benchmark port, startup or linker source.
 * Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
 * Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
 * Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
 * Verification note: functional changes require matching simulation logs or FPGA reports.
 * Maintenance note: update documents, metrics and hashes when this file changes.
 */

ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    RAM (rwx) : ORIGIN = 0x00004000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        *(.text.init)
        *(.text*)
        *(.rodata*)
    } > ROM

    .data : {
        *(.data*)
    } > RAM AT > ROM

    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM

    . = ALIGN(16);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
