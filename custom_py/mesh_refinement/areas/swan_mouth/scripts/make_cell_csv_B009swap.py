"""swan_mouth area: restore B009 (1.5.0) cell bathymetry at the tidally-choked Fremantle mouth,
cell-for-cell (NO DEM). Same 30206-cell mesh in B009 & B010, so we swap B009 cell_Zb into the
B010 run via a TUFLOW-FV Cell Elevation File. Cell_ID = .2dm element ID (matched to NC cells by
centroid, per the success_channel workflow). Writes outputs/cell_elevation_swan_mouth.csv + check fig.
"""
import numpy as np, netCDF4 as nc, csv, os
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from scipy.spatial import cKDTree

MESH = r'S:/Matt_Working/csiem/model_components/gis_repo/1_domain/mesh/csiem_mesh_B010_opt.2dm'
NC_B010 = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev.nc'
NC_B009 = r'G:/CSIEM/1.5.0/BGrid/csiem_B009_20221101_20240401_WQ.nc'
OUTCSV = r'G:/CSIEM/1.8.0/csiem-marvl/mesh_refinement/areas/swan_mouth/outputs/cell_elevation_swan_mouth.csv'
OUTFIG = r'G:/CSIEM/1.8.0/csiem-marvl/mesh_refinement/areas/swan_mouth/outputs/swan_mouth_before_after.png'
# AOI: Blackwall throat / neck into Melville only - restricted to EAST of 115.752 and NORTH of -32.035
# (excludes the outer dredged entrance channel to the SW, which B010 already deepens correctly)
AOI = dict(lon0=115.752, lon1=115.815, lat0=-32.035, lat1=-31.985)
DZ_MIN = 0.10          # only write cells whose B009 value differs from B010 by > this

# --- parse .2dm: nodes + elements (Cell_ID = element id) ---
nodes = {}; eid = []; econ = []
with open(MESH) as f:
    for line in f:
        t = line.split()
        if not t: continue
        if t[0] == 'ND': nodes[int(t[1])] = (float(t[2]), float(t[3]))   # lon, lat
        elif t[0] == 'E3T': eid.append(int(t[1])); econ.append([int(t[2]), int(t[3]), int(t[4])])
        elif t[0] == 'E4Q': eid.append(int(t[1])); econ.append([int(t[2]), int(t[3]), int(t[4]), int(t[5])])
eid = np.array(eid)
nlon = {k: v[0] for k, v in nodes.items()}; nlat = {k: v[1] for k, v in nodes.items()}
cenx = np.array([np.mean([nlon[n] for n in e]) for e in econ])
ceny = np.array([np.mean([nlat[n] for n in e]) for e in econ])
polys = [np.array([[nlon[n], nlat[n]] for n in e]) for e in econ]
print(f'.2dm: {len(eid)} elements')

# --- NC cell_Zb (same mesh/order in both) ---
d10 = nc.Dataset(NC_B010); cx = np.asarray(d10.variables['cell_X'][:]); cy = np.asarray(d10.variables['cell_Y'][:])
za = np.asarray(d10.variables['cell_Zb'][:]); za = za if za.ndim == 1 else za[0]
d09 = nc.Dataset(NC_B009); zb = np.asarray(d09.variables['cell_Zb'][:]); zb = zb if zb.ndim == 1 else zb[0]

# --- map each element -> nearest NC cell (cos-lat scaled) ---
sc = np.cos(np.radians(cy.mean()))
_, civ = cKDTree(np.c_[cx * sc, cy]).query(np.c_[cenx * sc, ceny])
za_el = za[civ]; zb_el = zb[civ]                      # B010 (old) & B009 (new) per element
mmatch = np.hypot((cx[civ] - cenx) * sc, cy[civ] - ceny) * 111000
print(f'element->cell match: median {np.median(mmatch):.1f} m, max {mmatch.max():.1f} m')

# --- select AOI cells that actually change ---
inaoi = (cenx >= AOI['lon0']) & (cenx <= AOI['lon1']) & (ceny >= AOI['lat0']) & (ceny <= AOI['lat1'])
sel = inaoi & (np.abs(za_el - zb_el) > DZ_MIN)
# do NOT let the swap create a new sill: south of -32.03, keep B010 where B009 is SHALLOWER (higher Zb)
keep_b010 = sel & (ceny < -32.03) & (zb_el > za_el)
sel = sel & ~keep_b010
print(f'retained B010 (avoid new sill, S of -32.03 & B009 shallower): {int(keep_b010.sum())} cells')
print(f'AOI elements: {inaoi.sum()} | changing (>{DZ_MIN} m): {sel.sum()}')
dz = zb_el[sel] - za_el[sel]
print(f'  swap B009<-: deepened {int((dz<0).sum())} cells, shallowed {int((dz>0).sum())} | mean dz {dz.mean():+.2f} m, range {dz.min():+.2f}..{dz.max():+.2f}')
print(f'  emergent barriers removed (B010>-1 -> B009<-1): {int(((za_el[sel]>-1)&(zb_el[sel]<-1)).sum())}')

# --- write CSV (Cell_ID, Z=B009, old_cell_Zb=B010, lon, lat) ---
with open(OUTCSV, 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['Cell_ID', 'Z', 'old_cell_Zb', 'lon', 'lat'])
    for i in np.where(sel)[0]:
        w.writerow([int(eid[i]), round(float(zb_el[i]), 3), round(float(za_el[i]), 3), round(float(cenx[i]), 6), round(float(ceny[i]), 6)])
print('wrote', OUTCSV, '(', int(sel.sum()), 'rows )')

# --- before/after check figure ---
fig, axes = plt.subplots(1, 2, figsize=(18, 8), sharex=True, sharey=True)
box = inaoi
z_eff = za_el.copy(); z_eff[sel] = zb_el[sel]        # effective post-override (retained cells keep B010)
for ax, z_el, ttl in [(axes[0], za_el, 'BEFORE (B010 current)'), (axes[1], z_eff, 'AFTER (effective override)')]:
    pc = PolyCollection([polys[i] for i in np.where(box)[0]], array=z_el[box], cmap='RdYlBu', edgecolors='k', linewidths=0.15)
    pc.set_clim(-16, 2); ax.add_collection(pc)
    # outline changed cells
    ch = PolyCollection([polys[i] for i in np.where(sel)[0]], facecolors='none', edgecolors='lime', linewidths=0.6); ax.add_collection(ch)
    ax.set_xlim(AOI['lon0'], AOI['lon1']); ax.set_ylim(AOI['lat0'], AOI['lat1']); ax.set_aspect('equal'); ax.set_title(ttl)
fig.colorbar(pc, ax=axes, fraction=0.02, pad=0.01).set_label('cell_Zb (m)  [red=deep, blue=shallow/land]')
fig.suptitle(f'swan_mouth Cell Elevation override: B009 swap ({int(sel.sum())} cells, lime outline)', fontweight='bold')
fig.savefig(OUTFIG, dpi=135, bbox_inches='tight'); print('wrote', OUTFIG)
