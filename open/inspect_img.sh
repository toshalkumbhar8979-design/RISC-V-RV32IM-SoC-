#!/bin/bash
# inspect_openlane_img.sh — list the introspectable contents of the
# efabless/openlane:latest image (whatever OL version it carries).
docker run --rm --entrypoint /bin/sh efabless/openlane:latest -c '
echo "=== env ==="; env | grep -iE "PDK|OPEN|DESIGN|HOME" | head -10
echo "=== /openlane2 mount? ==="; ls -la /openlane 2>/dev/null | head -5
echo "=== OL1 store ==="; ls /nix/store/xpc7xd67rslanlqh566s6jph53bn830w-openlane1-1.1.1 | head -20
echo "=== bin ==="; ls /nix/store/xpc7xd67rslanlqh566s6jph53bn830w-openlane1-1.1.1/bin 2>/dev/null | head -20
echo "=== pdk dirs ==="; ls -d /home/* /opt/* 2>/dev/null; find / -maxdepth 3 -name "*pdk*" -o -maxdepth 3 -name "sky130*" 2>/dev/null | head -10
'