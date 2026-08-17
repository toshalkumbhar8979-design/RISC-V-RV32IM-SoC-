#====================================================================
# Top-level Makefile — delegates to sim/Makefile (the full RV32IM
# build/simulation flow lives there, invoked from WSL2).
#   Windows host:  wsl -d kali-linux -- bash -c 'cd /mnt/c/.../RiscV && make'
#====================================================================
.PHONY: all sim run hex waves clean

all:
	$(MAKE) -C sim run

sim:
	$(MAKE) -C sim $(VVP_TARGET)

hex:
	$(MAKE) -C sim hex

run:
	$(MAKE) -C sim run

waves:
	$(MAKE) -C sim waves

clean:
	$(MAKE) -C sim clean