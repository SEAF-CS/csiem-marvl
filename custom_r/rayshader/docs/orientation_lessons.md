# ⚠ Orientation lessons (READ FIRST) — rayshader + GeoTIFF + mesh

This cost an enormous amount of debugging on the salt work. Internalise it before any render.

## TL;DR
1. **Terrain mesh:** `elmat <- raster_to_matrix(raster(dem))` **as-is** — do NOT transpose. This renders
   geographically correct (verified: Swan estuary winds NE, Garden Island the N–S island, ocean to the W).
2. **Any data overlay (salt, isosurface, pins):** draw as a **per-vertex-coloured 3-D MESH**
   (`rayshader:::generate_surface` + `rgl::tmesh3d` + `rgl::shade3d`), **NOT `add_overlay`**.
3. `theta=0, phi=90` plan view of the rtm terrain == the north-up GeoTIFF (truth). Oblique = tilt of that.

## Why `add_overlay` fails (the core gotcha)
`plot_3d` draws an `add_overlay` texture **transposed relative to the mesh** for a NON-SQUARE heightmap.
You cannot reconcile it: transposing the overlay swaps its dims so it no longer matches the heightmap.
Result: salt/markers land rotated/mirrored off the terrain. The **working oxycline used a mesh overlay**
(generate_surface + shade3d), which shares the mesh's coordinate frame and is always aligned — so do that.

### The mesh-overlay recipe (use for salt drape, isosurfaces, anything draped)
```r
salt_h <- elmat + RAISE            # RAISE ~1.5-2 m so it isn't z-fighting the seabed
salt_h[is.na(value_matrix)] <- NA  # mesh only where data exists (NA triangles are dropped)
surf <- rayshader:::generate_surface(salt_h, ZSCALE)
m    <- rgl::tmesh3d(vertices = t(surf$verts), indices = surf$inds, homogeneous = FALSE)
# c(value_matrix) is column-major == surf vertex order, so per-vertex colours line up:
vcol <- PAL[1 + round(pmin(pmax((c(value_matrix)-SMIN)/(SMAX-SMIN),0),1)*255)]
rgl::shade3d(m, col = vcol, meshColor = "vertices", lit = FALSE, alpha = ALPHA,
             front = "fill", back = "fill", tag = "salt")   # tag -> pop3d() to swap per frame
```
For an opaque single-colour isosurface (oxycline) use `col="#d7301f"` instead of per-vertex.

## Facts proven during debugging (don't re-derive)
- `t(raster_to_matrix(r))` == `raster::as.matrix(r)` (true north-up) EXACTLY (max|diff|=0). So rtm is the
  transpose of north-up; but **plot_3d's own transpose cancels it**, so feeding rtm gives correct geography.
- Coordinate check: salt tif, DEM, mask all share identical geotransforms (EPSG:28350); a value tif's
  finite cells are 100% on DEM water — i.e. the DATA is aligned; only the render path misleads.
- `quad_test`: an add_overlay quadrant pattern maps `overlay[i,j] -> screen(i down, j right)`, but the
  MESH maps the same indices transposed → the mismatch.
- 2-D matplotlib (`scripts/verify_overlay_2d.py`, `imshow` of the raw north-up array) is the trustworthy
  ground-truth orientation. Use it to sanity-check any 3-D result.

## Camera
- Salt hero: `theta=0` (north-facing), `phi=45` (or 31.5 for a lower, more dramatic angle), `zoom=0.62`.
- The domain is long N–S, so a true north-facing view foreshortens it — expected.
- HQ path-trace (oxycline) needs the bbox-shift trick for `scene_elements` — see `docs/hq_pathtrace.md`.

## Debug tooling kept (in ../rayshader_salt, archive later)
`verify_overlay_2d.py`, `bathy_northup.py`, `landmarks.py` (named landmarks), `terrain_only.R`,
`test_mirror.R`, `map_corners.R`, `quad_test.R`, `salt_mesh.R` — the scripts that finally nailed it.
