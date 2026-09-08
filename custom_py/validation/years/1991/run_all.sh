#!/usr/bin/env bash
# 1991 validation set — all components in dependency order. Per-step logs; continues on error.
cd "$(dirname "$0")/scripts" || exit 1
run() {  # run <label> <logfile> <cmd...>
  local label="$1" log="$2"; shift 2
  echo ">>> START  $label   ($(date '+%H:%M:%S'))"
  "$@" > "$log" 2>&1
  echo ">>> DONE   $label   exit=$?   ($(date '+%H:%M:%S'))   -> $log"
}
run "[1] region_validation (base+rev)" ../_log_region_validation.log python -u region_validation.py
run "[2] scatter"                      ../_log_scatter.log           python -u scatter.py 1991_rev
run "[2] scatter_lon"                  ../_log_scatter_lon.log       python -u scatter_lon.py 1991_rev
run "[3a] hovmoller"                   ../_log_hovmoller.log         python -u hovmoller.py
run "[4] transectA curtains"           ../_log_transectA.log        python -u run_transectA.py
run "[3b] profile_series"              ../_log_profile_series.log    python -u profile_series.py
run "[5] transectB curtains"           ../_log_transectB.log        python -u run_transectB.py
run "[6] transectOA curtains"          ../_log_transectOA.log       python -u run_transectOA.py
run "[6b] transectV shelf (V1-V12)"    ../_log_transectV.log         python -u diagnostics/transectV_shelf.py
run "[7] maps - campaigns"             ../_log_maps_campaigns.log    python -u run_maps.py campaigns
run "[8] maps - panels"                ../_log_maps_panels.log       python -u run_maps.py panels
run "[8b] maps - OA (zoom)"            ../_log_maps_OA.log           python -u run_maps_OA.py
run "[9] halocline (model vs field)"   ../_log_halocline.log         python -u halocline.py
# --- TimeSeries group (cs55/oa80 T-S-rho, velocity, temperature) — moved here from run_diagnostics ---
run "[TS1] cs55 timeseries"            ../_log_ts_cs55.log           python -u diagnostics/cs55_timeseries.py
run "[TS2] oa80 timeseries"            ../_log_ts_oa80.log           python -u diagnostics/oa80_timeseries.py
run "[TS3] velocity validation"        ../_log_velocity.log          python -u diagnostics/velocity_validation.py 1991
run "[TS4] temperature validation"     ../_log_temperature.log       python -u diagnostics/temperature_validation.py 1991
echo "ALL DONE  ($(date '+%H:%M:%S'))"
