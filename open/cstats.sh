#!/bin/bash
# cstats.sh — container CPU/mem + process snapshot.
docker stats --no-stream > /tmp/dst.txt 2>&1
tail -2 /tmp/dst.txt
echo "== top host procs =="
ps -e -o pid,etime,pcpu,pmem,comm --sort=-pcpu | head -6