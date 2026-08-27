#!/bin/bash
# test_compile.sh — compile key DOOM engine files to check for errors.
cd /mnt/c/Users/tosha/Downloads/RiscV/sw
CFLAGS="-march=rv32im_zicsr -mabi=ilp32 -Os -ffreestanding -fno-builtin -fno-common -DNORMALUNIX -DLINUX -DCMAP256 -Iplatform -Iplatform/include -Idoomgeneric/doomgeneric"
OK=0; FAIL=0
for f in doomdef.c d_main.c d_iwad.c d_loop.c d_mode.c g_game.c r_main.c \
         r_bsp.c r_data.c r_draw.c r_plane.c r_segs.c r_sky.c r_things.c \
         p_setup.c p_map.c p_user.c p_enemy.c p_spec.c p_mobj.c p_inter.c \
         m_menu.c m_misc.c m_fixed.c m_random.c m_argv.c m_config.c \
         v_video.c i_video.c i_system.c i_timer.c i_sound.c i_scale.c \
         i_input.c i_endoom.c i_joystick.c i_cdmus.c s_sound.c tables.c \
         sha1.c memio.c statdump.c st_lib.c st_stuff.c hu_lib.c hu_stuff.c \
         am_map.c f_finale.c f_wipe.c w_wad.c w_file.c w_file_stdc.c \
         w_checksum.c w_main.c z_zone.c sounds.c info.c d_event.c d_items.c \
         d_net.c dstrings.c doomstat.c doomgeneric.c m_bbox.c m_cheat.c \
         m_controls.c p_ceilng.c p_doors.c p_floor.c p_lights.c p_maputl.c \
         p_plats.c p_pspr.c p_saveg.c p_sight.c p_switch.c p_telept.c \
         p_tick.c; do
  if riscv64-unknown-elf-gcc $CFLAGS -c doomgeneric/doomgeneric/$f -o /tmp/doom_test.o 2>/dev/null; then
    OK=$((OK+1))
  else
    FAIL=$((FAIL+1))
    echo "FAIL: $f"
    riscv64-unknown-elf-gcc $CFLAGS -c doomgeneric/doomgeneric/$f -o /dev/null 2>&1 | head -3
  fi
done
echo "COMPILED OK: $OK  FAILED: $FAIL"