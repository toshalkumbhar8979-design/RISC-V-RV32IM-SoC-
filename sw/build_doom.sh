#!/bin/bash
# build_doom.sh — compile + link the full doomgeneric engine for RV32IM.
cd /mnt/c/Users/tosha/Downloads/RiscV/sw
INC="-I platform/include -I doomgeneric/doomgeneric"
CFLAGS="-march=rv32im_zicsr -mabi=ilp32 -Os -ffreestanding -fno-builtin \
  -fno-stack-protector -nostdlib -Wall -DNORMALUNIX -DLINUX -Wno-format"
mkdir -p build/doom
OUT=build/doom/app.elf

# engine sources (from Makefile.soso, minus sound/CD/net platform bits)
ENGINE_SRCS="am_map.c doomdef.c doomstat.c dstrings.c d_event.c d_items.c \
  d_iwad.c d_loop.c d_main.c d_mode.c d_net.c f_finale.c f_wipe.c g_game.c \
  hu_lib.c hu_stuff.c info.c i_cdmus.c i_endoom.c i_joystick.c i_scale.c \
  i_sound.c i_system.c i_timer.c memio.c m_argv.c m_bbox.c m_cheat.c \
  m_config.c m_controls.c m_fixed.c m_menu.c m_misc.c m_random.c p_ceilng.c \
  p_doors.c p_enemy.c p_floor.c p_inter.c p_lights.c p_map.c p_maputl.c \
  p_mobj.c p_plats.c p_pspr.c p_saveg.c p_setup.c p_sight.c p_spec.c \
  p_switch.c p_telept.c p_tick.c p_user.c r_bsp.c r_data.c r_draw.c \
  r_main.c r_plane.c r_segs.c r_sky.c r_things.c sha1.c sounds.c statdump.c \
  st_lib.c st_stuff.c s_sound.c tables.c v_video.c wi_stuff.c w_checksum.c \
  w_file.c w_main.c w_wad.c z_zone.c w_file_stdc.c i_input.c i_video.c \
  doomgeneric.c"

# our platform files
PLATFORM_SRCS="platform/doomgeneric_riscvsoc.c platform/riscvsoc_stubs.c"

# compile engine
FAIL=0
for src in $ENGINE_SRCS; do
  obj="build/doom/${src%.c}.o"
  if ! riscv64-unknown-elf-gcc $CFLAGS $INC -c doomgeneric/doomgeneric/$src -o "$obj" 2>/dev/null; then
    echo "FAIL: $src"
    riscv64-unknown-elf-gcc $CFLAGS $INC -c doomgeneric/doomgeneric/$src -o "$obj" 2>&1 | head -5
    FAIL=1
  fi
done

# compile platform
for src in $PLATFORM_SRCS; do
  obj="build/doom/$(basename ${src%.c}).o"
  if ! riscv64-unknown-elf-gcc $CFLAGS $INC -c "$src" -o "$obj" 2>/dev/null; then
    echo "FAIL: $src"
    riscv64-unknown-elf-gcc $CFLAGS $INC -c "$src" -o "$obj" 2>&1 | head -5
    FAIL=1
  fi
done

if [ "$FAIL" = "1" ]; then echo "== COMPILE ERRORS (see above) =="; exit 1; fi

# link
riscv64-unknown-elf-gcc $CFLAGS -nostdlib -T platform/linker.ld \
  build/doom/*.o -o $OUT -lgcc 2>&1 | head -15
if [ -f "$OUT" ]; then
  riscv64-unknown-elf-objcopy -O binary -j .text -j .data -j .bss $OUT build/app.bin
  echo "=== BUILT: $OUT ==="
  ls -la build/app.bin
else
  echo "=== LINK FAILED ==="
fi