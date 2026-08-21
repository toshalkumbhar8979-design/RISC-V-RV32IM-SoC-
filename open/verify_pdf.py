#!/usr/bin/env python3
# verify_pdf.py — check page count + extract first-page text of the paper.
from pypdf import PdfReader
r = PdfReader("/mnt/c/Users/tosha/Downloads/Risc V/reports/PHASE5_PAPER.pdf")
print("pages:", len(r.pages))
t = r.pages[0].extract_text()
print("--- first 500 chars ---")
print(t[:500])
print("--- has key sections:", all(s in t for s in ["Abstract", "I. Introduction", "riscv_doom_soc"]))