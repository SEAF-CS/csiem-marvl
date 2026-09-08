# TUFLOW-FV cell bathymetry / depth specification

Summary of TUFLOW-FV bathy commands (manual: https://docs.tuflow.com/fv/manual/2026.0/HD2D-Bath-2.html,
section HD2D-Bath-SB-3). Used to set/overwrite cell depths **beyond the mesh itself**.

## Commands (applied in control-file order; later overwrites earlier)
| Command | Purpose |
|---|---|
| `Set Zpts == <z>` | Uniform elevation across the whole domain |
| `Read GRID Zpts == file.asc/.flt` | Interpolate elevations from a DEM grid (ESRI ASCII / binary float) |
| `Read TIN Zpts == file.tin` | Elevations from an SMS-format TIN |
| `Read GIS Z Line == lines.shp \| points.shp` | **3-D breaklines** — polyline+point layers; enforce narrow linear features (channels) with along-line varying heights, linearly interpolated |
| `Cell Elevation File == file.csv, Cell_ID` | **Direct cell-by-cell** assignment, keyed by Cell_ID (or coordinates) |
| `Global Bed Elevation Limits == min, max` | Min/max caps — **applied LAST regardless of position** |

Syntax examples:
```
Set Zpts == 10.0
Read GRID Zpts == ../model/geo/LiDAR_5m.asc
Read TIN Zpts == ../model/geo/Bathy_Survey.tin
Read GIS Z Line == ../model/gis/2d_zln_M03_002_L.shp | ../model/gis/2d_zln_M03_002_P.shp
Cell Elevation File == ../model/geo/elevations.csv, Cell_ID
Global Bed Elevation Limits == -100, 99999
```

## Key behaviours
- **Cell-based:** elevations interpolate to **cell centroids**, not mesh nodes.
- **Mesh-independent:** external DEM/TIN datasets update bathy **without regenerating the mesh**.
- **Breaklines** ("3-D breaklines", varying height) are the intended tool to force **narrow channels**
  the mesh would otherwise smooth — i.e. the "preferential channel" use case.
- **Polygon masking:** GIS polygons set a constant elevation for all cells within.
- Time-varying bathy is possible via hydraulic-structure commands.

## Application to our channel (next step)
The transect/cross-section analysis (`docs/channel_transect_method.md`) shows the entrance channel is
~2–3 m too shallow in `cell_Zb`. Two fixes:
- **`Cell Elevation File`** — emit a CSV of `Cell_ID, elevation` for the channel-corridor cells, with
  elevation = DEM-derived depth inside each cell (deepest-in-cell preserves the connecting depth; mean is
  gentler). Need each cell's Cell_ID — the NC cell order matches the `.2dm` element order
  (`cross_sections.py` already finds the containing cell per point via TriFinder; map that to Cell_ID).
- **`Read GIS Z Line`** — write the locked thalweg polyline (+ vertices) as a shapefile with DEM depths;
  TUFLOW-FV burns the preferential channel along it.

DECISION PENDING (from user): corridor width, and deepest-in-cell vs mean rule.
