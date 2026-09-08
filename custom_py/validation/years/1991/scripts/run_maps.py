# Auto-assembled headless runner from sheet_maps_1991_transects.ipynb (REV config).
# Regenerates outputs_1991_transect_maps_rev/{var}/ from the re-run 1991 model output.
# Usage: python _run_maps_1991_rev.py [panels|campaigns]   (default panels)
import sys as _sys
import matplotlib
matplotlib.use('Agg')

# === Imports, EOS-80, config =================================================
import os, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import xarray as xr
import matplotlib.pyplot as plt
from scipy.interpolate import griddata
import tfv.xarray

MODEL_NC   = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc')  # REV
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'  # machinery only
PROFILE_DIR_1991 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
OUT_BASE   = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/maps')  # REV
OUT_BASE.mkdir(parents=True, exist_ok=True)

TEST_MODE = False   # FULL run

PANEL_WINDOWS = [
    ('6.16a', datetime(1991,8,13,15,36), datetime(1991,8,13,17,27)),
    ('6.16b', datetime(1991,8,13,20,9),  datetime(1991,8,14,0,25)),
    ('6.16c', datetime(1991,8,14,11,50), datetime(1991,8,14,17,32)),
    ('6.16d', datetime(1991,8,14,21,16), datetime(1991,8,15,0,59)),
    ('6.16e', datetime(1991,8,15,9,39),  datetime(1991,8,15,15,50)),
    ('6.16f', datetime(1991,8,15,19,20), datetime(1991,8,15,20,48)),
    ('6.16g', datetime(1991,8,16,0,29),  datetime(1991,8,16,1,35)),
    ('6.16h', datetime(1991,8,16,11,39), datetime(1991,8,16,13,35)),
    ('6.16i', datetime(1991,8,16,19,4),  datetime(1991,8,16,23,32)),
    ('6.16j', datetime(1991,8,17,1,44),  datetime(1991,8,17,2,41)),
    ('6.16k', datetime(1991,8,17,10,25), datetime(1991,8,17,11,50)),
    ('6.16l', datetime(1991,8,17,11,50), datetime(1991,8,17,15,46)),
    ('6.17a', datetime(1991,8,20,7,48),  datetime(1991,8,20,10,9)),
    ('6.17b', datetime(1991,8,20,19,31), datetime(1991,8,20,22,47)),
    ('6.17c', datetime(1991,8,21,2,27),  datetime(1991,8,21,3,13)),
    ('6.17d', datetime(1991,8,21,7,51),  datetime(1991,8,21,10,32)),
    ('6.17e', datetime(1991,8,21,18,50), datetime(1991,8,21,21,47)),
    ('6.17f', datetime(1991,8,22,0,45),  datetime(1991,8,22,2,37)),
    ('6.17g', datetime(1991,8,22,13,4),  datetime(1991,8,22,17,10)),
    ('6.17h', datetime(1991,8,22,23,1),  datetime(1991,8,23,1,59)),
]
CAMPAIGN_WINDOWS = [
    ('prestorm',  datetime(1991, 8, 13, 15, 36), datetime(1991, 8, 17, 15, 46)),
    ('poststorm', datetime(1991, 8, 20,  7, 48), datetime(1991, 8, 23,  1, 59)),
]
WINDOW_MODE = _sys.argv[1] if len(_sys.argv) > 1 else 'panels'   # 'panels' or 'campaigns'
WINDOWS = PANEL_WINDOWS if WINDOW_MODE == 'panels' else CAMPAIGN_WINDOWS
print(f'WINDOW_MODE={WINDOW_MODE}  ({len(WINDOWS)} windows)')

MODEL_VAR = {'salinity': 'SAL', 'temperature': 'TEMP', 'density': 'RHOW'}

def eos80_potential_density(S, T):
    T2,T3,T4,T5 = T*T,T*T*T,T*T*T*T,T*T*T*T*T
    Ssq = np.sqrt(np.clip(S,0,None)); S1p5 = S*Ssq; S2 = S*S
    a=[999.842594,6.793952e-2,-9.095290e-3,1.001685e-4,-1.120083e-6,6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b=[8.24493e-1,-4.0899e-3,7.6438e-5,-8.2467e-7,5.3875e-9]
    c=[-5.72466e-3,1.0227e-4,-1.6546e-6]; d0=4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2

# === Reuse the canonical field map machinery (1992 contour script) ===========
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_prefix = _src[:_src.index('for jday in JDAYS:')].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())
profile_dir = PROFILE_DIR_1991                     # <-- point the field machinery at 1991 casts
print('Field machinery loaded:', len(COORDS), 'coords | grid', GLON.shape,
      '| domain lon', LON_MIN, LON_MAX, 'lat', LAT_MIN, LAT_MAX)
print('profile_dir ->', profile_dir)

# === Field cast loader BY TIME WINDOW (1991) =================================
def _fname_dt(fn):
    name, _, jds = fn.partition('.')
    try:
        jday = int(jds); hh, mm = int(name[3:5]), int(name[5:7])
    except ValueError:
        return None
    return datetime(1991, 1, 1) + timedelta(days=jday - 1, hours=hh, minutes=mm)

def read_profiles_for_window(t0, t1):
    profiles = {}
    for stn in sorted(os.listdir(profile_dir)):
        sp = os.path.join(profile_dir, stn)
        if not os.path.isdir(sp) or stn not in COORDS or stn in EXCLUDE:
            continue
        for fn in sorted(os.listdir(sp)):
            prefix = fn[:3].lower()
            if prefix not in ('dfv', 'dhv', 'dtv', 'dmv'):
                continue
            dt = _fname_dt(fn)
            if dt is None or not (t0 <= dt <= t1):
                continue
            fpath = os.path.join(sp, fn)
            if prefix == 'dfv':            result, src = read_dfv(fpath), 'DFV'
            elif prefix in ('dhv','dtv'):  result, src = read_dhv_dtv(fpath), prefix.upper()
            else:                          result, src = read_dmv(fpath), 'DMV'
            if result is None:
                continue
            if stn not in profiles or (profiles[stn][1] != 'DFV' and src == 'DFV'):
                profiles[stn] = (result, src)
    return profiles

def field_sb_data(profiles, var_key):
    surf, bot = {}, {}
    for stn, (result, src) in profiles.items():
        if var_key not in result:
            continue
        lat, lon = COORDS[stn]
        sv, bv = extract_surface_bottom(result, src, var_key)
        if sv is not None: surf[stn] = (lat, lon, sv, src)
        if bv is not None: bot[stn] = (lat, lon, bv, src)
    return surf, bot

# === Winter CLIM update — set levels from the 1991 field data in-domain ======
def _nice_levels(vals, step, pad_lo=0.0, pad_hi=0.0):
    lo = np.floor((np.nanpercentile(vals, 2) - pad_lo) / step) * step
    hi = np.ceil((np.nanpercentile(vals, 98) + pad_hi) / step) * step
    return np.arange(lo, hi + step/2, step)

CLIM_STEP = {'salinity': 0.25, 'temperature': 0.25, 'density': 0.2}
_pool = {v: [] for v in MODEL_VAR}
for _lab, _t0, _t1 in WINDOWS:
    _profs = read_profiles_for_window(_t0, _t1)
    for _vn, _vk in [('salinity','salinity'),('temperature','temperature'),('density','density')]:
        _sd, _bd = field_sb_data(_profs, _vk)
        _pool[_vn] += [d[2] for d in _sd.values()] + [d[2] for d in _bd.values()]
for _vn in MODEL_VAR:
    arr = np.array(_pool[_vn], float)
    if len(arr) >= 5:
        VAR_CONFIG[_vn]['levels'] = _nice_levels(arr, CLIM_STEP[_vn])
        VAR_CONFIG[_vn]['krig_min'] = None
    print(f"{_vn:12s} n={len(arr):4d}  clim {VAR_CONFIG[_vn]['levels'][0]:.2f}..{VAR_CONFIG[_vn]['levels'][-1]:.2f}")

# === Model: open NC, inject density, native surface/bottom field on grid =====
ds = xr.open_dataset(MODEL_NC)
fv = ds.tfv   # density derived per-snapshot from S,T sheet (no full-field RHOW)
times_model = pd.to_datetime(ds['Time'].values)
cellx, celly = ds['cell_X'].values, ds['cell_Y'].values
def snap_time(mid):
    return times_model[int(np.argmin(np.abs(times_model - pd.Timestamp(mid))))]

def model_field_on_grid(model_date, model_var, where):
    datum = 'depth' if where == 'surface' else 'height'
    if model_var == 'RHOW':                                   # derive density from S,T sheet (no full-field RHOW)
        s = fv.get_sheet(['SAL', 'TEMP'], time=model_date, datum=datum, limits=(0, 2), agg='mean')
        vals = eos80_potential_density(np.asarray(s['SAL']).ravel().astype('float64'),
                                       np.asarray(s['TEMP']).ravel().astype('float64')) - 1000.0
    else:
        s = fv.get_sheet([model_var], time=model_date, datum=datum, limits=(0, 2), agg='mean')
        vals = np.asarray(s[model_var]).ravel().astype('float64')
    ok = np.isfinite(vals)
    z = griddata((cellx[ok], celly[ok]), vals[ok], (GLON, GLAT), method='linear')
    zm = np.ma.array(z, mask=~np.isfinite(z))
    zm[land_on_grid] = np.ma.masked
    return zm
print(f'Model {times_model.min()} -> {times_model.max()}; {len(cellx)} cells')

# === 2x2 figure: rows MODEL/FIELD, cols surface/bottom =======================
def _draw_panel(ax, z, levels, cmap, fmt, markers=None, desc=None, title=None):
    ax.set_facecolor('#e8e8e8'); cf = None
    if z is not None:
        cf = ax.contourf(GLON, GLAT, z, levels=levels, cmap=cmap, alpha=0.9, extend='both')
        cl = ax.contour(GLON, GLAT, z, levels=levels, colors='black', linewidths=0.4, alpha=0.5)
        ax.clabel(cl, inline=True, fontsize=7, fmt=fmt)
    for geom in coast_gdf.geometry:
        polys = [geom] if geom.geom_type == 'Polygon' else (list(geom.geoms) if geom.geom_type == 'MultiPolygon' else [])
        for poly in polys:
            xs, ys = poly.exterior.xy
            ax.fill(xs, ys, facecolor='#c4a882', edgecolor='#7a5c3a', linewidth=0.5, zorder=8)
    if markers is not None:
        p_lons, p_lats, p_vals, p_types = markers
        for i in range(len(p_lons)):
            mk = markers_dfv if p_types[i] == 'DFV' else markers_other
            ax.scatter(p_lons[i], p_lats[i], c=[p_vals[i]], cmap=cmap, s=28, zorder=10,
                       vmin=levels[0], vmax=levels[-1], **mk)
    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX)
    ax.set_aspect(1 / np.cos(np.radians((LAT_MIN + LAT_MAX) / 2)))
    ax.grid(True, alpha=0.3); ax.tick_params(labelsize=9)
    if title: ax.set_title(title, fontsize=10)
    if desc:
        ax.text(0.03, 0.03, desc, transform=ax.transAxes, fontsize=10, fontweight='bold', va='bottom',
                bbox=dict(boxstyle='round,pad=0.35', facecolor='white', alpha=0.85, edgecolor='gray'))
    return cf

def make_map_figure(win_label, t0, t1, var_name, save=True, show=False):
    vcfg = VAR_CONFIG[var_name]; levels = vcfg['levels']; cmap = vcfg['cmap']
    fmt = vcfg['fmt']; var_key = vcfg['key']; krig_min = vcfg['krig_min']; exact = vcfg['exact']
    mvar = MODEL_VAR[var_name]
    mid = t0 + (t1 - t0) / 2
    model_date = snap_time(mid.replace(minute=0))

    profiles = read_profiles_for_window(t0, t1)
    if len(profiles) < 5:
        print(f'{win_label} {var_name}: {len(profiles)} field profiles, skipping'); return None
    sd, bd = field_sb_data(profiles, var_key)
    fs = krige_field(sd, 'Surface', krig_min, exact) if len(sd) >= 5 else None
    fb = krige_field(bd, 'Bottom', krig_min, exact) if len(bd) >= 5 else None
    zfs = fs[0] if fs is not None else None
    zfb = fb[0] if fb is not None else None
    zms = model_field_on_grid(model_date, mvar, 'surface')
    zmb = model_field_on_grid(model_date, mvar, 'bottom')

    fig, axes = plt.subplots(2, 2, figsize=(12.5, 16), sharex=True, sharey=True)
    cf = _draw_panel(axes[0,0], zms, levels, cmap, fmt, desc='MODEL\nSurface (top 2m)', title='Surface')
    _draw_panel(axes[0,1], zmb, levels, cmap, fmt, desc='MODEL\nBottom (bot 2m)', title='Bottom')
    fmk = None if fs is None else (fs[1], fs[2], fs[3], fs[5])
    bmk = None if fb is None else (fb[1], fb[2], fb[3], fb[5])
    cff = _draw_panel(axes[1,0], zfs, levels, cmap, fmt, markers=fmk, desc='FIELD\nSurface (top 2m)')
    _draw_panel(axes[1,1], zfb, levels, cmap, fmt, markers=bmk, desc='FIELD\nBottom (bot 2m)')
    for ax in (axes[0,1], axes[1,1]): ax.tick_params(axis='y', labelleft=False)
    for ax in (axes[0,0], axes[0,1]): ax.tick_params(axis='x', labelbottom=False)

    win = f'{t0.strftime("%d-%b %H:%M")} – {t1.strftime("%d-%b %H:%M")}'
    fig.suptitle(f'1991 transect maps — {var_name.capitalize()} — {win_label.upper()}  ({win})\n'
                 f'{len(profiles)} field stns over window   |   model snapshot '
                 f'{pd.Timestamp(model_date).strftime("%d-%b %H:%M")}',
                 fontsize=13, fontweight='bold', y=0.99)
    plt.subplots_adjust(left=0.06, right=0.88, bottom=0.04, top=0.95, wspace=0.06, hspace=0.06)
    mappable = cf if cf is not None else cff
    if mappable is not None:
        cax = fig.add_axes([0.90, 0.30, 0.015, 0.40])
        fig.colorbar(mappable, cax=cax).set_label(vcfg['cbar_label'], fontsize=11)

    out_dir = OUT_BASE / var_name; out_dir.mkdir(exist_ok=True)
    fn = out_dir / f'map_{var_name}_{win_label.replace(".", "")}.png'
    if save: fig.savefig(fn, dpi=200, bbox_inches='tight')
    if show: plt.show()
    else: plt.close(fig)
    return fn if save else None

# === Generate ================================================================
VARS = ['temperature', 'salinity', 'density']
if TEST_MODE:
    jobs = []
    for w in WINDOWS:
        if len(read_profiles_for_window(w[1], w[2])) >= 5:
            jobs = [(w, 'salinity')]; break
else:
    jobs = [(w, v) for w in WINDOWS for v in VARS]
print(f'{"TEST" if TEST_MODE else "FULL"} run [{WINDOW_MODE}]: {len(jobs)} figure(s)')
for (wlab, t0, t1), v in jobs:
    out = make_map_figure(wlab, t0, t1, v, save=True, show=TEST_MODE)
    if out: print(f'  saved {out.parent.name}/{out.name}')
print('Done.')
