# Model-mesh overlay on terrain

Drape the TFV computational mesh (edges) over the rendered terrain to inspect channel resolution.
Full bathymetry/mesh-refinement analysis lives in **`../mesh_refinement/`** — this is just the rayshader
3-D overlay.

## Mesh source
`W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm`
27,456 nodes / 30,206 cells (23,358 E4Q quads + 6,848 E3T tris). ⚠ **Nodes are in EPSG:4326 lon/lat**
(not projected) — must warp to the DEM CRS (EPSG:28350) before use.

## Pipeline
```
python scripts/parse_mesh.py          # .2dm -> data/mesh_seg.csv (edges in plot_3d coords)
Rscript scripts/render_mesh_overlay.R # terrain + rgl::segments3d(faint) -> images/mesh_overlay*.png
```
(`parse_mesh.py` and `render_mesh_overlay.R` are also copied into ../mesh_refinement/scripts/.)

## Coordinate mapping (.2dm node → plot_3d frame)
node lon/lat → (warp) EPSG:28350 X,Y → DEM pixel `pcol=(X-Tc)/Ta, prow=(Y-Tf)/Te` → plot_3d:
`x = pcol-(W-1)/2`, `z = prow-(H-1)/2`, `y = DEM_elev/zscale (+raise)`  (W=419 E-W cols, H=847 N-S rows).
Clip edges to the DEM footprint. Draw with `rgl::segments3d(x,y,z, color="#222", alpha=0.28, lwd=0.4)`.
This shares the terrain mesh's frame so it aligns (same principle as the salt mesh overlay).
