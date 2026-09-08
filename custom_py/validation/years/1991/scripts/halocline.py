"""Halocline [9] — plan-view map of halocline HEIGHT above the seabed (m), 20 Aug 1991, MODEL vs FIELD.
Interface = depth where sigma_t first reaches the MIDPOINT between surface & bottom values (robust on
weak/gradual gradients); height = profile_bottom - interface_depth; 0 if effectively mixed
(top->bottom dsigma_t < DSIG_MIN). Interpolation = thin-plate RBF with land + distance-to-station masks.
Model column extracts the same detector from `fv.get_profile` at each station's cast time.
Finished from halocline_prototype.py (which compared detection/interp methods, field-only).
-> outputs/halocline_1991_rev.png
"""
import os, sys, csv, struct, numpy as np, pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.interpolate import griddata, NearestNDInterpolator
from scipy.ndimage import uniform_filter1d
import tfv.xarray, xarray as xr
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'lib')))
from eos80 import eos80_potential_density
from point_overrides import adjust_point

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
RUNLABEL = '1991 rev'
SURVEY_LOG = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/survey_log_1991.csv'
PROFILE_BASE = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
INV = os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'data', 'region_profiles_inventory.csv'))
BATHY_TIF = r'X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif'
OUT = os.path.join(HERE, '..', 'outputs', 'halocline_1991_rev.png')
TARGET, T0, T1 = '1991-08-20', 824, 1415
LATMIN, LATMAX, LONMIN, LONMAX = -32.28, -32.04, 115.60, 115.80
DSIG_MIN = 0.04     # min top->bottom sigma_t change to call a profile stratified (lowered from 0.10)
SURF_GUARD = 1.5    # interface must be deeper than this (m) — avoids near-surface spikes


def read_dfv(fp):
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
    o = np.argsort(depth[g]); return depth[g][o], sal[g][o], temp[g][o]


def _bin(depth, val, dz):
    e = np.arange(0, depth.max() + dz, dz); idx = np.digitize(depth, e) - 1
    zb, vb = [], []
    for bi in range(len(e) - 1):
        m = idx == bi
        if m.any(): zb.append(depth[m].mean()); vb.append(val[m].mean())
    return np.array(zb), np.array(vb)


def halo_height(depth, sigt, profmax):
    """Height (m) of the halocline above the seabed = profmax - interface depth.
    Interface = depth (below SURF_GUARD) where smoothed sigma_t first reaches the MIDPOINT between
    surface and bottom values (robust on gradual gradients). 0 if effectively mixed
    (top->bottom dsigma_t < DSIG_MIN); NaN if profile too short."""
    zb, sg = _bin(depth, sigt, 0.25)
    if len(zb) < 5: return np.nan
    sgs = uniform_filter1d(sg, 3)
    top = sgs[zb <= 1.5]; bot = sgs[zb >= zb.max() - 1.5]
    s_top = float(top.mean() if top.size else sgs[0]); s_bot = float(bot.mean() if bot.size else sgs[-1])
    dsig = s_bot - s_top
    if dsig < DSIG_MIN: return 0.0                                 # mixed
    cross = np.where((zb >= SURF_GUARD) & (sgs >= s_top + 0.5 * dsig))[0]
    return max(0.0, profmax - float(zb[cross[0]])) if len(cross) else 0.0


# ---- 20-Aug window casts (one per station, nearest to window mid) + inventory coords ----
inv = pd.read_csv(INV); inv = inv[(inv.date == TARGET) & (inv.time.astype(int) >= T0) & (inv.time.astype(int) <= T1)]
coords = inv.groupby('station')[['lon', 'lat']].first().to_dict('index')
log = []
with open(SURVEY_LOG) as f:
    for row in csv.DictReader(f):
        if row['date'] == TARGET and row['data_type'] == 'DFV+FV' and T0 <= int(row['time']) <= T1:
            log.append({'stn': row['station'], 'time': row['time'].zfill(4), 'jday': int(row['jday']), 't': int(row['time'])})
tmid = (T0 + T1) / 2; best = {}
for c in log:
    if c['stn'] not in best or abs(c['t'] - tmid) < best[c['stn']][1]: best[c['stn']] = (c, abs(c['t'] - tmid))

# ---- model setup ----
ds = xr.open_dataset(NC); fv = ds.tfv; mt = pd.to_datetime(ds['Time'].values)
def model_halo(lon, lat, when):
    md = mt[int(np.argmin(np.abs(mt - when)))]
    try:
        p = fv.get_profile((lon, lat), variables=['SAL', 'TEMP'], time=md)
        pt = p.sel(Time=md, method='nearest') if 'Time' in p.dims else p
        z = -np.asarray(pt['Z']).ravel(); S = np.asarray(pt['SAL']).ravel(); T = np.asarray(pt['TEMP']).ravel()
        ok = np.isfinite(z) & np.isfinite(S) & np.isfinite(T) & (z > 0.05)
        if ok.sum() < 4: return np.nan
        z, S, T = z[ok], S[ok], T[ok]; o = np.argsort(z); z, S, T = z[o], S[o], T[o]
        return halo_height(z, eos80_potential_density(S, T) - 1000.0, float(z.max()))
    except Exception:
        return np.nan

rows = []
for c, _ in best.values():
    stn = c['stn']
    if stn not in coords: continue
    p = os.path.join(PROFILE_BASE, stn, f"dfv{c['time']}.{c['jday']}")
    if not os.path.exists(p): continue
    prof = read_dfv(p)
    if prof is None: continue
    depth, S, T = prof; lon, lat = coords[stn]['lon'], coords[stn]['lat']
    fld = halo_height(depth, eos80_potential_density(S, T) - 1000.0, float(depth.max()))
    when = pd.Timestamp(f"{TARGET} {c['time'][:2]}:{c['time'][2:]}")
    mlon, mlat = adjust_point(stn, lon, lat)
    rows.append(dict(stn=stn, lon=lon, lat=lat, field=fld, model=model_halo(mlon, mlat, when)))
df = pd.DataFrame(rows).dropna(subset=['lon', 'lat'])
print(f'{len(df)} stations | field {df.field.min():.1f}-{df.field.max():.1f} m  model {df.model.min():.1f}-{df.model.max():.1f} m')
print(df.sort_values('lat', ascending=False)[['stn', 'field', 'model']].round(2).to_string(index=False))

# ---- bathy background + land mask (optional; skip if X: DEM unavailable) ----
bathy = BLON = BLAT = None
try:
    import rasterio; from rasterio.windows import from_bounds; from pyproj import Transformer
    tf78 = Transformer.from_crs('EPSG:4326', 'EPSG:7850', always_xy=True)
    x0, y0 = tf78.transform(LONMIN, LATMIN); x1, y1 = tf78.transform(LONMAX, LATMAX)
    with rasterio.open(BATHY_TIF) as src:
        w = from_bounds(min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1), src.transform)
        bathy = src.read(1, window=w).astype(float); bathy[bathy == src.nodata] = np.nan; wt = src.window_transform(w)
    nr, ncb = bathy.shape; tf47 = Transformer.from_crs('EPSG:7850', 'EPSG:4326', always_xy=True)
    blon = np.array([tf47.transform((wt * (c, 0))[0], (y0 + y1) / 2)[0] for c in range(ncb)])
    blat = np.array([tf47.transform((x0 + x1) / 2, (wt * (0, r))[1])[1] for r in range(nr)])
    BLON, BLAT = np.meshgrid(blon, blat)
except Exception as e:
    print('bathy background unavailable, skipping:', e)

# ---- grid + RBF interpolation with masks (both columns identical machinery) ----
GLON, GLAT = np.meshgrid(np.linspace(LONMIN, LONMAX, 300), np.linspace(LATMIN, LATMAX, 300))
CL = np.cos(np.radians(-32.15))
def kmdist(lo, la, lo0, la0): return np.hypot((lo - lo0) * CL * 111.32, (la - la0) * 110.57)
land = np.zeros(GLON.shape, bool)
if bathy is not None:
    land = NearestNDInterpolator(np.c_[BLON.ravel(), BLAT.ravel()], bathy.ravel())(GLON, GLAT) > 0
dmin = np.full(GLON.shape, 1e9)
for _, r in df.iterrows(): dmin = np.minimum(dmin, kmdist(GLON, GLAT, r.lon, r.lat))
far = dmin > 2.5
def interp(vals):
    """Point-honouring: griddata linear (contours follow the station values), nearest-fill inside
    the station footprint only, then land + distance masks."""
    sub = df.dropna(subset=[vals])
    P = np.c_[sub.lon * CL, sub.lat]; Q = np.c_[GLON.ravel() * CL, GLAT.ravel()]
    G = griddata(P, sub[vals].values, Q, method='linear').reshape(GLON.shape)        # honours points, hull-bounded
    Gn = griddata(P, sub[vals].values, Q, method='nearest').reshape(GLON.shape)
    G = np.where(np.isnan(G) & ~far, Gn, G)                                          # fill just outside hull, within 2.5 km
    G = np.clip(G, 0, None); G[land | far] = np.nan; return G
MOD, FLD = interp('model'), interp('field')

# ---- plot: MODEL | FIELD ----
levels = np.arange(0, 9, 1); cmap = plt.cm.YlOrRd; norm = BoundaryNorm(levels, cmap.N, clip=True)
fig, axes = plt.subplots(1, 2, figsize=(20, 13), sharey=True)
for ax, (G, ttl, col) in zip(axes, [(MOD, f'MODEL ({RUNLABEL})', 'model'), (FLD, 'FIELD (SMCWS)', 'field')]):
    if bathy is not None:
        ax.contourf(BLON, BLAT, -bathy, levels=np.arange(-2, 26, 1), cmap='Blues', alpha=0.25)
        ax.contourf(BLON, BLAT, np.where(bathy > 0, 1.0, np.nan), levels=[0.5, 1.5], colors=['#c8b896'], alpha=0.85)
        ax.contour(BLON, BLAT, -bathy, levels=[15], colors='dimgrey', linewidths=1.0, linestyles='--')
    cf = ax.contourf(GLON, GLAT, G, levels=levels, cmap=cmap, norm=norm, extend='max', alpha=0.75)
    cs = ax.contour(GLON, GLAT, G, levels=levels, colors='k', linewidths=0.7); ax.clabel(cs, inline=True, fontsize=8, fmt='%g')
    for _, r in df.iterrows():
        if np.isfinite(r[col]):
            ax.plot(r.lon, r.lat, 'ko', ms=3, zorder=10)
            ax.annotate(f'{r[col]:.0f}', (r.lon, r.lat), textcoords='offset points', xytext=(3, 2), fontsize=6, zorder=11)
    ax.set_xlim(LONMIN, LONMAX); ax.set_ylim(LATMIN, LATMAX); ax.set_aspect(1 / CL); ax.grid(alpha=0.25)
    ax.set_title(ttl, fontsize=12, fontweight='bold'); ax.set_xlabel('Longitude')
axes[0].set_ylabel('Latitude')
fig.colorbar(cf, ax=axes, orientation='horizontal', pad=0.05, aspect=40, shrink=0.5, label='Halocline height above seabed (m)')
fig.suptitle(f'Halocline height above seabed — 20 Aug 1991 (0824–1415) — MODEL ({RUNLABEL}) vs SMCWS field',
             fontsize=14, fontweight='bold', y=0.97)
fig.savefig(OUT, dpi=140, bbox_inches='tight'); print('wrote', os.path.abspath(OUT))
