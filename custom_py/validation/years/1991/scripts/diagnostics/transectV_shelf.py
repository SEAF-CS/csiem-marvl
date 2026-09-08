"""TransectV — cross-shelf V→V1 (Trigg shelf), MODEL vs FIELD, TransectA house style (2 rows
MODEL/FIELD x 3 cols T/S/density). Both rows 0-60 m (shelf zoom; deep water dropped), west limit
-55 km. Two figures, SAME colour limits: PRE-STORM (14 Aug, jday 226) and POST-STORM (21 Aug,
jday 233). MODEL exists only E of the OBC (~115.335). -> outputs/TransectV/transectV_shelf_{phase}.png
"""
import os, sys, csv, glob, numpy as np, pandas as pd, xarray as xr
from datetime import datetime
from pyproj import Transformer
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
import tfv.xarray
sys.path.insert(0, r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib')
from eos80 import eos80_potential_density

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
ROMS_NC = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/CLIMATOLOGY/ROMS_UTC+8_19901001_19911231_climatology_S6corr.nc'
SM = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991'
SURVEY_LOG = f'{SM}/survey_log_1991.csv'; PROFILE_BASE = f'{SM}/1991-08/profile_data'
MAP_DIR = f"{SM}/../DAdamo/Nick D'Adamo Cockburn Sound/Archivals of SMCWS data from old DEP CDs of the 1990s/MARINE CD-3 from DEP-CTD data SGI IRIS Crimson/dadamo_usr2/map"
OUT_DIR = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/TransectV'
os.makedirs(OUT_DIR, exist_ok=True)
OBC = 115.335; YMAX = 60.0; YTOP = -4.0; WEST_KM = -55.0; GHOST_KM = 4.0; READ_MAX = 320.0
PERIODS = [('prestorm', 226, pd.Timestamp('1991-08-14 12:00'), '#b8860b'),
           ('poststorm', 233, pd.Timestamp('1991-08-21 12:00'), '#228B22')]
VAR = {'temperature': dict(levels=np.arange(15.0, 20.6, 0.5), cmap=plt.cm.coolwarm, label='Temperature (°C)', key='temperature'),
       'salinity':    dict(levels=np.arange(35.0, 35.92, 0.05), cmap=plt.cm.RdYlBu_r, label='Salinity (psu)', key='salinity'),
       'density':     dict(levels=np.arange(25.0, 26.55, 0.1), cmap=plt.cm.viridis, label=r'Density ($\sigma_t$)', key='density')}

# ---- coords + V line + chainage (0 at coast V1, negative offshore/west) ----
tr = Transformer.from_crs('EPSG:28350', 'EPSG:4326', always_xy=True); COORDS = {}
for locf in glob.glob(os.path.join(MAP_DIR, '*.loc')):
    for line in open(locf, errors='replace'):
        p = line.split()
        if len(p) < 3: continue
        nm = p[0].upper().replace('0A', 'OA')
        if nm in COORDS: continue
        try: e, n = float(p[1]), float(p[2])
        except ValueError: continue
        if n < 1_000_000: n += 6_000_000
        lo, la = tr.transform(e, n); COORDS[nm] = (la, lo)
def hav(a, b):
    (la1, lo1), (la2, lo2) = a, b; R = 6371.0
    p1, p2 = np.radians(la1), np.radians(la2); dp, dl = np.radians(la2-la1), np.radians(lo2-lo1)
    return 2*R*np.arcsin(np.sqrt(np.sin(dp/2)**2 + np.cos(p1)*np.cos(p2)*np.sin(dl/2)**2))
V_LINE = [s for s in sorted([f'V{i}' for i in range(1, 13)] + ['V1A'], key=lambda s: COORDS.get(s, (0, 0))[1]) if s in COORDS]
ref = max(V_LINE, key=lambda s: COORDS[s][1])   # easternmost = coast
CHAIN = {s: -hav(COORDS[s], COORDS[ref]) for s in V_LINE}
OBC_CHAIN = np.interp(OBC, [COORDS[ref][1]] + [COORDS[s][1] for s in V_LINE[::-1]],
                      [0] + [CHAIN[s] for s in V_LINE[::-1]])

# ---- readers ----
def read_sdl(fn):
    d = open(fn, 'rb').read()
    if len(d) < 0x420: return None
    fl = np.frombuffer(d, '>f4', count=(len(d)-0x400)//4, offset=0x400); nz = np.nonzero(fl)[0]
    for i0 in [int(i) for i in nz[:6]]:
        rem = len(fl)-i0
        for nc, (cd, cs, cr, ct) in ((10, (4, 2, 3, 5)), (7, (3, 1, 2, 4))):
            if rem % nc or rem//nc < 2: continue
            rec = fl[i0:].reshape(rem//nc, nc); s = rec[:, 0].astype(float)
            if not (np.all(np.diff(s) >= 1) and s[0] >= 1 and np.all(np.abs(s-np.round(s)) < 1e-3)): continue
            if not (0 < np.median(rec[:, cd]) < 300 and 5 < np.median(rec[:, ct]) < 30): continue
            return rec[:, cd], rec[:, cs], rec[:, cr], rec[:, ct]
    return None
def read_dhv(fn):
    d = open(fn, 'rb').read(); n = (len(d)-0x410)//16
    if n < 2: return None
    r = np.frombuffer(d, '>f4', count=n*4, offset=0x410).reshape(n, 4); return r[:, 1], r[:, 3], r[:, 0], r[:, 2]
def load_field(stn, fn):
    fp = os.path.join(PROFILE_BASE, stn, fn)
    if not os.path.exists(fp): return None
    out = read_dhv(fp) if os.path.basename(fp).lower().startswith('dhv') else read_sdl(fp)
    if out is None: return None
    dep, sal, den, tmp = out
    g = (dep > 0.05) & (dep < READ_MAX) & (sal > 20) & (sal < 40) & (tmp > 5) & (tmp < 30)
    if g.sum() < 2: return None
    o = np.argsort(dep[g])
    return {'depth': dep[g][o], 'salinity': sal[g][o],
            'density': (den[g][o]-1000 if np.nanmean(den[g]) > 100 else den[g][o]), 'temperature': tmp[g][o]}

# ---- grid + section builder ----
GX = np.linspace(WEST_KM, 2.0, 340); GY = np.arange(0, 68, 1.0)
def section(profs, vk):
    stns = sorted(profs, key=lambda s: CHAIN[s]); xs = [CHAIN[s] for s in stns]
    bx = np.array(xs); bd = np.array([profs[s]['depth'][-1] for s in stns]) + 0.5
    all_x = [xs[0]-GHOST_KM] + xs + [xs[-1]+GHOST_KM]; all_s = [stns[0]] + stns + [stns[-1]]
    cols = np.zeros((len(GY), len(all_x)))
    for ci, (x, s) in enumerate(zip(all_x, all_s)):
        dep, val = profs[s]['depth'], profs[s][vk]; o = np.argsort(dep); dep, val = dep[o], val[o]
        lb = np.interp(x, bx, bd); tgt = max(lb, dep[-1]) + 1.0
        if tgt > dep[-1] + 0.2:
            bv = np.median(val[dep > dep[-1]-0.5]); ed = np.linspace(dep[-1]+0.1, tgt, 10)
            dep = np.concatenate([dep, ed]); val = np.concatenate([val, np.full(10, bv)])
        cols[:, ci] = np.interp(GY, dep, val, left=val[0], right=val[-1])
    ax = np.array(all_x); gv = np.zeros((len(GY), len(GX)))
    for j, gx in enumerate(GX):
        k = np.searchsorted(ax, gx)
        if k == 0: gv[:, j] = cols[:, 0]
        elif k >= len(ax): gv[:, j] = cols[:, -1]
        else:
            f = (gx-ax[k-1])/(ax[k]-ax[k-1]); gv[:, j] = cols[:, k-1]*(1-f) + cols[:, k]*f
    bot = np.interp(GX, bx, bd); GYY = np.tile(GY[:, None], (1, len(GX)))
    gv[GYY > bot[None, :]] = np.nan
    gv[:, (GX < all_x[0]) | (GX > all_x[-1])] = np.nan
    return gv, bx, bd

# ---- data loaders ----
ds = xr.open_dataset(NC); fv = ds.tfv   # density derived per-profile from S,T below (no full-field RHOW -> OOM on hourly NC)
mt = pd.to_datetime(ds['Time'].values)
dr = xr.open_dataset(ROMS_NC)   # ROMS climatology (lon/lat/depth grid, daily) - drives the OBC
def roms_for(model_time):
    tt = dr['time'].sel(time=np.datetime64(model_time), method='nearest').values; out = {}
    for s in V_LINE:
        if CHAIN[s] < WEST_KM - GHOST_KM: continue
        la, lo = COORDS[s]
        try:
            pr = dr[['salinity', 'water_temp']].sel(time=tt).interp(lon=lo, lat=la)
            dep = dr['depth'].values; S = np.asarray(pr['salinity']).ravel(); T = np.asarray(pr['water_temp']).ravel()
            ok = np.isfinite(S) & np.isfinite(T) & (dep < READ_MAX)
            if ok.sum() < 2: continue
            dep, S, T = dep[ok], S[ok], T[ok]; o = np.argsort(dep)
            R = eos80_potential_density(S, T) - 1000
            out[s] = {'depth': dep[o], 'salinity': S[o], 'temperature': T[o], 'density': R[o]}
        except Exception: pass
    return out
def field_for(jday):
    casts = {}
    for row in csv.DictReader(open(SURVEY_LOG)):
        if row['month'] != '1991-08' or int(row['jday']) != jday: continue
        stn = row['station'].upper().replace('0A', 'OA')
        if stn in V_LINE and stn not in casts: casts[stn] = row['fv_file']
    out = {}
    for s in V_LINE:
        if s in casts:
            p = load_field(s, casts[s])
            if p: out[s] = p
    return out
def model_for(model_time):
    md = mt[int(np.argmin(np.abs(mt - model_time)))]; out = {}
    for s in V_LINE:
        if COORDS[s][1] < OBC: continue
        la, lo = COORDS[s]
        try:
            p = fv.get_profile((lo, la), variables=['SAL', 'TEMP'], time=md)
            pt = p.sel(Time=md, method='nearest') if 'Time' in p.dims else p
            z = -np.asarray(pt['Z']).ravel(); S = np.asarray(pt['SAL']).ravel()
            T = np.asarray(pt['TEMP']).ravel(); R = eos80_potential_density(S, T)-1000
            ok = np.isfinite(z) & np.isfinite(S) & (z > 0.1)
            if ok.sum() < 2: continue
            o = np.argsort(z[ok])
            out[s] = {'depth': z[ok][o], 'salinity': S[ok][o], 'temperature': T[ok][o], 'density': R[ok][o]}
        except Exception: pass
    return md, out

# ---- figure ----
gXX, gYY = np.meshgrid(GX, GY)
def draw(rows, phase, jday, md, color, out, subtitle):
    nr = len(rows)
    fig, axes = plt.subplots(nr, 3, figsize=(20, 5*nr), sharex='col', sharey=True)
    for ri, (rlabel, profs) in enumerate(rows):
        for col, (vn, cfg) in enumerate(VAR.items()):
            ax = axes[ri, col]
            if len(profs) >= 2:
                gv, bx, bd = section(profs, cfg['key'])
                norm = BoundaryNorm(cfg['levels'], cfg['cmap'].N, clip=True)
                ax.contourf(gXX, gYY, gv, levels=cfg['levels'], cmap=cfg['cmap'], norm=norm, extend='both')
                cl = ax.contour(gXX, gYY, gv, levels=cfg['levels'][::2], colors='k', linewidths=0.4); ax.clabel(cl, fontsize=6, fmt='%.1f')
                ax.fill_between(np.concatenate([[GX[0]], bx, [GX[-1]]]), np.concatenate([[bd[0]], bd, [bd[-1]]]), YMAX+20, color='#8B7355', zorder=5)
                for s in sorted(profs, key=lambda s: CHAIN[s]):
                    if CHAIN[s] < WEST_KM: continue
                    ax.plot(CHAIN[s], 0, 'kv', ms=5, zorder=7, clip_on=False)
                    ax.text(CHAIN[s], YTOP*0.55, s, ha='center', va='bottom', fontsize=6, rotation=90, zorder=7)
            else:
                ax.text(0.5, 0.5, '<2 profiles', transform=ax.transAxes, ha='center')
            ax.axvline(OBC_CHAIN, color='0.25', ls='--', lw=1.2, zorder=6)
            ax.set_ylim(YMAX, YTOP); ax.set_xlim(WEST_KM, 2.0); ax.grid(True, lw=0.3, alpha=0.3)
            if col == 0: ax.set_ylabel(f'{rlabel}\nDepth (m)', fontsize=11, fontweight='bold')
            if ri == 0: ax.set_title(cfg['label'], fontsize=11)
            if ri == nr-1: ax.set_xlabel('Chainage from coast (km)   [offshore/west ←]  | dashed = OBC', fontsize=8)
    fig.subplots_adjust(top=0.93, bottom=0.13, left=0.06, right=0.99, hspace=0.13, wspace=0.05)
    for col, (vn, cfg) in enumerate(VAR.items()):
        pos = axes[nr-1, col].get_position(); cax = fig.add_axes([pos.x0, 0.06, pos.width, 0.013])
        sm = plt.cm.ScalarMappable(norm=BoundaryNorm(cfg['levels'], cfg['cmap'].N, clip=True), cmap=cfg['cmap']); sm.set_array([])
        fig.colorbar(sm, cax=cax, orientation='horizontal', extend='both').set_label(cfg['label'], fontsize=9)
    date = (datetime(1991, 1, 1) + pd.Timedelta(days=jday-1)).strftime('%d-%b')
    fig.text(0.5, 0.965, f'TransectV shelf (cross-shelf, 0–60 m) — {subtitle} — {date} 1991 (jday {jday}) {phase.upper()}'
             f'   |   model/ROMS {md:%d-%b}   (TUFLOW only E of OBC)',
             ha='center', fontsize=13, fontweight='bold', color=color)
    fig.savefig(out, dpi=150, bbox_inches='tight'); plt.close(fig); print('wrote', out)

for phase, jday, mtime, color in PERIODS:
    field = field_for(jday); md, model = model_for(mtime); roms = roms_for(mtime)
    print(f'{phase}: field {len(field)} | tuflow {len(model)} | roms {len(roms)} @ {md}')
    draw([('TUFLOW-FV', model), ('FIELD (DATA)', field)], phase, jday, md, color,
         os.path.join(OUT_DIR, f'transectV_shelf_{phase}.png'), 'TUFLOW vs DATA')
    draw([('ROMS clim', roms), ('TUFLOW-FV', model), ('FIELD (DATA)', field)], phase, jday, md, color,
         os.path.join(OUT_DIR, f'transectV_roms_{phase}.png'), 'ROMS vs TUFLOW vs DATA')
print('done')
