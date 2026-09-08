"""TransectOA validation [6] — Owen Anchorage cross-sections, model vs SMCWS field, 1991.

Brought IN LINE WITH TransectA/B: DFV-sourced profiles (survey log + read_dfv -> 3 vars T/S/density),
A/B `build_cross_section` + contourf + VAR_CONFIG, model (top) vs field (bottom). The original OA script
plotted salinity-only off the CSV warehouse — that data path is dropped. We KEEP the OA transect
ORIENTATION (the 4 W->E lines I-IV through Owen Anchorage on 18 Aug, chainage from the westernmost
station) by exec-reusing only the field script's GEOMETRY (ALL_STATIONS, TRANSECTS, compute_distances,
extract_bathymetry). One model-vs-field figure per transect -> years/1991/outputs/transectOA/.
"""
import os, sys, csv, struct, numpy as np, pandas as pd, xarray as xr
from datetime import datetime
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
SURVEY_LOG = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/survey_log_1991.csv'
PROFILE_BASE = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
OUT_DIR = os.path.join(HERE, '..', 'outputs', 'transectOA'); os.makedirs(OUT_DIR, exist_ok=True)
GRID_NX, GRID_NY = 400, 200

# ---- reuse the OA field GEOMETRY only (stations, transects, chainage, bathy) ----
FIELD = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/6-13_OATransects/plot_fig6_13_transects.py'
_src = open(FIELD, encoding='utf-8').read()
_split = _src.index('# --- Generate all four transects ---')
_G = {'__file__': FIELD, '__name__': 'oa_field'}
exec(compile(_src[:_split], FIELD, 'exec'), _G)
ALL_STATIONS = _G['ALL_STATIONS']; TRANSECTS = _G['TRANSECTS']
compute_distances = _G['compute_distances']; extract_bathymetry = _G['extract_bathymetry']
GHOST_WEST_KM = _G['GHOST_WEST_KM']; GHOST_EAST_KM = _G['GHOST_EAST_KM']; BATHY_BUFFER = _G['BATHY_BUFFER']

VAR_CONFIG = {
    'temperature': dict(levels=np.arange(15.4, 17.5, 0.2), cmap=plt.cm.coolwarm, label='Temperature (°C)'),
    'salinity':    dict(levels=np.arange(33.5, 35.6, 0.1), cmap=plt.cm.RdYlBu_r, label='Salinity (psu)'),
    'density':     dict(levels=np.arange(24.0, 26.1, 0.1), cmap=plt.cm.viridis,  label=r'Density ($\sigma_t$, kg m$^{-3}$)'),
}
VAR_ORDER = ['temperature', 'salinity', 'density']


# ---- DFV reader (3 vars + depth), same as TransectA/B ----
def read_dfv(filepath):
    with open(filepath, 'rb') as f: data = f.read()
    off = data.find(b'EPA')
    if off == 0x18:   ncols = struct.unpack('>H', data[0x136:0x138])[0]; nrecs = struct.unpack('>i', data[0x13c:0x140])[0]; ds0 = 0x528
    elif off == 0x14: ncols = struct.unpack('>H', data[0x132:0x134])[0]; nrecs = struct.unpack('>i', data[0x138:0x13c])[0]; ds0 = 0x49C
    else: return None
    if ncols < 4 or nrecs < 10 or ds0 + nrecs * ncols * 4 > len(data): return None
    rec = np.frombuffer(data, dtype='>f4', count=nrecs * ncols, offset=ds0).reshape(nrecs, ncols)
    depth = rec[:, 2].copy(); sal = rec[:, 0].copy(); den = rec[:, 1].copy(); temp = rec[:, 3].copy()
    imax = np.argmax(depth)
    if imax > 10: depth, sal, den, temp = depth[:imax+1], sal[:imax+1], den[:imax+1], temp[:imax+1]
    good = (depth > 0.1) & (depth < 50) & (sal > 20) & (sal < 40) & (temp > 5) & (temp < 30)
    if good.sum() < 5: return None
    depth, sal, den, temp = depth[good], sal[good], den[good], temp[good]
    edges = np.arange(0, depth.max() + 0.25, 0.25); idx = np.digitize(depth, edges) - 1
    d, s, dn, t = [], [], [], []
    for bi in range(len(edges) - 1):
        m = idx == bi
        if m.any(): d.append(depth[m].mean()); s.append(sal[m].mean()); dn.append(den[m].mean()); t.append(temp[m].mean())
    if len(d) < 3: return None
    return {'depth': np.array(d), 'salinity': np.array(s), 'density': np.array(dn), 'temperature': np.array(t)}


# ---- 18-Aug DFV casts for the OA stations ----
casts18 = []
with open(SURVEY_LOG) as f:
    for row in csv.DictReader(f):
        if row['date'] != '1991-08-18' or row['data_type'] != 'DFV+FV': continue
        h, m = int(row['time'][:2]), int(row['time'][2:])
        casts18.append({'station': row['station'], 'dt': datetime(1991, 8, 18, h, m), 'jday': int(row['jday']), 'time': row['time']})


def parse_window(s):                       # '0811–0915' -> (t0, t1) on 18 Aug
    a, b = s.replace('–', '-').split('-')
    return (datetime(1991, 8, 18, int(a[:2]), int(a[2:])), datetime(1991, 8, 18, int(b[:2]), int(b[2:])))


def field_profiles(stations, t0, t1):      # DFV cast per station, preferring the transect window
    tmid = t0 + (t1 - t0) / 2; profs = {}
    for stn in stations:
        cands = [c for c in casts18 if c['station'] == stn]
        if not cands: continue
        inwin = [c for c in cands if t0 <= c['dt'] <= t1]
        c = (inwin or sorted(cands, key=lambda c: abs((c['dt'] - tmid).total_seconds())))[0]
        p = os.path.join(PROFILE_BASE, stn, f"dfv{c['time']}.{c['jday']}")
        if os.path.exists(p):
            r = read_dfv(p)
            if r is not None: profs[stn] = r
    return profs


# ---- model ----
ds = xr.open_dataset(NC); fv = ds.tfv   # density derived per-profile from S,T (no full-field RHOW)
mtimes = pd.to_datetime(ds['Time'].values)


def snap(mid): return mtimes[int(np.argmin(np.abs(mtimes - mid)))]


def model_profiles(stations, md):
    profs = {}
    for stn in stations:
        la, lo = ALL_STATIONS[stn]['lat'], ALL_STATIONS[stn]['lon']
        mlon, mlat = adjust_point(stn, lo, la)
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


# ---- A/B-style cross-section builder, per-transect chainage dict ----
def build_cross_section(profiles, var_key, dists, gx, gy, gX, gY, bathy_dists, bathy_plot, ghost_w, ghost_e):
    stns = sorted(profiles.keys(), key=lambda s: dists[s]); sx = [dists[s] for s in stns]
    all_x = [ghost_w] + sx + [ghost_e]; all_s = [stns[0]] + stns + [stns[-1]]
    cols = np.zeros((len(gy), len(all_x)))
    for ci, (x, stn) in enumerate(zip(all_x, all_s)):
        dep = profiles[stn]['depth']; val = profiles[stn][var_key]; o = np.argsort(dep); dep, val = dep[o], val[o]
        lb = np.interp(x, bathy_dists, bathy_plot); tgt = max(lb, dep[-1]) + BATHY_BUFFER
        if tgt > dep[-1] + 0.2:
            bv = np.median(val[dep > dep[-1] - 0.5]); ed = np.linspace(dep[-1] + 0.1, tgt, 10)
            dep = np.concatenate([dep, ed]); val = np.concatenate([val, np.full(10, bv)])
        cols[:, ci] = np.interp(gy, dep, val, left=val[0], right=val[-1])
    ax = np.array(all_x); gv = np.zeros((len(gy), len(gx)))
    for j, x in enumerate(gx):
        k = np.searchsorted(ax, x)
        if k == 0: gv[:, j] = cols[:, 0]
        elif k >= len(ax): gv[:, j] = cols[:, -1]
        else:
            f = (x - ax[k-1]) / (ax[k] - ax[k-1]); gv[:, j] = cols[:, k-1] * (1 - f) + cols[:, k] * f
    bot = np.interp(gx, bathy_dists, bathy_plot)
    for j in range(len(gx)):
        if np.isnan(bot[j]): gv[:, j] = np.nan
        else: gv[gY[:, j] > bot[j], j] = np.nan
    for j, x in enumerate(gx):
        if x < all_x[0] or x > all_x[-1]: gv[:, j] = np.nan
    return gv


# ---- one model-vs-field figure per OA transect ----
print(f'Model coverage {mtimes.min()} -> {mtimes.max()}')
for tid, info in TRANSECTS.items():
    stations = info['stations']; t0, t1 = parse_window(info['time'])
    dists, lon0, lat0 = compute_distances(stations)
    bathy_dists, bathy_depths, bathy_plot = extract_bathymetry(stations, lon0, lat0)
    fprofs = field_profiles(stations, t0, t1)
    if len(fprofs) < 2:
        print(f'OA {tid}: {len(fprofs)} field profiles, skipping'); continue
    md = snap(pd.Timestamp(t0) + (pd.Timestamp(t1) - pd.Timestamp(t0)) / 2)
    mprofs = model_profiles(stations, md)
    ghost_w = min(dists.values()) - GHOST_WEST_KM; ghost_e = max(dists.values()) + GHOST_EAST_KM
    dmin, dmax = ghost_w - 0.05, ghost_e + 0.05
    depth_max = float(np.nanmax(bathy_plot)); pdep = min(depth_max, 25)
    gx = np.linspace(dmin, dmax, GRID_NX); gy = np.linspace(0, pdep + 0.5, GRID_NY); gX, gY = np.meshgrid(gx, gy)
    fig, axes = plt.subplots(2, 3, figsize=(20, 11), sharex='col', sharey=True)
    for ri, (rlabel, profs) in enumerate([('MODEL', mprofs), ('FIELD', fprofs)]):
        for col, vk in enumerate(VAR_ORDER):
            ax = axes[ri, col]; cfg = VAR_CONFIG[vk]
            if len(profs) >= 2:
                gv = build_cross_section(profs, vk, dists, gx, gy, gX, gY, bathy_dists, bathy_plot, ghost_w, ghost_e)
                norm = BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True)
                ax.contourf(gX, gY, gv, levels=cfg['levels'], cmap=cfg['cmap'], norm=norm, extend='both')
                cl = ax.contour(gX, gY, gv, levels=cfg['levels'], colors='k', linewidths=0.4)
                ax.clabel(cl, inline=True, fontsize=6, fmt='%.1f')
            else:
                ax.text(0.5, 0.5, '<2 profiles', transform=ax.transAxes, ha='center', va='center')
            ax.fill_between(bathy_dists, bathy_plot, depth_max + 5, color='#8B7355', zorder=5)
            ax.plot(bathy_dists, bathy_plot, 'k-', lw=1, zorder=6)
            for stn in sorted(profs.keys(), key=lambda s: dists[s]):
                ax.plot(dists[stn], 0, 'kv', ms=5, zorder=7, clip_on=False)
                ax.text(dists[stn], -0.8, stn, ha='center', va='bottom', fontsize=6, rotation=90, zorder=7, clip_on=False)
            ax.set_xlim(dmin, dmax); ax.set_ylim(pdep + 1, -1.8); ax.grid(True, lw=0.3, alpha=0.3)
            if col == 0: ax.set_ylabel(f'{rlabel}\nDepth (m)', fontsize=10, fontweight='bold')
            if ri == 1: ax.set_xlabel('Distance from westernmost station (km)\n← West     East →', fontsize=8)
    fig.subplots_adjust(top=0.9, bottom=0.16, left=0.06, right=0.99, hspace=0.16, wspace=0.05)
    for col, vk in enumerate(VAR_ORDER):
        cfg = VAR_CONFIG[vk]; pos = axes[1, col].get_position()
        cax = fig.add_axes([pos.x0, 0.065, pos.width, 0.015])
        sm = plt.cm.ScalarMappable(norm=BoundaryNorm(cfg['levels'], ncolors=cfg['cmap'].N, clip=True), cmap=cfg['cmap']); sm.set_array([])
        fig.colorbar(sm, cax=cax, orientation='horizontal', extend='both').set_label(cfg['label'], fontsize=9)
    fig.suptitle(f'Transect OA {tid} — {info["label"]} — model ({RUNLABEL}) vs SMCWS field\n'
                 f'18 Aug 1991, {info["time"]} hrs   |   model {pd.Timestamp(md):%d-%b %H:%M}',
                 fontsize=14, fontweight='bold', y=0.985)
    fn = os.path.join(OUT_DIR, f'compare_TransectOA_{tid}.png'); fig.savefig(fn, dpi=150, bbox_inches='tight'); plt.close(fig)
    print(f'  OA {tid}: model {len(mprofs)} / field {len(fprofs)} stns -> {os.path.basename(fn)}')
print('Done.')
