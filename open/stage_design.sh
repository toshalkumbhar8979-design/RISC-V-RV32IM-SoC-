#!/bin/bash
# stage_design.sh — copy the ASIC probe design to a Linux-native workdir.
set -e
SRC=/mnt/c/Users/tosha/Downloads/RiscV/open/designs/riscv_doom_soc
DST=/home/toshal/work/riscv_doom_soc
mkdir -p "$DST"
cp -r "$SRC/config.json"   "$DST/"
cp -r "$SRC/bootrom.hex"   "$DST/"
rm -rf "$DST/src"
cp -r "$SRC/src"           "$DST/"
echo "STAGED:"
ls "$DST"
echo "files:"; find "$DST" -type f | wc -l