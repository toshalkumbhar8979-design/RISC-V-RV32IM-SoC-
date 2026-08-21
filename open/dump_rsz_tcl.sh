#!/bin/bash
# dump_rsz_tcl.sh — dump the resizer TCL to understand iterations.
CID=$(docker ps -q | head -1)
docker exec "$CID" cat /nix/store/ss2cw3sxbrwwx9jl0rrppbw4kgcmgi2n-python3-3.11.9-env/lib/python3.11/site-packages/openlane/scripts/openroad/rsz_timing_postcts.tcl 2>/dev/null | sed -n '1,120p'