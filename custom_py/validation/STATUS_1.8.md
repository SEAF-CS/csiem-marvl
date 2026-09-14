# 1.8 validation prep — status (updated 2026-09-09)

**Live sims×assessments ledger: `MARVL.log` at the repo root** (append-only,
updated as runs/assessments progress — Matt's at-a-glance reference).

**2026-09-09:** Both reference sims COMPLETE (2021B ~02:35, 2013B ~04:xx,
clean "Exiting TUFLOWFV", full periods, no errors). Real `MODEL_VER=1.8.0`
validation running: Python suite (TransectA 2021B+2013B, kriged maps T/S 2021,
panels both) + MARVL 008 configs (2021B then 2013B) — logs in
`S:\tmp\csiem_18_rollout\testlogs\REAL_*.log`. The `output_archive/_test/`
copies (329 GB) + `MARVL_WQ_2021_WEMDEV_TEST.m` can be deleted once the real
pass is reviewed. **csiem-marvl consolidated + pushed**: GitHub main =
`c62d01c` (marvl/ layout, vendored aed-marvl, 1.8 suite, -mh port, origin
merge). Y: 1.7.0 folders (`csiem-marvl`, `-mh`, `-sg`) are now legacy.
New sims prepped: 2015B pair created from 2013B template (first B-mesh 2015);
2015A/2022B verified ready to fire.

# (original prep notes below)

Restart-safe notes for the 1.8 post-processing campaign. Written while the two
1.8 reference sims are still running — **nothing here opens a model NetCDF; do
not run any model-reading step until the run's `.log` shows
"Closing output files"/"Exiting TUFLOWFV"** (reading an in-flight NC can kill
the writer).

## Scope & decisions (Matt, 2026-09-06)

- First 1.8 validation pass = **2013B + 2021B WQ** only (the runs now on the
  H100; ETA ~09-Sep). 1990s re-validation and other modern years: later.
- Model NCs are read **directly from**
  `Q:\SEAF-CS\V1.8\MODEL\csiem_model_tfvaed_1.8\output_archive\1.8.0\<sim>\`
  (no SH-style results snapshot for 1.8).
- **Version-switch, same paths**: same scripts/output paths as 1.7; the
  `MODEL_VER` env var selects the model version. `MODEL_VER` unset/`1.7`
  reproduces the published 1.7 behaviour byte-identically. 1.8 figures
  overwrite 1.7 ones in `years/<year>/outputs/` — pre-1.8 outputs archived to
  `years/2013/outputs_pre1.8_20260906.zip` and `years/2021/outputs_pre1.8_20260906.zip`.
- MATLAB MARVL re-run based on **007_1.7_comparison** → cloned to
  **008_1.8_comparison** (marvl/configs/).

## What's wired (done)

| Piece | Change |
|---|---|
| `common/lib/transectA_modern.py` | `MODEL_VER` switch: RUNS root per version + 1.8 SIMS (`2013B`, `2021B` → output_archive/1.8.0). Default `1.7` unchanged. |
| `common/lib/transectA_modern_maps.py` | same switch + 1.8 SIMS. |
| `years/2013/scripts/run_transectA_2013.py`, `map_panels_2013.py` | SIM = `2013A` (1.7) / `2013B` (1.8) chosen by `MODEL_VER` — 2013 is A002 in 1.7 but **B010 in 1.8**. |
| `years/2021/scripts/run_maps_2021.py` | `MODEL_NC` per `MODEL_VER` (kriged sheet maps). 2021 wrappers already use `2021B`. |
| `marvl/configs/008_1.8_comparison/` | `MARVL_WQ_2013_WEMDEV.m`, `MARVL_WQ_2021_WEMDEV.m` cloned from 007: ncfile(1)=1.7 baseline (W: snapshot, A002), **ncfile(2)=1.8.0** (`output_archive/1.8.0/...WQ_WQ.nc`, legend csiem1.8.0), outputs → `marvl/outputs/008_1.8_comparison/`. Fixed stale field-data path `G:\CSIEM\1.7.0\...` → `G:\CSIEM\V1.7\DATA\csiem-data\...` and `csiem_DWER_public_reduced50` → `csiem_DWER_public` (reduced50 not in the V1.7 mat store). |

## How to run (AFTER the sims close)

```bash
cd custom_py/validation/years/2013/scripts
MODEL_VER=1.8.0 python run_transectA_2013.py     # sections
MODEL_VER=1.8.0 python map_panels_2013.py        # station maps
cd ../../2021/scripts
MODEL_VER=1.8.0 python run_transectA_2021.py
MODEL_VER=1.8.0 python map_panels_2021.py
MODEL_VER=1.8.0 python run_maps_2021.py          # kriged sheet maps (T + S)
```
(Windows: `set MODEL_VER=1.8.0` /  PowerShell `$env:MODEL_VER='1.8.0'`.)

MATLAB (R2024a is on this VM): open MATLAB in `marvl/configs/008_1.8_comparison/`,
`addpath(genpath(<repo>))`, then `run_AEDmarvl('./MARVL_WQ_2013_WEMDEV.m','matlab')`
(and the 2021 config). MARVL opens the NCs directly → sims must be closed.

## Resolved (Matt, 2026-09-07)

1. **2013 kriged sheet maps: NOT wanted** (too little field data that year) —
   2013 = TransectA + station panels only.
2. **B mesh throughout**: 008 2021 config baselines 1.7's **2021B** (B010,
   `2021B-20260131010652`), not 2021A. 1.7 never ran 2013 on the B mesh, so the
   008 2013 config is **single-model (1.8.0 2013B) vs field data** (the A002
   baseline lines are kept commented for easy revert).
3. **`csiem_DWER_public_reduced50.mat` is lost** — referenced by every config
   set since 001 (1.5 era) but only ever lived in the old `G:\CSIEM\1.7.0\`
   layout, which was retired; no generator script found. Configs now point at
   the full `csiem_DWER_public.mat` (**6.7 GB** — expect slow MATLAB loads; if
   intolerable, regenerate a documented thinned DWER mat, recipe TBD with Matt).

## Overnight plumbing test (2026-09-07, sims still running)

Mid-run copies of the 2021B NCs (main 62.7 GB + WQ_WQ 266 GB, robocopy Q:→Q:,
server-side, sims unaffected) staged at `output_archive/_test/2021B/`. A
`MODEL_VER=1.8.0-test` entry (both engines + run_maps_2021) points there.
The test copies hold data to ~04-Jun-2021 only.

- **TransectA: PASS** — all 12 windows plotted, bias stats out. NB the engine
  silently clamps to the last model timestep for windows beyond file coverage
  (post-June figures in this test are meaningless; fine on complete runs —
  consider an out-of-coverage guard later). Early-window biases plausible
  (T +0.2..+0.4, S ±0.2).
- **Kriged maps T + S: PASS** (exit 0 each; post-June windows carry the same
  clamping caveat, and S skips windows with <2 surface obs — expected).
- **Station panels: PASS** (exit 0, map_panels_2021.png written).
- **MARVL** (`MARVL_WQ_2021_WEMDEV_TEST.m`, timeseries module, MLAU-zone
  polygon averaging, 1.7-2021B baseline vs 1.8 test copy, R2024a
  `matlab -batch`): two library bugs found:
  1. `timeseries.polygon_file` relative path (fixed — absolute, see below).
  2. **aed-marvl version skew**: `marvl_plot_timeseries.m` calls
     `marvl_sort_agency_information(agency, fdata)` with 3 outputs, but the
     function was upgraded to `(agency, numPoints)` with 4 outputs
     (markerSize 3rd). Passing the fdata STRUCT as numPoints crashes
     `isfinite()` for any agency with dynamic_plotting (IMOS); and
     `agencyname` would silently receive markerSize. Patched both call sites
     in `marvl_plot_timeseries.m` (call with agency only + `~` for
     markerSize). NB the `_dev`/`_Logan`/`_Gladstone`/`_model_top` variants
     carry the same skew — not patched (unused here). **Upstream to
     aed-marvl.** Test 3 re-running.
- **Density for kriged maps: NOT wanted** (Matt 2026-09-07) — maps stay T + S;
  density lives in TransectA (σt via EOS-80).
- **Wrinkle fixed**: MARVL `timeseries.polygon_file` relative path
  `../../gis/Zones/...` only resolves from `marvl/configs/`; all 008 configs
  now use the absolute path to `gis/Zones/MLAU_Zones_v3_ll.shp`.
- Cleanup after the real runs: delete `output_archive/_test/` (329 GB) and the
  `*_TEST.m` MARVL config.

## Remaining notes

- TransectA field cache lives at `S:/tmp/tA/cs_2013_2024_ST.parquet` (volatile
  location; rebuilt automatically if missing, positions pinned 2020-11→2024-04).
- Big agency mats (heads-up for MARVL load times): BOM 8.4 GB, DWER 6.7 GB,
  WAMSI 4.8 GB; all others ≤82 MB.

## Related

- Model-side status: `Q:\SEAF-CS\V1.8\MODEL\csiem_model_tfvaed_1.8\CLAUDE.md`
- 1.7 validation mechanics/gotchas: `common/docs/` + `custom_py/validation/README.md`
