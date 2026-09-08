"""V-transect vs OBC polygons (map)  +  OBC forcing time series (T top, S bottom).
LEFT: model bathy + 6 OBC polygons + V1-V12 (as vtransect_vs_obc_polygons).
RIGHT: from the OBC NC the 1991 model currently uses (ROMS ..._S6corr_T1S1corr.nc),
surface T (top) and S (bottom) averaged in EACH OBC polygon, sim-start (20 Jul) -> 25 Aug,
one coloured line per polygon (colours match the map). Overlaid: V-station FIELD surface
T/S (jday 226=14 Aug, 233=21 Aug), each V symbol coloured to the polygon it aligns with
by DISTANCE FROM COAST.
-> years/1991/outputs/diagnostics/vtransect_obc_forcing_ts.png
"""
import matplotlib; matplotlib.use('Agg')
import os, glob, csv, numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.gridspec import GridSpec
from datetime import datetime, timedelta
import geopandas as gpd
from shapely.geometry import Point
from pyproj import Transformer
import xarray as xr, pandas as pd

SHP = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/climatology_assessment/diagnostics/biascorr_polygons'
MAP = r"Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/DAdamo/Nick D'Adamo Cockburn Sound/Archivals of SMCWS data from old DEP CDs of the 1990s/MARINE CD-3 from DEP-CTD data SGI IRIS Crimson/dadamo_usr2/map"
COAST = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/gis/AU_NESP-MaC-3-17_AIMS_Aus-Coastline-50k_2024_V1-1_simp.shp'
MESH = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev_ITER8/csiem_B010_19910720_19910831_rev.nc'
OBCNC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'  # placeholder, replaced below
FORCE = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/CLIMATOLOGY/ROMS_UTC+8_19901001_19911231_climatology_S6corr_T1S1corr.nc'
SM = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991'
PROFILE_BASE = f'{SM}/1991-08/profile_data'; SURVEY_LOG = f'{SM}/survey_log_1991.csv'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/vtransect_obc_forcing_ts.png'
os.makedirs(os.path.dirname(OUT), exist_ok=True)
T0, T1 = pd.Timestamp('1991-07-20'), pd.Timestamp('1991-08-25')
COLS = plt.cm.tab10(np.linspace(0, 1, 10))   # poly p -> COLS[p-1]
READ_MAX = 320.0
# bc adjustment from the OBC .fvc applied to every nodestring (no 'bc scale' -> scale=1):
#   bc offset == 0.0, 0.0, 0.0, 0.10, 0.50   (SSH, U, V, SALINITY, TEMPERATURE)
T_OFF, S_OFF = 0.50, 0.10   # what the model actually applies at the boundary = NC + offset

# ---- V coords ----
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

# ---- polygons + coast (metric) for distance-from-coast assignment ----
polys = {p: gpd.read_file(f'{SHP}/Polygons_{p}_MultiPolygon.shp').to_crs(4326).geometry.iloc[0] for p in range(1, 7)}
coast_g = gpd.read_file(COAST, bbox=(114.8, -32.85, 115.85, -31.55)).to_crs(28350)
coast_u = coast_g.boundary.unary_union
to_m = Transformer.from_crs(4326, 28350, always_xy=True)
def dcoast(lon, lat):
    x, y = to_m.transform(lon, lat); return Point(x, y).distance(coast_u)
poly_dc = {p: dcoast(g.representative_point().x, g.representative_point().y) for p, g in polys.items()}
def assign_poly(lon, lat):                      # nearest polygon by distance-from-coast
    d = dcoast(lon, lat); return min(poly_dc, key=lambda p: abs(poly_dc[p] - d))
Vpoly = {s: assign_poly(C[s][1], C[s][0]) for s in V}

# ---- OBC forcing: surface T/S per polygon over the window ----
fr = xr.open_dataset(FORCE); ft = pd.to_datetime(fr['time'].values)
w = (ft >= T0) & (ft <= T1); tw = ft[w]
LON, LAT = np.meshgrid(fr['lon'].values, fr['lat'].values)
Tsurf = fr['water_temp'].isel(depth=0).values[w]   # (time, lat, lon)
Ssurf = fr['salinity'].isel(depth=0).values[w]
force = {}
for p, g in polys.items():
    mask = np.array([[g.contains(Point(LON[j, k], LAT[j, k])) for k in range(LON.shape[1])] for j in range(LON.shape[0])])
    jj, kk = np.where(mask)
    force[p] = (np.array([np.nanmean(Tsurf[i][jj, kk]) for i in range(len(tw))]) + T_OFF,   # + bc offset (as applied)
                np.array([np.nanmean(Ssurf[i][jj, kk]) for i in range(len(tw))]) + S_OFF)

# ---- V field surface T/S (jday 226/233) ----
def read_sdl(fn):
    d = open(fn, 'rb').read()
    if len(d) < 0x420: return None
    fl = np.frombuffer(d, '>f4', count=(len(d)-0x400)//4, offset=0x400); nz = np.nonzero(fl)[0]
    for i0 in [int(i) for i in nz[:6]]:
        rem = len(fl)-i0
        for nc, (cd, cs, cr, ct) in ((10, (4, 2, 3, 5)), (7, (3, 1, 2, 4))):
            if rem % nc or rem//nc < 2: continue
            rec = fl[i0:].reshape(rem//nc, nc); s = rec[:, 0].astype(float)
            if not (np.all(np.diff(s) >= 1) and s[0] >= 1 and np.all(np.abs(s-np.round(s)) < 1e-3)): continue
            if not (0 < np.median(rec[:, cd]) < 300 and 5 < np.median(rec[:, ct]) < 30): continue
            return rec[:, cd], rec[:, cs], rec[:, ct]
    return None
def surf_TS(stn, fn):
    fp = os.path.join(PROFILE_BASE, stn, fn)
    if not os.path.exists(fp): return None
    out = read_sdl(fp)
    if out is None: return None
    dep, sal, tmp = out
    g = (dep > 0.05) & (dep < READ_MAX) & (sal > 20) & (sal < 40) & (tmp > 5) & (tmp < 30)
    if g.sum() < 2: return None
    top = dep[g] <= max(2.0, dep[g].min() + 1.5)
    return float(np.mean(tmp[g][top])), float(np.mean(sal[g][top]))
Vobs = []   # (dt, station, T, S, poly)
for r in csv.DictReader(open(SURVEY_LOG)):
    if r['month'] != '1991-08' or r['station'].upper() not in V: continue
    st = surf_TS(r['station'].upper(), r['fv_file'])
    if st is None: continue
    dt = datetime(1991, 1, 1) + timedelta(days=int(r['jday'])-1, hours=int(r['time'][:2]), minutes=int(r['time'][2:]))
    Vobs.append((dt, r['station'].upper(), st[0], st[1], Vpoly[r['station'].upper()]))
print(f'V field casts read: {len(Vobs)}')

# ============================ FIGURE ============================
mds = xr.open_dataset(MESH); cx = mds['cell_X'].values; cy = mds['cell_Y'].values; depth = -mds['cell_Zb'].values
fig = plt.figure(figsize=(23, 13))
gs = GridSpec(2, 2, width_ratios=[1.0, 1.25], wspace=0.13, hspace=0.16, left=0.04, right=0.99, top=0.93, bottom=0.06)
axm = fig.add_subplot(gs[:, 0]); axT = fig.add_subplot(gs[0, 1]); axS = fig.add_subplot(gs[1, 1])

# --- map ---
axm.tricontourf(cx, cy, depth, levels=np.arange(0, 115, 5), cmap='Blues', extend='max', alpha=0.9)
try: gpd.read_file(COAST, bbox=(114.8, -32.85, 115.85, -31.55)).plot(ax=axm, facecolor='#d9cba8', edgecolor='#7a5c3a', lw=0.6, zorder=3)
except Exception: pass
for p, g in polys.items():
    gpd.GeoSeries([g.boundary]).plot(ax=axm, color=COLS[p-1], lw=2.4, zorder=5)
    c = g.representative_point(); axm.text(c.x, c.y, f'poly {p}', color=COLS[p-1], fontweight='bold', fontsize=11, ha='center',
                                           bbox=dict(boxstyle='round,pad=0.2', fc='white', ec=COLS[p-1], alpha=0.85), zorder=6)
axm.plot([C[s][1] for s in V], [C[s][0] for s in V], '-k', lw=1.4, zorder=6)
for s in V:
    la, lo = C[s]; axm.plot(lo, la, '^', color=COLS[Vpoly[s]-1], markeredgecolor='k', ms=11, zorder=8)
    axm.text(lo, la + 0.013, s, fontsize=7.5, ha='center', fontweight='bold', zorder=8)
axm.set_xlim(114.82, 115.82); axm.set_ylim(-32.82, -31.58); axm.set_aspect(1/np.cos(np.radians(-32.2)))
axm.set_xlabel('Longitude'); axm.set_ylabel('Latitude'); axm.grid(alpha=0.25)
axm.set_title('V-transect vs OBC polygons (V symbol colour = nearest polygon by distance from coast)', fontsize=11, fontweight='bold')

# --- forcing time series ---
for p in range(1, 7):
    axT.plot(tw, force[p][0], '-', color=COLS[p-1], lw=2, label=f'poly {p}')
    axS.plot(tw, force[p][1], '-', color=COLS[p-1], lw=2, label=f'poly {p}')
for ax, idx, lbl in [(axT, 2, 'Temperature (°C)'), (axS, 3, 'Salinity (psu)')]:
    for dt, st, T, S, pp in Vobs:
        ax.plot(dt, (T if idx == 2 else S), '^', color=COLS[pp-1], markeredgecolor='k', ms=9, zorder=6)
    ax.set_ylabel(lbl, fontsize=11); ax.grid(alpha=0.3); ax.set_xlim(T0, T1)
    ax.axvline(datetime(1991, 8, 19), color='0.5', ls=':', lw=1)
axT.set_title('OBC forcing surface T/S per polygon AS APPLIED (NC + bc offset T+0.5°C, S+0.10 psu) + V-station field casts (▲)  — 20 Jul → 25 Aug 1991',
              fontsize=11, fontweight='bold')
axT.legend(fontsize=8, ncol=6, loc='upper center'); axS.xaxis.set_major_formatter(mdates.DateFormatter('%d %b'))
axS.set_xlabel('1991')
fig.savefig(OUT, dpi=150, bbox_inches='tight'); print('wrote', OUT)
print('V -> polygon (by distance from coast):', {s: Vpoly[s] for s in V})
