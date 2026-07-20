/*
 * CICC1003618 submission context:
 * File role: sw/linker/YH_rv_cpu_coremark.ld is part of the RISC-V software, benchmark port, startup or linker source.
 * Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
 * Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
 * Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
 * Verification note: functional changes require matching simulation logs or FPGA reports.
 * Maintenance note: update documents, metrics and hashes when this file changes.
 */

ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        *(.text.init)
        *(.text*)
        *(.rodata*)
        *(.srodata*)
    } > ROM

    .data : ALIGN(4) {
        _data_start = .;
        *(.data*)
        *(.sdata*)
        _data_end = .;
    } > RAM AT > ROM
    _data_load_start = LOADADDR(.data);

    .bss (NOLOAD) : ALIGN(4) {
        _bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > RAM

    . = ALIGN(16);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /DISCARD/ : {
        *(.comment*)
        *(.eh_frame*)
        *(.riscv.attributes)
    }
}
