# Translucent salt-cascade drape (1991)

Bottom-cell salinity painted on the seabed as a **translucent per-vertex mesh**, so the basin relief
reads through the colour (3-D). Shows the 1991 winter dense-water cascade into Cockburn Sound.

## Data source
Hydro NC: `S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc`
Var `SAL` (psu, no conversion). Also `TEMP` (for density σ-t if needed), `V_x/V_y`, `layerface_Z`, `NL`,
`cell_X/Y`, `cell_Zb`. 253 steps, 4-hourly, 1991-07-20→08-31.

## Pipeline
```
python scripts/extract_bottom_salinity.py    # bottom SAL per column -> data/sal_bottom/sal_###.tif
#   (edit T_START/T_END inside: full run = 1991-07-20..08-31 = 253 frames; cascade window = Aug 14..25)
MASKTIF=none ALPHA=0.45 SMIN=34.3 SMAX=34.9 THETA=0 PHI=45 ZOOM=0.62 OUT=images/drape Rscript scripts/render_drape.R
python -c "import glob,imageio.v2 as i; fs=sorted(glob.glob('images/drape/f_*.png')); \
  i.mimsave('images/salt.mp4',[i.imread(f) for f in fs])"   # or reuse assemble pattern, ~6 fps
```

## render_drape.R — env parameters
`SDIR`(data/sal_bottom) `PREFIX`(sal) `SMIN/SMAX`(colour scale psu) `MASKTIF`("none"=full domain, else a
mask tif e.g. data/cs_mask.tif) `ALPHA`(<1 = translucent, 0.45 good) `THETA/PHI/ZOOM` `RAISE`(m above
seabed, 2) `OUT` `FRAME`/`FRAMES`(comma list) `FORCE`(1 = re-render existing). Builds terrain once,
swaps the salt mesh per frame via `pop3d(tag="salt")`.

## Method = the mesh overlay (NOT add_overlay — see orientation_lessons.md)
`elmat = raster_to_matrix(dem_coarse_fixed)` as-is. Salt mesh = generate_surface of `elmat+RAISE` masked
to where salt is finite, per-vertex coloured by `c(salt)` (column-major == vertex order). PAL is a
cool→purple ramp `#abd9e9 … #762a83 … #40004b`.

## Science notes (important for interpretation)
- The salinity cascade signal is **weak** (~0.3 psu in the basin); dense water hugs the N **entrance**
  and does NOT strongly fill the deep basin floor in salinity terms.
- Tight scale 34.3–34.9 brings out the basin gradient (full range ~33–35.5; ocean clamps to purple).
- **Clip / isosurface tests** (viz_options.R) confirmed the entrance-only concentration. For a clearer
  plunge-to-bottom, compute **DENSITY (σ-t from SAL+TEMP)** — physically the right field; not yet done.
- CS-only focus: `design_cs_mask.py` → `cs_mask.tif` (rows 160-822, cols 58-242; drops offshore-W + Swan).

Hero: `theta=0` north-facing, `phi=45` (or 31.5 lower/more dramatic). Full-run MP4 ≈ 253 frames @ 6 fps.
