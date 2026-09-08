# Channel thalweg transect + cross-section method

How the entrance-channel comparison figures are built. All in **projected CRS (EPSG:28350)** — never in
DEM pixel space (an early bug: a window crossing the DEM's west edge gave a NEGATIVE pixel offset that
shifted the mesh overlay and the sampling — always clip the read window to `[0, W]/[0, H]`).

## 1. Crop + thalweg endpoints (`transect_compare2.py`)
- AOI lat −32.05..−32.2, lon 115.62..115.78 → CRS → **clipped** pixel window.
- Trace the deep line: per row, `argmin` DEM within a central column band (rough thalweg).
- Fit a **straight line** through it: PCA (`svd`) of the traced points → principal axis → endpoints
  = projection min/max. Then **nudge** the ends to sit on the chosen channel branch.
- Endpoints are env-tunable: `NW` = north end metres WEST, `SE` = south end metres EAST (negative =
  opposite). **Locked: `NW=1140, SE=1050`** (mean DEM depth along line −16.6 m, stays −14.7..−20.4 the
  whole way = fully in-channel). Print `MEANDEM` to tune (deeper mean = better on thalweg).

## 2. Sampling
- **DEM (truth):** `ds.sample(zip(X,Y))` at CRS points — robust, no pixel maths.
- **Model `cell_Zb`:** transect pts → lon/lat → nearest cell (cKDTree on cell_X/Y) for the line profile.
- **Maps:** DEM via `imshow(extent=[Xl,Xr,Ybot,Ytop], origin="upper")`; model via `PolyCollection` of
  mesh element polygons (CRS) coloured by `cell_Zb` (matched to elements by nearest centroid). Same
  turbo scale (−20..−5) and extent so the two depth fields compare directly.

## 3. Cross-sections (`cross_sections.py`)
- 10 sections perpendicular to the thalweg axis (`perp = [-u_y, u_x]`), at fractional positions 0.06..0.94.
- Each ±`HALF` m (700) across-channel, `M`=241 pts.
- **Model stepped profile = true point-in-cell:** triangulate the mesh (split quads into 2 tris, each
  inheriting its element's `cell_Zb`), build `matplotlib.tri.Triangulation` + `get_trifinder()`; for each
  section point the finder returns the containing triangle → its `cell_Zb`. Plot with `drawstyle="steps-mid"`
  so the steps land at real cell edges. DEM overlaid smooth. Fixed y-range (−22..−2) for cross-comparison.

## Reading the result
The model holds one `cell_Zb` across each cell's width (flat) and jumps at cell boundaries. Where the
channel is a sharp narrow notch the steps under-cut the deepest point (model too shallow); where broad
(entrance) they track the DEM. This is the quantitative basis for the cell-elevation override.
