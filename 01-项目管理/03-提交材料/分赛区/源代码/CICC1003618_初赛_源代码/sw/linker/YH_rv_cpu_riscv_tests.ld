/*
 * CICC1003618 submission context:
 * File role: sw/linker/YH_rv_cpu_riscv_tests.ld is part of the RISC-V software, benchmark port, startup or linker source.
 * Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
 * Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
 * Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
 * Verification note: functional changes require matching simulation logs or FPGA reports.
 * Maintenance note: update documents, metrics and hashes when this file changes.
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;

  .text.init : {
    *(.text.init)
  }

  . = ALIGN(0x100);
  .text : {
    *(.text)
    *(.text.*)
    *(.rodata)
    *(.rodata.*)
  }

  . = 0x00001000;
  .tohost : {
    *(.tohost)
  }

  . = 0x00002000;
  .data : {
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
  }

  .bss (NOLOAD) : {
    *(.sbss)
    *(.sbss.*)
    *(.bss)
    *(.bss.*)
    *(COMMON)
  }

  . = ALIGN(0x100);
  .signature : {
    *(.signature)
    *(.signature.*)
  }

  _end = .;
}
