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
