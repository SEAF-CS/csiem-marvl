# Auto-assembled headless runner from profile_curtain_1992_TransectA_compare.ipynb (REV config).
# Regenerates outputs_1992_TransectA_compare_rev/ from the re-run 1992 model output.
import matplotlib
matplotlib.use('Agg')   # force non-interactive backend (notebook strips the Agg call)

# === Imports, EOS-80, config =================================================
import os, numpy as np, pandas as pd
from pathlib import Path
from datetime import timedelta
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
import tfv.xarray
import sys as _sys; _sys.path.insert(0, r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/dadamo_transect')
try:
    from point_overrides import adjust_point
except Exception:
    def adjust_point(station, lon=None, lat=None): return lon, lat

MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc')  # REV
PLOT_TRANSECTS_1992 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/TransectA/plot_transects.py'
OUT_PNG_DIR = Path(r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/dadamo_transect/outputs_1992_TransectA_compare_rev')  # REV
OUT_PNG_DIR.mkdir(parents=True, exist_ok=True)

TEST_MODE = False   # FULL run: all jdays

def eos80_potential_density(S, T):
    T2,T3,T4,T5 = T*T,T*T*T,T*T*T*T,T*T*T*T*T
    Ssq = np.sqrt(np.clip(S,0,None)); S1p5 = S*Ssq; S2 = S*S
    a=[999.842594,6.793952e-2,-9.095290e-3,1.001685e-4,-1.120083e-6,6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b=[8.24493e-1,-4.0899e-3,7.6438e-5,-8.2467e-7,5.3875e-9]
    c=[-5.72466e-3,1.0227e-4,-1.6546e-6]; d0=4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2

# === Reuse the canonical 1992 field machinery ================================
_src = open(PLOT_TRANSECTS_1992, encoding='utf-8').read()
_marker = 'for panel_idx, jday in enumerate(JDAYS):'
_prefix = _src[:_src.index(_marker)].replace("matplotlib.use('Agg')", "")
__file__ = PLOT_TRANSECTS_1992  # so BASE/PARENT/MAP_DIR resolve inside the script
exec(compile(_prefix, PLOT_TRANSECTS_1992, 'exec'), globals())
print('Field machinery loaded:', len(COORDS), 'coords,', len(JDAYS), 'jdays,',
      len(ref_stns), 'union stations; chainage', XLIM_SOUTH, 'to', XLIM_NORTH, 'km')

# === Field profiles for a jday (mirrors plot_transects.py selection) =========
def field_profiles_for_jday(jday):
    active = active_stations(jday)
    cal_date = base_date + timedelta(days=jday - 1)
    t_mid = cal_date.replace(hour=12, minute=0)
    matches = [c for c in mar_casts if c['jday'] == jday and c['station'] in active]
    best = {}
    for m in matches:
        stn = m['station']; diff = abs((m['dt'] - t_mid).total_seconds())
        score = (TYPE_PRIORITY.get(m['ftype'], 9), diff)
        if stn not in best or score < best[stn][1]:
            best[stn] = (m, score)
    profiles, ptypes = {}, {}
    for m, _ in best.values():
        fp = find_profile_file(m['station'], jday, m['time'], m['prefix'])
        if fp is None: continue
        rd = READERS.get(m['prefix'])
        if rd is None: continue
        r = rd(fp)
        if r is not None:
            profiles[m['station']] = r; ptypes[m['station']] = m['ftype']
    times = [best[s][0]['dt'] for s in profiles]
    return profiles, cal_date, times

# === Model: open 1992 NC, inject density, sample fixed union stations ========
ds = xr.open_dataset(MODEL_NC)
ds['RHOW'] = eos80_potential_density(ds['SAL'], ds['TEMP'])
fv = ds.tfv                                   # decodes ResTime -> Time
times_model = pd.to_datetime(ds['Time'].values)
tmin, tmax = times_model.min(), times_model.max()
MODEL_STATIONS = [s for s in ref_stns if s in COORDS]   # fixed 42-station union

def snap_time(mid):
    return times_model[int(np.argmin(np.abs(times_model - mid)))]

def model_profiles_at(model_date):
    profs = {}
    for stn in MODEL_STATIONS:
        lat, lon = COORDS[stn]
        mlon, mlat = adjust_point(stn, lon, lat)   # channel-edge override (field stays at true station)
        try:
            p = fv.get_profile((mlon, mlat), variables=['SAL', 'TEMP', 'RHOW'], time=model_date)
            pt = p.sel(Time=model_date, method='nearest') if 'Time' in p.dims else p
            depth = -np.asarray(pt['Z']).ravel()
            sal = np.asarray(pt['SAL']).ravel(); temp = np.asarray(pt['TEMP']).ravel()
            den = np.asarray(pt['RHOW']).ravel() - 1000.0   # sigma_t to match field
            ok = np.isfinite(depth) & np.isfinite(sal) & np.isfinite(temp) & np.isfinite(den) & (depth > 0.1)
            if ok.sum() < 3: continue
            o = np.argsort(depth[ok])
            profs[stn] = {'depth': depth[ok][o], 'salinity': sal[ok][o],
                          'temperature': temp[ok][o], 'density': den[ok][o]}
        except Exception:
            pass
    return profs
print(f'Model {tmin} -> {tmax}; {len(MODEL_STATIONS)} fixed model stations')

# === Comparison figure: model (top) vs field (bottom), shared chainage =======
def make_compare_figure(jday, save=True, show=False):
    field_profs, cal_date, ftimes = field_profiles_for_jday(jday)
    if len(field_profs) < 2:
        print(f'jday {jday:03d}: {len(field_profs)} field profiles, skipping'); return None
    model_date = snap_time(pd.Timestamp(cal_date.replace(hour=12, minute=0)))
    model_profs = model_profiles_at(model_date)

    fig, axes = plt.subplots(2, 3, figsize=(20, 11.5), sharex='col', sharey=True)
    var_order = ['temperature', 'salinity', 'density']
    rows = [('MODEL', model_profs), ('FIELD', field_profs)]
    for ri, (rlabel, profs) in enumerate(rows):
        for col, vk in enumerate(var_order):
            ax = axes[ri, col]; cfg = VAR_CONFIG[vk]
            if len(profs) >= 2:
                gv = build_cross_section(profs, vk)
                norm = BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True)
                ax.contourf(grid_X, grid_Y, gv, levels=cfg['levels'], cmap=cfg['cmap'], norm=norm, extend='both')
                cl = ax.contour(grid_X, grid_Y, gv, levels=cfg['levels'], colors='k', linewidths=0.4)
                ax.clabel(cl, inline=True, fontsize=6, fmt='%.1f')
            else:
                ax.text(0.5, 0.5, '<2 profiles', transform=ax.transAxes, ha='center', va='center')
            ax.fill_between(bathy_chain, bathy_plot, depth_max_plot + 5, color='#8B7355', zorder=5)
            ax.plot(bathy_chain, bathy_plot, 'k-', lw=1, zorder=6)
            for stn in sorted(profs.keys(), key=lambda s: chainage_km(s)):
                x = chainage_km(stn)
                ax.plot(x, 0, 'kv', ms=5, zorder=7, clip_on=False)
                ax.text(x, -0.8, stn.replace('CS', '').replace('OA', 'O'), ha='center', va='bottom',
                        fontsize=5.5, rotation=90, zorder=7, clip_on=False)
            ax.set_xlim(XLIM_SOUTH, XLIM_NORTH); ax.set_ylim(depth_max_plot + 1, -2.5)
            ax.axvline(0, color='grey', lw=0.8, ls=':', alpha=0.6, zorder=4); ax.grid(True, lw=0.3, alpha=0.3)
            if col == 0: ax.set_ylabel(f'{rlabel}\nDepth (m)', fontsize=10, fontweight='bold')
            if ri == 1: ax.set_xlabel('Chainage from CS55 (km)\n← South     North →', fontsize=8)
    # bottom colorbar strip
    fig.subplots_adjust(top=0.92, bottom=0.16, left=0.06, right=0.99, hspace=0.14, wspace=0.05)
    for col, vk in enumerate(var_order):
        cfg = VAR_CONFIG[vk]; pos = axes[1, col].get_position()
        cax = fig.add_axes([pos.x0, 0.065, pos.width, 0.015])
        sm = plt.cm.ScalarMappable(norm=BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True), cmap=cfg['cmap'])
        sm.set_array([])
        fig.colorbar(sm, cax=cax, orientation='horizontal', extend='both').set_label(cfg['label'], fontsize=9)
    ft = (f"{min(ftimes).strftime('%H:%M')}–{max(ftimes).strftime('%H:%M')}" if ftimes else 'n/a')
    fig.text(0.5, 0.965,
             f'Transect A 1992  jday {jday:03d} — {cal_date.strftime("%d %b %Y")}   '
             f'field {ft} ({len(field_profs)} stns)   |   '
             f'model {pd.Timestamp(model_date).strftime("%d-%b %H:%M")}',
             ha='center', va='center', fontsize=13, fontweight='bold', color='#1f4e79')
    if save:
        fn = OUT_PNG_DIR / f'compare_TransectA_1992_jday{jday:03d}.png'; fig.savefig(fn, dpi=150, bbox_inches='tight')
    if show: plt.show()
    else: plt.close(fig)
    return OUT_PNG_DIR / f'compare_TransectA_1992_jday{jday:03d}.png' if save else None

# === Generate ================================================================
jobs = list(JDAYS)
if TEST_MODE:
    for jd in jobs:
        if len(field_profiles_for_jday(jd)[0]) >= 2:
            jobs = [jd]; break
print(f'{"TEST" if TEST_MODE else "FULL"} run: {len(jobs)} jday(s)')
for jd in jobs:
    out = make_compare_figure(jd, save=True, show=TEST_MODE)
    if out: print(f'  saved {out.name}')
print('Done.')
