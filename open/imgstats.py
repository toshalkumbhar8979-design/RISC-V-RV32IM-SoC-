#!/usr/bin/env python3
# imgstats.py — quick pixel stats for a PNG (coverage, color diversity).
from PIL import Image
import sys
from collections import Counter
for p in sys.argv[1:]:
    im = Image.open(p).convert('RGB')
    w,h = im.size
    px = im.load()
    # sample every 4th pixel
    c = Counter()
    for y in range(0,h,4):
        for x in range(0,w,4):
            c[px[x,y]] += 1
    total = sum(c.values())
    nonbg = sum(v for k,v in c.items() if k != (8,10,18))
    print(f"{p}: {w}x{h} sampled={total} unique={len(c)} nonbg_frac={nonbg/total:.3f} top={c.most_common(4)}")