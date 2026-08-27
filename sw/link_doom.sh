#!/bin/bash
# link_doom.sh — link the already-compiled doom engine objects.
cd /mnt/c/Users/tosha/Downloads/RiscV/sw
INC="-I platform/include -I doomgeneric/doomgeneric"
CFLAGS="-march=rv32im_zicsr -mabi=ilp32 -Os -ffreestanding -fno-builtin \
  -fno-stack-protector -nostdlib -DNORMALUNIX -DLINUX"
OUT=build/doom/app.elf
echo "=== LINK ==="
riscv64-unknown-elf-gcc $CFLAGS -nostdlib -T platform/linker.ld \
  build/doom/*.o -o $OUT -lgcc 2>&1 | head -20
if [ -f "$OUT" ]; then
  echo "=== LINK SUCCESS ==="
  ls -la $OUT
  riscv64-unknown-elf-objcopy -O binary -j .text -j .data -j .bss $OUT build/app.bin
  ls -la build/app.bin
else
  echo "=== LINK FAILED ==="
fi