"""Halocline [9] PROTOTYPE — flat plan-view map of halocline HEIGHT above the seabed (m), 20 Aug 1991.
Side-by-side: (LEFT) the original approach (1 m-binned salinity, "first depth above surface+0.02 psu",
griddata-linear) vs (RIGHT) an improved approach addressing the two issues flagged:
  - DETECTION: halocline depth = depth of MAX density(σt) gradient on a 0.25 m-binned, smoothed profile,
    with a mixed-water threshold (no spurious near-surface trigger; σt not S; finer).
  - INTERPOLATION: smooth RBF (thin-plate) with a distance mask (no triangulation facets / hull spill).
Field-only here (the validation version adds a model column the same way). -> outputs/halocline_prototype.png
"""
import os, sys, csv, struct, numpy as np, pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.interpolate import griddata, RBFInterpolator
from scipy.ndimage import uniform_filter1d
import rasterio
from rasterio.windows import from_bounds
from pyproj import Transformer

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'lib')))
from eos80 import eos80_potential_density

SURVEY_LOG = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/survey_log_1991.csv'
PROFILE_BASE = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
INV = os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'data', 'region_profiles_inventory.csv'))
BATHY_TIF = r'X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif'
OUT = os.path.join(HERE, '..', 'outputs', 'halocline_prototype.png')
TARGET, T0, T1 = '1991-08-20', 824, 1415
LATMIN, LATMAX, LONMIN, LONMAX = -32.28, -32.04, 115.60, 115.80


def read_dfv(fp):                       # depth, S, T (raw, unbinned)
    with open(fp, 'rb') as f: data = f.read()
    off = data.find(b'EPA')
    if off == 0x18:   nc = struct.unpack('>H', data[0x136:0x138])[0]; nr = struct.unpack('>i', data[0x13c:0x140])[0]; d0 = 0x528
    elif off == 0x14: nc = struct.unpack('>H', data[0x132:0x134])[0]; nr = struct.unpack('>i', data[0x138:0x13c])[0]; d0 = 0x49C
    else: return None
    if nc < 4 or nr < 10 or d0 + nr * nc * 4 > len(data): return None
    r = np.frombuffer(data, dtype='>f4', count=nr * nc, offset=d0).reshape(nr, nc)
    depth, sal, temp = r[:, 2].copy(), r[:, 0].copy(), r[:, 3].copy()
    im = np.argmax(depth)
    if im > 10: depth, sal, temp = depth[:im+1], sal[:im+1], temp[:im+1]
    g = (depth > 0.1) & (depth < 50) & (sal > 20) & (sal < 40) & (temp > 5) & (temp < 30)
    if g.sum() < 5: return None
    o = np.argsort(depth[g])
    return depth[g][o], sal[g][o], temp[g][o]


def _bin(depth, val, dz):
    e = np.arange(0, depth.max() + dz, dz); idx = np.digitize(depth, e) - 1
    zb, vb = [], []
    for bi in range(len(e) - 1):
        m = idx == bi
        if m.any(): zb.append(depth[m].mean()); vb.append(val[m].mean())
    return np.array(zb), np.array(vb)


def halo_original(depth, sal, profmax):
    zb, sb = _bin(depth, sal, 1.0)
    if len(zb) < 3: return np.nan
    s0 = sb[:min(3, len(sb))].mean(); sN = sb[-min(3, len(sb)):].mean()
    if abs(sN - s0) < 0.03: return 0.0
    for d, s in zip(zb, sb):
        if s > s0 + 0.02: return max(0.0, profmax - d)
    return 0.0


DSIG_MIN = 0.10   # min top->bottom sigma_t change to call a profile stratified (tunable)
def halo_improved(depth, sigt, profmax, dbg=None):
    """Interface = depth where sigma_t first reaches the MIDPOINT between surface and bottom values
    (robust on weak/gradual gradients, unlike argmax-gradient). Returns height of that interface
    above the seabed (m); 0 if the profile is effectively mixed (total dsigma_t < DSIG_MIN)."""
    zb, sg = _bin(depth, sigt, 0.25)
    if len(zb) < 4: return np.nan
    sg = uniform_filter1d(sg, 3)                       # gentle smooth
    s_top = float(sg[:3].mean()); s_bot = float(sg[-3:].mean()); dsig = s_bot - s_top
    if dsig < DSIG_MIN:
        if dbg is not None: dbg.update(dsig=dsig, hd=np.nan)
        return 0.0
    s_mid = s_top + 0.5 * dsig
    cross = np.where((zb >= 1.0) & (sg >= s_mid))[0]   # first midpoint crossing below 1 m
    if len(cross) == 0:
        if dbg is not None: dbg.update(dsig=dsig, hd=np.nan)
        return 0.0
    hd = float(zb[cross[0]])
    if dbg is not None: dbg.update(dsig=dsig, hd=hd)
    return max(0.0, profmax - hd)


# ---- collect 20-Aug window casts (one per station) + coords from inventory ----
inv = pd.read_csv(INV); inv = inv[(inv.date == TARGET)]
inv = inv[(inv.time.astype(int) >= T0) & (inv.time.astype(int) <= T1)]
coords = inv.groupby('station')[['lon', 'lat']].first().to_dict('index')
log = []
with open(SURVEY_LOG) as f:
    for row in csv.DictReader(f):
        if row['date'] != TARGET or row['data_type'] != 'DFV+FV': continue
        t = int(row['time'])
        if T0 <= t <= T1: log.append({'stn': row['station'], 'time': row['time'].zfill(4), 'jday': int(row['jday']), 't': t})
tmid = (T0 + T1) / 2; best = {}
for c in log:
    if c['stn'] not in best or abs(c['t'] - tmid) < best[c['stn']][1]: best[c['stn']] = (c, abs(c['t'] - tmid))

rows = []
for c, _ in best.values():
    stn = c['stn']
    if stn not in coords: continue
    p = os.path.join(PROFILE_BASE, stn, f"dfv{c['time']}.{c['jday']}")
    if not os.path.exists(p): continue
    prof = read_dfv(p)
    if prof is None: continue
    depth, S, T = prof; sigt = eos80_potential_density(S, T) - 1000.0; pmax = float(depth.max())
    dbg = {}; impr = halo_improved(depth, sigt, pmax, dbg)
    rows.append(dict(stn=stn, lon=coords[stn]['lon'], lat=coords[stn]['lat'], pmax=pmax,
                     orig=halo_original(depth, S, pmax), impr=impr,
                     dsig=dbg.get('dsig', np.nan), hd=dbg.get('hd', np.nan)))
df = pd.DataFrame(rows).dropna(subset=['lon', 'lat'])
print(f'{len(df)} stations | height orig {df.orig.min():.1f}-{df.orig.max():.1f}  impr {df.impr.min():.1f}-{df.impr.max():.1f}')
print('per-station (pmax=profile depth, dsig=top->bottom sigma_t, hd=interface depth):')
print(df.sort_values('lat', ascending=False)[['stn', 'pmax', 'dsig', 'hd', 'orig', 'impr']].round(2).to_string(index=False))

# ---- bathy window (background + land mask) ----
tf78 = Transformer.from_crs('EPSG:4326', 'EPSG:7850', always_xy=True)
x0, y0 = tf78.transform(LONMIN, LATMIN); x1, y1 = tf78.transform(LONMAX, LATMAX)
with rasterio.open(BATHY_TIF) as src:
    w = from_bounds(min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1), src.transform)
    bathy = src.read(1, window=w).astype(float); bathy[bathy == src.nodata] = np.nan; wt = src.window_transform(w)
nr, ncb = bathy.shape
tf47 = Transformer.from_crs('EPSG:7850', 'EPSG:4326', always_xy=True)
blon = np.array([tf47.transform((wt * (c, 0))[0], (y0 + y1) / 2)[0] for c in range(ncb)])
blat = np.array([tf47.transform((x0 + x1) / 2, (wt * (0, r))[1])[1] for r in range(nr)])
BLON, BLAT = np.meshgrid(blon, blat)

# ---- grids + two interpolation approaches ----
GLON, GLAT = np.meshgrid(np.linspace(LONMIN, LONMAX, 300), np.linspace(LATMIN, LATMAX, 300))
CL = np.cos(np.radians(-32.15))
def kmdist(lo, la, lo0, la0): return np.hypot((lo - lo0) * CL * 111.32, (la - la0) * 110.57)
# land mask on the halo grid (nearest bathy elevation)
from scipy.interpolate import NearestNDInterpolator
land_on_grid = NearestNDInterpolator(np.c_[BLON.ravel(), BLAT.ravel()], bathy.ravel())(GLON, GLAT) > 0
# distance-to-nearest-station mask
dmin = np.full(GLON.shape, 1e9)
for _, r in df.iterrows(): dmin = np.minimum(dmin, kmdist(GLON, GLAT, r.lon, r.lat))
far = dmin > 2.5   # km

ORIG = griddata((df.lon, df.lat), df.orig, (GLON, GLAT), method='linear')
ORIG[land_on_grid] = np.nan
P = np.c_[df.lon * CL, df.lat]
rbf = RBFInterpolator(P, df.impr.values, kernel='thin_plate_spline', smoothing=0.5)
IMPR = rbf(np.c_[GLON.ravel() * CL, GLAT.ravel()]).reshape(GLON.shape)
IMPR = np.clip(IMPR, 0, None); IMPR[land_on_grid | far] = np.nan

# ---- plot ----
levels = np.arange(0, 9, 1); cmap = plt.cm.YlOrRd; norm = BoundaryNorm(levels, cmap.N, clip=True)
fig, axes = plt.subplots(1, 2, figsize=(20, 13), sharey=True)
for ax, (G, ttl, col) in zip(axes, [(ORIG, 'ORIGINAL\nsalinity surface+0.02 onset · griddata-linear', 'orig'),
                                     (IMPR, 'IMPROVED\nmidpoint-crossing σt interface · RBF + distance mask', 'impr')]):
    ax.contourf(BLON, BLAT, -bathy, levels=np.arange(-2, 26, 1), cmap='Blues', alpha=0.25)
    ax.contourf(BLON, BLAT, np.where(bathy > 0, 1.0, np.nan), levels=[0.5, 1.5], colors=['#c8b896'], alpha=0.85)
    ax.contour(BLON, BLAT, -bathy, levels=[15], colors='dimgrey', linewidths=1.0, linestyles='--')
    cf = ax.contourf(GLON, GLAT, G, levels=levels, cmap=cmap, norm=norm, extend='max', alpha=0.75)
    cs = ax.contour(GLON, GLAT, G, levels=levels, colors='k', linewidths=0.7); ax.clabel(cs, inline=True, fontsize=8, fmt='%g')
    for _, r in df.iterrows():
        ax.plot(r.lon, r.lat, 'ko', ms=3, zorder=10)
        ax.annotate(f'{r[col]:.0f}', (r.lon, r.lat), textcoords='offset points', xytext=(3, 2), fontsize=6, zorder=11)
    ax.set_xlim(LONMIN, LONMAX); ax.set_ylim(LATMIN, LATMAX); ax.set_aspect(1 / CL); ax.grid(alpha=0.25)
    ax.set_title(ttl, fontsize=11, fontweight='bold'); ax.set_xlabel('Longitude')
axes[0].set_ylabel('Latitude')
fig.colorbar(cf, ax=axes, orientation='horizontal', pad=0.05, aspect=40, shrink=0.5,
             label='Halocline height above seabed (m)')
fig.suptitle('Halocline height above seabed — 20 Aug 1991 (0824–1415) — SMCWS field — PROTOTYPE: original vs improved',
             fontsize=14, fontweight='bold', y=0.97)
fig.savefig(OUT, dpi=140, bbox_inches='tight'); print('wrote', os.path.abspath(OUT))
