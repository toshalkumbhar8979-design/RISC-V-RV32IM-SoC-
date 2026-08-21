#!/usr/bin/env python3
# verify_pdf.py — check page count + extract text of a generated PDF.
import sys
from pypdf import PdfReader
path = sys.argv[1] if len(sys.argv) > 1 else "/mnt/c/Users/tosha/Downloads/Risc V/reports/PHASE5_PAPER.pdf"
r = PdfReader(path)
print("pages:", len(r.pages))
t = r.pages[0].extract_text()
print("--- first 500 chars ---")
print(t[:500])
print("size bytes:", __import__("os").path.getsize(path))