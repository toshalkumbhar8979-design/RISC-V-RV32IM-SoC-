#!/bin/bash
# p5_metrics.sh — extract key metrics from the completed run's metrics.json.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
M="$R/final/metrics.json"
echo "==" extract from metrics.json ==
python3 - "$M" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
keys=["design__instance__count","design__die__bbox","design__core__bbox",
"design__instance__area","synth__design__instance__area","floorplan__design__die__area",
"floorplan__design__core__area","design__instance__utilization",
"cts__clock__skew__worst","cts__clock__skew__postcts",
"cts__clock__latency__skew",  "routing__route__wirelength","routing__detailedroute__wirelength",
"routing__detailedroute__via_count","routing__detailedroute__total__vias",
"routing__detailedroute__max__via_count","routing__globalroute__wirelength",
"fin__timing__setup__ws","fin__timing__hold__ws","fin__timing__setup__wns","fin__timing__hold__wns",
"fin__timing__setup__tns","fin__timing__hold__tns","fin__timing__setup__fmax",
"design__power__total","design__power__leakage","design__power__dynamic",
"fin__antenna__violating__nets","fin__drc__violations","magic__drc__violations",
"klayout__drc__violations","lvs__netgen__errors","lvs__netgen__match",
"finish__arc__drc__errors","finish__failing__points","finish__power__ir__avg",
"finish__power__nr__wicked"]
for k in keys:
    if k in d:
        print(f"{k}: {d[k]}")
PY