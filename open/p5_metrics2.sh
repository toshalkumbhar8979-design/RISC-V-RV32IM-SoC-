#!/bin/bash
# p5_metrics2.sh — list all metric keys + dump routing/timing/lvs ones.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
M="$R/final/metrics.json"
python3 - "$M" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
for k,v in d.items():
    lk=k.lower()
    if any(s in lk for s in ["routing","wirel","via","timing__setup__ws","timing__hold","__wns","__tns","fmax","drc","lvs","antenna","power__total","instance__count","area","util"]):
        print(f"{k}: {v}")
PY