# 1992 refinement diagnostics (Tier 2)

Ported from `years/1991/scripts/diagnostics/` (2026-07). Process/mechanism diagnostics that
complement the Tier-1 scoring set (`../../run_all.sh`). Run ad-hoc during refinement, not every
scoring pass. Absolute paths; read the 1992 rev NC (`1992_marmay_rev/…rev.nc`, 22-Feb→19-Apr);
write PNGs to `years/1992/outputs/`. Run one: `python <script>.py`; or all: `bash run_diagnostics.sh`.

## 1992 focus differs from 1991
Autumn (Feb–Apr), **March survey** (per-jday TransectA occupations + coastal-salinity maps), heavily
**Cockburn Sound**. Not a fresh-plume winter storm — the estuary is **hypersaline (inverse)** in
autumn, and the CS **dense-water / stratification** is the interest.

## Scripts
**A. E–W along-thalweg transect (NAR → mouth → offshore OA)** — `transect_NAR_offshore_v2.py`
(salinity; March snapshot). **MODEL-ONLY** here (`MODEL_ONLY=True`) — the 1991 DFV field-loader is
1991-specific; a 1992 per-jday field loader is TODO. Shows the hypersaline/well-mixed estuary +
mouth structure. → `outputs/diagnostics/transect_NAR_offshore_v2.png`.

**B. Point time-series at CS55 & OA80** — `cs55_timeseries.py`, `oa80_timeseries.py`: model surf/bot
T·S·ρ vs field dots (Feb-start → last March cast) + forcing panel (raw NAR+CAN inflow, model-met CS
wind; OA80 overlays the raw NAR inflow-T = flat 21.6 °C). → `outputs/*_timeseries_TSrho_1992_rev.png`.

**C. Tidal-transmission check** — `wl_propagation_v2.py`: tidal-band WL mouth→NAR vs the real inland
tide (Barrack St PTBAR02). Confirms whether the Fremantle mouth is choked. → `outputs/diagnostics/wl_tidal_attenuation.png`.

**TODO:** IC maps (`ic_map.py`/`ic_temp_map.py`) — not yet ported; the 1992 IC (`…_Mar_B010_Sgrad`)
uses the OLD two-stage form (west/ref/east_edge), so the breakpoint-reading `ic_map.py` needs
generalising to handle both.

## Config caveats — 1992 rev is BEHIND 1991 (drives what these diagnostics show)
- **No `Cell Elevation File` bathy overrides** → Fremantle mouth still tidally choked (the 1991
  root-cause fix; same B010 mesh — a drop-in). **This is the priority 1992 fix.**
- **RAW SCE inflow BC** (`sce_WIR_…_19700101_19941231.fvc`, not `_SALclim`) → flat 27.16 psu / 21.6 °C
  placeholders. Lower priority for 1992: season-appropriate by luck (autumn Swan ≈ 21.6 °C) + low
  flow (~1 m³/s), so near-negligible. The Narrows climatology (already built) covers Mar/Apr if wanted.
- IC = `initial_condition_2D_Mar_B010_Sgrad.csv` (salty two-stage; fine for the hypersaline autumn).
