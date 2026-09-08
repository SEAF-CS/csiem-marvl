"""Extended surf/bot maps — IDENTICAL methodology to run_maps.py / map_salinity_prestorm.png
(kriged FIELD + points, NATIVE model, 2x2 MODEL/FIELD x surf/bot, land mask) but zoomed out +
outer winter grids (Y/V/MA/MN) added. Loops WINDOWS {prestorm, poststorm, each survey day} x
VARS {salinity, temperature}. Model blank W of OBC (~115.335). Prestorm salinity keeps the canonical
name map_salinity_prestorm_extended.png. -> outputs/maps/{var}/map_{var}_{window}_extended.png
"""
import sys, matplotlib; matplotlib.use('Agg')
import os, glob, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import xarray as xr
import matplotlib.pyplot as plt
from scipy.interpolate import griddata
import tfv.xarray

MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc')
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'
PROFILE_DIR_1991 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
OUT_BASE = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/maps')

# === machinery ===
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_prefix = _src[:_src.index('for jday in JDAYS:')].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())
profile_dir = PROFILE_DIR_1991

LON_MIN, LON_MAX = 114.85, 115.83; LAT_MIN, LAT_MAX = -32.58, -31.82
coast_gdf = gpd.read_file(COAST_SHP, bbox=(LON_MIN, LAT_MIN, LON_MAX, LAT_MAX))
land_union = unary_union(coast_gdf.geometry); land_buffered = land_union.buffer(0.003)
grid_lon = np.linspace(LON_MIN, LON_MAX, 520); grid_lat = np.linspace(LAT_MIN, LAT_MAX, 470)
GLON, GLAT = np.meshgrid(grid_lon, grid_lat); cos_lat = np.cos(np.radians((LAT_MIN+LAT_MAX)/2))
land_on_grid = contains(land_buffered, GLON, GLAT)
for locf in glob.glob(os.path.join(MAP_DIR, '*.loc')):
    for k, v in load_loc(locf).items(): COORDS.setdefault(k, v)

def read_sdl(fp):
    d = open(fp, 'rb').read()
    if len(d) < 0x420: return None
    fl = np.frombuffer(d, '>f4', count=(len(d)-0x400)//4, offset=0x400); nz = np.nonzero(fl)[0]
    for i0 in [int(i) for i in nz[:6]]:
        rem = len(fl)-i0
        for nc, (cd, cs, cr, ct) in ((10, (4, 2, 3, 5)), (7, (3, 1, 2, 4))):
            if rem % nc or rem//nc < 2: continue
            rec = fl[i0:].reshape(rem//nc, nc); s = rec[:, 0].astype(float)
            if not (np.all(np.diff(s) >= 1) and s[0] >= 1 and np.all(np.abs(s-np.round(s)) < 1e-3)): continue
            if not (0 < np.median(rec[:, cd]) < 300 and 5 < np.median(rec[:, ct]) < 30): continue
            dep, sal, den, tmp = rec[:, cd], rec[:, cs], rec[:, cr], rec[:, ct]
            good = (dep > 0.1) & (dep < 320) & (sal > 20) & (sal < 40) & (tmp > 5) & (tmp < 30)
            if good.sum() < 3: return None
            return {'depth': dep[good], 'salinity': sal[good], 'temperature': tmp[good], 'density': den[good]}
    return None
def _fdt(fn):
    name, _, jds = fn.partition('.')
    try: jd = int(jds); hh, mm = int(name[3:5]), int(name[5:7])
    except ValueError: return None
    return datetime(1991, 1, 1) + timedelta(days=jd-1, hours=hh, minutes=mm)
def read_profiles_for_window(t0, t1):
    profs = {}
    for stn in sorted(os.listdir(profile_dir)):
        sp = os.path.join(profile_dir, stn)
        if not os.path.isdir(sp) or stn not in COORDS or stn in EXCLUDE: continue
        for fn in sorted(os.listdir(sp)):
            pf = fn[:3].lower()
            if pf not in ('dfv', 'dhv', 'dtv', 'dmv', 'dsv', 'esv'): continue
            dt = _fdt(fn)
            if dt is None or not (t0 <= dt <= t1): continue
            fp = os.path.join(sp, fn)
            if pf == 'dfv': r, sc = read_dfv(fp), 'DFV'
            elif pf in ('dhv', 'dtv'): r, sc = read_dhv_dtv(fp), pf.upper()
            elif pf == 'dmv': r, sc = read_dmv(fp), 'DMV'
            else: r, sc = read_sdl(fp), 'SDL'
            if r is None: continue
            if stn not in profs or (profs[stn][1] != 'DFV' and sc == 'DFV'): profs[stn] = (r, sc)
    return profs
def field_sb_data(profiles, var_key):
    surf, bot = {}, {}
    for stn, (r, sc) in profiles.items():
        if var_key not in r: continue
        lat, lon = COORDS[stn]; sv, bv = extract_surface_bottom(r, sc, var_key)
        if sv is not None: surf[stn] = (lat, lon, sv, sc)
        if bv is not None: bot[stn] = (lat, lon, bv, sc)
    return surf, bot

# === variables ===
VARS = {
    'salinity':    dict(mvar='SAL', fkey='salinity', levels=np.arange(34.0, 35.6, 0.25),
                        cmap=plt.cm.RdYlBu_r, fmt='%.1f', cbar='Salinity (psu)'),
    'temperature': dict(mvar='TEMP', fkey='temperature', levels=np.arange(15.0, 20.6, 0.5),
                        cmap=plt.cm.coolwarm, fmt='%.1f', cbar='Temperature (°C)'),
}

# === model native surf/bot on grid ===
ds = xr.open_dataset(MODEL_NC); fv = ds.tfv
tm = pd.to_datetime(ds['Time'].values); cellx, celly = ds['cell_X'].values, ds['cell_Y'].values
def snap_time(mid): return tm[int(np.argmin(np.abs(tm - pd.Timestamp(mid))))]
def model_grid(model_date, mvar, where):
    datum = 'depth' if where == 'surface' else 'height'
    s = fv.get_sheet([mvar], time=model_date, datum=datum, limits=(0, 2), agg='mean')
    vals = np.asarray(s[mvar]).ravel().astype('float64'); ok = np.isfinite(vals)
    z = griddata((cellx[ok], celly[ok]), vals[ok], (GLON, GLAT), method='linear')
    zm = np.ma.array(z, mask=~np.isfinite(z)); zm[land_on_grid] = np.ma.masked; return zm

def _panel(ax, z, lev, cmap, fmt, markers=None, desc=None, title=None):
    ax.set_facecolor('#e8e8e8'); cf = None
    if z is not None:
        cf = ax.contourf(GLON, GLAT, z, levels=lev, cmap=cmap, alpha=0.9, extend='both')
        cl = ax.contour(GLON, GLAT, z, levels=lev, colors='k', linewidths=0.4, alpha=0.5); ax.clabel(cl, inline=True, fontsize=7, fmt=fmt)
    for geom in coast_gdf.geometry:
        polys = [geom] if geom.geom_type == 'Polygon' else (list(geom.geoms) if geom.geom_type == 'MultiPolygon' else [])
        for poly in polys:
            xs, ys = poly.exterior.xy; ax.fill(xs, ys, facecolor='#c4a882', edgecolor='#7a5c3a', lw=0.5, zorder=8)
    if markers is not None:
        pl, pa, pv, pt = markers
        for i in range(len(pl)):
            mk = markers_dfv if pt[i] == 'DFV' else markers_other
            ax.scatter(pl[i], pa[i], c=[pv[i]], cmap=cmap, s=22, zorder=10, vmin=lev[0], vmax=lev[-1], **mk)
    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX); ax.set_aspect(1/cos_lat)
    ax.grid(True, alpha=0.3); ax.tick_params(labelsize=9); ax.axvline(115.335, color='0.35', ls='--', lw=1, zorder=9)
    if title: ax.set_title(title, fontsize=10)
    if desc: ax.text(0.03, 0.03, desc, transform=ax.transAxes, fontsize=10, fontweight='bold', va='bottom',
                     bbox=dict(boxstyle='round,pad=0.35', facecolor='white', alpha=0.85, edgecolor='gray'))
    return cf

def make_map(win_label, t0, t1, vname):
    vcfg = VARS[vname]; lev, cmap, fmt = vcfg['levels'], vcfg['cmap'], vcfg['fmt']
    profiles = read_profiles_for_window(t0, t1)
    sd, bd = field_sb_data(profiles, vcfg['fkey'])
    if len(sd) < 5:
        print(f'  {win_label}/{vname}: {len(sd)} surf stns, skip'); return
    model_date = snap_time((t0 + (t1 - t0)/2).replace(minute=0))
    fs = krige_field(sd, 'Surface', None, True) if len(sd) >= 5 else None
    fb = krige_field(bd, 'Bottom', None, True) if len(bd) >= 5 else None
    zms = model_grid(model_date, vcfg['mvar'], 'surface'); zmb = model_grid(model_date, vcfg['mvar'], 'bottom')
    fig, axes = plt.subplots(2, 2, figsize=(13.5, 15), sharex=True, sharey=True)
    cf = _panel(axes[0, 0], zms, lev, cmap, fmt, desc='MODEL\nSurface (top 2m)', title='Surface')
    _panel(axes[0, 1], zmb, lev, cmap, fmt, desc='MODEL\nBottom (bot 2m)', title='Bottom')
    fmk = None if fs is None else (fs[1], fs[2], fs[3], fs[5]); bmk = None if fb is None else (fb[1], fb[2], fb[3], fb[5])
    cff = _panel(axes[1, 0], fs[0] if fs else None, lev, cmap, fmt, markers=fmk, desc='FIELD\nSurface (top 2m)')
    _panel(axes[1, 1], fb[0] if fb else None, lev, cmap, fmt, markers=bmk, desc='FIELD\nBottom (bot 2m)')
    for ax in (axes[0, 1], axes[1, 1]): ax.tick_params(axis='y', labelleft=False)
    for ax in (axes[0, 0], axes[0, 1]): ax.tick_params(axis='x', labelbottom=False)
    win = f'{t0.strftime("%d-%b %H:%M")} – {t1.strftime("%d-%b %H:%M")}'
    fig.suptitle(f'1991 EXTENDED maps — {vname.capitalize()} — {win_label.upper()}  ({win})\n'
                 f'{len(profiles)} field stns (core + Y/V/MA/MN)   |   model snapshot '
                 f'{pd.Timestamp(model_date).strftime("%d-%b %H:%M")}   (dashed = OBC)',
                 fontsize=13, fontweight='bold', y=0.99)
    plt.subplots_adjust(left=0.06, right=0.88, bottom=0.04, top=0.95, wspace=0.06, hspace=0.06)
    mp = cf if cf is not None else cff
    cax = fig.add_axes([0.90, 0.30, 0.015, 0.40]); fig.colorbar(mp, cax=cax).set_label(vcfg['cbar'], fontsize=11)
    od = OUT_BASE / vname; od.mkdir(parents=True, exist_ok=True)
    fn = od / f'map_{vname}_{win_label}_extended.png'
    fig.savefig(fn, dpi=200, bbox_inches='tight'); plt.close(fig); print('  wrote', fn.name)

# === windows: prestorm, poststorm, + each survey day ===
WINDOWS = [('prestorm', datetime(1991, 8, 13, 15, 36), datetime(1991, 8, 17, 15, 46)),
           ('poststorm', datetime(1991, 8, 20, 7, 48), datetime(1991, 8, 23, 1, 59))]
for d in range(13, 24):   # 13–23 Aug per-day
    day = datetime(1991, 8, d)
    WINDOWS.append((f'day{d:02d}', day, day + timedelta(hours=23, minutes=59)))

for wlab, t0, t1 in WINDOWS:
    for vname in VARS:
        try:
            make_map(wlab, t0, t1, vname)
        except Exception as e:
            print(f'  ERROR {wlab}/{vname}: {type(e).__name__}: {e}')
print('done')
