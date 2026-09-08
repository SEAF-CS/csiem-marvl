# Auto-assembled headless runner from sheet_maps_1992_March.ipynb (REV config).
# Regenerates outputs_1992_March_maps_rev/ from the re-run 1992 model output.
import matplotlib
matplotlib.use('Agg')   # force non-interactive backend (notebook strips the Agg call)

# === Imports, EOS-80, config =================================================
import os, numpy as np, pandas as pd
from pathlib import Path
from datetime import timedelta
import xarray as xr
import matplotlib.pyplot as plt
from scipy.interpolate import griddata
import tfv.xarray

MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc')  # REV
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'
OUT_BASE = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1992/outputs/maps')  # REV
OUT_BASE.mkdir(parents=True, exist_ok=True)

TEST_MODE = False   # FULL run: all survey days x all variables

# model variable name per field variable
MODEL_VAR = {'salinity': 'SAL', 'temperature': 'TEMP', 'density': 'RHOW'}

def eos80_potential_density(S, T):
    T2,T3,T4,T5 = T*T,T*T*T,T*T*T*T,T*T*T*T*T
    Ssq = np.sqrt(np.clip(S,0,None)); S1p5 = S*Ssq; S2 = S*S
    a=[999.842594,6.793952e-2,-9.095290e-3,1.001685e-4,-1.120083e-6,6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b=[8.24493e-1,-4.0899e-3,7.6438e-5,-8.2467e-7,5.3875e-9]
    c=[-5.72466e-3,1.0227e-4,-1.6546e-6]; d0=4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2

# === Reuse the canonical field map machinery =================================
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_marker = 'for jday in JDAYS:'
_prefix = _src[:_src.index(_marker)].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())
print('Field map machinery loaded:', len(COORDS), 'coords,', len(JDAYS), 'survey days')
print('Domain lon', LON_MIN, LON_MAX, '| lat', LAT_MIN, LAT_MAX, '| grid', GLON.shape)

# === Field surface/bottom data for a jday (mirrors contour script loop) ======
def read_profiles_for_jday(jday):
    suffix = f'.{jday:03d}'; profiles = {}
    for stn_dir in sorted(os.listdir(profile_dir)):
        sp = os.path.join(profile_dir, stn_dir)
        if not os.path.isdir(sp) or stn_dir not in COORDS or stn_dir in EXCLUDE:
            continue
        for fn in sorted(os.listdir(sp)):
            if not fn.endswith(suffix):
                continue
            prefix = fn.split('.')[0][:3]; fpath = os.path.join(sp, fn)
            if prefix == 'dfv':      result, src = read_dfv(fpath), 'DFV'
            elif prefix in ('dhv','dtv'): result, src = read_dhv_dtv(fpath), prefix.upper()
            elif prefix == 'dmv':    result, src = read_dmv(fpath), 'DMV'
            else: continue
            if result is None: continue
            if stn_dir not in profiles or profiles[stn_dir][1] != 'DFV':
                profiles[stn_dir] = (result, src)
            break
    return profiles

def field_sb_data(profiles, var_key):
    surf, bot = {}, {}
    for stn, (result, src) in profiles.items():
        lat, lon = COORDS[stn]
        sv, bv = extract_surface_bottom(result, src, var_key)
        if sv is not None: surf[stn] = (lat, lon, sv, src)
        if bv is not None: bot[stn] = (lat, lon, bv, src)
    return surf, bot

# === Model: open NC, native surface/bottom field on grid =====================
# (density is derived per-snapshot from the S,T sheet in model_field_on_grid --
#  never build a full-field RHOW: on the hourly NC that is a 5.7 GiB alloc -> OOM)
ds = xr.open_dataset(MODEL_NC)
fv = ds.tfv
times_model = pd.to_datetime(ds['Time'].values)
tmin, tmax = times_model.min(), times_model.max()
cellx, celly = ds['cell_X'].values, ds['cell_Y'].values

def snap_time(mid):
    return times_model[int(np.argmin(np.abs(times_model - mid)))]

def model_field_on_grid(model_date, model_var, where):
    """where='surface' -> top-2m mean; 'bottom' -> bottom-2m mean. Returns masked grid."""
    datum = 'depth' if where == 'surface' else 'height'
    if model_var == 'RHOW':                                   # derive density from the S,T sheet (no full-field RHOW)
        s = fv.get_sheet(['SAL', 'TEMP'], time=model_date, datum=datum, limits=(0, 2), agg='mean')
        sal = np.asarray(s['SAL']).ravel().astype('float64')
        tmp = np.asarray(s['TEMP']).ravel().astype('float64')
        vals = eos80_potential_density(sal, tmp) - 1000.0     # sigma_t to match field density
    else:
        s = fv.get_sheet([model_var], time=model_date, datum=datum, limits=(0, 2), agg='mean')
        vals = np.asarray(s[model_var]).ravel().astype('float64')
    ok = np.isfinite(vals)
    z = griddata((cellx[ok], celly[ok]), vals[ok], (GLON, GLAT), method='linear')
    zm = np.ma.array(z, mask=~np.isfinite(z))
    zm[land_on_grid] = np.ma.masked
    return zm
print(f'Model {tmin} -> {tmax}; {len(cellx)} cells')

# === 2x2 figure: rows MODEL/FIELD, cols surface/bottom =======================
def _draw_panel(ax, z, levels, cmap, fmt, coast_gdf, markers=None, desc=None, title=None):
    ax.set_facecolor('#e8e8e8')
    cf = None
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

def make_map_figure(jday, var_name, save=True, show=False):
    vcfg = VAR_CONFIG[var_name]; levels = vcfg['levels']; cmap = vcfg['cmap']
    fmt = vcfg['fmt']; var_key = vcfg['key']; krig_min = vcfg['krig_min']; exact = vcfg['exact']
    cal_date = base_date + timedelta(days=jday - 1)
    model_date = snap_time(pd.Timestamp(cal_date.replace(hour=12, minute=0)))
    mvar = MODEL_VAR[var_name]

    profiles = read_profiles_for_jday(jday)
    if len(profiles) < 5:
        print(f'jday {jday:03d} {var_name}: {len(profiles)} field profiles, skipping'); return None
    sd, bd = field_sb_data(profiles, var_key)
    fs = krige_field(sd, 'Surface', krig_min, exact) if sd else None
    fb = krige_field(bd, 'Bottom', krig_min, exact) if bd else None
    zfs = fs[0] if fs is not None else None
    zfb = fb[0] if fb is not None else None

    zms = model_field_on_grid(model_date, mvar, 'surface')
    zmb = model_field_on_grid(model_date, mvar, 'bottom')

    fig, axes = plt.subplots(2, 2, figsize=(12.5, 16), sharex=True, sharey=True)
    cf = _draw_panel(axes[0,0], zms, levels, cmap, fmt, coast_gdf, desc='MODEL\nSurface (top 2m)', title='Surface')
    _draw_panel(axes[0,1], zmb, levels, cmap, fmt, coast_gdf, desc='MODEL\nBottom (bot 2m)', title='Bottom')
    fmk = None if fs is None else (fs[1], fs[2], fs[3], fs[5])
    bmk = None if fb is None else (fb[1], fb[2], fb[3], fb[5])
    cff = _draw_panel(axes[1,0], zfs, levels, cmap, fmt, coast_gdf, markers=fmk, desc='FIELD\nSurface (top 2m)')
    _draw_panel(axes[1,1], zfb, levels, cmap, fmt, coast_gdf, markers=bmk, desc='FIELD\nBottom (bot 2m)')
    for ax in (axes[0,1], axes[1,1]): ax.tick_params(axis='y', labelleft=False)
    for ax in (axes[0,0], axes[0,1]): ax.tick_params(axis='x', labelbottom=False)

    fig.suptitle(f'Transect-domain maps — {var_name.capitalize()} — jday {jday:03d} '
                 f'({cal_date.strftime("%d %b %Y")})   |   {len(profiles)} field stns   |   '
                 f'model {pd.Timestamp(model_date).strftime("%d-%b %H:%M")}',
                 fontsize=13, fontweight='bold', y=0.99)
    plt.subplots_adjust(left=0.06, right=0.88, bottom=0.04, top=0.95, wspace=0.06, hspace=0.06)
    mappable = cf if cf is not None else cff
    if mappable is not None:
        cax = fig.add_axes([0.90, 0.30, 0.015, 0.40])
        fig.colorbar(mappable, cax=cax).set_label(vcfg['cbar_label'], fontsize=11)

    out_dir = OUT_BASE / f'daily_{var_name}'; out_dir.mkdir(exist_ok=True)
    fn = out_dir / f'map_{var_name}_{jday:03d}.png'
    if save: fig.savefig(fn, dpi=200, bbox_inches='tight')
    if show: plt.show()
    else: plt.close(fig)
    return fn if save else None

# === Generate ================================================================
VARS = ['temperature', 'salinity', 'density']
jobs = [(jd, v) for jd in JDAYS for v in VARS]
if TEST_MODE:
    for jd in JDAYS:
        if len(read_profiles_for_jday(jd)) >= 5:
            jobs = [(jd, v) for v in VARS][:1]; break
print(f'{"TEST" if TEST_MODE else "FULL"} run: {len(jobs)} figure(s)')
for jd, v in jobs:
    out = make_map_figure(jd, v, save=True, show=TEST_MODE)
    if out: print(f'  saved {out.parent.name}/{out.name}')
print('Done.')
