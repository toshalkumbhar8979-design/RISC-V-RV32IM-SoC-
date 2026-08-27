CROSS   := riscv64-unknown-elf-
CC      := $(CROSS)gcc
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
BUILD   := build
DGDIR   := doomgeneric/doomgeneric

ARCH    := -march=rv32im_zicsr -mabi=ilp32
CFLAGS  := $(ARCH) -Os -ffreestanding -fno-builtin -fno-stack-protector \
           -fno-common -Wall -Wno-format -Wno-unused-variable -Wno-unused-function \
           -DNORMALUNIX -DLINUX -DCMAP256 \
           -Iplatform -Iplatform/include -I$(DGDIR)
LDFLAGS := -m elf32lriscv -T platform/linker.ld

DGSRC := am_map.c doomdef.c doomstat.c dstrings.c d_event.c d_items.c \
  d_iwad.c d_loop.c d_main.c d_mode.c f_finale.c f_wipe.c g_game.c \
  hu_lib.c hu_stuff.c info.c i_endoom.c i_scale.c i_sound.c i_system.c \
  i_timer.c memio.c m_argv.c m_bbox.c m_cheat.c m_config.c m_controls.c \
  m_fixed.c m_menu.c m_misc.c m_random.c p_ceilng.c p_doors.c p_enemy.c \
  p_floor.c p_inter.c p_lights.c p_map.c p_maputl.c p_mobj.c p_plats.c \
  p_pspr.c p_saveg.c p_setup.c p_sight.c p_spec.c p_switch.c p_telept.c \
  p_tick.c p_user.c r_bsp.c r_data.c r_draw.c r_main.c r_plane.c r_segs.c \
  r_sky.c r_things.c sha1.c sounds.c statdump.c st_lib.c st_stuff.c \
  s_sound.c tables.c v_video.c wi_stuff.c w_checksum.c w_file.c w_main.c \
  w_wad.c z_zone.c

DGOBJS := $(addprefix $(BUILD)/dg_,$(addsuffix .o,$(basename $(DGSRC))))

OBJS := $(BUILD)/crt.o $(BUILD)/platform.o $(BUILD)/riscvsoc_stubs.o \
        $(BUILD)/doomgeneric_riscvsoc.o $(BUILD)/doom_main.o $(DGOBJS)

.PHONY: all hex clean

all: $(BUILD)/app.elf

$(BUILD)/app.elf: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILD)/crt.o: platform/crt.S | $(BUILD)
	$(AS) $(ARCH) -o $@ $<

$(BUILD)/platform.o: platform/platform.c platform/platform.h platform/sys_regs.h | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/riscvsoc_stubs.o: platform/riscvsoc_stubs.c | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/doomgeneric_riscvsoc.o: platform/doomgeneric_riscvsoc.c | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/doom_main.o: doom_main.c | $(BUILD)
	$(CC) $(CFLAGS) -I$(DGDIR) -c -o $@ $<

$(BUILD)/dg_%.o: $(DGDIR)/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

hex: $(BUILD)/app.elf
	$(OBJCOPY) -O binary -j .text -j .rodata -j .data $< $(BUILD)/app.bin
	python3 ../tests/bin2hex.py --bytes $(BUILD)/app.bin ../sim/app_flash.hex

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)