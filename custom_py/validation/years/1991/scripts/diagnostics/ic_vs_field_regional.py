"""Regionally-informed IC check, in the map_salinity_prestorm style (kriged field + native model).
The model's graded IC (initial_condition_2D_Aug_B010_Sgrad.csv, vertically-uniform per cell) vs a
FIELD IC = kriged DEPTH-MEAN of the first pre-storm cast (13-17 Aug 1991) at each winter-network
station. 3 panels: MODEL IC (native grid) | FIELD IC (kriged + points) | MODEL-FIELD difference.
Same machinery/extent/land-mask as map_prestorm_extended.py. Model blank W of the OBC (no cells).
Caveat: field is 3-4 wks post-IC (20 Jul); marine water mass ~ steady -> fair regional guide.
-> outputs/maps/salinity/ic_vs_field_regional.png
"""
import sys, matplotlib; matplotlib.use('Agg')
import os, glob, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.colors import TwoSlopeNorm
from scipy.interpolate import griddata
import tfv.xarray

IC_CSV = r'S:/Matt_Working/csiem/model_components/includes/ic/initial_condition_2D_Aug_B010_Sgrad.csv'
MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc')
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'
PROFILE_DIR_1991 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
OUT = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/maps/salinity/ic_vs_field_regional.png')
PRE0, PRE1 = datetime(1991, 8, 13, 15, 36), datetime(1991, 8, 17, 15, 46)

# === reuse machinery ===
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_prefix = _src[:_src.index('for jday in JDAYS:')].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())
profile_dir = PROFILE_DIR_1991

# === zoom out: widen extent + rebuild grid/land mask ===
LON_MIN, LON_MAX = 114.85, 115.83
LAT_MIN, LAT_MAX = -32.58, -31.82
coast_gdf = gpd.read_file(COAST_SHP, bbox=(LON_MIN, LAT_MIN, LON_MAX, LAT_MAX))
land_union = unary_union(coast_gdf.geometry); land_buffered = land_union.buffer(0.003)
grid_lon = np.linspace(LON_MIN, LON_MAX, 520); grid_lat = np.linspace(LAT_MIN, LAT_MAX, 470)
GLON, GLAT = np.meshgrid(grid_lon, grid_lat)
cos_lat = np.cos(np.radians((LAT_MIN + LAT_MAX) / 2))
land_on_grid = contains(land_buffered, GLON, GLAT)

for locf in glob.glob(os.path.join(MAP_DIR, '*.loc')):
    for k, v in load_loc(locf).items():
        COORDS.setdefault(k, v)

def read_sdl(filepath):
    data = open(filepath, 'rb').read()
    if len(data) < 0x420: return None
    fl = np.frombuffer(data, '>f4', count=(len(data) - 0x400) // 4, offset=0x400); nz = np.nonzero(fl)[0]
    for i0 in [int(i) for i in nz[:6]]:
        rem = len(fl) - i0
        for nc, (cd, cs, cr, ct) in ((10, (4, 2, 3, 5)), (7, (3, 1, 2, 4))):
            if rem % nc or rem // nc < 2: continue
            rec = fl[i0:].reshape(rem // nc, nc); s = rec[:, 0].astype(float)
            if not (np.all(np.diff(s) >= 1) and s[0] >= 1 and np.all(np.abs(s - np.round(s)) < 1e-3)): continue
            if not (0 < np.median(rec[:, cd]) < 300 and 5 < np.median(rec[:, ct]) < 30): continue
            dep, sal, den, tmp = rec[:, cd], rec[:, cs], rec[:, cr], rec[:, ct]
            good = (dep > 0.1) & (dep < 320) & (sal > 20) & (sal < 40) & (tmp > 5) & (tmp < 30)
            if good.sum() < 3: return None
            return {'depth': dep[good], 'salinity': sal[good], 'temperature': tmp[good], 'density': den[good]}
    return None

def _fname_dt(fn):
    name, _, jds = fn.partition('.')
    try: jday = int(jds); hh, mm = int(name[3:5]), int(name[5:7])
    except ValueError: return None
    return datetime(1991, 1, 1) + timedelta(days=jday - 1, hours=hh, minutes=mm)

def read_profiles_for_window(t0, t1):
    profiles = {}
    for stn in sorted(os.listdir(profile_dir)):
        sp = os.path.join(profile_dir, stn)
        if not os.path.isdir(sp) or stn not in COORDS or stn in EXCLUDE: continue
        for fn in sorted(os.listdir(sp)):
            prefix = fn[:3].lower()
            if prefix not in ('dfv', 'dhv', 'dtv', 'dmv', 'dsv', 'esv'): continue
            dt = _fname_dt(fn)
            if dt is None or not (t0 <= dt <= t1): continue
            fpath = os.path.join(sp, fn)
            if prefix == 'dfv':            result, src = read_dfv(fpath), 'DFV'
            elif prefix in ('dhv', 'dtv'): result, src = read_dhv_dtv(fpath), prefix.upper()
            elif prefix == 'dmv':          result, src = read_dmv(fpath), 'DMV'
            else:                          result, src = read_sdl(fpath), 'SDL'
            if result is None: continue
            if stn not in profiles or (profiles[stn][1] != 'DFV' and src == 'DFV'):
                profiles[stn] = (result, src)
    return profiles

# === FIELD IC = depth-mean per station -> krige_field ===
profiles = read_profiles_for_window(PRE0, PRE1)
dm = {}
for stn, (result, src) in profiles.items():
    lat, lon = COORDS[stn]
    dm[stn] = (lat, lon, float(np.mean(result['salinity'])), src)
levels = np.arange(34.0, 35.6, 0.25); cmap = VAR_CONFIG['salinity']['cmap']; fmt = VAR_CONFIG['salinity']['fmt']
ff = krige_field(dm, 'IC', None, VAR_CONFIG['salinity']['exact'])
zf = ff[0]; print(f'{len(dm)} field IC stns | depth-mean {min(d[2] for d in dm.values()):.2f}-{max(d[2] for d in dm.values()):.2f}')

# === MODEL IC = graded IC gridded natively (like model_field_on_grid) ===
ic = pd.read_csv(IC_CSV, skipinitialspace=True); ds = xr.open_dataset(MODEL_NC)
cellx, celly = ds['cell_X'].values, ds['cell_Y'].values; sal_ic = ic['SAL'].values
zi = griddata((cellx, celly), sal_ic, (GLON, GLAT), method='linear')
zi = np.ma.array(zi, mask=~np.isfinite(zi)); zi[land_on_grid] = np.ma.masked

# === difference (only where both present) ===
zd = np.ma.array(zi.filled(np.nan) - np.ma.array(zf).filled(np.nan))
zd = np.ma.masked_invalid(zd)
print(f'overlap mean(model-field) {np.nanmean(zd.filled(np.nan)):+.2f}')

# === draw ===
def coast(ax):
    for geom in coast_gdf.geometry:
        polys = [geom] if geom.geom_type == 'Polygon' else (list(geom.geoms) if geom.geom_type == 'MultiPolygon' else [])
        for poly in polys:
            xs, ys = poly.exterior.xy
            ax.fill(xs, ys, facecolor='#c4a882', edgecolor='#7a5c3a', linewidth=0.5, zorder=8)
def frame(ax):
    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX); ax.set_aspect(1 / cos_lat)
    ax.grid(True, alpha=0.3); ax.tick_params(labelsize=9); ax.axvline(115.335, color='0.35', ls='--', lw=1, zorder=9)

fig, axes = plt.subplots(1, 3, figsize=(20, 8.5), sharex=True, sharey=True)
for ax in axes: ax.set_facecolor('#e8e8e8')
# panel 1: model IC
cf = axes[0].contourf(GLON, GLAT, zi, levels=levels, cmap=cmap, alpha=0.9, extend='both')
cl = axes[0].contour(GLON, GLAT, zi, levels=levels, colors='k', linewidths=0.4, alpha=0.5); axes[0].clabel(cl, fontsize=7, fmt=fmt)
coast(axes[0]); frame(axes[0]); axes[0].set_title('MODEL graded IC (20 Jul, depth-uniform)', fontsize=11)
# panel 2: field IC + points
axes[1].contourf(GLON, GLAT, zf, levels=levels, cmap=cmap, alpha=0.9, extend='both')
cl = axes[1].contour(GLON, GLAT, zf, levels=levels, colors='k', linewidths=0.4, alpha=0.5); axes[1].clabel(cl, fontsize=7, fmt=fmt)
for i in range(len(ff[1])):
    mk = markers_dfv if ff[5][i] == 'DFV' else markers_other
    axes[1].scatter(ff[1][i], ff[2][i], c=[ff[3][i]], cmap=cmap, s=22, zorder=10, vmin=levels[0], vmax=levels[-1], **mk)
coast(axes[1]); frame(axes[1]); axes[1].set_title('FIELD IC = kriged depth-mean (1st pre-storm cast)', fontsize=11)
# panel 3: difference
dn = TwoSlopeNorm(vmin=-1.0, vcenter=0.0, vmax=1.0); dlev = np.arange(-1.0, 1.01, 0.1)
cfd = axes[2].contourf(GLON, GLAT, zd, levels=dlev, cmap='RdBu_r', norm=dn, extend='both')
axes[2].contour(GLON, GLAT, zd, levels=[0], colors='k', linewidths=0.6)
coast(axes[2]); frame(axes[2]); axes[2].set_title('MODEL - FIELD  (red = IC too salty -> lower here)', fontsize=11)
axes[0].set_ylabel('lat')
for ax in axes: ax.set_xlabel('lon')
plt.subplots_adjust(left=0.05, right=0.90, bottom=0.08, top=0.90, wspace=0.08)
cax1 = fig.add_axes([0.915, 0.55, 0.012, 0.33]); fig.colorbar(cf, cax=cax1).set_label('Salinity (psu)', fontsize=10)
cax2 = fig.add_axes([0.915, 0.12, 0.012, 0.33]); fig.colorbar(cfd, cax=cax2).set_label('ΔSAL model-field', fontsize=10)
fig.suptitle('Regionally-informed IC check — model graded IC vs field depth-mean (pre-storm 1991)   (dashed = OBC)',
             fontsize=13, fontweight='bold', y=0.965)
fig.savefig(OUT, dpi=190, bbox_inches='tight'); print('wrote', OUT)
