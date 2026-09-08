"""Surface MODEL | FIELD | ROMS comparison on a SINGLE day (the V-transect day, 14 Aug 1991),
S and T, extended domain — to test whether the ROMS/TUFLOW divergence is a ROMS bias (S6corr).
Same kriged-field + native-model methodology as map_salinity_prestorm_extended.py; ROMS added as a
native 3rd panel (its own lon/lat grid, surface level). 2 rows (S,T) x 3 cols (MODEL/FIELD/ROMS).
-> outputs/diagnostics/map_surface_MFR_{day}.png
"""
import sys, matplotlib; matplotlib.use('Agg')
import os, glob, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.interpolate import griddata
import tfv.xarray

MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc')
ROMS_NC = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/CLIMATOLOGY/ROMS_UTC+8_19901001_19911231_climatology_S6corr.nc'
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'
PROFILE_DIR_1991 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
OUT_DIR = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics')
DAY = datetime.strptime(sys.argv[1], '%Y-%m-%d') if len(sys.argv) > 1 else datetime(1991, 8, 14)  # V-transect day (arg YYYY-MM-DD; default 14-Aug pre-storm, 21-Aug = post-storm)
PHASE = 'PRE-STORM' if DAY < datetime(1991, 8, 18) else 'POST-STORM'   # storm survey = 18 Aug 1991
D0, D1 = DAY, DAY + timedelta(hours=23, minutes=59)

# === machinery (COORDS, readers, krige_field, coast/grid) ===
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_prefix = _src[:_src.index('for jday in JDAYS:')].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())
profile_dir = PROFILE_DIR_1991

LON_MIN, LON_MAX = 114.85, 115.83; LAT_MIN, LAT_MAX = -32.58, -31.82
coast_gdf = gpd.read_file(COAST_SHP, bbox=(LON_MIN, LAT_MIN, LON_MAX, LAT_MAX))
land_union = unary_union(coast_gdf.geometry); land_buffered = land_union.buffer(0.003)
grid_lon = np.linspace(LON_MIN, LON_MAX, 460); grid_lat = np.linspace(LAT_MIN, LAT_MAX, 420)
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
def field_surf(profiles, var_key):
    surf = {}
    for stn, (r, sc) in profiles.items():
        if var_key not in r: continue
        lat, lon = COORDS[stn]; sv, _ = extract_surface_bottom(r, sc, var_key)
        if sv is not None: surf[stn] = (lat, lon, sv, sc)
    return surf

# === model + ROMS surface on grid ===
ds = xr.open_dataset(MODEL_NC); fv = ds.tfv
tm = pd.to_datetime(ds['Time'].values); cellx, celly = ds['cell_X'].values, ds['cell_Y'].values
model_date = tm[int(np.argmin(np.abs(tm - pd.Timestamp(DAY.replace(hour=12)))))]
def model_surf_grid(mvar):
    s = fv.get_sheet([mvar], time=model_date, datum='depth', limits=(0, 2), agg='mean')
    vals = np.asarray(s[mvar]).ravel().astype('float64'); ok = np.isfinite(vals)
    z = griddata((cellx[ok], celly[ok]), vals[ok], (GLON, GLAT), method='linear')
    zm = np.ma.array(z, mask=~np.isfinite(z)); zm[land_on_grid] = np.ma.masked; return zm
dr = xr.open_dataset(ROMS_NC)
roms_day = dr['time'].sel(time=np.datetime64(DAY), method='nearest').values
rlon2, rlat2 = np.meshgrid(dr['lon'].values, dr['lat'].values)
def roms_surf_grid(rvar):
    da = dr[rvar].sel(time=roms_day).isel(depth=0)
    v = np.asarray(da).ravel(); ok = np.isfinite(v)
    z = griddata((rlon2.ravel()[ok], rlat2.ravel()[ok]), v[ok], (GLON, GLAT), method='linear')
    zm = np.ma.array(z, mask=~np.isfinite(z)); zm[land_on_grid] = np.ma.masked; return zm

# === variables ===
ROWS = [dict(name='Salinity (psu)', mvar='SAL', rvar='salinity', fkey='salinity',
             levels=np.arange(34.0, 35.65, 0.1), cmap=plt.cm.RdYlBu_r, fmt='%.1f'),
        dict(name='Temperature (°C)', mvar='TEMP', rvar='water_temp', fkey='temperature',
             levels=np.arange(15.0, 21.1, 0.5), cmap=plt.cm.coolwarm, fmt='%.1f')]
profiles = read_profiles_for_window(D0, D1)
print(f'{DAY:%d-%b}: {len(profiles)} field stns | model {model_date} | roms {pd.Timestamp(roms_day):%d-%b}')

def coast(ax):
    for geom in coast_gdf.geometry:
        polys = [geom] if geom.geom_type == 'Polygon' else (list(geom.geoms) if geom.geom_type == 'MultiPolygon' else [])
        for poly in polys:
            xs, ys = poly.exterior.xy; ax.fill(xs, ys, facecolor='#c4a882', edgecolor='#7a5c3a', lw=0.5, zorder=8)
def frame(ax):
    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX); ax.set_aspect(1/cos_lat)
    ax.grid(True, alpha=0.3); ax.tick_params(labelsize=8); ax.axvline(115.335, color='0.35', ls='--', lw=1, zorder=9)

fig, axes = plt.subplots(2, 3, figsize=(19, 13), sharex=True, sharey=True)
for ri, cfg in enumerate(ROWS):
    lev, cmap = cfg['levels'], cfg['cmap']
    zM = model_surf_grid(cfg['mvar']); zR = roms_surf_grid(cfg['rvar'])
    sd = field_surf(profiles, cfg['fkey'])
    fs = krige_field(sd, 'Surface', None, True) if len(sd) >= 5 else None
    panels = [('MODEL (TUFLOW)', zM, None), ('FIELD (data)', fs[0] if fs else None, fs), ('ROMS clim', zR, None)]
    for ci, (ttl, z, mk) in enumerate(panels):
        ax = axes[ri, ci]; ax.set_facecolor('#e8e8e8')
        if z is not None:
            cf = ax.contourf(GLON, GLAT, z, levels=lev, cmap=cmap, alpha=0.9, extend='both')
            cl = ax.contour(GLON, GLAT, z, levels=lev, colors='k', linewidths=0.35, alpha=0.5); ax.clabel(cl, fontsize=6, fmt=cfg['fmt'])
        coast(ax); frame(ax)
        if mk is not None:
            for i in range(len(mk[1])):
                m = markers_dfv if mk[5][i] == 'DFV' else markers_other
                ax.scatter(mk[1][i], mk[2][i], c=[mk[3][i]], cmap=cmap, s=20, zorder=10, vmin=lev[0], vmax=lev[-1], **m)
        if ri == 0: ax.set_title(ttl, fontsize=12, fontweight='bold')
        if ci == 0: ax.set_ylabel(f"{cfg['name']}\nlat", fontsize=10)
    pos = axes[ri, 2].get_position(); cax = fig.add_axes([pos.x1+0.008, pos.y0, 0.011, pos.height])
    sm = plt.cm.ScalarMappable(norm=BoundaryNorm(lev, cmap.N, clip=True), cmap=cmap); sm.set_array([])
    fig.colorbar(sm, cax=cax, extend='both').set_label(cfg['name'], fontsize=9)
fig.suptitle(f'Surface MODEL | FIELD | ROMS — {DAY:%d-%b %Y} (V-transect day, {PHASE})   |   model {model_date:%d-%b %H:%M}'
             f'   (dashed = OBC; ROMS clim S6corr)', fontsize=14, fontweight='bold', y=0.95)
plt.subplots_adjust(left=0.05, right=0.90, bottom=0.04, top=0.92, wspace=0.06, hspace=0.08)
OUT_DIR.mkdir(parents=True, exist_ok=True)
out = OUT_DIR / f'map_surface_MFR_{DAY:%b%d}.png'
fig.savefig(out, dpi=160, bbox_inches='tight'); print('wrote', out)
