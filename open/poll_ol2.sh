#!/bin/bash
# poll_ol2.sh — tail interesting lines from the OL2 run log.
L=/mnt/c/Users/tosha/Downloads/RiscV/open/ol2.log
echo "== size: $(wc -c < "$L" 2>/dev/null) bytes =="
grep -aE "\[INFO\]|\[STEP\]|WARN|ERROR|Flow complete|Synthesis|placement|routing|DRC|LVS|GDS|check" "$L" 2>/dev/null | tail -14
echo "== tail raw =="
tail -c 600 "$L" | strings | tail -8