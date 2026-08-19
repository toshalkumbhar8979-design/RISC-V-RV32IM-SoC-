#!/bin/sh
# runner.sh — ECP5 flow from a WSL ext4 staging dir. Stage: syn|pnr|bit|all
set -e
HB=$HOME/riscv_fpga_build
REPO=/mnt/c/Users/tosha/Downloads/RiscV
YF=$REPO/fpga/ecp5/soc.ys
mkdir -p $REPO/fpga/ecp5/build

stage=${1:-all}
if [ "$stage" = all ] || [ "$stage" = syn ]; then
  rm -rf $HB; mkdir -p $HB/fpga_src
  cp -r $REPO/rtl $HB/
  cp -r $REPO/fpga/ecp5/src $HB/fpga_src/
  cp $REPO/sim/bootrom.hex $HB/
  cp $YF $HB/
  echo "== yosys =="
  cd $HB && yosys -s soc.ys > syn.log 2>&1; echo "rc=$?"
  tail -30 syn.log
fi
if [ "$stage" = all ] || [ "$stage" = pnr ]; then
  echo "== nextpnr-ecp5 =="
  cd $HB && nextpnr-ecp5 --25k --package CABGA381 --json riscv.json \
      --textcfg riscv.config --freq 33 > pnr.log 2>&1; echo "rc=$?"
  tail -35 pnr.log
fi
if [ "$stage" = all ] || [ "$stage" = bit ]; then
  echo "== ecppack =="
  cd $HB && ecppack riscv.config riscv.bit > pack.log 2>&1; echo "rc=$?"
  tail -3 pack.log
  cp -f riscv.json riscv.config riscv.bit $REPO/fpga/ecp5/build/ 2>/dev/null || true
  ls -la $REPO/fpga/ecp5/build/riscv.*
fi