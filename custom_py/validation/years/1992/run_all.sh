#!/usr/bin/env bash
# 1992 validation set — all components in dependency order. Per-step logs; continues on error.
# (1992 has no hovmoller; maps are daily, no campaigns/panels modes.)
cd "$(dirname "$0")/scripts" || exit 1
run() {  # run <label> <logfile> <cmd...>
  local label="$1" log="$2"; shift 2
  echo ">>> START  $label   ($(date '+%H:%M:%S'))"
  "$@" > "$log" 2>&1
  echo ">>> DONE   $label   exit=$?   ($(date '+%H:%M:%S'))   -> $log"
}
run "[1] region_validation (base+rev)" ../_log_region_validation.log python -u region_validation.py
run "[2] scatter"                      ../_log_scatter.log           python -u scatter.py 1992_rev
run "[2] scatter_lon"                  ../_log_scatter_lon.log       python -u scatter_lon.py 1992_rev
run "[4] transectA curtains"           ../_log_transectA.log        python -u run_transectA.py
run "[7/8] maps - daily"               ../_log_maps.log              python -u run_maps.py
# --- TimeSeries group (cs55/oa80 T-S-rho, velocity, temperature) — moved here from run_diagnostics ---
run "[TS1] cs55 timeseries"            ../_log_ts_cs55.log           python -u diagnostics/cs55_timeseries.py
run "[TS2] oa80 timeseries"            ../_log_ts_oa80.log           python -u diagnostics/oa80_timeseries.py
run "[TS3] velocity validation"        ../_log_velocity.log          python -u diagnostics/velocity_validation.py 1992
run "[TS4] temperature validation"     ../_log_temperature.log       python -u diagnostics/temperature_validation.py 1992
echo "ALL DONE  ($(date '+%H:%M:%S'))"
