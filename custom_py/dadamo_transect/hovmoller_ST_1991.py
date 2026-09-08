"""Hovmoller (depth-time curtain) comparison — model vs SMCWS field — for the 1991 sim.
A4 portrait grid:  columns = SITES (CS55, OA80) ;  rows = [S model, S field, T model, T field].

  - MODEL: tfv `fv.plot_hovmoller(point, var, time_limits=...)`            (oxygen_hovmoller_plot.ipynb)
  - FIELD: per-cast QC -> interp onto a 0.25 m depth grid -> depth x time   (process_dwer_mooring...ipynb)
           pcolormesh + raw-sample scatter; NaN inserted across >1.5-day gaps.
Shared per-variable clim (so the two sites are comparable); common depth axis; shared date axis.
CLI:  python hovmoller_ST_1991.py
"""
import os, warnings, numpy as np, pandas as pd, xarray as xr
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt, matplotlib.dates as mdates
import seaborn as sns; sns.set(style='white', font_scale=0.75)
import tfv.xarray
import region_validation_core as core
from point_overrides import adjust_point   # model-sample location override (field stays at true station)

DIR = core.DIR
NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev.nc'
RUNLABEL = '1991 rev'
SITES = {'CS55': (115.7140, -32.1876), 'OA80': (115.7013, -32.1313)}   # (lon, lat)
WIN = slice('1991-08-10', '1991-08-25')
DZ = 0.25
# variable: (model var, field index in _read_cast (depth,T,S), label, cmap, round)
VARS = {'S': dict(mvar='SAL',  fi=2, label='Salinity (psu)',     cmap=None, rnd=0.25, clim_fixed=None),
        'T': dict(mvar='TEMP', fi=1, label='Temperature (°C)', cmap='inferno', rnd=0.5, clim_fixed=(15.2, 17.0))}
try:
    import cmocean; VARS['S']['cmap'] = cmocean.cm.haline; VARS['T']['cmap'] = cmocean.cm.thermal
except Exception:
    VARS['S']['cmap'] = 'viridis'

INV = pd.read_csv(os.path.join(DIR, 'region_profiles_inventory.csv'))


def read_site_casts(station):
    cs = INV[(INV.station == station) & (INV.year == 1991)].copy()
    ts = cs['time'].astype(int).astype(str).str.zfill(4)
    cs['dt'] = pd.to_datetime(cs['date']) + pd.to_timedelta(ts.str[:2].astype(int), 'h') + pd.to_timedelta(ts.str[2:].astype(int), 'm')
    cs = cs[(cs['dt'] >= pd.Timestamp(WIN.start)) & (cs['dt'] <= pd.Timestamp(WIN.stop))].sort_values('dt')
    out = []
    for _, r in cs.iterrows():
        res = core._read_cast(r['source_file'], r['prefix'])      # (depth, T, S)
        if res is None: continue
        depth, T, S = res; o = np.argsort(depth)
        out.append((r['dt'], depth[o], T[o], S[o]))
    return out


def build_field(casts, fi, zgrid):
    times, raw = [], []
    field = np.full((len(zgrid), len(casts)), np.nan)
    for j, (dt, depth, T, S) in enumerate(casts):
        v = (depth, T, S)[fi]
        dd, idx = np.unique(np.round(depth, 2), return_inverse=True)
        vv = np.array([v[idx == k].mean() for k in range(len(dd))])
        f = np.interp(zgrid, dd, vv, left=np.nan, right=np.nan)
        f[(zgrid < dd.min()) | (zgrid > dd.max())] = np.nan
        field[:, j] = f; times.append(dt)
        raw += list(zip([dt] * len(depth), depth))
    return times, field, raw


def gap_insert(tlist, F, max_gap=1.5):
    t = [pd.Timestamp(x) for x in tlist]; ot = [t[0]]; cols = [F[:, 0]]
    for j in range(1, len(t)):
        if (t[j] - t[j - 1]).total_seconds() / 86400 > max_gap:
            ot.append(t[j - 1] + (t[j] - t[j - 1]) / 2); cols.append(np.full(F.shape[0], np.nan))
        ot.append(t[j]); cols.append(F[:, j])
    return np.array(ot), np.column_stack(cols)


# ---- read casts + common depth grid ----
CASTS = {s: read_site_casts(s) for s in SITES}
for s in SITES: print(f'{s}: {len(CASTS[s])} casts in {WIN.start}..{WIN.stop}')
zmax = max(c[1].max() for s in SITES for c in CASTS[s])
zgrid = np.arange(0, zmax + DZ, DZ)
YLIM = (-(zmax + 1), -0.7)   # trim the top 0.7 m (surface band) to fill whitespace

# ---- per-variable clim from field (both sites) ----
for vk, v in VARS.items():
    pool = []
    for s in SITES:
        _, F, _ = build_field(CASTS[s], v['fi'], zgrid); pool.append(F[np.isfinite(F)])
    arr = np.concatenate(pool)
    v['clim'] = v.get('clim_fixed') or (float(np.floor(np.nanpercentile(arr, 2) / v['rnd']) * v['rnd']),
                                        float(np.ceil(np.nanpercentile(arr, 98) / v['rnd']) * v['rnd']))
    print(f"{vk} clim {v['clim']}")

# ---- figure: 4 rows x 2 cols on A4 portrait ----
#   rows = OA80 (model,field) then CS55 (model,field) ;  cols = S (left), T (right)
ds = xr.open_dataset(NC); fv = ds.tfv
fig, axes = plt.subplots(4, 2, figsize=(8.27, 11.69), sharex=True, constrained_layout=True)
rowdef = [('OA80', 'model'), ('OA80', 'field'), ('CS55', 'model'), ('CS55', 'field')]
cols = ['S', 'T']
mappable = {}
for ri, (site, kind) in enumerate(rowdef):
    lon, lat = SITES[site]
    for ci, vk in enumerate(cols):
        v = VARS[vk]; ax = axes[ri, ci]
        if kind == 'model':
            mlon, mlat = adjust_point(site, lon, lat)   # nudge channel-edge sites into the channel
            hov = fv.plot_hovmoller((mlon, mlat), v['mvar'], time_limits=WIN, ax=ax, cmap=v['cmap'], clim=v['clim'])
            mappable[vk] = hov
        else:
            times, F, raw = build_field(CASTS[site], v['fi'], zgrid)
            tg, Fg = gap_insert(times, F)
            ax.pcolormesh(tg, -zgrid, Fg, shading='nearest', vmin=v['clim'][0], vmax=v['clim'][1], cmap=v['cmap'])
            ax.scatter(pd.to_datetime([r[0] for r in raw]), -np.array([r[1] for r in raw]), s=2, c='k', alpha=0.2, lw=0, zorder=4)
        ax.set_ylim(*YLIM)
        if ri == 0: ax.set_title(v['label'].split(' (')[0], fontsize=11, fontweight='bold')
        if ci == 0: ax.set_ylabel(f'{site} {kind}\nDepth (m)', fontsize=8)
        else: ax.tick_params(labelleft=False)
for ci in range(2):
    axes[3, ci].xaxis.set_major_locator(mdates.DayLocator(interval=3)); axes[3, ci].xaxis.set_major_formatter(mdates.DateFormatter('%d-%b'))
fig.autofmt_xdate()
# per-variable colorbars at the bottom of each column (S under left, T under right)
fig.colorbar(mappable['S'], ax=axes[:, 0].ravel().tolist(), location='bottom', shrink=0.9, pad=0.015, label=VARS['S']['label'])
fig.colorbar(mappable['T'], ax=axes[:, 1].ravel().tolist(), location='bottom', shrink=0.9, pad=0.015, label=VARS['T']['label'])
fig.suptitle(f'CS55 & OA80 Hovmoller — model ({RUNLABEL}) vs SMCWS field\nOA80 (top) / CS55 (bottom) — Salinity (left) / Temperature (right) — 10–25 Aug 1991',
             fontsize=11, fontweight='bold')
OUT = os.path.join(DIR, 'hovmoller_ST_CS55_OA80_1991_rev.png')
fig.savefig(OUT, dpi=150); print('wrote', OUT)
