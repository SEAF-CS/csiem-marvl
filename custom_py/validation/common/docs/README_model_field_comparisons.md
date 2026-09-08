# CSIEM model ↔ SMCWS field comparison plots — dev summary

Quick-restart guide for the transect/curtain/map notebooks in this folder that
compare the **CSIEM TUFLOW-FV model** against the historical **SMCWS CTD surveys**
(1991, 1992; 1994 in progress).

_Last updated: 2026-06 (session)._

---

## Notebooks & outputs (this folder)

| Notebook | What it makes | Output dir | N |
|---|---|---|---|
| `profile_curtain_1991_HD.ipynb` | Model-only density/sal/temp curtain + station profiles + map inset, daily | `outputs_1991/` | 108 |
| `profile_curtain_1991_TransectA.ipynb` | Model-only, Transect A geometry, one fig per survey panel | `outputs_1991_TransectA/` | 60 |
| `profile_curtain_1991_TransectA_compare.ipynb` | **Model-vs-field** curtains (model top / field bottom), shared CS55 chainage | `outputs_1991_TransectA_compare/` | 19 |
| `profile_curtain_1992_TransectA_compare.ipynb` | Same, 1992 (per-jday panels) | `outputs_1992_TransectA_compare/` | 10 |
| `sheet_maps_1992_March.ipynb` | **Plan-view** surface/bottom maps, 2×2 model/field, per day per variable | `outputs_1992_March_maps/daily_{var}/` | 36 |
| `sheet_maps_1991_transects.ipynb` | Same 2×2 model/field plan-view, paneled by **1991 transect windows** instead of calendar days, winter clim auto-computed. `WINDOW_MODE='panels'` → one map per transect occupation (Figs 6.16a–l, 6.17a–h = 20); `'campaigns'` → pre-/post-storm aggregate (2). | `outputs_1991_transect_maps/{var}/` | 20 or 2 × 3 vars |
| `profile_curtain_1994May_TransectABC_compare.ipynb` | Model-vs-field curtains, **Transects A/B/C**, May intensive (jdays 123/124) | `outputs_1994May_TransectABC_compare/Transect{A,B,C}/` | field-ready; model **pending** |

### 1994 status (mid-flight, as of this session)
- Field side **A/B/C built and verified** (jday 123 for A/B, 124 for C; new **DSV** reader). Each section exec's its own `plot_transects{,_B,_C}.py`. Note divergent structure: A = main/dev/spur + CS55 haversine chainage; B = `CHAIN_B` (cumulative from CS30) + two-phase bathy fill; C = single-day `CHAIN_C`.
- **Model not yet available for May 1994**: the `1994B/csiem_B010_19931101_19941231.nc` run is **still running** (sim time only ~mid-Feb 1994 and advancing; needs to reach ≥ early May). It is also **actively writing the NC**, so reads throw `NetCDF: HDF error`. The notebook is resilient — it falls back to field-only + a "MODEL pending" placeholder on the model row. **Re-run with `TEST_MODE=False` once the run is stable and covers May** to populate the model rows.
- March 1994 intensive (jdays 080/081) is blocked on an FV reader the field team hasn't written yet.

Every notebook has a `TEST_MODE = True` flag (renders one panel inline). Set it
`False` to regenerate the full set. Shapefiles `transect_A.shp` / `transect_A_100m.shp`
(Transect A polyline, built from the 1991 station list) also live here.

---

## Quantitative region validation (obs vs paired model scatter)

`region_validation_core.py` + `region_validation_plots.py` — obs-vs-TUFLOW-FV
**scatter validation** bucketed by region, **time-window filterable**, **no ROMS/BC**
(pure model validation, distinct from the climatology assessment which compares the BC).

**Regions:** the **inner embayments OA (Owen Anchorage) & CS (Cockburn Sound)** are
tagged by point-in-polygon against `…/1.7.0/csiem-marvl/gis/Zones/MLAU_Zones_v3_ll.shp`
**dissolved by `BP_Region`**; all other casts fall back to the N/NW/W/SW/S **lat bands**
(same cutoffs as the climatology assessment). See `region_map_<tag>.png` to verify bucketing.

**Inventory:** `region_profiles_inventory.csv` (built by `g:/tmp/build_full_inventory.py`)
is the **full** cast set — it re-runs the `identify_outer_profiles.py` scan **without the
inner-exclusion box** (that box was exactly what dropped CS/OA) and with a **3 m** depth
floor (vs 8 m outer), recovering the inner profiles. 2515 casts total; **1991 = 686**
(CS 420, OA 195) vs only 6 in the outer-ring inventory. Binary CTD readers are reused
from `identify_outer_profiles.py` via exec-prefix.

**Run:**
```
python region_validation_core.py 1991     # -> region_validation_1991.csv  (paired obs+model)
python region_validation_plots.py 1991     # -> scatter_validation/region_bias/region_map _1991.png
```
Windows are named in `WINDOWS` (core) — `1991`/`1992`/`1994`/`all`, or call `run((lo,hi))`
with any dates. Plots: 2×2 scatter (surf/bot × T/S, coloured by region, 1:1 + bias/RMSE),
per-region bias bars (`region_bias_<tag>.png/.csv`), and the cast/region map.
`region_validation_plots_lon.py <tag>` is a scatter variant with **colour = longitude
(cross-shelf), shape = region** (`scatter_validation_lon_<tag>.png`). Single-day cuts:
filter `region_validation_1991.csv` by `date` to a new `region_validation_<tag>.csv`
(e.g. `1991_0813`) and re-plot — no need to re-extract.

**1991 result (654-cast mid-Aug survey, all paired):** model **T excellent** (surf bias
−0.13 °C) but **S too salty by +1.1 psu at the surface** — the model sits at ~35.3 psu
top-to-bottom (its IC/BC value) and **misses the observed winter surface freshening**
(obs surf S median ~34.3, fresh tail to ~24.5 near the Swan mouth; NW band bias +2.78).
Bottom S bias is smaller (+0.7). → the **well-mixed/background salinity is ~0.5–1.0 psu
too salty** (an IC/forcing lever); the **surface stratification miss** is a freshwater-flux
gap, not fixable by the IC alone. Feeds the **1991 IC refresh**.

**1991 IC refresh** built from this — graded by longitude via the reusable
`…/model_components/includes/ic/make_graded_ic.py` (config-driven, two-stage, region-gated;
verified to reproduce the 1992 `…_Mar_B010_Sgrad.csv` exactly). `initial_condition_2D_Aug_B010_Sgrad.csv`:
**T 18.5→15.5** (W limit→ref lon 115.75, held east); **S 35.4→34.0** (W→ref) then a **2nd stage
34.0→20.0 confined to the Swan-Canning estuary** (MLAU `Swan Canning` region) so eastern
Cockburn Sound stays marine (~34). Not yet wired into the 1991 .fvc.

---

## Data sources

**Model output (TUFLOW-FV HD runs)** — variables `H, V_x, V_y, SAL, TEMP` only:
- 1991: `S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug/csiem_B010_19910720_19910831.nc` (4-hourly, 20 Jul–24 Aug 1991)
- 1992: `S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay/csiem_B010_19920222_19920531.nc` (daily-ish, 22 Feb–31 May 1992)

**Field data (SMCWS):** `Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/{year}/`
- 1991: `Transect_A/` (panels 6.16a–l pre-storm, 6.17a–h post-storm); DFV binary profiles in `1991-08/profile_data/`; station coords hard-coded in the scripts.
- 1992: `TransectA/` (per-jday panels 069–087) + `March/` (plan-view maps, jdays 069–088); DFV/DMV/DHV/DTV readers; station coords from `.loc` files (EPSG:28350) in the DEP archive `MARINE CD-3/.../dadamo_usr2/map/`.
- Bathymetry DEM: `X:/O2Me_EIAbathymetry_DEM/...AHD.tif`. Coastline: AIMS 50k shp under `smcws_data/gis/`.

---

## Key model gotchas (hard-won)

1. **Time decode:** the NC files have only `ResTime` (hours since 1990), no `Time`
   variable. The `.tfv` accessor builds `Time` from it — so **call `fv = ds.tfv`
   BEFORE reading `ds['Time']`**, else you get a 1970-epoch index.
2. **`get_profile` needs an EXACT model timestamp** (`.sel(Time=[t])`, no nearest).
   Snap your target time to the nearest model step:
   `md = times[int(np.argmin(np.abs(times - target)))]`. (`plot_curtain`/`get_sheet`
   tolerate arbitrary times.)
3. **No `RHOW` in HD output** — inject it: `ds['RHOW'] = eos80_potential_density(ds['SAL'], ds['TEMP'])`
   (EOS-80, p=0). For field comparisons the field uses **sigma-t**, so use `RHOW - 1000`.
4. **Surface/bottom sheets:** `fv.get_sheet([var], time=md, datum='depth', limits=(0,2), agg='mean')`
   = top-2 m mean (surface); `datum='height'` = bottom-2 m mean.

## Field-machinery reuse pattern

To stay in lock-step with the published field figures, the compare/map notebooks
**exec the canonical SMCWS script up to its plotting loop** and reuse its objects:
- 1992 transects → `smcws_data/1992/TransectA/plot_transects.py`, split at `for panel_idx, jday in enumerate(JDAYS):`
- 1992 maps → `smcws_data/1992/March/contour_coastal_salinity.py`, split at `for jday in JDAYS:`
- **1991 maps reuse the SAME 1992 `contour_coastal_salinity.py` machinery** (grid/coast/readers/
  `krige_field`/`VAR_CONFIG` are year-agnostic). Built by `g:/tmp/build_maps91_nb.py`, which after the
  exec-prefix: (1) overrides `profile_dir` → `1991/1991-08/profile_data`; (2) replaces the by-jday
  loader with a **by-time-window** loader (1991 casts are `{prefix}{hhmm}.{jday}`, e.g. `dfv0729.226`,
  jday 225 = 13-Aug → parse the timestamp from the filename); (3) iterates the **transect windows**
  from `1991/Transect_A/map_panel_windows.py` — default `WINDOW_MODE='panels'` does one map per
  occupation (THESIS_PANELS_616 6.16a–l + _617 6.17a–h = 20 maps/var, each with its own model
  snapshot at the panel midpoint); `'campaigns'` aggregates to pre-/post-storm (2 maps/var, better
  domain coverage). Per-panel legs are near-colinear → the kriged field is a corridor along the
  transect (station markers carry the values; sparse panels with <5 stns are skipped); (4) recomputes clim (2nd–98th pct)
  from the 1991 field data → S 34.0–35.25, T 15.25–17.5, σt 24.8–25.8. Model is a single snapshot at
  each window midpoint; field is aggregated over the multi-day window.

When doing this: set `__file__` to the script path (its `BASE`/`PARENT`/`MAP_DIR`
resolve from it); `.replace("matplotlib.use('Agg')", "")` so the notebook backend
wins; and **avoid name collisions** — those scripts define their own `OUT_DIR`
(we use `OUT_PNG_DIR`). 1991 used hard-coded copies of the field helpers instead.

## Conventions

- **Chainage from CS55** (km): north negative, south positive; axis drawn South-left / North-right.
- Field curtains gridded by `build_cross_section` (0.25 m bins, bathy extension, distance/ghost masks).
- Maps: pykrige Ordinary Kriging, 300×400 grid, distance mask 0.04°, AIMS land mask.
- **Field is the style/clim reference** (xlim/ylim/clim/levels/cmap come from the SMCWS scripts).

## Build/run workflow

Builder scripts live in `g:/tmp/build_*.py`: they author the notebook cell sources
as strings, **smoke-test headless** (exec all cells with `Agg`), then emit the `.ipynb`.
Full batches run via `g:/tmp/run_full_*.py` (sets `TEST_MODE=False`).

## Known limitations / TODO

- **Temperature model row saturates** (model runs ~1–2 °C warmer than the field's
  narrow clim). Option: give the model its own per-variable clim.
- **Kriging is slow** (~1 fig/min; 36 maps ≈ 1 h). Cache kriged arrays or drop grid res if iterating.
- Curtain/map notebooks are visual only; quantitative obs−model differencing now lives in
  the **region validation** scatter tool above (`region_validation_*.py`).

## Dependencies

`tfv==1.0.14`, `xarray`, `geopandas`, `pykrige`, `rasterio`, `pyproj`, `scipy`,
`shapely` (incl. `shapely.vectorized`), `matplotlib`. Network drives `S:` (model),
`X:` (bathy DEM), and `G:` (field + outputs) must be mounted.
