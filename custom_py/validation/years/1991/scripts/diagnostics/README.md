# 1991 refinement diagnostics (Tier 2)

Process/mechanism diagnostics that complement the Tier-1 scoring set (`../../run_all.sh`).
Tier 1 answers *does the model match the field, cast-by-cast?*; these answer *why is it off, and
which lever?* They are **run ad-hoc during refinement**, not every scoring pass.

All scripts use **absolute paths** (model NC, `common/lib`, output dir) so they run from anywhere;
they read the current rev NC (`output_archive/1.7.0/1991_aug_rev/…rev.nc`) and write PNGs to
`years/1991/outputs/` (time-series, IC maps) or `…/outputs/diagnostics/` (transects, grid checks).
Run one at a time: `python <script>.py`. Or the lot: `bash run_diagnostics.sh`.

## Groups

**A. E–W along-thalweg transect (NAR → Fremantle mouth → offshore OA)** — estuary stratification,
salt wedge, and plume export in one section. Model curtain + field curtain (offshore of mouth) +
surf/bot line.
- `transect_NAR_offshore_v2.py`   → `outputs/diagnostics/transect_NAR_offshore_v2.png`   (salinity)
- `transect_NAR_offshore_temp.py` → `outputs/diagnostics/transect_NAR_offshore_temp.png` (temperature)

**B. Point time-series at the two key sites** — model surf/bot **T·S·ρ** vs field cast dots, from
sim start to the last field cast, plus a forcing panel (river inflow + CS wind; OA80 also overlays
the NAR inflow-T BC). West-limit IC values marked.
- `cs55_timeseries.py`  → `outputs/cs55_timeseries_TSrho_1991_rev.png`   (Cockburn Sound, 115.714,-32.188)
- `oa80_timeseries.py`  → `outputs/oa80_timeseries_TSrho_1991_rev.png`   (Owen Anchorage, 115.7013,-32.1313)

**C. IC verification maps** — confirm the graded initial condition actually written.
- `ic_map.py`      → `includes/ic/…_Sgrad_map.png`       (salinity; dual-scale: shelf gradient + estuary drop)
- `ic_temp_map.py` → `includes/ic/…_Sgrad_TEMPmap.png`   (temperature)

**D. Grid / connectivity checks** — mesh bathymetry & tidal exchange (the chain that found the
tidally-choked mouth). Re-run **C** after any bathy-override change; D2/D3 are largely one-off.
- `wl_propagation_v2.py`     → `outputs/diagnostics/wl_tidal_attenuation.png`  (tidal transmission mouth→NAR vs real; RECURRING check)
- `mouth_bathy.py`           → `outputs/diagnostics/mouth_bathymetry_sill.png` (bed profile along the entrance)
- `bathy_compare_B009_B010.py` → `outputs/diagnostics/bathy_compare_B009_B010.png` (current mesh vs B009 reference)

## Notes
- Scripts were promoted from `S:/tmp` (2026-07); originals may still be there.
- Group D overlaps the `csiem-marvl/mesh_refinement/` workflow (which builds the bathy overrides).
- Builders for the inflow climatology (`build_sce_salclim.py`, `build_sce_tempclim.py`) are refinement
  *tooling*, not assessment — still in `S:/tmp`; promote alongside if desired.

## Winter deep-water assessment (Jul 2026 — new SMCWS outer-grid data)
Three diagnostics built from the recovered winter-intensive network (core CS/OA + Y/V/MA/MN outer
grids; coords from EPA .loc, SDL/HAMON casts read via `read_sdl`; pre-storm window 13–17 Aug):
- **`map_prestorm_extended.py`** → `outputs/maps/salinity/map_salinity_prestorm_extended.png`. Same
  methodology as `run_maps.py`/`map_salinity_prestorm.png` (kriged field + points, NATIVE model, 2×2
  surf/bot, 34.0–35.5 scale, land mask) but zoomed out + outer grids added (192 stns). Model blank
  W of the OBC (~115.335, no cells).
- **`ic_vs_field_regional.py`** → `.../ic_vs_field_regional.png`. Model graded IC | kriged field
  depth-mean IC (+points) | difference. Same machinery/extent.
- **`transectV_shelf.py`** → `outputs/diagnostics/transectV_shelf_226.png`. Cross-shelf V12→V1 in the
  TransectA style; model row = shelf zoom (only E of OBC), field row = full 0–300 m (deep water mass).

**Finding (all three agree):** offshore/northern & OBC salinity is ~0.3 psu too salty (western flank
MA already matches). The deep salty subsurface core (35.8–35.9, 150–260 m) sits W of the shelf model's
OBC, so it doesn't enter the OBC unless the domain is extended. Nearshore shelf T is ~1 °C cooler than
field — the regional +0.39 warm bias is offshore-surface, not the shelf.
