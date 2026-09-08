"""TransectB validation [5] — E-W cross-section, model vs SMCWS field, 1991, in the field's ORIGINAL
style. Reuses the canonical TransectB field machinery (COORDS, E-W chainage, read_dfv, build_cross_section,
bathy line, VAR_CONFIG, panels) via exec-prefix of the published script; adds a MODEL row — model profiles
sampled at the TransectB stations at each panel midpoint, pushed through the SAME build_cross_section +
contourf. Per panel: model (top) vs field (bottom), 3 vars, shared CS55 E-W chainage (west left/east right).
→ years/1991/outputs/transectB/.
"""
import os, sys, numpy as np, pandas as pd, xarray as xr
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
import tfv.xarray

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'lib')))
from point_overrides import adjust_point
from eos80 import eos80_potential_density

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
RUNLABEL = '1991 rev'
OUT_DIR = os.path.join(HERE, '..', 'outputs', 'transectB'); os.makedirs(OUT_DIR, exist_ok=True)

# ---- reuse canonical TransectB field machinery (exec up to its per-panel plot loop) ----
FIELD = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/Transect_B/plot_transects.py'
_src = open(FIELD, encoding='utf-8').read()
_split = _src.index('for panel_idx, (panel_id, t0, t1) in enumerate(ALL_PANELS):')
_G = {'__file__': FIELD, '__name__': 'tb_field'}
exec(compile(_src[:_split], FIELD, 'exec'), _G)
COORDS = _G['COORDS']; chainage_km = _G['chainage_km']; read_dfv = _G['read_dfv']
build_cross_section = _G['build_cross_section']; VAR_CONFIG = _G['VAR_CONFIG']; ALL_PANELS = _G['ALL_PANELS']
bathy_chain = _G['bathy_chain']; bathy_depths = _G['bathy_depths']; bathy_plot = _G['bathy_plot']
grid_X = _G['grid_X']; grid_Y = _G['grid_Y']; depth_max_plot = _G['depth_max_plot']
XLIM_WEST = _G['XLIM_WEST']; XLIM_EAST = _G['XLIM_EAST']; aug_casts = _G['aug_casts']
PROFILE_BASE = _G['PROFILE_BASE']; ref_stns = _G['ref_stns']
VAR_ORDER = ['temperature', 'salinity', 'density']


def field_profiles_for_panel(t0, t1):
    tmid = t0 + (t1 - t0) / 2; best = {}
    for c in aug_casts:
        if t0 <= c['dt'] <= t1:
            dd = abs((c['dt'] - tmid).total_seconds())
            if c['station'] not in best or dd < best[c['station']][1]: best[c['station']] = (c, dd)
    profs = {}
    for c, _ in best.values():
        p = os.path.join(PROFILE_BASE, c['station'], f"dfv{c['time']}.{c['jday']}")
        if os.path.exists(p):
            r = read_dfv(p)
            if r is not None: profs[c['station']] = r
    return profs


# ---- model ----
ds = xr.open_dataset(NC); fv = ds.tfv   # density derived per-profile from S,T (no full-field RHOW)
mtimes = pd.to_datetime(ds['Time'].values); tmin, tmax = mtimes.min(), mtimes.max()
MODEL_STATIONS = [s for s in ref_stns if s in COORDS]   # the 14 TransectB stations (shore pt is bathy-only)


def snap(mid): return mtimes[int(np.argmin(np.abs(mtimes - mid)))]


def model_profiles_at(md):
    profs = {}
    for stn in MODEL_STATIONS:
        lat, lon = COORDS[stn]; mlon, mlat = adjust_point(stn, lon, lat)
        try:
            p = fv.get_profile((mlon, mlat), variables=['SAL', 'TEMP'], time=md)
            pt = p.sel(Time=md, method='nearest') if 'Time' in p.dims else p
            z = -np.asarray(pt['Z']).ravel(); S = np.asarray(pt['SAL']).ravel(); T = np.asarray(pt['TEMP']).ravel()
            den = eos80_potential_density(S, T) - 1000.0
            ok = np.isfinite(z) & np.isfinite(S) & np.isfinite(T) & np.isfinite(den) & (z > 0.1)
            if ok.sum() < 3: continue
            o = np.argsort(z[ok])
            profs[stn] = {'depth': z[ok][o], 'salinity': S[ok][o], 'temperature': T[ok][o], 'density': den[ok][o]}
        except Exception:
            pass
    return profs


def make_compare(panel_id, t0, t1):
    fprofs = field_profiles_for_panel(t0, t1)
    if len(fprofs) < 2:
        print(f'{panel_id}: {len(fprofs)} field profiles, skipping'); return None
    md = snap(pd.Timestamp(t0) + (pd.Timestamp(t1) - pd.Timestamp(t0)) / 2)
    mprofs = model_profiles_at(md)
    fig, axes = plt.subplots(2, 3, figsize=(20, 11), sharex='col', sharey=True)
    for ri, (rlabel, profs) in enumerate([('MODEL', mprofs), ('FIELD', fprofs)]):
        for col, vk in enumerate(VAR_ORDER):
            ax = axes[ri, col]; cfg = VAR_CONFIG[vk]
            if len(profs) >= 2:
                gv = build_cross_section(profs, vk, bathy_chain, bathy_depths)
                norm = BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True)
                ax.contourf(grid_X, grid_Y, gv, levels=cfg['levels'], cmap=cfg['cmap'], norm=norm, extend='both')
                cl = ax.contour(grid_X, grid_Y, gv, levels=cfg['levels'], colors='k', linewidths=0.4)
                ax.clabel(cl, inline=True, fontsize=6, fmt='%.1f')
            else:
                ax.text(0.5, 0.5, '<2 profiles', transform=ax.transAxes, ha='center', va='center')
            ax.fill_between(bathy_chain, bathy_plot, depth_max_plot + 5, color='#8B7355', zorder=5)
            ax.plot(bathy_chain, bathy_plot, 'k-', lw=1, zorder=6)
            for stn in sorted(profs.keys(), key=lambda s: chainage_km(s)):
                x = chainage_km(stn); ax.plot(x, 0, 'kv', ms=5, zorder=7, clip_on=False)
                ax.text(x, -0.8, stn.replace('CS', ''), ha='center', va='bottom', fontsize=6, zorder=7, clip_on=False)
            ax.set_xlim(XLIM_WEST, XLIM_EAST); ax.set_ylim(depth_max_plot + 1, -2.5)
            ax.axvline(0, color='grey', lw=0.8, ls=':', alpha=0.6, zorder=4); ax.grid(True, lw=0.3, alpha=0.3)
            if col == 0: ax.set_ylabel(f'{rlabel}\nDepth (m)', fontsize=10, fontweight='bold')
            if ri == 1: ax.set_xlabel('Chainage from CS55 (km)\n← West     East →', fontsize=8)
    fig.subplots_adjust(top=0.92, bottom=0.16, left=0.06, right=0.99, hspace=0.14, wspace=0.05)
    for col, vk in enumerate(VAR_ORDER):
        cfg = VAR_CONFIG[vk]; pos = axes[1, col].get_position()
        cax = fig.add_axes([pos.x0, 0.065, pos.width, 0.015])
        sm = plt.cm.ScalarMappable(norm=BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True), cmap=cfg['cmap']); sm.set_array([])
        fig.colorbar(sm, cax=cax, orientation='horizontal', extend='both').set_label(cfg['label'], fontsize=9)
    is_pre = '6.16' in panel_id; sc = '#b8860b' if is_pre else '#228B22'
    fig.text(0.5, 0.965, f'Transect B  panel {panel_id} ({"PRE" if is_pre else "POST"}-STORM)   '
             f'field {t0:%d-%b %H:%M}–{t1:%H:%M}   |   model {pd.Timestamp(md):%d-%b %H:%M}',
             ha='center', va='center', fontsize=13, fontweight='bold', color=sc)
    fn = os.path.join(OUT_DIR, f'compare_TransectB_{panel_id}.png'); fig.savefig(fn, dpi=150, bbox_inches='tight'); plt.close(fig)
    return fn


print(f'Model coverage {tmin} -> {tmax}; {len(MODEL_STATIONS)} TransectB model stations')
jobs = [(pid, t0, t1) for (pid, t0, t1) in ALL_PANELS
        if tmin <= (pd.Timestamp(t0) + (pd.Timestamp(t1) - pd.Timestamp(t0)) / 2) <= tmax]
print(f'{len(jobs)} panels in model window')
for pid, t0, t1 in jobs:
    out = make_compare(pid, t0, t1)
    if out: print(f'  saved {os.path.basename(out)}')
print('Done.')
