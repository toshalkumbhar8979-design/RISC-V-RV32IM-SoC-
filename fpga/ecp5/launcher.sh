#!/bin/sh
# launcher.sh — start the yosys synth detached on the WSL ext4 staging
cd "$HOME/riscv_fpga_build" || exit 1
setsid nohup yosys -s soc.ys > syn.log 2>&1 &
echo LAUNCHED