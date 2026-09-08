#!/usr/bin/env bash
# ============================================================================
# 1991 ITER7 — FULL PLOT SET
#   Tier-1 validation (run_all.sh) + Tier-2 diagnostics (run_diagnostics.sh)
#   + extended maps (prestorm/poststorm/all survey days x S,T)
#   + MFR surface (pre + post) + TransectV cross-shelf.
#
# READINESS GATE: waits until the 1991 model NC exists AND has stopped being
# written (mtime stable >=3 min) before plotting — so this is safe to launch at
# any time, including while the sim is still running. It fires when the sim
# actually finishes (~5 h) rather than at a blind fixed delay.
#
# Reusable / manual fallback:  bash plot_full_set_1991.sh
# ============================================================================
cd "$(dirname "$0")" || exit 1
NC="S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev.nc"
STAMP() { date '+%Y-%m-%d %H:%M:%S'; }

# ---- readiness gate --------------------------------------------------------
echo "[$(STAMP)] GATE: waiting for sim to finish writing $NC"
MAX=$((11*3600)); WAITED=0; STABLE=0; LAST="none"
while true; do
  if [ -f "$NC" ]; then
    NOW=$(stat -c '%Y' "$NC" 2>/dev/null || echo x)
    if [ "$NOW" = "$LAST" ]; then STABLE=$((STABLE+60)); else STABLE=0; LAST="$NOW"; fi
    if [ "$STABLE" -ge 180 ]; then echo "[$(STAMP)] GATE: NC stable ${STABLE}s -> sim done, plotting."; break; fi
  fi
  if [ "$WAITED" -ge "$MAX" ]; then echo "[$(STAMP)] GATE TIMEOUT ${WAITED}s -> NC missing/never stabilised; ABORT."; exit 2; fi
  sleep 60; WAITED=$((WAITED+60))
done

# ---- plot ------------------------------------------------------------------
run() { local label="$1" log="$2"; shift 2; echo ">>> START $label ($(date '+%H:%M:%S'))"; "$@" > "$log" 2>&1; echo ">>> DONE  $label exit=$? ($(date '+%H:%M:%S')) -> $log"; }

echo "=========== 1991 FULL PLOT SET  START $(STAMP) ==========="
# Tier-1: region_validation, scatter(_lon), hovmoller, transectA/B/OA, profile_series, maps (campaigns/panels/OA), halocline
run "[T1] run_all.sh" _log_full_tier1.log bash run_all.sh

cd scripts/diagnostics || exit 1
# Tier-2 + new diagnostics
run "[T2] extended maps (pre/post/all-days x S,T)" ../../_log_full_extended.log   python -u map_prestorm_extended.py
run "[T2] MFR surface prestorm  (14 Aug)"          ../../_log_full_MFR_pre.log     python -u map_surface_MFR.py 1991-08-14
run "[T2] MFR surface poststorm (21 Aug)"          ../../_log_full_MFR_post.log    python -u map_surface_MFR.py 1991-08-21
run "[T2] TransectV cross-shelf (pre/post)"        ../../_log_full_transectV.log   python -u transectV_shelf.py
run "[T2] run_diagnostics.sh (process/mechanism)"  ../../_log_full_diagnostics.log bash run_diagnostics.sh

echo "=========== 1991 FULL PLOT SET  DONE  $(STAMP) ==========="
