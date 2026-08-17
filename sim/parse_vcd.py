#!/usr/bin/env python3
"""parse_vcd.py — tiny VCD browser: print named signals as a time table."""
import sys, re

def load_toc(path):
    toc = {}
    with open(path, 'rb') as f:
        data = f.read()
    txt = data.decode('latin-1', errors='replace')
    # scope dump
    for m in re.finditer(r'\$var\s+\w+\s+\d+\s+(\S+)\s+([^\s]+)(?:\s+\[[^\]]+\])?\s+\$end', txt):
        toc[m.group(1)] = m.group(2)
    return txt, toc

def dump(txt, toc, signals, t0=0, t1=1e18):
    # translate symbol -> vcd id
    ids = {}
    for name in signals:
        for vid, nm in toc.items():
            if nm == name or nm.endswith('.' + name):
                ids[name] = vid
    print("signals:", ids)
    cur = {name: '?' for name in signals}
    tcur = 0
    for line in txt.splitlines():
        if line.startswith('#'):
            tcur = int(line[1:])
        else:
            for name, vid in ids.items():
                if line.startswith(vid):
                    cur[name] = line[1:]
        if tcur >= t0 and tcur <= t1 and tcur != last:
            pass
        last = tcur

if __name__ == '__main__':
    import sys, os
    path = sys.argv[1]
    signals = sys.argv[2].split(',')
    t0 = float(sys.argv[3]) if len(sys.argv) > 3 else 0
    t1 = float(sys.argv[4]) if len(sys.argv) > 4 else 1e18
    txt, toc = load_toc(path)
    ids = {}
    for name in signals:
        for vid, nm in toc.items():
            if nm == name or nm.endswith('.' + name):
                ids[name] = vid
    print("MATCHED:", {k: v for k, v in ids.items()}, file=sys.stderr)
    cur = {name: '?' for name in signals}
    tcur = 0
    prev = None
    for line in txt.splitlines():
        if line.startswith('#'):
            tcur = int(line[1:])
        elif line:
            vid = None; val = None
            if line[0] == 'b':
                parts = line.split()
                val, vid = parts[0][1:], parts[-1]
            else:
                val, vid = line[0], line[1:]
            for name, v in ids.items():
                if vid == v:
                    cur[name] = val
        if tcur >= t0*1000 and tcur <= t1*1000:
            key = tuple(cur.items())
            if key != prev:
                print("%8dns %s" % (tcur//1000, "  ".join("%s=%s" % (k, v) for k, v in cur.items())))
                prev = key