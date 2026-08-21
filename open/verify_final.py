#!/usr/bin/env python3
# verify_final.py — check the final paper PDF.
from pypdf import PdfReader
import os
p = "/mnt/c/Users/tosha/Downloads/Risc V/reports/RISCV_SOC_PAPER.pdf"
r = PdfReader(p)
print("pages:", len(r.pages))
print("size MB:", round(os.path.getsize(p)/1e6, 2))
alltext = ""
for pg in r.pages:
    alltext += pg.extract_text()
for key in ["Abstract", "I. Introduction", "II. Architecture", "III. Physical", "IV. Sign-off", "V. Discussion", "VI. Conclusion", "References", "Fig. 1", "Table III", "18,267", "DRC", "LVS", "OpenLane"]:
    print(f"  contains {key!r}:", key in alltext)

# check the paper has embedded images (XObject count)
imgs = 0
for pg in r.pages:
    res = pg.get("/Resources")
    if res and "/XObject" in res:
        xo = res["/XObject"]
        for k in xo:
            if "Image" in str(xo[k].get_object()):
                imgs += 1
print("embedded images:", imgs)