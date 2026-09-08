# Rayshader visualisation — Cockburn Sound / CSIEM

Clean reference for the TFV-AED 3-D rayshader visualisations. Combines the oxycline
(2024) and salt-cascade (1991) work. **Quick-restart recipes below; deep notes in `docs/`.**

## Layout

```
scripts/   reusable scripts (oxycline + salt, one per pipeline stage)
docs/      how-to + hard-won lessons (READ docs/orientation_lessons.md FIRST)
archive/   experimental/test scripts (oxycline/ done; salt experimentals still in ../rayshader_salt)
images/    rendered frames + final MP4s/GIFs
data/      DEMs + extracted interface/salinity GeoTIFFs
rlib/4.4   self-contained R library (rayshader 0.37.3, rayrender 0.38.10) — referenced by abs path
```

R is invoked as `Rscript scripts/<x>.R` **from this folder** (relative `data/` paths assume cwd here).
Every R script starts with `.libPaths(c("G:/CSIEM/1.8.0/csiem-marvl/rayshader/rlib/4.4", .libPaths()))`.

⚠ Salt data (`data/sal_bottom/`, `data/halo_series/`) + salt experimental scripts currently live in
`../rayshader_salt/`. Fold/delete that folder once happy; salt scripts here expect those data paths.

## The 4 plot types — quick restart

### 1. Oxycline isosurface, HQ path-traced  → `docs/oxycline_isosurface.md`, `docs/hq_pathtrace.md`

O2=5.5 mg/L surface draped over terrain, ray-traced. Pipeline:

```
python scripts/extract_oxycline_series.py   # WQ NC -> data/oxy6_series/*.tif + dem_coarse.tif
python scripts/fix_dem.py                    # repair the land-wall -> dem_coarse_fixed.tif
Rscript scripts/render_series_hq.R           # 66 frames, NEE path-trace (~18-20 h)
python scripts/assemble_hq.py                # -> images/oxycline_hq_*.mp4
```

Preview (fast, rasterised): `Rscript scripts/render_timeseries.R`. HQ single-frame template:
`scripts/hq_water_frame.R` (shows the scene_elements + faint-water trick).

**Jan-2024 orbit variant** (52f, continuous slow orbit, no hero hold) — `*_jan2024*` scripts:
```
python scripts/extract_oxycline_jan2024.py    # 15-Jan 12:00 -> 24-Jan 00:00 (4-hourly, 52f) -> data/oxy6_jan2024
Rscript scripts/render_hq_jan2024_orbit.R      # continuous orbit theta 50->5, phi 40->46, zoom 0.62->0.85 -> images/hq_jan2024 (~14 h on 4 cores)
python scripts/assemble_hq_jan2024.py          # 6 fps -> images/oxycline_hq_jan2024_orbit.mp4 (~8.7 s)
```
Window trimmed to land the straight-to-HQ render under a 16 h budget; reuses `data/dem_coarse_fixed.tif`.
NB ~16 min/frame at 256 samples on this 4-core box (the original 66f estimate assumed a faster machine).

**1991 storm PYCNOCLINE variant** (61f, same isosurface HQ pipeline, DENSITY field, violet) — `*_1991*` scripts:
```
python scripts/extract_pycnocline_1991.py     # sigma-t=25.30 isopycnal, 11->26 Aug 1991 (6-hourly, 61f) -> data/pyc_1991
Rscript scripts/render_hq_1991_orbit.R         # continuous orbit theta 30->0 (N-facing), phi 40->46, zoom 0.62->0.85 -> images/hq_1991 (~16 h)
python scripts/assemble_hq_1991.py             # 8 fps -> images/pycnocline_hq_1991_storm_orbit.mp4
```
Field is sigma-t density (EOS-80 @ p=0 from SAL+TEMP; no gsw/seawater installed so it's inline) — the
physically-correct metric for the storm de-/re-stratification the salt version couldn't show (SALT.md TODO #4).
NC = `1991_aug_rev_ITER9` (full event, hourly). THR=25.30 = top of the dense plume descending into the north
basin on the flood tide (cf. `analytics/smcws_data/1991/Fig6-22/fig622_model.png`). Story: broad pre-storm
pycnocline (Aug 11) -> storm shatters it (~Aug 17-20) -> plume cascades back into the basin (Aug 21-25).
Preview to lock look before the HQ run: `Rscript scripts/preview_1991.R` (3 rasterised frames).

**22-Aug-1991 FLOOD-TIDE clip** (37f, hourly, short + smooth, DYNAMIC water) — `*_1991_flood*` scripts:
```
python scripts/extract_pycnocline_1991.py      # (config set to flood window) 22 Aug 00:00 -> 23 Aug 12:00,
                                               #   hourly (37f) -> data/pyc_1991_flood + water_level.csv
Rscript scripts/verify_water_1991.R            # OPTIONAL: 2 HQ frames at tidal extremes to check the water slab
Rscript scripts/render_hq_1991_flood.R         # dynamic water + gentle camera -> images/hq_1991_flood
python scripts/assemble_hq_1991_flood.py       # 5 fps -> images/pycnocline_flood_22aug1991.mp4
```
Shows the dense pulse advancing into the north basin as the tide floods (cf. Fig 6.22, 22 Aug 05:00).
Key difference from the orbit variants: the sea-surface **water level is DYNAMIC** — the dielectric slab
rises/falls per frame from `data/pyc_1991_flood/water_level.csv` (CS-mean free surface, 3 h-smoothed to
tame the basin seiche so it reads as a tidal rise/fall; raw hourly / 6-hourly is too jittery to animate).
⚠ Render speed on this 4-core box is ~16 min/frame at samples=128, 880x760 ("fast" budget ≈ 10 h) —
much slower than the ~16 min/frame-at-256 the older notes assumed. Bump SAMP/W/H in the script for quality.

### 2. Translucent salt-cascade drape  → `docs/salt_drape_translucent.md`

Bottom-salinity coloured on the seabed as a translucent per-vertex MESH (NOT add_overlay!).

```
python scripts/extract_bottom_salinity.py    # SAL NC -> data/sal_bottom/*.tif (set time window inside)
MASKTIF=none ALPHA=0.45 SMIN=34.3 SMAX=34.9 THETA=0 PHI=45 Rscript scripts/render_drape.R
```

Renderer is fully env-parametrised (SDIR/PREFIX/SMIN/SMAX/MASKTIF/ALPHA/THETA/PHI/RAISE/OUT/FRAME(S)/FORCE).

### 3. Model-mesh overlay  → `docs/mesh_overlay.md`, and `../mesh_refinement/`

Model `.2dm` mesh edges draped on terrain (channel-resolution check). See `../mesh_refinement/`.

### 4. Wind panel composite  → `docs/wind_panel.md`

Stacks any 3-D frame series over a swept wind-timeseries panel (storm-vs-response).

```
python scripts/extract_wind.py               # BARRA NC -> data/wind_cs_1991.csv
SRC=images/drape_low python scripts/composite_wind.py   # -> images/composite/*.png
```

## ⚠ Orientation — read `docs/orientation_lessons.md` before touching any render

`raster_to_matrix` + `plot_3d` have non-obvious orientation behaviour that cost a LOT of debugging.
Two rules: (1) use `raster_to_matrix(dem)` AS-IS (rtm) for the mesh — it is north-up-correct;
(2) overlays must be drawn as a per-vertex MESH (generate_surface + shade3d), **never `add_overlay`**,
because add_overlay transposes vs the mesh on non-square grids.
