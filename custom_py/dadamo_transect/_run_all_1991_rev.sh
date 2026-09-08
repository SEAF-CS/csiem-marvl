#!/usr/bin/env bash
# Full 1991 REV validation set, in dependency order. Logs per step; continues on error.
cd "G:/CSIEM/1.8.0/csiem-marvl/custom_py/dadamo_transect" || exit 1
run() {  # run <label> <logfile> <cmd...>
  local label="$1" log="$2"; shift 2
  echo "============================================================"
  echo ">>> START  $label   ($(date '+%H:%M:%S'))"
  "$@" > "$log" 2>&1
  local rc=$?
  echo ">>> DONE   $label   exit=$rc   ($(date '+%H:%M:%S'))   -> $log"
  return 0
}

run "1. region validation (revcompare: base+rev extraction)" _run_regionval_1991_rev.log \
    python -u region_validation_1991_revcompare.py
run "2a. scatter (region/bias/map)"  _run_scatter_1991_rev.log \
    python -u region_validation_plots.py 1991_rev
run "2b. scatter (longitude-coloured)" _run_scatter_lon_1991_rev.log \
    python -u region_validation_plots_lon.py 1991_rev
run "3. hovmoller (CS55/OA80)"        _run_hovmoller_1991_rev.log \
    python -u hovmoller_ST_1991.py
run "4. transect A compare curtains"  _run_transectA_1991_rev.log \
    python -u _run_transectA_1991_rev.py
run "5a. maps - campaigns (pre/post)" _run_maps_1991_rev_campaigns.log \
    python -u _run_maps_1991_rev.py campaigns
run "5b. maps - panels (per occupation)" _run_maps_1991_rev_panels.log \
    python -u _run_maps_1991_rev.py panels

echo "============================================================"
echo "ALL DONE  ($(date '+%H:%M:%S'))"
