/*====================================================================
 * linker.ld — riscv_doom_soc application memory map (Phase-0 map).
 *   .text/.rodata/.data/.bss live in SRAM at 0x0001_0000; the boot
 *   loader copies the raw image here from SPI flash. Stack grows down
 *   from the top of SRAM (32 KB), heap follows __bss_end.
 *====================================================================*/
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 32K
}

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
  bss  PT_NULL;
}

SECTIONS {
  . = ORIGIN(RAM);
  .text : {
    *(.text.entry)
    *(.text*)
    *(.init*)
  } > RAM : text

  .rodata : ALIGN(4) {
    *(.rodata*)
    *(.srodata*)
  } > RAM : text

  .data : ALIGN(4) {
    *(.data*)
    *(.sdata*)
  } > RAM : data

  .bss (NOLOAD) : ALIGN(4) {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  } > RAM : bss

  __heap_start = ALIGN(4);
  __heap_end   = ORIGIN(RAM) + LENGTH(RAM) - 4096;   /* 4 KB stack reserve */
  __stack_bottom = ORIGIN(RAM) + LENGTH(RAM);
  __stack_top    = __stack_bottom - 4096;
}