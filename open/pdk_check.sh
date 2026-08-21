#!/bin/bash
# pdk_check.sh — checks whether any sky130 PDK/SMT files are bundled in the
# efabless/openlane:latest (OL1.1.1 nix) image.
docker run --rm --entrypoint /bin/sh efabless/openlane:latest -c '
echo "== nix store pdk-ish =="
ls /nix/store 2>/dev/null | grep -iE "pdk|sky|sram" | head
echo "== find stdcell =="
find / -maxdepth 6 -name "sky130_fd_sc_hd" -type d 2>/dev/null | head -3
echo "== find .volare =="
find / -maxdepth 4 -name ".volare" -type d 2>/dev/null | head -3
echo "== volare homes =="
ls /home 2>/dev/null; ls /root 2>/dev/null | head -5
echo "== OL1 config defaults =="
sed -n "1,40p" /openlane1/env-vars 2>/dev/null
'