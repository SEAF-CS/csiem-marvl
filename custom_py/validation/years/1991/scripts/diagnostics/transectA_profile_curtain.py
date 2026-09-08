"""TransectA profile-curtain (1991) — model density curtain along the N->S transect +
10 concurrent obs-vs-model profiles + map inset (style after profile_curtain.ipynb).
10 profiles = 8 TransectA CTD stations (spread N->S) + 2 at the velocity moorings
(CSC1 ~chain -5.1, CSC3 ~chain +1.4), each using its nearest concurrent CTD cast.
Two figures: pre-storm (jday 226, 14 Aug) and post-storm (jday 234, 22 Aug).
Density = full EOS-80 (kg m-3, 1024-1027) to match the reference.
-> years/1991/outputs/diagnostics/transectA_profile_curtain_{pre,post}.png
"""
import os, numpy as np, pandas as pd
# --- reuse run_transectA.py machinery (COORDS, chainage_km, read_dfv, aug_casts, fv, model_profiles_at, bathy) ---
RT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/scripts/run_transectA.py'
_src = open(RT, encoding='utf-8').read()
_prefix = _src[:_src.index('# === Comparison figure')]          # everything up to (not incl.) the render section
G = {}; exec(compile(_prefix, RT, 'exec'), G)
COORDS, chainage_km, read_dfv = G['COORDS'], G['chainage_km'], G['read_dfv']
haversine_m, PROFILE_BASE, aug_casts = G['haversine_m'], G['PROFILE_BASE'], G['aug_casts']
fv, model_profiles_at, snap_time = G['fv'], G['model_profiles_at'], G['snap_time']
ref_stns, bathy_chain, bathy_plot = G['ref_stns'], G['bathy_chain'], G['bathy_plot']
build_cross_section, grid_x, grid_y = G['build_cross_section'], G['grid_x'], G['grid_y']
eos80 = G['eos80_potential_density']
# NOTE: live 1991_aug_rev NC is mid-write by a new sim (only reaches Jul 23) -> use the
# latest COMPLETE snapshot (ITER9) for the model. Repoint to ITER10/11 once archived+complete.
import xarray as xr, tfv.xarray
COMPLETE_NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev_ITER9/csiem_B010_19910720_19910831_rev.nc'
_dsC = xr.open_dataset(COMPLETE_NC); G['fv'] = _dsC.tfv; G['times'] = pd.to_datetime(_dsC['Time'].values)
fv = G['fv']; snap_time = G['snap_time']; model_profiles_at = G['model_profiles_at']; ds_model = _dsC
print('MODEL = ITER9 snapshot (live NC is mid-write); ntime', len(G['times']))
import matplotlib.pyplot as plt
from matplotlib import cm, colors
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics'
os.makedirs(OUT, exist_ok=True)

# velocity moorings (1991) — chainage anchors for the 2 velocity-site profiles
def dms(d, m, s): return d + m/60 + s/3600
MOOR = {'CSC1': (-dms(32,8,53), dms(115,41,14)), 'CSC3': (-dms(32,11,37.2), dms(115,42,1.8))}
def chain_pt(la, lo):
    d = haversine_m(COORDS['CS55'][0], COORDS['CS55'][1], la, lo)
    return (-d if la > COORDS['CS55'][0] else d) / 1000.0
MOOR_CH = {k: chain_pt(v[0], v[1]) for k, v in MOOR.items()}
DLEV = np.arange(1024.0, 1027.05, 0.1)                 # full density levels (kg m-3)

# canonical "Default Transect A" route (from smcws Transect_A/map_panel_windows.py) -> curtain + map line
DEFAULT_ROUTE = ['OA10','OA15','OA20','OA25','OA65','OA80','CS20','CS45','CS55','CS85','CS105','CS155','CS135','CS140','CS145','CS150']
_RCH = [chainage_km(s) for s in DEFAULT_ROUTE if chainage_km(s) is not None]
XLIM = (min(_RCH) - 1, max(_RCH) + 1)                  # COMMON curtain x-range (full route) across the whole set
# velocity current-meter files per mooring (1991), for the vectors on the velocity-site panels
VELFILES = {'CSC1': [('c02s0891.dat','top'), ('c02b0891.dat','near-bed')], 'CSC3': [('c04s0891.dat','top')]}
VEL_CUR = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/currents_data'
import re
_VREC = re.compile(r'^\s*(\d{1,4}):\s*(\d{1,2})\s+(\d{1,2})\s?(\d{1,2})\s?(\d{2})\s+'
                   r'(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(?:-?[\d.]+\s+){0,2}(-?[\d.]+)\s*$')
def read_vel_meter(path):
    txt = open(path, errors='replace').read()
    ht = re.search(r'(?i)meter\s*height[^:]*:\s*([\d.]+)', txt); dp = re.search(r'(?i)water\s*depth\s*:?\s*([\d.]+)', txt)
    from datetime import datetime as _dt
    t, e, n = [], [], []
    for line in txt.splitlines():
        m = _VREC.match(line)
        if not m: continue
        try:
            hh, mi = divmod(int(m.group(1)), 100)
            t.append(_dt(1900+int(m.group(5)), int(m.group(4)), int(m.group(3)), hh, mi, int(m.group(2))))
        except ValueError: continue
        e.append(float(m.group(8))); n.append(float(m.group(9)))       # cm/s, E and N components
    t = np.array(t); e = np.array(e); n = np.array(n)
    g = (np.abs(e) < 300) & (np.abs(n) < 300)                          # drop -8888 flags
    return dict(height=float(ht.group(1)) if ht else np.nan, depth=float(dp.group(1)) if dp else np.nan,
                t=t[g], e=e[g], n=n[g])
def mooring_vectors(moor, when):   # -> [(depth_below_surf, height_above_bed, N_cmps, E_cmps), ...] nearest the cast time
    out = []; when = pd.Timestamp(when).to_pydatetime()
    for fn, _lvl in VELFILES.get(moor, []):
        p = os.path.join(VEL_CUR, moor, fn)
        if not os.path.exists(p): continue
        m = read_vel_meter(p)
        if len(m['t']) == 0 or not np.isfinite(m['depth']): continue
        dts = np.array([abs((x - when).total_seconds()) for x in m['t']])
        k = int(np.argmin(dts))
        if dts[k] > 3*3600: continue                                       # nothing within 3 h of the cast
        out.append((m['depth'] - m['height'], m['height'], float(m['n'][k]), float(m['e'][k])))
    return out

def model_vel_profiles_at(md, stations):   # V_x/V_y vertical profiles (cm/s) at route stations -> curtain quiver field
    vp = {}
    for stn in stations:
        if stn not in COORDS: continue
        lat, lon = COORDS[stn]
        try:
            p = fv.get_profile((lon, lat), variables=['V_x', 'V_y'], time=md)
            pt = p.sel(Time=md, method='nearest') if 'Time' in p.dims else p
            depth = -np.asarray(pt['Z']).ravel()
            vx = np.asarray(pt['V_x']).ravel() * 100; vy = np.asarray(pt['V_y']).ravel() * 100
            ok = np.isfinite(depth) & np.isfinite(vx) & np.isfinite(vy) & (depth > 0.1)
            if ok.sum() < 2: continue
            o = np.argsort(depth[ok]); vp[stn] = {'depth': depth[ok][o], 'vx': vx[ok][o], 'vy': vy[ok][o]}
        except Exception:
            pass
    return vp

def model_vel_at_time(lon, lat, height, when):   # model (N,E) cm/s at the nearest output hour to `when` (V_x=E, V_y=N)
    t0 = pd.Timestamp(when).round('h')
    try:
        r = fv.get_timeseries(['V_x', 'V_y'], (lon, lat), datum='height',
                              time=slice(t0 - pd.Timedelta(hours=1.5), t0 + pd.Timedelta(hours=1.5)),
                              limits=(max(0.1, height - 0.75), height + 0.75))
        rt = pd.to_datetime(r['Time'].values)
        if len(rt) == 0: return np.nan, np.nan
        k = int(np.argmin(np.abs((rt - t0).total_seconds())))             # nearest record to the rounded hour
        return float(np.asarray(r['V_y'], float).ravel()[k]) * 100, float(np.asarray(r['V_x'], float).ravel()[k]) * 100
    except Exception as ex:
        print(f'  model_vel fail ({lon:.3f},{lat:.3f},h={height}): {ex}'); return np.nan, np.nan

def field_profiles_for_jday(jday):
    profs = {}
    for c in [c for c in aug_casts if c['jday'] == jday]:
        p = os.path.join(PROFILE_BASE, c['station'], f"dfv{c['time']}.{c['jday']}")
        if os.path.exists(p):
            r = read_dfv(p)
            if r is not None: profs[c['station']] = r
    return profs

def select_10(avail):
    ch = {s: chainage_km(s) for s in avail if chainage_km(s) is not None}
    vel = {}
    for m, mch in MOOR_CH.items():
        s = min(ch, key=lambda x: abs(ch[x] - mch)); vel[s] = m
    others = [s for s in ch if s not in vel]
    targets = np.linspace(min(ch.values()), max(ch.values()), 8)
    chosen = []
    for t in targets:
        cand = [s for s in others if s not in chosen]
        if cand: chosen.append(min(cand, key=lambda s: abs(ch[s] - t)))
    ten = sorted(set(list(vel) + chosen), key=lambda s: ch[s])
    # top up to 10 if dedup shrank it
    for s in sorted(others, key=lambda s: ch[s]):
        if len(ten) >= 10: break
        if s not in ten: ten = sorted(ten + [s], key=lambda s: ch[s])
    return ten[:10], vel

def full_density(prof):   # normalise a profile's density to full kg m-3
    d = np.asarray(prof['density'], float)
    return d + 1000.0 if np.nanmedian(d) < 100 else d

# surface density field for the map inset
cx = ds_model['cell_X'].values; cy = ds_model['cell_Y'].values

def make_fig(jday, phase, tag):
    profs_f = field_profiles_for_jday(jday)
    if len(profs_f) < 5:
        print(f'{phase}: only {len(profs_f)} field profiles — skip'); return
    ten, vel = select_10(profs_f.keys())
    cast_dt = {c['station']: c['dt'] for c in aug_casts if c['jday'] == jday}   # actual cast time per station
    cal = pd.Timestamp('1991-01-01') + pd.Timedelta(days=jday-1)
    md = snap_time(pd.Timestamp(cal.replace(hour=12)))
    print(f'{phase} (jday {jday}, model {md:%d-%b %H:%M}): 10 = {ten}  velocity={vel}')
    # model curtain (all ref stations) + model profiles at the 10
    mprof_all = model_profiles_at(md)
    mprof_route = {s: mprof_all[s] for s in DEFAULT_ROUTE if s in mprof_all}   # curtain on the STANDARD route
    gv = build_cross_section(mprof_route, 'density', bathy_chain, bathy_plot) + 1000.0
    vprofs = model_vel_profiles_at(md, DEFAULT_ROUTE)                          # velocity profiles for the curtain quiver
    mprof10 = {s: mprof_all[s] for s in ten if s in mprof_all}
    # surface density (map)
    s = fv.get_sheet(['SAL', 'TEMP'], time=md, datum='depth', limits=(0, 2), agg='mean')
    dsurf = eos80(np.asarray(s['SAL']).ravel().astype(float), np.asarray(s['TEMP']).ravel().astype(float))

    fig = plt.figure(figsize=(16, 11))
    gs = fig.add_gridspec(3, 6, width_ratios=[1,1,1,1,1,0.95], height_ratios=[1.2,1,1], hspace=0.28, wspace=0.12)
    axT = fig.add_subplot(gs[0, :5]); axcb = fig.add_axes([0.845, 0.70, 0.012, 0.20])
    paxes = [fig.add_subplot(gs[r, c]) for r in (1, 2) for c in range(5)]
    axmap = fig.add_subplot(gs[1:, 5])

    # --- curtain ---
    cf = axT.contourf(grid_x, -grid_y, gv, levels=DLEV, cmap='jet', extend='both')
    fig.colorbar(cf, cax=axcb).set_label('Density (kg m$^{-3}$)', fontsize=9)
    # velocity quiver overlay (along-transect N-S horizontal flow; V_y=northward, no vertical W in the output)
    if len(vprofs) >= 3:
        gvy = build_cross_section(vprofs, 'vy', bathy_chain, bathy_plot)       # northward cm/s on (grid_y, grid_x), bathy-masked
        VCAP = 30.0                                                            # display speed cap (cm/s)
        schain = [chainage_km(s) for s in vprofs]; smin, smax = min(schain), max(schain)
        xi = [j for j in range(0, len(grid_x), max(1, len(grid_x)//26)) if smin <= grid_x[j] <= smax]   # dense field, station span only
        yi = [int(np.argmin(np.abs(grid_y - d))) for d in range(2, 22, 2)]
        Xq, Yq, Uq = [], [], []
        for jy in yi:
            for jx in xi:
                u = gvy[jy, jx]
                if np.isfinite(u): Xq.append(grid_x[jx]); Yq.append(-grid_y[jy]); Uq.append(-np.clip(u, -VCAP, VCAP))  # N->left
        if Xq:                                                                # ipynb style: uniform scale, dense; white arrows w/ dark edge
            QC = axT.quiver(Xq, Yq, Uq, np.zeros(len(Uq)), color='white', edgecolor='0.15', linewidth=0.5,
                            width=0.0035, scale=300, scale_units='width', pivot='mid', zorder=7)
            axT.quiverkey(QC, 0.035, 1.05, 20, '20 cm/s (N◄|►S)', labelpos='E', coordinates='axes', fontproperties=dict(size=8))
    for st in ten:
        x = chainage_km(st); mk = 's' if st in vel else 'v'
        axT.axvline(x, color='white', ls='--', lw=0.9, alpha=0.85, zorder=6)
        axT.plot(x, 0, marker=mk, ms=8, mfc=('gold' if st in vel else 'white'), mec='k', clip_on=False, zorder=8)
        axT.text(x, 0.6, (vel[st]+'\n'+st if st in vel else st), fontsize=7, ha='center', va='bottom',
                 fontweight='bold', color=('darkgreen' if st in vel else 'black'), zorder=9)
    axT.set_xlim(*XLIM); axT.set_ylim(-25, 2)              # COMMON x-range (full route) for cross-day comparison
    axT.set_xlabel('Chainage from CS55 (km)   [N ◄  ► S]', fontsize=10); axT.set_ylabel('Depth (m)', fontsize=10)
    axT.set_title(f'TransectA profile-curtain — {phase} (jday {jday}, {cal:%d-%b-%Y})  |  model {md:%d-%b %H:%M}',
                  fontsize=12, fontweight='bold')

    # --- 10 profiles ---
    dmean = np.nanmean([np.nanmean(full_density(profs_f[s])) for s in ten if s in profs_f])
    qkey = None; qkey_ax = None                      # capture one model/obs quiver for a shared scale key
    for i, st in enumerate(ten):
        ax = paxes[i]
        if st in profs_f:
            p = profs_f[st]; ax.plot(full_density(p), -np.asarray(p['depth']), '-o', color='crimson', lw=1.8, ms=2.5, label='Obs')
        if st in mprof10:
            mp = mprof10[st]; ax.plot(np.asarray(mp['density'])+1000, -np.asarray(mp['depth']), '-s', color='steelblue', lw=1.8, ms=2.5, label='Model')
        ax.axvline(dmean, color='grey', ls='--', lw=1.5, alpha=0.7)
        if st in vel:                                    # velocity quivers at meter depths (left=N, right=S)
            x0, VSC, DZ = 1025.5, 0.06, 0.4               # ref x; density-units per cm/s (amplified); obs/model depth split (m)
            mla, mlo = MOOR[vel[st]]                       # actual mooring coords for the model extraction
            when = cast_dt.get(st, pd.Timestamp(cal).replace(hour=12))     # sample both at the cast time
            for depth, hgt, N, E in mooring_vectors(vel[st], when):
                Nm, Em = model_vel_at_time(mlo, mla, hgt, when)            # model at the nearest output hour
                yo, ym = -depth + DZ, -depth - DZ                          # obs above, model below (no overlap)
                qo = ax.quiver(x0, yo, -N, 0.0, angles='xy', scale_units='xy', scale=1/VSC,
                               color='purple', width=0.013, zorder=10); qo.set_clip_on(False)
                ax.plot(x0, yo, 'o', ms=3.0, color='purple', zorder=11)
                if np.isfinite(Nm):
                    qm = ax.quiver(x0, ym, -Nm, 0.0, angles='xy', scale_units='xy', scale=1/VSC,
                                   color='steelblue', width=0.011, zorder=9); qm.set_clip_on(False)
                    ax.plot(x0, ym, 'o', ms=3.0, color='steelblue', zorder=11)
                if qkey is None: qkey, qkey_ax = qo, ax
        if st in profs_f and st in mprof10:      # obs-model density bias over the depth overlap
            od = np.asarray(profs_f[st]['depth'], float); ov = full_density(profs_f[st])
            mdp = np.asarray(mprof10[st]['depth'], float); mv = np.asarray(mprof10[st]['density'], float) + 1000
            o = np.argsort(mdp); mdp, mv = mdp[o], mv[o]
            sel = (od >= max(od.min(), mdp.min())) & (od <= min(od.max(), mdp.max()))
            if sel.sum() >= 3:
                bias = np.nanmean(np.interp(od[sel], mdp, mv) - ov[sel])
                ax.text(0.05, 0.045, f'Δρ {bias:+.2f}', transform=ax.transAxes, fontsize=7.5,
                        color='steelblue', va='bottom', fontweight='bold')
        ttl = f"{vel[st]} (~{st})" if st in vel else st
        ax.set_title(ttl, fontsize=9.5, fontweight='bold', color=('darkgreen' if st in vel else 'black'))
        ax.set_xlim(1024, 1027); ax.set_ylim(-25, 0); ax.grid(alpha=0.3); ax.tick_params(axis='x', labelrotation=30, labelsize=7)
        if i < 5: ax.tick_params(labelbottom=False)
        else: ax.set_xlabel('Density (kg m$^{-3}$)', fontsize=8)
        if i in (0, 5): ax.set_ylabel('Depth (m)', fontsize=8)
        else: ax.tick_params(labelleft=False)
    if qkey is not None:                                          # shared 20 cm/s scale key on the first velocity panel
        qkey_ax.quiverkey(qkey, 0.66, 0.90, 20, '20 cm/s', labelpos='E', coordinates='axes',
                          fontproperties=dict(size=7), color='0.25')
    for j in range(len(ten), len(paxes)): paxes[j].axis('off')   # hide unused panels (occupations with <10 stations)

    # --- map ---
    axmap.scatter(cx, cy, c=dsurf, s=2, cmap='jet', vmin=1024, vmax=1027, edgecolors='none')
    poly = np.array([[COORDS[s][1], COORDS[s][0]] for s in DEFAULT_ROUTE])   # STANDARD Transect-A route
    axmap.plot(poly[:, 0], poly[:, 1], 'r-', lw=1.8, zorder=4)
    for st in ten:
        la, lo = COORDS[st]; axmap.plot(lo, la, 'o', ms=5, mfc=('gold' if st in vel else 'yellow'), mec='k', zorder=6)
    for m, (la, lo) in MOOR.items():
        axmap.plot(lo, la, '*', ms=13, mfc='lime', mec='k', zorder=7); axmap.text(lo+0.002, la, m, fontsize=8, color='darkgreen', fontweight='bold')
    axmap.set_xlim(115.62, 115.76); axmap.set_ylim(-32.32, -32.03); axmap.set_aspect(1/np.cos(np.radians(-32.2)))
    axmap.set_title('Transect map (surface density)', fontsize=9); axmap.tick_params(labelsize=7)
    axmap.set_xlabel('Lon', fontsize=8)

    fig.legend(handles=[Line2D([0],[0],color='crimson',lw=2,marker='o',label='Observed (CTD)'),
                        Line2D([0],[0],color='steelblue',lw=2,marker='s',label='Model'),
                        Line2D([0],[0],color='grey',lw=2,ls='--',label=f'10-profile mean ({dmean:.2f})'),
                        Line2D([0],[0],marker='*',color='w',mfc='lime',mec='k',ms=12,label='Velocity mooring'),
                        Line2D([0],[0],color='purple',lw=2.4,marker='>',ms=6,label='Obs velocity @cast (◄N | S►)'),
                        Line2D([0],[0],color='steelblue',lw=2.0,marker='>',ms=6,label='Model velocity @cast hr')],
               loc='lower center', ncol=6, fontsize=8, bbox_to_anchor=(0.42, 0.003))
    fig.subplots_adjust(top=0.93, bottom=0.09, left=0.05, right=0.985)
    out = f'{OUT}/transectA_profile_curtain_{tag}.png'
    fig.savefig(out, dpi=160, bbox_inches='tight'); plt.close(fig); print('wrote', out)

# ---- full pre/post-storm set: one figure per survey occupation (storm ~19-Aug = jday 231) ----
STORM_JDAY, MIN_STN = 231, 6
from collections import defaultdict
_present = defaultdict(set)
for c in aug_casts:
    p = os.path.join(PROFILE_BASE, c['station'], f"dfv{c['time']}.{c['jday']}")
    if os.path.exists(p) and chainage_km(c['station']) is not None:
        _present[c['jday']].add(c['station'])
OCC = sorted(_present)
import sys; ONLY = int(sys.argv[1]) if len(sys.argv) > 1 else None            # optional: render a single jday for quick iteration
print(f'occupations: {OCC}  (storm jday {STORM_JDAY}){"  ONLY="+str(ONLY) if ONLY else ""}')
made = []
for k, jd in enumerate(OCC, 1):
    if ONLY is not None and jd != ONLY: continue
    cal = pd.Timestamp('1991-01-01') + pd.Timedelta(days=jd-1)
    pre = jd < STORM_JDAY
    phase = 'PRE-STORM' if pre else 'POST-STORM'
    if len(_present[jd]) < MIN_STN:
        print(f'  skip jday {jd} ({cal:%d-%b}): only {len(_present[jd])} chainable stations (<{MIN_STN})'); continue
    tag = f'{k:02d}_{cal:%d%b}_{"pre" if pre else "post"}'
    make_fig(jd, phase, tag)
    made.append(tag)
print(f'done — {len(made)} figures: {made}')
