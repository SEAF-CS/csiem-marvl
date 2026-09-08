"""L2 (estuary + offshore) OBS vs MODEL — 6-panel [obs | model] per row (T / S / density),
same style/scales as the L1 transect validation. The L2 line is a single path with OA10
(Fremantle mouth) = 0 km:
  * NEGATIVE = estuary thalweg OA10 -> Narrows (locked in l2_thalweg.py) — MODEL ONLY.
  * POSITIVE = that day's offshore transect (OA10 -> ... stations from daily_maps) — obs + model.
Model curtain runs the whole path (nearest wet cell) at the day's median cast time; obs only
exist on the offshore stations. Seabed = model bed cell_Zb along the path (TIF doesn't cover
the estuary), so obs and model share one bottom.

Usage: python transect_L2_estuary_validation.py [JDAY]
-> years/1991/outputs/diagnostics/transect_long/L2_{jday}.png
"""
import os, sys, numpy as np, pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.interpolate import griddata
from scipy.spatial import cKDTree
from scipy.ndimage import uniform_filter1d
from datetime import datetime, timedelta
import xarray as xr

TLD = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/TransectLong'
sys.path.insert(0, TLD)
sys.path.insert(0, r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import transect_long_lib as TL
from transect_config import LINE_META   # single source: L2 per-day offshore lists
from l2_thalweg import THALWEG          # OA10 -> NAR (lon, lat), dense least-cost thalweg
from eos80 import eos80_potential_density
import tfv.xarray

MODEL_NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'   # live rev, no ITER suffix = latest iteration (matches transect_long_validation.py)
MODEL_LABEL = 'ITER8'   # iteration label shown in the panel title — bump when a new iteration is run
OUT_DIR = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/transect_long'
ONLY_JD = int(sys.argv[1]) if len(sys.argv) > 1 else None

# per-day OFFSHORE transects come from the shared config (transect_config.L2_BY_JDAY),
# so the same station lists drive the daily maps and these validation figures.
L2_OFFSHORE = {jd: cfg['main'] for jd, cfg in LINE_META['L2']['by_jday'].items()}
DEPTH_MAX = 45; DZ = 0.25; GHOST = 1.5; SMOOTH = 5
XHI = 35.0          # common offshore right edge (km) so every L2 day ends at the same X
DEPTH_LIM = 38.0    # common depth axis (m) for every L2 panel
# Non-uniform levels: COARSE across the fresh estuary range + FINE across the narrow
# marine range, so both the estuary freshening AND the offshore marine structure show
# (a single uniform scale can only do one or the other).
SCAL = {'T': np.arange(14.0, 20.1, 0.25),
        'S': np.array([14, 18, 22, 26, 29, 31, 33, 34,
                       34.3, 34.5, 34.7, 34.9, 35.1, 35.3, 35.5, 35.7]),
        'D': np.array([10, 14, 18, 21, 23, 24,
                       24.4, 24.6, 24.8, 25.0, 25.2, 25.4, 25.6, 25.8, 26.0, 26.2])}

def hav(la1, lo1, la2, lo2):
    R = 6371.0; p1, p2 = np.radians(la1), np.radians(la2); dlo, dla = np.radians(lo2 - lo1), np.radians(la2 - la1)
    return 2 * R * np.arcsin(np.sqrt(np.sin(dla / 2) ** 2 + np.cos(p1) * np.cos(p2) * np.sin(dlo / 2) ** 2))

def project_to_line(lats, lons, mpts, mch):
    """Chainage of points projected onto the combined polyline (obs-metric km)."""
    P = np.column_stack([lons * 111.32 * np.cos(np.radians(-32.2)), lats * 111.32])
    M = np.asarray(mpts); mch = np.asarray(mch, float)
    best_ch = np.full(len(P), np.nan); best_d = np.full(len(P), np.inf)
    for i in range(len(M) - 1):
        a, b = M[i], M[i + 1]; ab = b - a; L2 = float(ab @ ab)
        if L2 == 0: continue
        t = np.clip(((P - a) @ ab) / L2, 0.0, 1.0)
        d = np.hypot(*(P - (a + t[:, None] * ab)).T)
        ch_i = mch[i] + t * np.sqrt(L2)
        m = d < best_d; best_d[m] = d[m]; best_ch[m] = ch_i[m]
    return best_ch

def build_line(offshore):
    """Combined polyline (lon,lat) + chainage with OA10 = 0 (estuary -ve, offshore +ve)."""
    est_rev = THALWEG[::-1]                      # NAR -> OA10 (last point ~ OA10)
    off = [(TL.COORDS[s][1], TL.COORDS[s][0]) for s in offshore if s in TL.COORDS]
    combined = est_rev[:-1] + off                # drop dup OA10 at estuary end; offshore starts at OA10
    oa10_idx = len(est_rev) - 1
    lons = np.array([p[0] for p in combined]); lats = np.array([p[1] for p in combined])
    ch = np.concatenate([[0.0], np.cumsum([hav(lats[i], lons[i], lats[i + 1], lons[i + 1])
                                           for i in range(len(combined) - 1)])])
    ch -= ch[oa10_idx]
    mpts = np.column_stack([lons * 111.32 * np.cos(np.radians(-32.2)), lats * 111.32])
    return lons, lats, ch, oa10_idx, mpts

# ---- model ----
print('opening model NC ...', flush=True)
ds = xr.open_dataset(MODEL_NC)
CX, CY, CZB = ds['cell_X'].values, ds['cell_Y'].values, np.asarray(ds['cell_Zb'])
CT = cKDTree(np.column_stack([CX * 111.32 * np.cos(np.radians(-32.2)), CY * 111.32]))
fv = ds.tfv
MT = pd.to_datetime(ds['Time'].values)

def model_seabed(lons, lats, ch, grid_x):
    glon = np.interp(grid_x, ch, lons); glat = np.interp(grid_x, ch, lats)
    q = np.column_stack([glon * 111.32 * np.cos(np.radians(-32.2)), glat * 111.32])
    _, ci = CT.query(q)
    dep = np.clip(-CZB[ci], 0.3, None)
    return uniform_filter1d(dep, size=SMOOTH)

def model_grids(poly, mpts, ch, grid_x, grid_y, seabed, mid_dt):
    md = MT[int(np.argmin(np.abs(MT - mid_dt)))]
    c = fv.get_curtain(poly, variables=['SAL', 'TEMP'], time=md)
    cx = np.asarray(c['cell_X']); cy = np.asarray(c['cell_Y'])
    li = np.clip(np.asarray(c['line_index']).astype(int), 0, len(cy) - 1)
    cch = project_to_line(cy[li], cx[li], mpts, ch)
    z = -np.asarray(c['Z'])[0].mean(axis=1)
    S = np.asarray(c['SAL'])[0].astype(float); T = np.asarray(c['TEMP'])[0].astype(float)
    vals = {'sal': S, 'temp': T, 'density': eos80_potential_density(S, T) - 1000.0}
    GXg, GYg = np.meshgrid(grid_x, grid_y); ok = np.isfinite(cch) & np.isfinite(z)
    grids = {}
    for key, v in vals.items():
        m = ok & np.isfinite(v)
        g = griddata((cch[m], z[m]), v[m], (GXg, GYg), method='linear')
        g[GYg > seabed[None, :]] = np.nan
        g[:, (grid_x < np.nanmin(cch[ok])) | (grid_x > np.nanmax(cch[ok]))] = np.nan
        grids[key] = g
    return grids, md

# fixed geographic landmarks (lon/lat), projected onto each day's line and shown
# only where the line actually passes near them (<=FEAT_MAXD km): Mewstone (at MA2,
# SW/MA days incl. 229), FFB (halfway MA5<->MA6, MA days), Stragglers (at OA55,
# the western days).
FEAT_LL = [('Mewstone', TL.COORDS['MA2'][0], TL.COORDS['MA2'][1]),
           ('FFB', 0.5 * (TL.COORDS['MA5'][0] + TL.COORDS['MA6'][0]),
                   0.5 * (TL.COORDS['MA5'][1] + TL.COORDS['MA6'][1])),
           ('Stragglers', TL.COORDS['OA55'][0], TL.COORDS['OA55'][1])]
FEAT_MAXD = 2.0

def project_pt(lo, la, mpts, ch):
    p = np.array([lo * 111.32 * np.cos(np.radians(-32.2)), la * 111.32])
    M = np.asarray(mpts); best = (1e9, 0.0)
    for i in range(len(M) - 1):
        a, b = M[i], M[i + 1]; ab = b - a; L2 = float(ab @ ab)
        if L2 == 0: continue
        t = float(np.clip((p - a) @ ab / L2, 0, 1)); d = float(np.hypot(*(p - (a + t * ab))))
        if d < best[0]: best = (d, ch[i] + t * np.sqrt(L2))
    return best[1], best[0]

# ---- per day ----
n = 0
for jd, offshore in sorted(L2_OFFSHORE.items()):
    if ONLY_JD and jd != ONLY_JD: continue
    lons, lats, ch, oa10_idx, mpts = build_line(offshore)
    off_stn = [s for s in offshore if s in TL.COORDS]
    xs_map = {s: ch[oa10_idx + i] for i, s in enumerate(off_stn)}

    ref = TL.outer_ref_minutes(off_stn, jd)
    profiles, picked = {}, {}
    for s in off_stn:
        for m, fn in sorted(TL.casts.get((s, jd), []), key=lambda t: abs(t[0] - ref)):
            p = TL.load_profile(s, fn, DEPTH_MAX + 20)
            if p: profiles[s] = p; picked[s] = m; break
    if not profiles:
        print(f'L2 jday {jd}: no offshore obs — skip'); continue

    grid_x = np.linspace(ch[0] - GHOST, ch[-1] + GHOST, 900)
    seabed = model_seabed(lons, lats, ch, grid_x)
    depth_lim = DEPTH_LIM
    grid_y = np.arange(0, depth_lim + DZ, DZ)
    GX = np.tile(grid_x[None, :], (len(grid_y), 1)); GY = np.tile(grid_y[:, None], (1, len(grid_x)))

    stns = sorted(profiles, key=lambda s: xs_map[s]); xs = np.array([xs_map[s] for s in stns])
    tmin, tmax = min(picked.values()), max(picked.values())
    mid_dt = datetime(1991, 1, 1) + timedelta(days=jd - 1, minutes=0.5 * (tmin + tmax))
    poly = np.column_stack([lons, lats])
    mgrids, md = model_grids(poly, mpts, ch, grid_x, grid_y, seabed, mid_dt)
    print(f'L2 jday {jd}: {len(stns)} offshore obs | model curtain @ {md:%d-%b %H:%M}', flush=True)

    xlo, xhi = grid_x[0] + 2.0, XHI           # fixed axis; left edge trimmed 2 km
    lm = [(0.0, 'Fremantle mouth'), (max(ch[0], xlo), 'Narrows')]   # 0 and estuary end
    for _nm, _la, _lo in FEAT_LL:
        _fc, _fd = project_pt(_lo, _la, mpts, ch)
        if _fd <= FEAT_MAXD and xlo <= _fc <= xhi:
            lm.append((_fc, _nm))
    fig, axes = plt.subplots(3, 2, figsize=(23, 14), sharex=True, sharey=True)
    row_cf = [None, None, None]
    for ri, (var, label, cmap, key) in enumerate(TL.VAR_CFG):
        levels = SCAL[key]; norm = BoundaryNorm(levels, ncolors=cmap.N, clip=True)
        g_obs = TL.build_section(profiles, xs_map, var, grid_x, seabed, grid_y, GHOST)
        for ci, (g, is_mod) in enumerate([(g_obs, False), (mgrids.get(var), True)]):
            ax = axes[ri, ci]
            if g is not None:
                cf = ax.contourf(GX, GY, g, levels=levels, cmap=cmap, norm=norm, extend='both')
                cl = ax.contour(GX, GY, g, levels=levels[::2], colors='k', linewidths=0.4); ax.clabel(cl, fmt='%.1f', fontsize=7, inline=True)
                row_cf[ri] = cf
            ax.fill_between(grid_x, seabed, depth_lim + 5, color='#8B7355', zorder=3)
            ax.plot(grid_x, seabed, '-', color='k', lw=0.7, zorder=4)
            for c0, lab in lm:
                ax.plot([c0, c0], [float(np.interp(c0, grid_x, seabed)), depth_lim], ls=(0, (6, 4)), color='k', lw=1.0, alpha=0.8, zorder=6)
                if ri == 0:
                    ax.text(c0 + 0.4, min(TL.FEATURE_LABEL_Y, depth_lim - 0.5), lab, rotation=0,
                            ha='left', va='center', fontsize=8, fontweight='bold',
                            zorder=11, clip_on=False, bbox=dict(boxstyle='round,pad=0.2', fc='white', ec='0.4', lw=0.4, alpha=0.85))
            if not is_mod:
                for sx, s in zip(xs, stns):
                    ax.plot([sx, sx], [0, 0.02 * depth_lim], '-', color='k', lw=0.9, zorder=5)
                    ax.text(sx, -0.035 * depth_lim, s, fontsize=6.5, rotation=90, ha='center', va='bottom', color='k', zorder=5)
            ax.set_ylim(depth_lim, -0.12 * depth_lim); ax.set_xlim(xlo, xhi); ax.tick_params(labelsize=10)
            if ci == 0: ax.set_ylabel('Depth (m)', fontsize=12)
            if ri == 0: ax.set_title('OBSERVED (CTD, offshore only)' if not is_mod else f'MODEL @ {md:%d-%b %H:%M}', fontsize=13, fontweight='bold')
            if ri == 2: ax.set_xlabel('Chainage from OA10 (km)   [estuary/Narrows ←  |  → offshore]', fontsize=12)
        axes[ri, 0].text(xlo + 0.5, 20, label, fontsize=13, fontweight='bold', ha='left',
                         va='center', zorder=12, bbox=dict(boxstyle='round,pad=0.3', fc='white', ec='0.5', alpha=0.9))

    fig.suptitle(f"Cross-shelf transect L2: Narrows — Fremantle — Five Fathom Bank — OBS vs MODEL\n"
                 f"{(datetime(1991,1,1)+timedelta(days=jd-1)):%d %b %Y} (jday {jd}) — obs casts "
                 f"{tmin//60:02.0f}:{tmin%60:02.0f}–{tmax//60:02.0f}:{tmax%60:02.0f} WST | model {md:%d-%b %H:%M}",
                 fontsize=15, color=('#b8860b' if jd in TL.PRE_JDAYS else '#228B22'), fontweight='bold', y=0.99)
    fig.subplots_adjust(left=0.045, right=0.925, top=0.915, bottom=0.055, wspace=0.04, hspace=0.14)
    for ri in range(3):
        if row_cf[ri] is None: continue
        p = axes[ri, 1].get_position(); cax = fig.add_axes([0.935, p.y0, 0.012, p.height])
        fig.colorbar(row_cf[ri], cax=cax).ax.tick_params(labelsize=9)
    out = os.path.join(OUT_DIR, f'L2_{jd}.png'); fig.savefig(out, dpi=145); plt.close(fig); n += 1
    print(f'  wrote {os.path.basename(out)}', flush=True)

print(f'\n{n} L2 estuary+offshore figures -> {OUT_DIR}')
