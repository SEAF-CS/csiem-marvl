# Mesh refinement — TUFLOW-FV channel bathymetry overrides

Diagnose where the TFV model grid under-resolves a channel, then **correct cell depths via
TUFLOW-FV bathy overrides** (no remeshing). One channel per *area*; the workflow repeats per area.

Motivation: the 1991 salt-cascade movie (`../rayshader/`) showed dense water reaching the Cockburn
Sound entrance but not strongly cascading to the deep basin. Candidate cause = entrance channels too
shallow/chunky in the model grid, throttling the flow. Each area here quantifies and fixes one channel.

## Layout — common vs per-area

```
common/                      shared, area-independent
  data/    cockburn_swan_2.tif (hi-res DEM truth) · dem_coarse_fixed.tif · cs_mask.tif
           mesh_seg.csv · mesh_plot.npz (whole-mesh derivatives) · landmarks_px.csv
  docs/    channel_transect_method.md · tuflowfv_bathy_options.md   (the method + TFV command ref)
  scripts/ parse_mesh.py · render_mesh_overlay.R   (whole-mesh resolution check, run once)
  outputs/ mesh_overlay.png · mesh_overlay_plan.png

areas/<name>/                one channel; scripts COPIED here and params tuned inline
  scripts/ channel_dem · build_mesh_depthmap · transect_compare · cross_sections
           identify_channel_cells · make_cell_csv
  data/    _chan_win.npy  (area-specific pixel window etc.)
  outputs/ the figures + cell_elevation_channel.csv (the override)

  success_channel/   ✅ DONE  (Cockburn Sound entrance, N of the sound)
  minstrel_channel/  ⏳ NEXT  (scripts copied; see scripts/RETUNE.md before running)
```

Mesh (external, abs path in scripts): `...gis_repo/1_domain/mesh/csiem_mesh_B010_opt.2dm` (nodes in
**lon/lat**, warp to CRS!). Model depths: `cell_Zb` from the `1991_aug_rev` NC.

## Run convention
- **Per-area scripts:** `cd areas/<name>` then `python scripts/<x>.py`. Relative paths assume that cwd —
  shared inputs via `../../common/data/...`, area inputs via `data/...`, figures to `outputs/...`.
- **Common scripts:** `cd common` then `python scripts/parse_mesh.py` / `Rscript scripts/render_mesh_overlay.R`.

## Per-area pipeline (order)
1. `channel_dem.py` — crop hi-res DEM to the area AOI → `outputs/channel_dem.png`, `data/_chan_win.npy`.
2. `build_mesh_depthmap.py` — mesh cells coloured by `cell_Zb` over the AOI → `outputs/mesh_depthmap.png`.
3. `transect_compare.py` — straight thalweg down the channel; DEM | model `cell_Zb` | profile.
   Endpoints from PCA-fit + `NW`/`SE` nudges (env-tunable). Shows model **~2–3 m shallower** on the notch.
4. `cross_sections.py` — N perpendicular sections, DEM (smooth) vs model **stepped per-cell `cell_Zb`**
   (point-in-cell via TriFinder).
5. `identify_channel_cells.py` — pick the corridor cells (half-width `CH`) along the thalweg, list element IDs.
6. `make_cell_csv.py` — emit `outputs/cell_elevation_channel.csv` (`Cell_ID,Z,...`) = DEM depth at each
   cell centroid within the corridor + any manual tweaks, plus a before/after check figure.

Override is then wired into a TUFLOW-FV control file as `Cell Elevation File == <csv>, Cell_ID`
(see `common/docs/tuflowfv_bathy_options.md`), and the run repeated to check the cascade strengthens.

## What is area-specific (tune these per channel — that's why scripts are copied)
AOI box (lon/lat) · thalweg trace band (col/row fractions `SC0,SC1` / `RR0,RR1`) · endpoint nudges
`NW`,`SE` · corridor half-width `CH` + `KEEP_KM` · any manual per-cell depth tweaks in `make_cell_csv.py`.

### Success channel (locked)
AOI lon 115.62–115.78, lat −32.05–−32.20 · trace band cols 0.40–0.70, rows 0.05–0.78 · `NW=1140 SE=1050`
· `CH=75 m`, `KEEP_KM=(1.0,9.0)` · manual tweaks: 8.75–9.0 km −1 m; last cell → −17 m; EAST mound cells
6928/6929/7166 → −14 m. 145 corridor cells, mean deepening ~0.8 m.

## Add a new area
`cp -r areas/success_channel areas/<new>` (or copy just `scripts/`), wipe its `outputs/`/`data/`, then retune the
area-specific params above and run the pipeline from `areas/<new>/`.
