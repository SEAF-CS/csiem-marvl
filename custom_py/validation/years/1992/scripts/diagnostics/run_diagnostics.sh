#!/usr/bin/env bash
# 1992 Tier-2 refinement diagnostics. Per-script logs; continues on error. Reads the 1992 rev NC.
# NB run SERIALLY (this script is sequential) - concurrent NetCDF reads can corrupt (HDF errors).
cd "$(dirname "$0")" || exit 1
run() { local label="$1"; shift; echo ">>> START $label ($(date '+%H:%M:%S'))"; "$@" > "_diag_${label}.log" 2>&1; echo ">>> DONE  $label exit=$? ($(date '+%H:%M:%S'))"; }
run transect_S  python -u transect_NAR_offshore_v2.py   # estuary->offshore salinity (model-only)
run wl_tidal    python -u wl_propagation_v2.py          # tidal transmission mouth->NAR (choke check)
echo "ALL 1992 DIAGNOSTICS DONE ($(date '+%H:%M:%S'))"
