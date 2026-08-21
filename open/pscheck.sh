#!/bin/bash
# pscheck.sh — safe process listing (no fragile inline pipes).
ps -e -o pid,etime,comm > /tmp/ps.txt
grep -iE "docker|containerd|pull|sleep" /tmp/ps.txt | head -12
echo "END"