# CSIEM hindcast validation — session restart guide

Single-page orientation for validating the **CSIEM TUFLOW-FV (+AED) hindcast** against the
historical **SMCWS CTD surveys** (1991, 1992; 1994 in progress), and for the current
IC/BC/parameter refinement loop. Pairs with `README_model_field_comparisons.md` (plotting
mechanics) and `../climatology_assessment/FINDINGS.md` (boundary-condition audit).

_Last updated: 2026-06-15._

---

## 0. TL;DR — where things live

| Thing | Path |
|---|---|
| **Model run dir** (setup + launch) | `S:/Matt_Working/csiem/model_runs/HD/` — `csiem_B010_<start>_<end>[_rev].fvc`, `run_tuflowfv_vm.sh` |
| **Model includes (WORKING copy the runs read)** | `S:/Matt_Working/csiem/model_components/` — curated subset; **edit here for changes to take effect** |
| **Model includes (1.7 master template)** | `W:/WAMSI/1.7/csiem_model_tfvaed_1.7/model_components/` — full tree; mirror only |
| **Model output archive** | `S:/Matt_Working/csiem/output_archive/1.7.0/{1991_aug,1991_aug_rev,1992_marmay,1992_marmay_rev,1994B}/` |
| **Field data (SMCWS CTD)** | `Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/{year}/` |
| **Point validation** (this folder) | `G:/CSIEM/1.8.0/csiem-marvl/custom_py/dadamo_transect/` |
| **Background BC climatology audit** | `G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment/` |
| **Iteration helper scripts** | `g:/tmp/make_ic_grad.py`, `g:/tmp/make_obc_poly6_damped.py`, `g:/tmp/write_phe_corrected_csv.py`, `g:/tmp/rebuild_obc_nc.py` |

> **S: vs W::** `S:/…/model_components` is a **separate working copy**, NOT a junction to W:.
> The runs include `../../model_components/…` → the S: copy. Always edit S: first; mirror to
> the W: master only to keep the template consistent.

---

## 1. The model

TUFLOW-FV hydrodynamics (HD: `H, V_x, V_y, SAL, TEMP` only; AED biogeochem layered on for WQ runs).
Mesh = CSIEM mesh B (6 ocean open-boundary segments, "6OBC"). Three hindcast windows in active use:

| Window | Run name | Output (.nc) | Notes |
|---|---|---|---|
| 1991 winter | `csiem_B010_19910720_19910831` | `1991_aug/…nc` (base), `1991_aug_rev/…_rev.nc` | 4-hourly; mid-Aug Transect-A storm survey |
| 1992 autumn | `csiem_B010_19920222_19920531` | `1992_marmay/…nc`, `1992_marmay_rev/…_rev.nc` | daily-ish; Mar TransectA + plan-view survey |
| 1993–94 | `csiem_B010_19931101_19941231` | `1994B/…nc` | long run; May-1994 A/B/C intensive (model still advancing past mid-Feb 1994 historically) |

Each window has a **base** `.fvc` and a **`_rev`** `.fvc` (the current refinement). Runs are launched
from the run dir via `run_tuflowfv_vm.sh`. Outputs land in the run dir then are moved to
`output_archive/1.7.0/<window>[_rev]/`.

**Model gotchas** (see README for detail): NC has only `ResTime` → call `fv = ds.tfv` **before**
reading `ds['Time']`; `get_profile` needs an exact model timestamp (snap to nearest step); no `RHOW`
in HD output (inject EOS-80 `RHOW`, use `RHOW-1000` sigma-t for field comparison); surface = top-2 m
mean (`datum='depth'`), bottom = bottom-2 m mean (`datum='height'`).

---

## 2. The field data (SMCWS)

`Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/{year}/`. Binary CTD profiles (DFV/DMV/DHV/DTV/DSV
readers, exec-reused from `climatology/identify_outer_profiles.py`).

- **1991** `1991/` — `Transect_A/` (thesis panels 6.16a–l **pre-storm**, 6.17a–h **post-storm**);
  DFV profiles in `1991-08/profile_data/`; casts named `{prefix}{hhmm}.{jday}` (e.g. `dfv0729.226`).
  Station coords hard-coded in the scripts. `survey_log_1991.csv` indexes DFV+FV casts.
- **1992** `1992/` — `TransectA/` (per-jday panels 069–087) + `March/` (plan-view maps, jdays 069–088).
  Coords from `.loc` files (EPSG:28350).
- **1994** `1994/` — May intensive Transects **A/B/C** (jdays 123/124); new **DSV** reader. March
  intensive (080/081) blocked on an FV reader the field team hasn't written.
- Bathymetry DEM: `X:/O2Me_EIAbathymetry_DEM/…AHD.tif`. Coastline: AIMS 50k shp under `smcws_data/gis/`.

---

## 3. Two assessment tracks (keep them distinct)

### A. Background BC climatology audit — `../climatology_assessment/`
**Question:** is the *boundary forcing* right? Compares **404 outer-ring / open-ocean casts**
(1991–1994) three ways: **OBS** (field cast) vs **BC** (the forcing actually applied — ROMS
climatology 1991–92, HYCOM 1993–94, sampled inside the 6 seaward bias-correction polygons) vs
**MODEL** (TUFLOW-FV at the cast). Tagged to 5 latitude bands (N/NW/W/SW/S).

Key files: `ocean_assessment_core.py` → `extended_assessment.csv`; `ocean_assessment_plots.py`
(scatter/bias); `ocean_assessment_bc_envelope.py` / `_bc_timeseries.py` (seasonal BC envelopes per
band); `ocean_assessment_profiles.py` (404 obs-vs-BC-vs-model profile curtains); narrative in
`FINDINGS.md`. This track is what surfaced the **Peel-Harvey pre-Cut over-salting** and the
**poly-6 summer over-correction** that the refinements below target.

### B. Point validation — `./dadamo_transect/` (this folder)
**Question:** does the *model* match the obs, cast by cast and along transects? **Inner embayments
included** (OA Owen Anchorage, CS Cockburn Sound tagged by point-in-polygon against
`MLAU_Zones_v3_ll.shp` dissolved by `BP_Region`; everything else → N/NW/W/SW/S lat bands).
Inventory `region_profiles_inventory.csv` (full cast set, inner box NOT excluded, 3 m depth floor;
~2515 casts; 1991≈686, 1992≈1272 in-window).

---

## 4. The validation set — what to run, per year

All driven from `dadamo_transect/`. Each notebook/script has a base vs `_rev` form: the slow notebooks
were converted to headless `_run_*_rev.py` runners (assembled from the notebook cells with
`MODEL_NC`→rev, `OUT…`→`_rev`, `TEST_MODE=False`, forced Agg). Re-point `MODEL_NC` to the relevant
`…_rev.nc` after a re-run.

### Quantitative — region validation + scatter (1991/1992; tag-driven)
- `region_validation_core.py` — paired obs+model extraction; `WINDOWS={'1991','1992','1994','all'}`;
  `FV_RUNS` lists the per-window NC paths (**edit these / the `REV_NC` in the revcompare to point at
  the latest run**). `point_overrides.py` nudges channel-edge model sample points.
- `region_validation_<YEAR>_revcompare.py` — extracts **base + rev** over the overlap window, writes
  `region_validation_<YEAR>_base.csv`, `_rev.csv`, `_revcompare.csv/png` (per-region surf/bot S&T bars,
  baseline vs rev). **Run this first** — it produces the `_rev.csv` the scatter plots consume.
- `region_validation_plots.py <tag>` → `scatter_validation_<tag>.png` (2×2 surf/bot×T/S),
  `region_bias_<tag>.png/csv`, `region_map_<tag>.png`. Use `<tag>=<YEAR>_rev`.
- `region_validation_plots_lon.py <tag>` → `scatter_validation_lon_<tag>.png` (colour=longitude,
  shape=region).
- Single-day cut: filter `region_validation_<YEAR>.csv` by `date` to e.g. `_0813` and re-plot (no
  re-extract).

### Hovmöller (1991) — `hovmoller_ST_1991.py`
Depth-time curtains, sites CS55 & OA80, rows = [S/T × model/field]. `NC` and `RUNLABEL` are set at the
top (already rev-pointed). → `hovmoller_ST_CS55_OA80_1991_rev.png`.

### Transect curtains (model-vs-field) — `profile_curtain_<YEAR>_TransectA_compare.ipynb`
Model (top) vs field (bottom) cross-sections on shared CS55 chainage. 1991 = 20 thesis panels
(`_run_transectA_1991_rev.py` → `outputs_1991_TransectA_compare_rev/`, 19 rendered);
1992 = per-jday (`outputs_1992_TransectA_compare[_rev]/`); 1994 = A/B/C (model rows pending the run).

### Plan-view maps (2×2 model/field, surface/bottom) — `sheet_maps_<…>.ipynb`
- 1991: `sheet_maps_1991_transects.ipynb` (`_run_maps_1991_rev.py [panels|campaigns]`). **Two modes:**
  `campaigns` = pre-/post-storm aggregate (2 windows → 6 figs); `panels` = one map per transect
  occupation aligned to the panel window times (20 windows → ~60 figs; ~1 fig/min kriging).
  → `outputs_1991_transect_maps_rev/{var}/`.
- 1992: `sheet_maps_1992_March.ipynb` (`_run_maps_1992_rev.py`) → `outputs_1992_March_maps_rev/daily_{var}/`.
- Maps reuse the canonical 1992 `contour_coastal_salinity.py` kriging machinery (year-agnostic);
  1991 swaps in a by-time-window cast loader and recomputes winter clim from the 1991 field data.

### Run order (rev refresh, one year)
1. `region_validation_<YEAR>_revcompare.py`  → CSVs + bias bars (also makes `_rev.csv`)
2. `region_validation_plots.py <YEAR>_rev` + `region_validation_plots_lon.py <YEAR>_rev`  → scatter
3. `hovmoller_ST_1991.py`  (1991 only)
4. `_run_transectA_<YEAR>_rev.py`  → curtains
5. `_run_maps_<YEAR>_rev.py campaigns` then `… panels`  (1991) / `_run_maps_1992_rev.py` (1992)

`_run_all_1991_rev.sh` chains all of the above in dependency order with per-step logs.

---

## 5. Current refinement loop (IC / BC / parameters)

We iterate by editing **initial conditions, boundary conditions, and parameters**, re-running the HD
sim, then re-running §4 to score it (base vs `_rev`). Levers in play:

| Lever | Mechanism | Script / file |
|---|---|---|
| **Graded IC** | E–W longitude-graded T/S 2D IC; 2nd stage freshens the Swan-Canning estuary to ~20 psu so eastern CS stays marine | `g:/tmp/make_ic_grad.py` (and the config-driven `model_components/includes/ic/make_graded_ic.py`) → `initial_condition_2D_<mon>_B010_Sgrad.csv` |
| **OBC salinity correction (poly-6)** | Damp the southern OBC's summer over-salting: `S_new = annual_mean + K·(S − annual_mean)`, **K=0.50**, poly-6 cells only | `g:/tmp/make_obc_poly6_damped.py` → `ROMS_…_climatology_S6corr.nc`; used via `3_ocean/obc_hd_<win>_6OBC_climatology_S6corr.fvc` |
| **OBC encoding / SSH** | Rebuild ROMS/HYCOM BC NCs to int16 reference encoding and zero `surf_el` (MOCK Fremantle tide supplies WL) | `g:/tmp/rebuild_obc_nc.py` |
| **Peel-Harvey inflow SAL correction** | Per-water-year salinity offsets (−1.5/−2.0/−1.5/0 for 1990/91→1993/94) flooring the pre-Cut hypersaline climatology | `g:/tmp/write_phe_corrected_csv.py` → `5_phe/phe_WIR_inflows_wq_SALcorr.fvc` |
| **Surface-water drains** | Lake Richmond / Drain D1 freshwater inflow (GLM4 1980–2025) into Mangles Bay | `7_sw/sw_MISC_…fvc` (D1 active, D2–D13 disabled) + `environment_repo/7_sw/CSV/LakeRichmond_Outflow_GLM4_*.csv` |
| **Discharge modifiers** | SDOOL ocean outfall re-enabled for the 1990s (~171 ML/d, Woodman Pt dominant) | `model_modifier_library/discharges/modifier-0003_SDOOL/…` |

The current **`_rev`** runs (1991 & 1992) combine: graded fresh IC + Peel-Harvey SALcorr +
poly-6 OBC S6corr (k=0.5) + SDOOL re-enabled (1991 also has the Lake Richmond drain wired).

### Scoreboard (this session, model − obs bias; + = model too salty/warm)
| | 1991 surf S | 1991 bot S | 1991 surf T | 1992 surf S | 1992 bot S |
|---|---|---|---|---|---|
| baseline | **+1.117** | +0.720 | −0.133 | +0.278 | +0.272 |
| rev (re-run) | **−0.053** | **−0.398** | +0.161 | **−0.019** | −0.035 |

The headline +1.1 psu 1991 surface over-salting (missing winter freshening) is **resolved**; 1992
surface salinity pulled from +0.28 to ≈0.

---

## 6. Open issues / next refinements

- **1991 — saline underflow into the CS basin.** Bottom S now runs slightly *fresh* (−0.40) and the
  dense saline underflow that should sink into the Cockburn Sound basin is under-developed. Fix needs
  **more saline water in Owen Anchorage (OA, north)** to supply the gravity current → adjust the
  **northern OBC polygons (1 / 2)** saltier (or relax their correction), rather than the southern poly-6.
- **1992 — OBC correction over-damped.** The poly-6 damping (k=0.5) probably went **too far**; damp
  **less** (raise K toward ~0.7–0.8 = retain more of the original seasonal correction) and re-score.
- **1994** — model rows pending until the `1994B` run reaches May 1994 and stops actively writing the
  NC (reads throw `NetCDF: HDF error` mid-write). Then run the A/B/C compare with `TEST_MODE=False`.

---

## 7. Editing the OBC polygons 1 & 6 — answer to the standing question

**Yes — `g:/tmp/make_obc_poly6_damped.py` is the script**, but as written it is **hard-wired to
polygon 6 only** (`K=0.50`, reads `Polygons_6_MultiPolygon.shp`, writes `…_S6corr.nc`). The six
polygon shapefiles all exist:
`…/climatology_assessment/diagnostics/biascorr_polygons/Polygons_{1..6}_MultiPolygon.shp`
(geographic layout N→S: **poly 1,2 = north coast** ~−31.7 near the Swan/OA entry; poly 3,4,5 = western
ocean arc; **poly 6 = southern OBC** ~−32.65 near Peel-Harvey).

To act on the two levers in §6 (saltier OA via poly-1, less damping on poly-6) the script should be
**generalised** to a per-polygon spec, e.g.:

```python
# per-polygon transform: K = seasonal-anomaly damping (1=original, 0=flat annual mean)
#                         dS = constant salinity offset (psu) added after damping
POLY_OPS = {
    1: dict(K=1.0, dS=+0.5),   # poly-1 (north/OA): keep seasonality, add +0.5 psu to feed the underflow
    6: dict(K=0.7, dS= 0.0),   # poly-6 (south): damp LESS than the current 0.5
}
# S_new = annmean + K*(S-annmean) + dS, applied only to cells inside each polygon
```

This preserves the existing surgical-copy approach (modify only in-polygon cells of a file copy via
`netCDF4` auto-maskandscale; every other cell stays byte-identical). Output a new suffix (e.g.
`…_S1S6corr.nc`) and point new `obc_hd_<win>_6OBC_climatology_<suffix>.fvc` includes at it.
**I can write that generalised script when you want to try the next 1991/1992 OBC iteration.**
