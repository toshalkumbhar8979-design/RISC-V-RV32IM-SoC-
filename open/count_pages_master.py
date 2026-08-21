#!/usr/bin/env python3
# count_pages_master.py — page count of the master report.
from pypdf import PdfReader
r = PdfReader("/mnt/c/Users/tosha/Downloads/Risc V/reports/RISCV_SOC_MASTER.pdf")
print("MASTER pages:", len(r.pages))
for i in range(len(r.pages)):
    t = r.pages[i].extract_text()[:80].replace("\n", " ")
    print(f"  p{i+1}: {t}")