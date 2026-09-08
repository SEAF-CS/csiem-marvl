"""Headless runner (assembled from profile_curtain_1994May_TransectABC_compare.ipynb):
1994 May A/B/C transect model-vs-field compare against the 1994_autumn_rev NC.
Config: MODEL_NC->rev, OUT_BASE->years/1994/outputs, TEST_MODE=False, Agg.
Model extraction = per-profile get_profile([SAL,TEMP]) + eos80 (NO full-field RHOW).
"""
# === Shared: imports, model open, generic model-sampling + figure ============
import os, csv, struct, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import xarray as xr
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
import tfv.xarray

MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1994_autumn_rev/csiem_B010_19931101_19941231_rev.nc')  # REV
OUT_BASE = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1994/outputs')
OUT_BASE.mkdir(parents=True, exist_ok=True)
TEST_MODE = False
TX_SCRIPTS = {
    'A': r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1994/TransectA/plot_transects.py',
    'B': r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1994/TransectA/plot_transects_B.py',
    'C': r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1994/TransectA/plot_transects_C.py',
}
MODEL_VAR = {'temperature': 'TEMP', 'salinity': 'SAL', 'density': 'RHOW'}

def eos80_potential_density(S, T):
    T2,T3,T4,T5 = T*T,T*T*T,T*T*T*T,T*T*T*T*T
    Ssq = np.sqrt(np.clip(S,0,None)); S1p5 = S*Ssq; S2 = S*S
    a=[999.842594,6.793952e-2,-9.095290e-3,1.001685e-4,-1.120083e-6,6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b=[8.24493e-1,-4.0899e-3,7.6438e-5,-8.2467e-7,5.3875e-9]
    c=[-5.72466e-3,1.0227e-4,-1.6546e-6]; d0=4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2

import time as _time
fv = None; MODEL_OK = False
for _attempt in range(8):   # the 1994B NC on the network drive intermittently throws HDF errors
    try:
        ds = xr.open_dataset(MODEL_NC)
        fv = ds.tfv   # do NOT inject ds['RHOW'] here: it forces a full-dataset SAL+TEMP read
                      # through the accessor and HDF-errors on the large 1994 NC over the network.
        _ = ds['SAL']  # touch to confirm readable
        times_model = pd.to_datetime(ds['Time'].values)
        TMIN, TMAX = times_model.min(), times_model.max()
        MODEL_OK = True
        MODEL_STATUS = f'run at {TMAX:%d-%b-%Y}'
        print(f'Model coverage: {TMIN} -> {TMAX} (open attempt {_attempt+1})')
        break
    except Exception as e:
        print(f'  model open attempt {_attempt+1} failed ({type(e).__name__}); retrying...')
        _time.sleep(3)
if not MODEL_OK:
    times_model = pd.DatetimeIndex([]); TMIN = TMAX = pd.Timestamp('1900-01-01')
    MODEL_STATUS = 'NC unreadable (HDF)'
    print('MODEL NC not readable after retries; field-only mode.')

def load_field_prefix(script_path, marker):
    """Exec a canonical 1994 transect script up to its plotting loop, into a fresh ns."""
    src = open(script_path, encoding='utf-8').read()
    prefix = src[:src.index(marker)].replace("matplotlib.use('Agg')", "")
    ns = {'__file__': script_path, '__name__': 'field94'}
    exec(compile(prefix, script_path, 'exec'), ns)
    return ns

def model_profiles(coords_map, stations, model_date):
    """Sample model at given stations; returns {} if model_date outside coverage
    OR if the NetCDF can't be read (e.g. the 1994 run is still writing the file)."""
    if model_date is None or not (TMIN <= model_date <= TMAX):
        return {}
    profs = {}
    for stn in stations:
        if stn not in coords_map: continue
        lat, lon = coords_map[stn]
        try:
            p = fv.get_profile((lon, lat), variables=['SAL','TEMP'], time=model_date)
            pt = p.sel(Time=model_date, method='nearest') if 'Time' in p.dims else p
            depth = -np.asarray(pt['Z']).ravel()
            sal = np.asarray(pt['SAL']).ravel(); temp = np.asarray(pt['TEMP']).ravel()
            den = eos80_potential_density(sal, temp) - 1000.0   # sigma_t, computed per-profile (no full-dataset RHOW read)
            ok = np.isfinite(depth)&np.isfinite(sal)&np.isfinite(temp)&np.isfinite(den)&(depth>0.1)
            if ok.sum() < 3: continue
            o = np.argsort(depth[ok])
            profs[stn] = {'depth':depth[ok][o],'salinity':sal[ok][o],
                          'temperature':temp[ok][o],'density':den[ok][o]}
        except Exception:
            pass
    return profs

def make_compare(ctx, field_profs, model_profs, title, out_png, save=True, show=False):
    """ctx: dict with build_fn, chain_fn, gridX, gridY, bathy_chain, bathy_plot,
    depth_max_plot, xlim(left,right), VAR_CONFIG, model_date."""
    VC = ctx['VAR_CONFIG']; var_order = ['temperature','salinity','density']
    fig, axes = plt.subplots(2, 3, figsize=(20, 11.5), sharex='col', sharey=True)
    rows = [('MODEL', model_profs), ('FIELD', field_profs)]
    gridX, gridY = ctx['gridX'], ctx['gridY']
    for ri, (rlabel, profs) in enumerate(rows):
        for col, vk in enumerate(var_order):
            ax = axes[ri, col]; cfg = VC[vk]
            if len(profs) >= 2:
                gv = ctx['build_fn'](profs, vk)
                norm = BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True)
                ax.contourf(gridX, gridY, gv, levels=cfg['levels'], cmap=cfg['cmap'], norm=norm, extend='both')
                cl = ax.contour(gridX, gridY, gv, levels=cfg['levels'], colors='k', linewidths=0.4)
                ax.clabel(cl, inline=True, fontsize=6, fmt='%.1f')
            else:
                msg = 'MODEL not yet simulated\nfor this date' if rlabel == 'MODEL' else '<2 profiles'
                ax.text(0.5, 0.5, msg, transform=ax.transAxes, ha='center', va='center',
                        fontsize=11, color='firebrick' if rlabel == 'MODEL' else 'gray')
            ax.fill_between(ctx['bathy_chain'], ctx['bathy_plot'], ctx['depth_max_plot']+5, color='#8B7355', zorder=5)
            ax.plot(ctx['bathy_chain'], ctx['bathy_plot'], 'k-', lw=1, zorder=6)
            for stn in sorted(profs.keys(), key=lambda s: ctx['chain_fn'](s)):
                x = ctx['chain_fn'](stn)
                ax.plot(x, 0, 'kv', ms=5, zorder=7, clip_on=False)
                ax.text(x, -0.8, stn.replace('CS','').replace('OA','O'), ha='center', va='bottom',
                        fontsize=5.5, rotation=90, zorder=7, clip_on=False)
            ax.set_xlim(*ctx['xlim']); ax.set_ylim(ctx['depth_max_plot']+1, -2.5)
            ax.axvline(0, color='grey', lw=0.8, ls=':', alpha=0.6, zorder=4); ax.grid(True, lw=0.3, alpha=0.3)
            if col == 0: ax.set_ylabel(f'{rlabel}\nDepth (m)', fontsize=10, fontweight='bold')
            if ri == 1: ax.set_xlabel('Chainage (km)', fontsize=8)
    fig.subplots_adjust(top=0.92, bottom=0.16, left=0.06, right=0.99, hspace=0.14, wspace=0.05)
    for col, vk in enumerate(var_order):
        cfg = VC[vk]; pos = axes[1, col].get_position()
        cax = fig.add_axes([pos.x0, 0.065, pos.width, 0.015])
        sm = plt.cm.ScalarMappable(norm=BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True), cmap=cfg['cmap'])
        sm.set_array([]); fig.colorbar(sm, cax=cax, orientation='horizontal', extend='both').set_label(cfg['label'], fontsize=9)
    fig.text(0.5, 0.965, title, ha='center', va='center', fontsize=13, fontweight='bold', color='#1f4e79')
    if save: fig.savefig(out_png, dpi=150, bbox_inches='tight')
    if show: plt.show()
    else: plt.close(fig)
    return out_png if save else None

def snap_or_none(target):
    return times_model[int(np.argmin(np.abs(times_model - target)))] if (TMIN <= target <= TMAX) else None

# === Transect A (jdays 123, 124) — same structure as 1992 ====================
FA = load_field_prefix(TX_SCRIPTS['A'], 'for jday in JDAYS:')
def fieldA(jday):
    active = FA['active_stations'](jday); cal = FA['base_date'] + timedelta(days=jday-1)
    tmid = cal.replace(hour=12, minute=0)
    matches = [c for c in FA['casts'] if c['jday']==jday and c['station'] in active]
    best = {}
    for m in matches:
        d = abs((m['dt']-tmid).total_seconds()); sc = (FA['TYPE_PRIORITY'].get(m['ftype'],9), d)
        if m['station'] not in best or sc < best[m['station']][1]: best[m['station']] = (m, sc)
    profs = {}
    for cast,_ in best.values():
        fp = FA['find_profile_file'](cast['station'], jday, cast['time'], cast['prefix'])
        rd = FA['READERS'].get(cast['prefix'])
        if fp and rd:
            r = rd(fp)
            if r is not None: profs[cast['station']] = r
    return profs, active, cal

def ctxA():
    return dict(VAR_CONFIG=FA['VAR_CONFIG'], gridX=FA['grid_X'], gridY=FA['grid_Y'],
                bathy_chain=FA['bathy_chain'], bathy_plot=FA['bathy_plot'], depth_max_plot=FA['depth_max_plot'],
                xlim=(FA['XLIM_SOUTH'], FA['XLIM_NORTH']), chain_fn=FA['chainage_km'],
                build_fn=lambda p,v: FA['build_cross_section'](p, v, FA['bathy_chain'], FA['bathy_depths']))

def run_A(jdays):
    od = OUT_BASE/'TransectA'; od.mkdir(exist_ok=True); outs=[]
    for jday in jdays:
        fp, active, cal = fieldA(jday)
        if len(fp) < 2: print(f'A jday {jday}: {len(fp)} field — skip'); continue
        md = snap_or_none(pd.Timestamp(cal.replace(hour=12)))
        mp = model_profiles(FA['COORDS'], active, md)
        ttl = (f'Transect A — jday {jday:03d} ({cal.strftime("%d %b %Y")})   '
               f'field {len(fp)} stns   |   ' + (f'model {pd.Timestamp(md).strftime("%d-%b %H:%M")}' if md is not None
               else f'MODEL pending ({MODEL_STATUS})'))
        ctx = ctxA(); ctx['model_date'] = md
        outs.append(make_compare(ctx, fp, mp, ttl, od/f'compare_A_jday{jday:03d}.png', show=TEST_MODE))
        print(f'  A jday {jday}: field {len(fp)}, model {len(mp)} -> saved')
    return outs

# === Transect B (jdays 123, 124) — CHAIN_B + two-phase bathy =================
FB = load_field_prefix(TX_SCRIPTS['B'], 'all_cast_depths = []')
def _B_build_day_profiles():
    CHAIN_B = FB['CHAIN_B']; day_profiles = {}; all_cast_depths = []
    for jday in FB['JDAYS']:
        active = FB['TRANSECT_BY_JDAY'][jday]; cal = datetime(1994,1,1) + timedelta(days=jday-1)
        tmid = cal.replace(hour=12, minute=0)
        matches = [c for c in FB['casts'] if c['jday']==jday and c['station'] in active]
        best = {}
        for m in matches:
            d = abs((m['dt']-tmid).total_seconds()); sc = (FB['TYPE_PRIORITY'].get(m['ftype'],9), d)
            if m['station'] not in best or sc < best[m['station']][1]: best[m['station']] = (m, sc)
        profs = {}
        for cast,_ in best.values():
            fp = FB['find_profile_file'](cast['station'], jday, cast['time'], cast['prefix'])
            rd = FB['READERS'].get(cast['prefix'])
            if fp and rd:
                r = rd(fp)
                if r is not None:
                    profs[cast['station']] = r
                    if cast['station'] in CHAIN_B: all_cast_depths.append((CHAIN_B[cast['station']], r['depth'].max()))
        day_profiles[jday] = profs
    # bathy fill (mirror script)
    bathy_depths = FB['bathy_depths_raw'].copy(); nan = np.isnan(bathy_depths)
    if all_cast_depths and nan.any():
        cdc = np.array(sorted(all_cast_depths, key=lambda x: x[0])); cx, cd = cdc[:,0], cdc[:,1]+FB['BATHY_BUFFER']
        bathy_depths[nan] = np.interp(FB['bathy_chain'][nan], cx, cd)
    from scipy.ndimage import uniform_filter1d
    bsm = uniform_filter1d(np.nan_to_num(bathy_depths, nan=0), size=FB['BATHY_SMOOTH'])
    bathy_plot = np.where(~np.isnan(bathy_depths), bsm, np.nan)
    dmp = min(np.nanmax(bathy_plot)+1.0, FB['MAX_DEPTH'])
    return day_profiles, bathy_depths, bathy_plot, dmp

B_day_profiles, B_bd, B_bp, B_dmp = _B_build_day_profiles()
def ctxB(profs):
    sc = {s: FB['CHAIN_B'][s] for s in FB['CHAIN_B']}
    return dict(VAR_CONFIG=FB['VAR_CONFIG'], gridX=FB['grid_X'], gridY=FB['grid_Y'],
                bathy_chain=FB['bathy_chain'], bathy_plot=B_bp, depth_max_plot=B_dmp,
                xlim=(FB['XLIM_HI'], FB['XLIM_LO']), chain_fn=lambda s: FB['CHAIN_B'].get(s, np.nan),
                build_fn=lambda p,v: FB['build_cross_section'](p, v, FB['bathy_chain'], B_bd, {s:FB['CHAIN_B'][s] for s in p if s in FB['CHAIN_B']}))

def run_B(jdays):
    od = OUT_BASE/'TransectB'; od.mkdir(exist_ok=True); outs=[]
    for jday in jdays:
        fp = {s:p for s,p in B_day_profiles[jday].items() if s in FB['CHAIN_B']}
        if len(fp) < 2: print(f'B jday {jday}: {len(fp)} field — skip'); continue
        cal = datetime(1994,1,1) + timedelta(days=jday-1)
        md = snap_or_none(pd.Timestamp(cal.replace(hour=12)))
        mp = model_profiles(FB['COORDS'], FB['TRANSECT_BY_JDAY'][jday], md)
        mp = {s:p for s,p in mp.items() if s in FB['CHAIN_B']}
        ttl = (f'Transect B — jday {jday:03d} ({cal.strftime("%d %b %Y")})   field {len(fp)} stns   |   '
               + (f'model {pd.Timestamp(md).strftime("%d-%b %H:%M")}' if md is not None else f'MODEL pending ({MODEL_STATUS})'))
        outs.append(make_compare(ctxB(fp), fp, mp, ttl, od/f'compare_B_jday{jday:03d}.png', show=TEST_MODE))
        print(f'  B jday {jday}: field {len(fp)}, model {len(mp)} -> saved')
    return outs

# === Transect C (jday 124 only) — single-day script ==========================
FC = load_field_prefix(TX_SCRIPTS['C'], 'fig, axes = plt.subplots')
# C's prefix builds field `profiles`, `stn_chain`, bathy at module level. Extend
# stn_chain to all TRANSECT_C so the model row can be gridded too.
FC['stn_chain'] = {s: FC['CHAIN_C'][s] for s in FC['TRANSECT_C']}
def ctxC():
    return dict(VAR_CONFIG=FC['VAR_CONFIG'], gridX=FC['grid_X'], gridY=FC['grid_Y'],
                bathy_chain=FC['bathy_chain'], bathy_plot=FC['bathy_plot'], depth_max_plot=FC['depth_max_plot'],
                xlim=(FC['XLIM_LO'], FC['XLIM_HI']), chain_fn=lambda s: FC['CHAIN_C'].get(s, np.nan),
                build_fn=lambda p,v: FC['build_cross_section'](p, v))

def run_C():
    od = OUT_BASE/'TransectC'; od.mkdir(exist_ok=True)
    jday = FC['JDAY']; fp = dict(FC['profiles'])
    if len(fp) < 2: print(f'C jday {jday}: {len(fp)} field — skip'); return []
    cal = datetime(1994,1,1) + timedelta(days=jday-1)
    md = snap_or_none(pd.Timestamp(cal.replace(hour=12)))
    mp = model_profiles(FC['COORDS'], FC['TRANSECT_C'], md)
    ttl = (f'Transect C — jday {jday:03d} ({cal.strftime("%d %b %Y")})   field {len(fp)} stns   |   '
           + (f'model {pd.Timestamp(md).strftime("%d-%b %H:%M")}' if md is not None else f'MODEL pending ({MODEL_STATUS})'))
    out = make_compare(ctxC(), fp, mp, ttl, od/f'compare_C_jday{jday:03d}.png', show=TEST_MODE)
    print(f'  C jday {jday}: field {len(fp)}, model {len(mp)} -> saved')
    return [out]

# === Generate ================================================================
if TEST_MODE:
    run_A([123]); run_B([123]); run_C()
else:
    run_A([123, 124]); run_B([123, 124]); run_C()
print('Done. Outputs under', OUT_BASE)