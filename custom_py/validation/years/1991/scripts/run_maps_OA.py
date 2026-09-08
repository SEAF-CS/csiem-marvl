# Special "maps - OA" component: an Owen-Anchorage ZOOM map keyed to the TransectOA survey.
# Differs from run_maps.py (campaigns/panels) in exactly two ways:
#   (a) ONE time window  = the TransectOA profile span (08:11-12:13, 18-Aug-1991) padded +-2 h
#       -> 06:11-14:13.  NB this falls in the gap BETWEEN the prestorm (13-17) and poststorm
#          (20-23) campaign windows, so it is new coverage not shown by run_maps.py.
#   (b) a higher-resolution SPATIAL ZOOM centred on Owen Anchorage (bounding box of the 25 OA/CS
#       transect stations + pad), vs the broad full-domain campaign/panel maps.
# Everything else (2x2 MODEL/FIELD x surface/bottom, krige, model sheet, clim) is reused verbatim
# from the same field machinery run_maps.py uses.  Output -> outputs/maps/{var}/map_{var}_OA.png
# Usage: python run_maps_OA.py
import sys as _sys
import matplotlib
matplotlib.use('Agg')

import os, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import xarray as xr
import matplotlib.pyplot as plt
from scipy.interpolate import griddata
import tfv.xarray

MODEL_NC     = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc')  # REV
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'  # machinery only
OA_GEOM      = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/6-13_OATransects/plot_fig6_13_transects.py'  # OA station coords + transect times
PROFILE_DIR_1991 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
OUT_BASE     = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/maps')
OUT_BASE.mkdir(parents=True, exist_ok=True)

OA_DATE     = datetime(1991, 8, 18)   # the OA transects are all on 18-Aug-1991
WIN_PAD     = timedelta(hours=2)      # "within 2 h of the start and stop of the OA profile set"
OA_PAD_FRAC = 0.12                    # fractional padding around the OA station bounding box
GRID_N      = 300                     # zoom-grid nodes per axis (finer per-km than the broad 300x400 grid)

MODEL_VAR = {'salinity': 'SAL', 'temperature': 'TEMP', 'density': 'RHOW'}

def eos80_potential_density(S, T):
    T2,T3,T4,T5 = T*T,T*T*T,T*T*T*T,T*T*T*T*T
    Ssq = np.sqrt(np.clip(S,0,None)); S1p5 = S*Ssq; S2 = S*S
    a=[999.842594,6.793952e-2,-9.095290e-3,1.001685e-4,-1.120083e-6,6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b=[8.24493e-1,-4.0899e-3,7.6438e-5,-8.2467e-7,5.3875e-9]
    c=[-5.72466e-3,1.0227e-4,-1.6546e-6]; d0=4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2

# === Reuse the canonical field map machinery (1992 contour script) — same as run_maps.py =====
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_prefix = _src[:_src.index('for jday in JDAYS:')].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())
profile_dir = PROFILE_DIR_1991                     # <-- point the field machinery at 1991 casts
print('Field machinery loaded:', len(COORDS), 'coords | broad grid', GLON.shape,
      '| broad domain lon', LON_MIN, LON_MAX, 'lat', LAT_MIN, LAT_MAX)

# === Reuse the OA geometry (station coords + transect time windows) — same exec trick as run_transectOA ==
_g = {'__file__': OA_GEOM, '__name__': 'oa_geom'}
_s = open(OA_GEOM, encoding='utf-8').read()
exec(compile(_s[:_s.index('# --- Generate all four transects ---')], OA_GEOM, 'exec'), _g)
ALL_STATIONS = _g['ALL_STATIONS']; TRANSECTS = _g['TRANSECTS']
OA_STNS = sorted({s for info in TRANSECTS.values() for s in info['stations']})

# --- OA time window: span of the four transect windows, padded +-2 h ---
def _hhmm(s): return int(s[:2]), int(s[2:])
_starts, _stops = [], []
for info in TRANSECTS.values():
    a, b = info['time'].replace('–', '-').split('-')
    ha, ma = _hhmm(a); hb, mb = _hhmm(b)
    _starts.append(OA_DATE.replace(hour=ha, minute=ma)); _stops.append(OA_DATE.replace(hour=hb, minute=mb))
OA_T0, OA_T1 = min(_starts) - WIN_PAD, max(_stops) + WIN_PAD
print(f'OA transect span {min(_starts):%d-%b %H:%M}..{max(_stops):%H:%M}  ->  map window '
      f'{OA_T0:%d-%b %H:%M}..{OA_T1:%H:%M}  (+-2 h)')

# --- OA zoom box: bounding box of the transect stations + fractional pad ---
_lons = [ALL_STATIONS[s]['lon'] for s in OA_STNS]; _lats = [ALL_STATIONS[s]['lat'] for s in OA_STNS]
_lpad = (max(_lons) - min(_lons)) * OA_PAD_FRAC; _apad = (max(_lats) - min(_lats)) * OA_PAD_FRAC

# Make the OA station coords authoritative so read_profiles_for_window finds the 18-Aug casts,
# and drop the 1992-context EXCLUDE so every OA cast in-box is usable.
for s in OA_STNS:
    COORDS[s] = (ALL_STATIONS[s]['lat'], ALL_STATIONS[s]['lon'])
EXCLUDE = set()

# === Rebuild the field-machinery grid globals for the high-res OA zoom =======================
# krige_field / model_field_on_grid / _draw_panel all read these as module globals at call time,
# so reassigning them here repoints the whole machinery at the zoomed, higher-resolution grid.
LON_MIN, LON_MAX = min(_lons) - _lpad, max(_lons) + _lpad
LAT_MIN, LAT_MAX = min(_lats) - _apad, max(_lats) + _apad
grid_lon = np.linspace(LON_MIN, LON_MAX, GRID_N)
grid_lat = np.linspace(LAT_MIN, LAT_MAX, GRID_N)
GLON, GLAT = np.meshgrid(grid_lon, grid_lat)
cos_lat = np.cos(np.radians((LAT_MIN + LAT_MAX) / 2))
land_on_grid = contains(land_buffered, GLON, GLAT)
print(f'OA zoom: lon {LON_MIN:.4f}..{LON_MAX:.4f}  lat {LAT_MIN:.4f}..{LAT_MAX:.4f}  '
      f'grid {GLON.shape}  ({len(OA_STNS)} OA/CS stations)')

# === Field cast loader BY TIME WINDOW (1991) — copied from run_maps.py =======================
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

# === CLIM from the OA-window, in-box field data (mirrors run_maps.py) =========================
def _nice_levels(vals, step, pad_lo=0.0, pad_hi=0.0):
    lo = np.floor((np.nanpercentile(vals, 2) - pad_lo) / step) * step
    hi = np.ceil((np.nanpercentile(vals, 98) + pad_hi) / step) * step
    return np.arange(lo, hi + step/2, step)

CLIM_STEP = {'salinity': 0.25, 'temperature': 0.25, 'density': 0.2}
_profs0 = read_profiles_for_window(OA_T0, OA_T1)
for _vn in MODEL_VAR:
    _sd, _bd = field_sb_data(_profs0, _vn)
    arr = np.array([d[2] for d in _sd.values()] + [d[2] for d in _bd.values()], float)
    arr = arr[np.isfinite(arr)]
    if len(arr) >= 5:
        VAR_CONFIG[_vn]['levels'] = _nice_levels(arr, CLIM_STEP[_vn])
        VAR_CONFIG[_vn]['krig_min'] = None
    print(f"{_vn:12s} n={len(arr):4d}  clim {VAR_CONFIG[_vn]['levels'][0]:.2f}..{VAR_CONFIG[_vn]['levels'][-1]:.2f}")

# === Model: open NC, inject density, native surface/bottom field on grid (copied) ============
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

# === 2x2 figure: rows MODEL/FIELD, cols surface/bottom (copied from run_maps.py) =============
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
            ax.scatter(p_lons[i], p_lats[i], c=[p_vals[i]], cmap=cmap, s=40, zorder=10,
                       vmin=levels[0], vmax=levels[-1], **mk)
    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX)
    ax.set_aspect(1 / np.cos(np.radians((LAT_MIN + LAT_MAX) / 2)))
    ax.grid(True, alpha=0.3); ax.tick_params(labelsize=9)
    if title: ax.set_title(title, fontsize=10)
    if desc:
        ax.text(0.03, 0.03, desc, transform=ax.transAxes, fontsize=10, fontweight='bold', va='bottom',
                bbox=dict(boxstyle='round,pad=0.35', facecolor='white', alpha=0.85, edgecolor='gray'))
    return cf

def make_map_figure(t0, t1, var_name, save=True):
    vcfg = VAR_CONFIG[var_name]; levels = vcfg['levels']; cmap = vcfg['cmap']
    fmt = vcfg['fmt']; var_key = vcfg['key']; krig_min = vcfg['krig_min']; exact = vcfg['exact']
    mvar = MODEL_VAR[var_name]
    mid = t0 + (t1 - t0) / 2
    model_date = snap_time(mid.replace(minute=0))

    profiles = read_profiles_for_window(t0, t1)
    if len(profiles) < 5:
        print(f'OA {var_name}: {len(profiles)} field profiles, skipping'); return None
    sd, bd = field_sb_data(profiles, var_key)
    fs = krige_field(sd, 'Surface', krig_min, exact) if len(sd) >= 5 else None
    fb = krige_field(bd, 'Bottom', krig_min, exact) if len(bd) >= 5 else None
    zfs = fs[0] if fs is not None else None
    zfb = fb[0] if fb is not None else None
    zms = model_field_on_grid(model_date, mvar, 'surface')
    zmb = model_field_on_grid(model_date, mvar, 'bottom')

    fig, axes = plt.subplots(2, 2, figsize=(13, 13.5), sharex=True, sharey=True)
    cf = _draw_panel(axes[0,0], zms, levels, cmap, fmt, desc='MODEL\nSurface (top 2m)', title='Surface')
    _draw_panel(axes[0,1], zmb, levels, cmap, fmt, desc='MODEL\nBottom (bot 2m)', title='Bottom')
    fmk = None if fs is None else (fs[1], fs[2], fs[3], fs[5])
    bmk = None if fb is None else (fb[1], fb[2], fb[3], fb[5])
    cff = _draw_panel(axes[1,0], zfs, levels, cmap, fmt, markers=fmk, desc='FIELD\nSurface (top 2m)')
    _draw_panel(axes[1,1], zfb, levels, cmap, fmt, markers=bmk, desc='FIELD\nBottom (bot 2m)')
    for ax in (axes[0,1], axes[1,1]): ax.tick_params(axis='y', labelleft=False)
    for ax in (axes[0,0], axes[0,1]): ax.tick_params(axis='x', labelbottom=False)

    win = f'{t0.strftime("%d-%b %H:%M")} - {t1.strftime("%d-%b %H:%M")}'
    fig.suptitle(f'1991 Owen Anchorage ZOOM map (TransectOA window) - {var_name.capitalize()}  ({win})\n'
                 f'{len(profiles)} field stns over window   |   model snapshot '
                 f'{pd.Timestamp(model_date).strftime("%d-%b %H:%M")}',
                 fontsize=13, fontweight='bold', y=0.99)
    plt.subplots_adjust(left=0.07, right=0.87, bottom=0.05, top=0.94, wspace=0.06, hspace=0.06)
    mappable = cf if cf is not None else cff
    if mappable is not None:
        cax = fig.add_axes([0.89, 0.30, 0.015, 0.40])
        fig.colorbar(mappable, cax=cax).set_label(vcfg['cbar_label'], fontsize=11)

    out_dir = OUT_BASE / var_name; out_dir.mkdir(exist_ok=True)
    fn = out_dir / f'map_{var_name}_OA.png'
    if save: fig.savefig(fn, dpi=200, bbox_inches='tight')
    plt.close(fig)
    return fn if save else None

# === Generate (one OA window x 3 vars) =======================================================
VARS = ['temperature', 'salinity', 'density']
print(f'OA run: {len(VARS)} figure(s)')
for v in VARS:
    out = make_map_figure(OA_T0, OA_T1, v, save=True)
    if out: print(f'  saved {out.parent.name}/{out.name}')
print('Done.')
