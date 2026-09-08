"""TransectLong MODEL VALIDATION — obs vs CSIEM model along the long composite
transects L1/L2 (Aug 1991). Extends smcws_data/1991/TransectLong/plot_transects_long.py
per its NOTE_for_model_validation.md: a 3x2 grid [obs | model] per row (T / S / density),
sharing depth axis + one colorbar per row (identical levels).

Geometry/seabed/section machinery is reused verbatim from `transect_long_lib.py`
(a render-loop-free snapshot of plot_transects_long.py) so obs and model share the
same master polyline, chainage (ref station = 0), seabed and colour scales. The model
column is a tfv get_curtain along that same master lat/lon path at each day's MEDIAN
cast time (a single quasi-synoptic snapshot; casts span ~a day), regridded onto the
obs grid. Density = rho - 1000 (EOS-80) from the curtain SAL/TEMP.

Usage: python transect_long_validation.py [LINE] [JDAY]   (no args = all L1/L2 days)
-> years/1991/outputs/diagnostics/transect_long/{L1,L2}_{jday}.png
"""
import os, sys, numpy as np, pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.interpolate import griddata
from datetime import datetime, timedelta
import xarray as xr

TLD = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/TransectLong'
sys.path.insert(0, TLD)
sys.path.insert(0, r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib')
import transect_long_lib as TL          # helpers, COORDS, casts, build_section, SCALES, VAR_CFG, readers
from transect_config import LINE_META, FEATURES
from eos80 import eos80_potential_density
import tfv.xarray

MODEL_NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'   # live rev (matches all run_all siblings; was pinned to _ITER7 while ITER8 wrote)
OUT_DIR = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/transect_long'
os.makedirs(OUT_DIR, exist_ok=True)
ONLY_LINE = sys.argv[1] if len(sys.argv) > 1 else None
ONLY_JD = int(sys.argv[2]) if len(sys.argv) > 2 else None

print('opening model NC ...', flush=True)
ds = xr.open_dataset(MODEL_NC); fv = ds.tfv
MT = pd.to_datetime(ds['Time'].values)

def project_to_master(lats, lons, mpts, mch):
    """Obs-metric chainage of points projected onto the master polyline, using the
    SAME fixed-cos latlon_km projection as the obs (TL.latlon_km). This is why we do
    NOT use the curtain's own Chainage: get_curtain measures the cell-crossing path
    length (~1.24x the straight polyline here), which stretches the model x-axis."""
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

def model_curtain_grids(poly, mpts, mch, grid_x, grid_y, seabed, mid_dt):
    """Model T/S/density on the obs (grid_x, grid_y) grid, from a tfv get_curtain along
    the master polyline at the model time nearest mid_dt. Each curtain cell is placed by
    projecting its real lon/lat (cell_X/cell_Y via line_index) onto the master in the OBS
    metric — so obs and model share exactly the same chainage."""
    md = MT[int(np.argmin(np.abs(MT - mid_dt)))]
    c = fv.get_curtain(poly, variables=['SAL', 'TEMP'], time=md)
    li = np.asarray(c['line_index']).astype(int)
    ch = project_to_master(np.asarray(c['cell_Y'])[li], np.asarray(c['cell_X'])[li], mpts, mch)  # obs-metric km
    z = -np.asarray(c['Z'])[0].mean(axis=1)                             # depth (m, +down)
    S = np.asarray(c['SAL'])[0].astype(float); T = np.asarray(c['TEMP'])[0].astype(float)
    vals = {'sal': S, 'temp': T, 'density': eos80_potential_density(S, T) - 1000.0}
    GXg, GYg = np.meshgrid(grid_x, grid_y)
    ok = np.isfinite(ch) & np.isfinite(z)
    grids = {}
    for key, v in vals.items():
        m = ok & np.isfinite(v)
        g = griddata((ch[m], z[m]), v[m], (GXg, GYg), method='linear')
        g[GYg > seabed[None, :]] = np.nan
        g[:, (grid_x < np.nanmin(ch[ok])) | (grid_x > np.nanmax(ch[ok]))] = np.nan
        grids[key] = g
    return grids, md

n_figs = 0
for lname, meta in LINE_META.items():
    if ONLY_LINE and lname != ONLY_LINE: continue
    if lname == 'L2': continue   # L2 is produced by transect_L2_estuary_validation.py
                                 # (estuary+offshore); this script must NOT overwrite L2_*.png
    master = [s for s in meta['master'] if s in TL.COORDS]
    mpts, mch = TL.main_chainage(master, meta.get('ref_station'))
    master_set = set(master); master_ch = dict(zip(master, mch)); mch_arr = np.array(mch)
    poly = np.array([(TL.COORDS[s][1], TL.COORDS[s][0]) for s in master])   # (lon, lat) along master
    mseab_stn = np.array([TL.station_max_depth(s) for s in master]) + 0.5
    _v = ~np.isnan(mseab_stn)
    if _v.any() and not _v.all():
        mseab_stn[~_v] = np.interp(mch_arr[~_v], mch_arr[_v], mseab_stn[_v])
    mseab_stn = np.nan_to_num(mseab_stn, nan=10.0)
    scales = TL.SCALES[lname]

    # Fixed FULL-MASTER grid + seabed + depth axis + landmarks, computed ONCE per
    # line. The model is sampled/regridded on this same grid every day (identical
    # path & grid; only the time changes) and always spans the whole transect;
    # the obs column stays masked to that day's own stations. (Mirrors the dense
    # fixed-line convention used for Transect A.)
    grid_x = np.linspace(mch_arr[0] - meta['ghost_km'], mch_arr[-1] + meta['ghost_km'], 800)
    seabed = TL.sample_seabed(master, mch, grid_x, mch_arr, mseab_stn)
    depth_lim = min(meta['depth_max'], float(seabed.max()) + 3)
    grid_y = np.arange(0, depth_lim + meta['dz'], meta['dz'])
    GX = np.tile(grid_x[None, :], (len(grid_y), 1)); GY = np.tile(grid_y[:, None], (1, len(grid_x)))
    s_lat = min(TL.COORDS[s][0] for s in master); n_lat = max(TL.COORDS[s][0] for s in master)
    feats = []
    for ft in FEATURES.get(lname, []):
        if ft.get('beyond_end') and not (s_lat > ft['lat']): continue
        if ft.get('beyond_start') and not (n_lat < ft['lat']): continue
        fc, fd = (0.0, 0.0) if ft.get('at_zero') else TL.feature_chainage(ft['lat'], ft['lon'], mpts, mch)
        if fd <= TL.FEATURE_MAX_DIST: feats.append((ft['name'], fc))
    xlo = min([grid_x[0]] + [c - 1.5 for _, c in feats]); xhi = max([grid_x[-1]] + [c + 1.5 for _, c in feats])

    for jd, cfg in sorted(meta['by_jday'].items()):
        if ONLY_JD and jd != ONLY_JD: continue
        stations = [s for s in TL.active_set(cfg) if s in TL.COORDS]
        xs_map = {s: (master_ch[s] if s in master_set else TL.project_chainage(s, mpts, mch)) for s in stations}
        ref = TL.outer_ref_minutes(stations, jd)
        profiles, picked_time = {}, {}
        for s in stations:
            for m, fn in sorted(TL.casts.get((s, jd), []), key=lambda t: abs(t[0] - ref)):
                p = TL.load_profile(s, fn, meta['depth_max'] + 20)
                if p:
                    profiles[s] = p; picked_time[s] = m; break
        if len(profiles) < TL.MIN_STATIONS:
            print(f'{lname} jday {jd}: {len(profiles)} stns — skip'); continue

        stns = sorted(profiles, key=lambda s: xs_map[s]); xs = np.array([xs_map[s] for s in stns])
        tmin, tmax = min(picked_time.values()), max(picked_time.values())
        mid_dt = datetime(1991, 1, 1) + timedelta(days=jd - 1, minutes=0.5 * (tmin + tmax))
        mgrids, md = model_curtain_grids(poly, mpts, mch, grid_x, grid_y, seabed, mid_dt)
        print(f'{lname} jday {jd}: {len(stns)} stns | model curtain @ {md:%d-%b %H:%M}', flush=True)

        fig, axes = plt.subplots(3, 2, figsize=(23, 14), sharex=True, sharey=True)
        row_cf = [None, None, None]
        for ri, (var, label, cmap, key) in enumerate(TL.VAR_CFG):
            levels = scales[key]; norm = BoundaryNorm(levels, ncolors=cmap.N, clip=True)
            g_obs = TL.build_section(profiles, xs_map, var, grid_x, seabed, grid_y, meta['ghost_km'])
            g_mod = mgrids.get(var)
            cf = None
            for ci, (g, is_mod) in enumerate([(g_obs, False), (g_mod, True)]):
                ax = axes[ri, ci]
                if g is not None:
                    cf = ax.contourf(GX, GY, g, levels=levels, cmap=cmap, norm=norm, extend='both')
                    cl = ax.contour(GX, GY, g, levels=levels[::2], colors='k', linewidths=0.4); ax.clabel(cl, fmt='%.1f', fontsize=7, inline=True)
                fx = np.concatenate([[xlo], grid_x, [xhi]]); fs = np.concatenate([[seabed[0]], seabed, [seabed[-1]]])
                ax.fill_between(fx, fs, depth_lim + 5, color='#8B7355', zorder=3); ax.plot(fx, fs, '-', color='k', lw=0.7, zorder=4)
                for fname, fc in feats:
                    top = float(np.interp(fc, grid_x, seabed)); ax.plot([fc, fc], [top, depth_lim], ls=(0, (6, 4)), color='k', lw=1.0, alpha=0.8, zorder=6)
                    if ri == 0:
                        right = 'Mandurah' in fname   # channel label to the left of its line
                        ax.text(fc + (-0.4 if right else 0.4), min(TL.FEATURE_LABEL_Y, depth_lim - 0.5), fname,
                                rotation=0, ha='right' if right else 'left', va='center',
                                fontsize=8, fontweight='bold', zorder=11, clip_on=False,
                                bbox=dict(boxstyle='round,pad=0.2', fc='white', ec='0.4', lw=0.4, alpha=0.85))
                if not is_mod:
                    for sx, s in zip(xs, stns):
                        c = 'k' if s in master_set else '#e07b00'
                        ax.plot([sx, sx], [0, 0.02 * depth_lim], '-', color=c, lw=0.9, zorder=5)
                        ax.text(sx, -0.035 * depth_lim, s, fontsize=6.5, rotation=90, ha='center', va='bottom', color=c, zorder=5)
                ax.set_ylim(depth_lim, -0.12 * depth_lim); ax.set_xlim(xlo, xhi); ax.tick_params(labelsize=10)
                if ci == 0: ax.set_ylabel('Depth (m)', fontsize=12)
                if ri == 0: ax.set_title('OBSERVED (CTD)' if not is_mod else f'MODEL @ {md:%d-%b %H:%M}', fontsize=13, fontweight='bold')
                if ri == 2: ax.set_xlabel(meta['xlabel'], fontsize=12)
            axes[ri, 0].text(-25, 25, label, fontsize=13, fontweight='bold',
                             ha='center', va='center', zorder=12, bbox=dict(boxstyle='round,pad=0.3', fc='white', ec='0.5', alpha=0.9))
            row_cf[ri] = cf

        date = (datetime(1991, 1, 1) + timedelta(days=jd - 1)).strftime('%d %b %Y')
        storm = ('PRE-STORM', '#b8860b') if jd in TL.PRE_JDAYS else ('POST-STORM', '#228B22')
        fig.suptitle(f"{meta['title']} — OBS vs MODEL\n{date} (jday {jd}) — {storm[0]} — obs casts "
                     f"{tmin//60:02.0f}:{tmin%60:02.0f}–{tmax//60:02.0f}:{tmax%60:02.0f} WST | model {md:%d-%b %H:%M}",
                     fontsize=15, color=storm[1], fontweight='bold', y=0.99)
        # tight obs|model gap (model shifted left); one colorbar per row on the right edge
        fig.subplots_adjust(left=0.045, right=0.925, top=0.915, bottom=0.055,
                            wspace=0.04, hspace=0.14)
        for ri in range(3):
            if row_cf[ri] is None:
                continue
            p = axes[ri, 1].get_position()
            cax = fig.add_axes([0.935, p.y0, 0.012, p.height])
            fig.colorbar(row_cf[ri], cax=cax).ax.tick_params(labelsize=9)
        out = os.path.join(OUT_DIR, f'{lname}_{jd}.png')
        fig.savefig(out, dpi=145); plt.close(fig); n_figs += 1
        print(f'  wrote {os.path.basename(out)}', flush=True)

print(f'\n{n_figs} obs-vs-model section figures -> {OUT_DIR}')
