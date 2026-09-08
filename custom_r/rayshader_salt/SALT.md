# SALT cascade rayshader animation — working notes

**Goal:** Animate the dense-water *salt cascade* down the slope into Cockburn Sound (CS),
following a **halocline** isosurface — 1991 post-storm event. Sibling of the oxycline movie
(`../rayshader/`); same pipeline/logic, different field/time/angle.

## The science being shown
- 1991 winter: water column stratifies, a **storm (~Aug 17–19)** fully mixes it, then post-storm
  the **dense salty blob in the north cascades down-slope into the CS basin** (~Aug 21–25).
- Reference transect (the dynamic we're capturing):
  `G:\CSIEM\1.8.0\csiem-marvl\custom_py\dadamo_transect\outputs_1991_TransectA_compare_rev\compare_TransectA_6.17d_post.png`

## Data
- **NC:** `S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc`
  - vars: `SAL` (psu, no conversion), `TEMP`, `V_x/V_y`, `layerface_Z`, `NL`, `cell_X/Y` (EPSG:4326),
    `cell_Zb`. 253 steps, 4-hourly, 1991-07-20 → 08-31. Topology matches the oxygen file
    (NumLayerFaces3D = NumCells3D + NumCells2D ⇒ same top_face crossing logic).
  - **Salinity is LOWER than the transect colourbar:** median 34.5, p95 35.2, **max 35.5 psu**
    (transect 35.5–36.2 scale was field/density, not this model SAL).
- **DEM:** reused from oxycline run — `data/dem_coarse_fixed.tif` (land-wall repaired), same coarse
  grid (847×419, DEC=4 from `cockburn_swan_2.tif`). Copied in, not regenerated.

## Decisions LOCKED (2026-06-17)
- **Threshold THR = 34.6 psu** = the dense tongue entering CS (NOT 35.2 — that was too high).
  ⚠️ 34.6 is near the domain median, so the surface appears broadly (north shelf + west open ocean)
  → **needs a spatial mask to the CS basin + northern entrance** (open ocean west strip cols ~0–45
  and Swan/other areas are spurious). Mask not yet built.
- **Window:** Aug 14 → Aug 25, 4-hourly = **67 frames** (pre-storm → mix → cascade).
- **Surface colour:** purple / violet `#762a83`.
- **Hero camera:** `theta≈15` (closer to north-facing), phi=40, zoom=0.62, ZSCALE=0.4 — fine-tune.

## Pipeline / scripts (in this folder)
- `extract_halocline_series.py` — SAL=THR crossing (upper fresh → lower salty), shallowest per
  column, gridded onto coarse DEM → `data/halo_series/halo_###.tif` (67 frames). DONE.
- `diag_halo_coverage.py` / `diag_halo_zoom.py` — where 34.6 appears (mask design). DONE.
- `render_salt_preview.R` — fast rasterised preview (theta=15, purple). `FRAME=n` for one frame,
  else all → `images/preview/` + `images/halo_preview_aug14_25.gif` (12 fps). DONE.
- Shares the R library: `.libPaths("../rayshader/rlib/4.4")`.

## PIVOT (2026-06-17): primary viz = BOTTOM-SALINITY DRAPE, not the isosurface
The SAL=34.6 top-surface (halocline) showed the tongue at the CS *entrance* but left the deep basin
floor bare (no fresh→salty crossing there / clipped at seabed), so it did NOT depict the dense water
*plunging into the basin*. Decision: show the cascade as a **colour drape of BOTTOM-cell salinity on
the seabed** — dense salty water pooling/spreading on the basin floor over time.
- `extract_bottom_salinity.py` → `data/sal_bottom/sal_###.tif` (bottom SAL per column, gridded). 67 frames.
- `render_drape_preview.R` — colormaps salinity → RGBA, `add_overlay` onto sphere_shade seabed; this is
  the **surface texture** (tag "surface"), so it works in render_highquality WITHOUT scene_elements.
  Each frame needs its own plot_3d (texture baked in). theta=15, scale SMIN/SMAX env (default 34.6..35.5).
- Colormap: cool→purple ramp `#e0f3f8…#762a83…#40004b` (no white, won't blend with no-data).
- The halocline isosurface series (`halo_series/`, `render_salt_preview.R`) is kept as a fallback/option.

## Salt signal is WEAK; amplified via CS mask + tight scale (decision: stay with SALT, not density)
Quantified: CS basin bottom-sal moves only ~0.3 psu over the event (p2..p98 = 33.97..34.71), NOT a clean
post-storm rise (basin max higher pre-storm). Strongest salt is OFFSHORE west (spurious). The reference
cascade reads clearest in DENSITY (cold+salty) and the NC has TEMP — density remains the better physical
metric — but user chose to AMPLIFY SALT instead of switching.
Amplification (works — basin structure now visible):
- **CS mask** `data/cs_mask.tif` (built by `design_cs_mask.py`): water cells, rows 160–822, cols 58–242
  (drops offshore-west cols<58 + Swan/east; Garden Island excluded as land). ⚠ rectangular edges look
  artificial — TODO feather to basin/bathymetry.
- **Tight colour scale** SMIN=34.1, SMAX=34.77 (basin p2..p98). cool→purple ramp; dense water = purple in
  the north, tongue pushes down the east into the basin by ~f059.
- Renderer `render_drape_preview.R` now applies CSMASK + tight scale (env SMIN/SMAX/MASKTIF; FRAMES list).

## ✅✅✅ ORIENTATION TRULY RESOLVED (2026-06-18, user-confirmed plan view)
ROOT CAUSE: `add_overlay` + `plot_3d` apply the overlay texture TRANSPOSED relative to the mesh for a
NON-SQUARE heightmap — irreconcilable (transposing the overlay swaps its dims, so it no longer matches
the heightmap). This is why EVERY add_overlay attempt fought the terrain.
THE FIX (matches the working oxycline): elmat = `raster_to_matrix(dem)` AS-IS (rtm, NOT transposed) —
confirmed correct terrain (`terr_compare.R`: rtm matches truth, Swan winds NE). Draw the salt NOT via
add_overlay but as a PER-VERTEX-COLOURED MESH sharing the terrain coord frame:
  salt_h <- elmat + 2; salt_h[is.na(salt)] <- NA            # raise ~2 m so it isn't z-fighting the seabed
  surf <- rayshader:::generate_surface(salt_h, ZSCALE)
  m <- rgl::tmesh3d(t(surf$verts), surf$inds, homogeneous=FALSE)
  vcol <- PAL[1+round(pmin(pmax((c(salt)-SMIN)/(SMAX-SMIN),0),1)*255)]   # c(salt) column-major == vert order
  rgl::shade3d(m, col=vcol, meshColor="vertices", lit=FALSE, alpha=1)
Verified plan view (`salt_mesh_plan2.png`) matches `verify_overlay_2d` truth — user confirmed CORRECT.
Reference/proof scripts: terr_compare.R, salt_mesh.R, bathy_northup_truth.py, landmarks.py.

## (superseded) earlier transpose note
`raster_to_matrix()` returns the GeoTIFF array TRANSPOSED, and `plot_3d` then renders it rotated+mirrored,
so renders looked geographically wrong (Swan appeared SW instead of NE; bathy mirrored). PROOF:
`t(raster_to_matrix(r))` == `raster::as.matrix(r)` (true north-up) EXACTLY (max|diff|=0; any flip differs
26–33 m). FIX: apply `t()` to elmat, the value/salt tifs, AND the mask — all transposed identically so they
stay aligned AND become true north-up. Then **theta=0 = due-north-facing** (N=back, E=right, W=left, S=front;
verified by colored-corner test `confirm_transpose.R` and 2D overlay `verify_overlay_2d.py`, user-confirmed).
Tools kept: `map_corners.R` (geo→matrix map), `test_mirror.R` (the t()==truth proof), `verify_overlay_2d.py`
(north-up salt-over-bathy sanity check). Earlier non-transposed renders were genuinely wrong — ignore them.
NOTE: the oxycline movie used the SAME DEM at theta=45 without this transpose — its geography is likely
also rotated/mirrored; revisit if that matters (user never flagged it there).

## Robust renderer: `render_drape.R` (replaces render_drape_preview.R)
Parametrised + resumable + field-agnostic (env: SDIR/PREFIX/SMIN/SMAX/MASKTIF/THETA/PHI/ZOOM/OUT/FRAME(S)/
FORCE). Drape = surface TEXTURE → survives render_highquality with NO scene_elements. Default = salt
(data/sal_bottom, scale 34.1..34.77, cs_mask). To swap to density later: point SDIR/PREFIX + new SMIN/SMAX.
Full masked animation: `images/drape_cascade_aug14_25.gif` (67 frames, 12 fps).

## VIZ STYLE LOCKED (2026-06-19): translucent full drape
User picked option B (of clip / translucent / isosurface). render_drape.R now: salt = per-vertex MESH,
`ALPHA` env <1 = translucent so the basin RELIEF reads through (3-D). Production settings:
`MASKTIF=none ALPHA=0.45 SMIN=34.3 SMAX=34.9 THETA=0 PHI=45` (north-facing). PAL now starts at #abd9e9
(dropped the near-white low end). Output: `images/salt_cascade_aug14_25.mp4` (67 frames, 8.4 fps ≈ 8 s).
NOTE (science, still open): clip/isosurface tests (optA/optC) confirmed the dense water hugs the N
ENTRANCE and does NOT strongly fill the deep basin floor in SALINITY — density (σ-t, cold+salty) would
show the plunge-to-bottom far better. User stayed with salt for now.

## Full-length render + mesh overlay (2026-06-19)
- FULL run: extract window widened to the whole NC (1991-07-20→08-31, 253 frames, native 4-hourly).
  `images/salt_cascade_FULL_1991.mp4` (253 frames @ 6 fps ≈ 42 s, translucent, theta=0 phi=45).
- MESH overlay diagnostic (channel resolution): `parse_mesh.py` reads the TFV `.2dm`
  (`W:\WAMSI\1.7\...\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm`, 27456 nodes / 30206 cells).
  ⚠ nodes are in EPSG:4326 lon/lat (NOT projected) — must warp to DEM crs (EPSG:28350). Edges in the DEM
  footprint (32k of 57k) → `data/mesh_seg.csv` in plot_3d coords (px=pcol-(W-1)/2, pz=prow-(H-1)/2,
  py=elev/zscale; W=419 E-W, H=847 N-S). `render_mesh_overlay.R` draws them via rgl::segments3d (faint).
  Outputs `images/mesh_overlay.png` (oblique) + `images/mesh_overlay_plan.png`. Aligns with terrain.

## Lower camera + wind panel (2026-06-20)
- Camera lowered: PHI 45 → 31.5 (30% down, more side-on). Re-render OUT=images/drape_low.
- WIND: `extract_wind.py` pulls 10 m wind from BARRA `BARRA_PH_UTC+8_19910101_19911231.nc` (vars
  uwnd10m/vwnd10m, hourly) at nearest grid pt to CS (lat -32.154, lon 115.747) → `data/wind_cs_1991.csv`.
  Peak 20.4 m/s on 1991-08-01 19h. `composite_wind.py` stacks each 3D frame over a wind-speed timeseries
  panel with a red marker that sweeps in sync (frame time = 1991-07-20 + 4h*i). Output
  `images/salt_cascade_wind_1991.mp4` (253 frames @ 6 fps ≈ 42 s). Wind-rose variant not done (timeseries
  chosen for storm-vs-cascade timing).

## TODO / next (priority: robust pipeline first, science later — per user)
1. (cosmetic) Feather/clip the rectangular CS mask edges to the basin shape.
2. Port HQ path-trace config from `../rayshader/render_series_hq.R` (NEE + bright wrap + 256/sobol_blue +
   denoise, clamp 8, theta=15). Drape is a texture so no scene_elements; add faint 0 m AHD water surface
   (dielectric slab) as in oxycline run. Build `render_series_hq_salt.R`, resumable.
3. Assemble MP4 (`assemble_hq.py` style).
4. LATER (science): salt shows storm-flush not post-storm cascade-in; revisit DENSITY (σ-t, TEMP available)
   for the physically-correct cascade depiction.

## Resource note
Decision (2026-06-17): run the oxycline HQ render and this salt dev IN PARALLEL, accepting ~half speed
each (HQ frames went 18→~43 min under contention). HQ is resumable; don't delete `../rayshader/images/hq_frames/`.

## Status
- Oxycline HQ run is rendering in parallel in `../rayshader/` (~20 h, resumable). Don't disturb its
  `images/hq_frames/`. This salt dev shares CPU — extraction/preview slow it slightly, harmless.
