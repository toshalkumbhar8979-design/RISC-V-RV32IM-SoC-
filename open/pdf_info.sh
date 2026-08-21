#!/bin/bash
# pdf_info.sh — verify the generated PDF header + page count.
P="/mnt/c/Users/tosha/Downloads/Risc V/reports/PHASE5_PAPER.pdf"
echo "== header =="
head -c 12 "$P" | strings
echo
echo "== size =="
wc -c "$P"
echo "== /Count lines =="
strings "$P" | grep -a "/Count [0-9]" | head -3