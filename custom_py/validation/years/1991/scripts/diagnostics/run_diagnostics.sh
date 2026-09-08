#!/usr/bin/env bash
# 1991 Tier-2 refinement diagnostics. Per-script logs; continues on error. Reads the current rev NC.
cd "$(dirname "$0")" || exit 1
run() { local label="$1"; shift; echo ">>> START $label ($(date '+%H:%M:%S'))"; "$@" > "_diag_${label}.log" 2>&1; echo ">>> DONE  $label exit=$? ($(date '+%H:%M:%S'))"; }
# A. estuary->offshore transects
run transect_S    python -u transect_NAR_offshore_v2.py
run transect_T    python -u transect_NAR_offshore_temp.py
# B. long transects
# long transects (obs vs model, get_curtain) -> outputs/diagnostics/transect_long/{L1,L2}_*.png
run translong_L1  python -u transect_long_validation.py         # L1 composite offshore section
run translong_L2  python -u transect_L2_estuary_validation.py   # L2 estuary+offshore section
# surface Model|Field|ROMS comparison maps (where does the warm/salt inflow come from?)
run mfr_pre       python -u map_surface_MFR.py 1991-08-14        # -> map_surface_MFR_Aug14.png (pre-storm)
run mfr_post      python -u map_surface_MFR.py 1991-08-21        # -> map_surface_MFR_Aug21.png (post-storm)
# TransectA density profile-curtains, full pre/post-storm set (one per survey occupation, jd225-234)
# NB: uses the latest COMPLETE snapshot NC (ITER9) if the live rev is mid-write -> repoint inside the script
run prof_curtain  python -u transectA_profile_curtain.py        # -> transectA_profile_curtain_NN_DDMon_{pre,post}.png
# C. IC maps
run ic_map_S      python -u ic_map.py
run ic_map_T      python -u ic_temp_map.py
# D. grid / tidal checks
run wl_tidal      python -u wl_propagation_v2.py
run mouth_bathy   python -u mouth_bathy.py
run bathy_compare python -u bathy_compare_B009_B010.py
echo "ALL DIAGNOSTICS DONE ($(date '+%H:%M:%S'))"
