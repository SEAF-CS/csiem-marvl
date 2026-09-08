"""ProfileSeries validation [3b] — depth-time, model vs SMCWS field, 1991.

Reproduced in the FIELD ProfileSeries' ORIGINAL style: scipy `griddata` time-depth interpolation +
`contourf` on the field `VAR_CONFIG` levels/cmaps (consistent with the transect cross-sections and the
kriged maps — NOT the hovmoller pcolormesh). The canonical field machinery (read_dfv / build_grid /
VAR_CONFIG / station_profiles) is reused via exec-prefix of the published script; a MODEL row is then
added per station — model profiles sampled at the run's timesteps over the window, pushed through the
SAME `build_grid` and contoured with the SAME levels/cmaps.

Layout: 8 rows = site × (model, field) for OA80/CS20/CS55/CS155 (N→S); 3 cols = T, S, density(σt).
"""
import os, sys, warnings, numpy as np, pandas as pd, xarray as xr
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt, matplotlib.dates as mdates
from matplotlib.colors import BoundaryNorm
import tfv.xarray

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'lib')))
from point_overrides import adjust_point
from eos80 import eos80_potential_density

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
RUNLABEL = '1991 rev'
COORDS = {'OA80': (115.7013, -32.1313), 'CS20': (115.7055, -32.1501),   # (lon, lat), N->S
          'CS55': (115.7140, -32.1876), 'CS155': (115.7207, -32.2464)}
OUT = os.path.join(HERE, '..', 'outputs', 'profile_series_1991_rev.png')

# ---- reuse the canonical field ProfileSeries machinery (readers, build_grid, VAR_CONFIG, data load) ----
FIELD = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/ProfileSeries/plot_profile_series.py'
_src = open(FIELD, encoding='utf-8').read()
_split = _src.index('fig, axes = plt.subplots(4, 3')           # everything before the figure = machinery + data load
_G = {'__file__': FIELD, '__name__': 'ps_field'}
exec(compile(_src[:_split], FIELD, 'exec'), _G)
build_grid   = _G['build_grid'];   VAR_CONFIG = _G['VAR_CONFIG']; STATIONS = _G['STATIONS']
station_profiles = _G['station_profiles']; t_min = _G['t_min']; t_max = _G['t_max']
STORM_GAP    = _G['STORM_GAP'];    MAX_DEPTH  = _G['MAX_DEPTH']
VAR_KEYS = ['temperature', 'salinity', 'density']

# ---- MODEL: sample a profile at each station for every model step in the window -> same prof dicts ----
ds = xr.open_dataset(NC); fv = ds.tfv
mtimes = pd.to_datetime(ds['Time'].values)
mwin = mtimes[(mtimes >= pd.Timestamp(t_min)) & (mtimes <= pd.Timestamp(t_max))]
mwin = mwin[::max(1, len(mwin) // 120)]   # cap ~120 model steps (handles 1-hourly output; keeps the curtain smooth & fast)
print(f'model steps in window: {len(mwin)}  ({mwin.min()} .. {mwin.max()})')
model_profiles = {s: [] for s in STATIONS}
for stn in STATIONS:
    lon, lat = COORDS[stn]; mlon, mlat = adjust_point(stn, lon, lat)
    for md in mwin:
        try:
            prof = fv.get_profile((mlon, mlat), variables=['SAL', 'TEMP'], time=md)
            pt = prof.sel(Time=md, method='nearest') if 'Time' in prof.dims else prof
            z = -np.asarray(pt['Z']).ravel(); T = np.asarray(pt['TEMP']).ravel(); S = np.asarray(pt['SAL']).ravel()
            ok = np.isfinite(z) & np.isfinite(T) & np.isfinite(S)
            if ok.sum() < 2: continue
            z, T, S = z[ok], T[ok], S[ok]; o = np.argsort(z); z, T, S = z[o], T[o], S[o]
            model_profiles[stn].append((md.to_pydatetime(),
                {'depth': z, 'temperature': T, 'salinity': S, 'density': eos80_potential_density(S, T) - 1000.0}))
        except Exception:
            continue
    print(f'{stn}: model {len(model_profiles[stn])} profiles | field {len(station_profiles[stn])}')

# ---- figure: 8 rows (site x model/field) x 3 cols (T,S,density), field contourf style ----
fig, axes = plt.subplots(8, 3, figsize=(19, 22), sharex=True)
rowdef = [(s, k) for s in STATIONS for k in ('model', 'field')]
for ri, (stn, kind) in enumerate(rowdef):
    profiles = (model_profiles if kind == 'model' else station_profiles)[stn]
    for ci, vk in enumerate(VAR_KEYS):
        ax = axes[ri, ci]; cfg = VAR_CONFIG[vk]
        T_GRID, D_GRID, V_GRID = build_grid(profiles, vk, t_min, t_max)
        if V_GRID is not None:
            norm = BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True)
            ax.contourf(T_GRID, D_GRID, V_GRID, levels=cfg['levels'], cmap=cfg['cmap'], norm=norm, extend='both')
            cs = ax.contour(T_GRID, D_GRID, V_GRID, levels=cfg['levels'], colors='k', linewidths=0.3)
            ax.clabel(cs, inline=True, fontsize=5, fmt='%.1f')
        ax.axvspan(mdates.date2num(STORM_GAP[0]), mdates.date2num(STORM_GAP[1]), color='grey', alpha=0.3, zorder=3)
        for dt, _ in profiles:
            ax.plot(mdates.date2num(dt), 0, 'kv', markersize=3, zorder=7, clip_on=False)
        ax.set_ylim(MAX_DEPTH, 0); ax.grid(True, linewidth=0.3, alpha=0.3)
        if ri == 0: ax.set_title(cfg['label'], fontsize=12, fontweight='bold')
        if ci == 0: ax.set_ylabel(f'{stn} · {kind}\nDepth (m)', fontsize=9,
                                  fontweight='bold' if kind == 'model' else 'normal')
        if ri == len(rowdef) - 1:
            ax.xaxis.set_major_locator(mdates.DayLocator(interval=2)); ax.xaxis.set_major_formatter(mdates.DateFormatter('%d\n%b'))
# colorbars: one per column at the bottom
for ci, vk in enumerate(VAR_KEYS):
    cfg = VAR_CONFIG[vk]; norm = BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True)
    sm = plt.cm.ScalarMappable(norm=norm, cmap=cfg['cmap']); sm.set_array([])
    cax = fig.add_axes([0.07 + ci * 0.315, 0.045, 0.25, 0.008])
    fig.colorbar(sm, cax=cax, orientation='horizontal', label=cfg['label'])
fig.suptitle(f'ProfileSeries — model ({RUNLABEL}) vs SMCWS field — depth-time at OA80 / CS20 / CS55 / CS155 (N→S)\n'
             f'{t_min:%d-%b} to {t_max:%d-%b} 1991 (19 Aug storm gap shaded) · field-style griddata+contourf',
             fontsize=14, fontweight='bold', y=0.99)
fig.subplots_adjust(top=0.95, bottom=0.085, left=0.06, right=0.985, hspace=0.13, wspace=0.08)
fig.savefig(OUT, dpi=150); print('wrote', os.path.abspath(OUT))
