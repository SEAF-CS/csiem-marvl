# Oxycline isosurface movie (2024)

The O2 = 5.5 mg/L isosurface (top of the depleted bottom water) draped over Cockburn Sound, morphing
13–23 Jan 2024 (4-hourly, 66 frames), then a hero orbit+zoom. Red surface = depleted water.

## Data source
WQ NC: `W:\WAMSI\1.7\SH-20251123-1.7.0\2023B-20251124150126\results\csiem_B010_20221101_20240401_WQ_WQ.nc`
Var `WQ_OXY_OXY` (÷31.25 → mg/L). Topology: `NL`, `cell_X/Y` (EPSG:4326), `layerface_Z`, `ResTime`.
`NumLayerFaces3D = NumCells3D + NumCells2D` ⇒ `top_face = arange(n3) + col0` gives each cell's top face.

## Pipeline
```
python scripts/extract_oxycline_series.py   # -> data/oxy6_series/oxy6_###.tif + data/dem_coarse.tif
python scripts/fix_dem.py                    # -> data/dem_coarse_fixed.tif   (see DEM fix below)
Rscript scripts/render_series_hq.R           # HQ path-trace 66 frames (~18-20 h, resumable)
python scripts/assemble_hq.py                # -> images/oxycline_hq_20240113_23.mp4
```
Fast rasterised preview instead of HQ: `Rscript scripts/render_timeseries.R`
(fixed hero for 28 frames, then orbit+zoom; `render_snapshot`, seconds/frame, NOISE-FREE).

## Crossing detection (extract)
Per water column find the shallowest top-down crossing where O2 goes from >THR (above) to <THR (below):
`cross[1:] = below[1:] & ~below[:-1] & prev_same`, then linear-interp the elevation where O2==THR.
Grid onto the coarse DEM (DEC=4), mask: `dist>400 m`, `demc>=0` (land), `grid<=demc` (below seabed).

## ⚠ DEM land-wall fix (`fix_dem.py`)
`cockburn_swan_2.tif` pads open-water cells **outside the bathy survey to exactly 0 m** (N/S/E edges
bottom out at 0.00; W edge has real −22 m). With `water=FALSE` that flat 0-shelf renders as a spurious
**land wall** boxing in the basin. Fix: reset the exactly-0 fill cells to NaN and re-fill with scipy
`griddata` from real bathy → `dem_coarse_fixed.tif` (drop-in, same grid). Always render with the fixed DEM.

## Render method (the key trick)
Oxycline is added as a **3-D mesh** (generate_surface + shade3d, opaque red `#d7301f`), NOT add_overlay.
For rasterised preview it just works. For HQ path-tracing it must instead be a **rayrender object**
passed via `scene_elements` (add_overlay/rgl meshes are dropped by render_highquality) — see
`docs/hq_pathtrace.md` and `scripts/hq_water_frame.R`.

Camera (hero): `theta=45, phi=40, zoom=0.62, ZSCALE=0.4`. (Salt later used theta=0; oxycline kept 45.)
