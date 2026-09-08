"""V-transect stations vs the 6 OBC bias-correction polygons, over model bathymetry.
Plan-view map: model depth (cell_Zb) shaded + coastline + the 6 OBC polygon outlines
(labelled) + the V1-V12 cross-shelf transect. Shows which OBC polygon(s) the V-transect
samples (it runs W->E at lat ~-31.86, crossing poly-2/poly-3, just S of poly-1).
-> years/1991/outputs/diagnostics/vtransect_vs_obc_polygons.png
"""
import matplotlib; matplotlib.use('Agg')
import os, glob, numpy as np
import matplotlib.pyplot as plt
from matplotlib.tri import Triangulation
import geopandas as gpd
from pyproj import Transformer
import xarray as xr

SHP = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/climatology_assessment/diagnostics/biascorr_polygons'
MAP = r"Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/DAdamo/Nick D'Adamo Cockburn Sound/Archivals of SMCWS data from old DEP CDs of the 1990s/MARINE CD-3 from DEP-CTD data SGI IRIS Crimson/dadamo_usr2/map"
COAST = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/gis/AU_NESP-MaC-3-17_AIMS_Aus-Coastline-50k_2024_V1-1_simp.shp'
NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev_ITER8/csiem_B010_19910720_19910831_rev.nc'   # mesh geometry only
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/vtransect_vs_obc_polygons.png'
os.makedirs(os.path.dirname(OUT), exist_ok=True)

# --- V-transect station coords (EPSG:28350 .loc -> lon/lat) ---
tr = Transformer.from_crs('EPSG:28350', 'EPSG:4326', always_xy=True); C = {}
for f in glob.glob(os.path.join(MAP, '*.loc')):
    for ln in open(f, errors='replace'):
        p = ln.split()
        if len(p) < 3: continue
        nm = p[0].upper()
        if nm in C: continue
        try: e, n = float(p[1]), float(p[2])
        except ValueError: continue
        if n < 1e6: n += 6e6
        lo, la = tr.transform(e, n); C[nm] = (la, lo)
V = [s for s in sorted([f'V{i}' for i in range(1, 13)] + ['V1A'], key=lambda s: C.get(s, (0, 1e9))[1]) if s in C]

# --- model bathymetry ---
ds = xr.open_dataset(NC)
cx = ds['cell_X'].values; cy = ds['cell_Y'].values; depth = -ds['cell_Zb'].values
nv = ds['cell_node'].values if 'cell_node' in ds else None

fig, ax = plt.subplots(figsize=(12, 13))
tcf = ax.tricontourf(cx, cy, depth, levels=np.arange(0, 115, 5), cmap='Blues', extend='max', alpha=0.9)
cb = plt.colorbar(tcf, ax=ax, shrink=0.75, pad=0.02); cb.set_label('model depth (m)', fontsize=11)
ax.tricontour(cx, cy, depth, levels=[10, 20, 50, 100], colors='0.4', linewidths=0.5, alpha=0.6)

# coastline
try:
    coast = gpd.read_file(COAST, bbox=(114.8, -32.85, 115.85, -31.55))
    coast.plot(ax=ax, facecolor='#d9cba8', edgecolor='#7a5c3a', lw=0.6, zorder=3)
except Exception as e:
    print('coast skip:', e)

# --- OBC polygons ---
cols = plt.cm.tab10(np.linspace(0, 1, 10))
for i, p in enumerate(range(1, 7)):
    g = gpd.read_file(f'{SHP}/Polygons_{p}_MultiPolygon.shp').to_crs(4326)
    g.boundary.plot(ax=ax, color=cols[i], lw=2.4, zorder=5)
    c = g.geometry.iloc[0].representative_point()
    ax.text(c.x, c.y, f'OBC\npoly {p}', color=cols[i], fontweight='bold', fontsize=12, ha='center', va='center', zorder=6,
            bbox=dict(boxstyle='round,pad=0.2', fc='white', ec=cols[i], alpha=0.8))

# --- V-transect ---
vx = [C[s][1] for s in V]; vy = [C[s][0] for s in V]
ax.plot(vx, vy, '-', color='k', lw=1.6, zorder=7)
ax.plot(vx, vy, '^', color='yellow', markeredgecolor='k', markersize=9, zorder=8, label='V-transect station')
for s in V:
    la, lo = C[s]; ax.text(lo, la + 0.012, s, fontsize=7.5, ha='center', va='bottom', zorder=8, fontweight='bold')

ax.set_xlim(114.82, 115.82); ax.set_ylim(-32.82, -31.58)
ax.set_aspect(1/np.cos(np.radians(-32.2)))
ax.set_xlabel('Longitude', fontsize=11); ax.set_ylabel('Latitude', fontsize=11)
ax.legend(loc='lower right', fontsize=10)
ax.set_title('V-transect (V1–V12) vs the 6 OBC bias-correction polygons, over model bathymetry\n'
             'V-line runs W→E at lat −31.86: crosses poly-2 & poly-3, just south of poly-1', fontsize=12, fontweight='bold')
ax.grid(alpha=0.25)
fig.savefig(OUT, dpi=160, bbox_inches='tight'); print('wrote', OUT)
# quick which-poly-contains-which-V report
from shapely.geometry import Point
polys = {p: gpd.read_file(f'{SHP}/Polygons_{p}_MultiPolygon.shp').to_crs(4326).geometry.iloc[0] for p in range(1, 7)}
print('V station -> containing OBC polygon:')
for s in V:
    la, lo = C[s]; inside = [p for p, g in polys.items() if g.contains(Point(lo, la))]
    print(f'  {s} (lon {lo:.3f}): {("in poly "+",".join(map(str,inside))) if inside else "—"}')
