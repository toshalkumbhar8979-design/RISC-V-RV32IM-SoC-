OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  FLASH (rx)  : ORIGIN = 0x20000000, LENGTH = 4M
  PSRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 8M
  SRAM  (rwx) : ORIGIN = 0x00010000, LENGTH = 32K
}

SECTIONS {
  . = ORIGIN(FLASH);
  .text : {
    *(.text.entry)
    *(.text*)
    *(.init*)
  } > FLASH

  .rodata : ALIGN(4) {
    *(.rodata*)
    *(.srodata*)
  } > FLASH

  . = ORIGIN(PSRAM);
  .data : ALIGN(4) {
    __data_start = .;
    *(.data*)
    *(.sdata*)
    __data_end = .;
  } > PSRAM

  .bss (NOLOAD) : ALIGN(4) {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  } > PSRAM

  __heap_start = ALIGN(4);
  __heap_end   = ORIGIN(PSRAM) + LENGTH(PSRAM) - 4096;
  __stack_bottom = ORIGIN(SRAM) + LENGTH(SRAM);
  __stack_top    = __stack_bottom - 4096;

  /DISCARD/ : { *(.eh_frame*) }
}