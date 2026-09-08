"""Velocity VALIDATION — CSIEM model vs SMCWS moored current meters (year-parameterized).

Per mooring/level a validation card: speed time series (obs vs model) | current sticks
(obs up / model down, direction TOWARD) | hodograph (E-N cloud + principal-axis lines +
skill box). Model velocity is extracted at each meter's height above bed (tfv
get_timeseries datum='height', a +/-0.75 m band — zero-width returns NaN). V m/s -> cm/s.

Skill per meter (hourly-aligned, on the overlap): speed bias & RMSE, complex vector
correlation |rho| + veering (arg), principal-axis error. Written to velocity_skill_{year}.csv.

Year auto-detected from this file's path (years/<YYYY>/...); override with argv[1].
Uses the ITER6 1991 NC (clean/complete) and the 1992 marmay NC.
-> outputs/diagnostics/velocity_validation_{year}.png  (+ velocity_skill_{year}.csv)
"""
import matplotlib; matplotlib.use('Agg')
import os, re, sys, numpy as np, pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.gridspec import GridSpec
from datetime import datetime, timedelta
import xarray as xr
os.environ['TQDM_DISABLE'] = '1'
import tfv.xarray

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
YEAR_DIR   = os.path.abspath(os.path.join(SCRIPT_DIR, '..', '..'))
_m = re.search(r'years[/\\](\d{4})', YEAR_DIR)
YEAR = sys.argv[1] if len(sys.argv) > 1 else (_m.group(1) if _m else '1991')
SMCWS = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS'
OUT_DIR = os.path.join(YEAR_DIR, 'outputs', 'TimeSeries'); os.makedirs(OUT_DIR, exist_ok=True)
OBS_C, MOD_C = '#1f5c8b', '#c1272d'

# per-year config: model NC, extraction window, event markers, and meter series
YEARS = {
    '1991': dict(
        nc=r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc',   # current ITER7 rev (ITER6 was the dev reference)
        win=(datetime(1991, 8, 10), datetime(1991, 8, 31)),
        events=[(datetime(1991, 8, 19), '19 Aug storm')],
        series=[('CSC1', 'c02s0891.dat', 'top'), ('CSC1', 'c02b0891.dat', 'near-bed'),
                ('CSC2', 'c03s0891.dat', 'top'), ('CSC2', 'c03b0891.dat', 'near-bed'),
                ('CSC3', 'c04s0891.dat', 'top'),  # CSC3 near-bed velocity unreliable (temp only)
                ('SDC1', 'c01m0891.dat', 'mid')]),
    '1992': dict(
        nc=r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc',
        win=(datetime(1992, 3, 4), datetime(1992, 4, 10)),   # intensive + ADCP window (whole NC is slow)
        events=[(datetime(1992, 3, 24), 'ADCP'), (datetime(1992, 3, 25), '')],
        series=[('CSC4', 'c05s0392.dat', 'top'), ('CSC4', 'c05b0392.dat', 'near-bed'),
                ('CSC5', 'c06m0392.dat', 'mid'), ('CSC5', 'c06b0392.dat', 'near-bed'),
                ('SDC1', 'c01b0392.dat', 'near-bed'), ('SW1', 'c07b0392.dat', 'near-bed')]),
}
CFG = YEARS[YEAR]; WIN0, WIN1 = CFG['win']; CUR = f'{SMCWS}/{YEAR}/currents_data'
print(f'YEAR={YEAR}  window {WIN0:%d %b}-{WIN1:%d %b}  {len(CFG["series"])} series', flush=True)

REC_RE = re.compile(r'^\s*(\d{1,4}):\s*(\d{1,2})\s+(\d{1,2})\s?(\d{1,2})\s?(\d{2})\s+'
                    r'(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+'
                    r'(?:-?[\d.]+\s+){0,2}(-?[\d.]+)\s*$')

def _dms(txt, pat):
    m = re.search(pat, txt)
    if not m: return np.nan
    val = float(m.group(1)) + float(m.group(2))/60 + float(m.group(3))/3600
    return -val if m.group(4).upper() in ('S', 'W') else val

def read_meter(path):
    txt = open(path, errors='replace').read()
    ht  = re.search(r'(?i)meter\s*height[^:]*:\s*([\d.]+)', txt)
    dep = re.search(r'(?i)water\s*depth\s*:?\s*([\d.]+)', txt)
    lat = _dms(txt, r'(?i)latitude\s*:?\s*(\d+)\s+(\d+)\s+([\d.]+)\s*([NS])')
    lon = _dms(txt, r'(?i)longitude\s*:?\s*(\d+)\s+(\d+)\s+([\d.]+)\s*([EW])')
    t, sp, e, n = [], [], [], []
    for line in txt.splitlines():
        m = REC_RE.match(line)
        if not m: continue
        try:
            hh, mi = divmod(int(m.group(1)), 100)
            t.append(datetime(1900+int(m.group(5)), int(m.group(4)), int(m.group(3)), hh, mi, int(m.group(2))))
        except ValueError:
            continue
        sp.append(float(m.group(7))); e.append(float(m.group(8))); n.append(float(m.group(9)))
    t = np.array(t); sp = np.array(sp); e = np.array(e); n = np.array(n)
    # 1992 files mislabel cm/s as m/s but values are cm/s; convert only if genuinely m/s-scale
    if len(sp) and np.median(sp[sp > -8000]) < 1.5 and re.search(r'\(m/s\)', txt):
        e, n = e*100, n*100; sp = np.where(sp > -8000, sp*100, sp)
    good = (sp >= 0) & (sp < 300) & (np.abs(e) < 300) & (np.abs(n) < 300)
    return dict(lat=lat, lon=lon, height=float(ht.group(1)) if ht else np.nan,
                depth=float(dep.group(1)) if dep else np.nan, t=t[good], e=e[good], n=n[good])

def subset(t, *vs):
    if len(t) == 0: return (t,) + vs
    m = (t >= np.datetime64(WIN0)) & (t <= np.datetime64(WIN1))
    return (t[m],) + tuple(v[m] for v in vs)

def bin_mean(t, *vs, hours=6):
    if len(t) == 0: return (np.array([]),) * (len(vs)+1)
    t0 = pd.Timestamp(t[0]).replace(minute=0, second=0)
    idx = np.array([int((pd.Timestamp(x)-t0).total_seconds() // (hours*3600)) for x in t])
    ks = np.unique(idx)
    ct = np.array([t0 + timedelta(hours=float(k)*hours + hours/2) for k in ks])
    return (ct, *[np.array([np.nanmean(v[idx == k]) for k in ks]) for v in vs])

def to_grid(t, v, grid_ns):
    if len(t) == 0: return np.full(len(grid_ns), np.nan)
    ts = np.array([pd.Timestamp(x).value for x in t], float)
    return np.interp(grid_ns, ts, v, left=np.nan, right=np.nan)

def princ_axis(e, n):
    if np.isfinite(e).sum() < 3: return np.nan
    ev, evec = np.linalg.eigh(np.cov(e[np.isfinite(e)], n[np.isfinite(n)]))
    return np.degrees(np.arctan2(evec[0, -1], evec[1, -1])) % 180

# ---- model ----
print('opening model NC ...', flush=True)
ds = xr.open_dataset(CFG['nc']); fv = ds.tfv
def model_ts(lon, lat, height):
    lim = (max(0.1, height - 0.75), height + 0.75)
    r = fv.get_timeseries(['V_x', 'V_y'], (lon, lat), time=slice(pd.Timestamp(WIN0), pd.Timestamp(WIN1)),
                          datum='height', limits=lim)
    mt = np.array(pd.to_datetime(r['Time'].values).to_pydatetime())
    return subset(mt, np.asarray(r['V_x'], float).ravel()*100, np.asarray(r['V_y'], float).ravel()*100)

# ---- load, extract, score ----
GRID = pd.date_range(WIN0, WIN1, freq='H'); GNS = GRID.astype(np.int64).values.astype(float)
rows, skill = [], []
for site, fn, lname in CFG['series']:
    path = os.path.join(CUR, site, fn)
    if not os.path.exists(path):
        print(f'  MISSING {path}'); continue
    try:
        ob = read_meter(path); ot, oe, on = subset(ob['t'], ob['e'], ob['n'])
        if len(ot) < 10: print(f'  {site} {lname}: too few obs'); continue
        mt, me, mn = model_ts(ob['lon'], ob['lat'], ob['height'])
        # hourly-aligned skill
        oE, oN = to_grid(ot, oe, GNS), to_grid(ot, on, GNS)
        mE, mN = to_grid(mt, me, GNS), to_grid(mt, mn, GNS)
        v = np.isfinite(oE) & np.isfinite(oN) & np.isfinite(mE) & np.isfinite(mN)
        os_, ms_ = np.hypot(oE[v], oN[v]), np.hypot(mE[v], mN[v])
        wo, wm = oE[v] + 1j*oN[v], mE[v] + 1j*mN[v]
        rho = np.mean(np.conj(wo)*wm) / np.sqrt(np.mean(np.abs(wo)**2) * np.mean(np.abs(wm)**2))
        sk = dict(site=site, level=lname, height=ob['height'], n=int(v.sum()),
                  obs_spd=os_.mean(), mod_spd=ms_.mean(), bias=ms_.mean()-os_.mean(),
                  rmse=np.sqrt(np.mean((ms_-os_)**2)), vcorr=abs(rho), veer=np.degrees(np.angle(rho)),
                  pax_o=princ_axis(oE[v], oN[v]), pax_m=princ_axis(mE[v], mN[v]))
        skill.append(sk)
        rows.append(dict(tag=f"{site} {lname} ({ob['height']:.1f} m ASB, {ob['depth']:.0f} m)",
                         ot=ot, oe=oe, on=on, mt=mt, me=me, mn=mn, sk=sk))
        print(f"  {site:4s} {lname:8s}: obs {sk['obs_spd']:.1f} mod {sk['mod_spd']:.1f} cm/s  "
              f"bias {sk['bias']:+.1f} rmse {sk['rmse']:.1f} vcorr {sk['vcorr']:.2f} "
              f"veer {sk['veer']:+.0f} pax {sk['pax_o']:.0f}/{sk['pax_m']:.0f}", flush=True)
    except Exception as ex:
        print(f'  {site} {lname} ERROR: {type(ex).__name__}: {ex}', flush=True)

# ---- skill csv ----
csv_path = os.path.join(OUT_DIR, f'velocity_skill_{YEAR}.csv')
pd.DataFrame(skill).to_csv(csv_path, index=False, float_format='%.2f')
print('wrote', csv_path, flush=True)

# ---- figure ----
nr = len(rows)
fig = plt.figure(figsize=(17, 3.05*nr))
gs = GridSpec(nr, 3, width_ratios=[2.4, 2.4, 1.45], hspace=0.55, wspace=0.3,
              left=0.05, right=0.985, top=1-0.5/(3.05*nr), bottom=0.06)
def mark(ax):
    for d, _ in CFG['events']: ax.axvline(d, color='0.4', ls='--', lw=1.1, zorder=1)
for i, r in enumerate(rows):
    sk = r['sk']
    ax1 = fig.add_subplot(gs[i, 0])
    bt, bo = bin_mean(r['ot'], np.hypot(r['oe'], r['on'])); mt, mo = bin_mean(r['mt'], np.hypot(r['me'], r['mn']))
    ax1.plot(bt, bo, '-', color=OBS_C, lw=1.5, label='obs'); ax1.plot(mt, mo, '-', color=MOD_C, lw=1.5, label='model')
    mark(ax1); ax1.set_ylim(0, None); ax1.grid(alpha=0.3); ax1.set_ylabel('speed (cm/s)', fontsize=9)
    ax1.set_title(f"{r['tag']}   —   speed", fontsize=9, loc='left', fontweight='bold')
    ax1.xaxis.set_major_formatter(mdates.DateFormatter('%d %b')); ax1.set_xlim(WIN0, WIN1)
    if i == 0: ax1.legend(fontsize=8, loc='upper right', ncol=2)
    ax2 = fig.add_subplot(gs[i, 1])
    bt, be, bn = bin_mean(r['ot'], r['oe'], r['on']); mt, me, mn = bin_mean(r['mt'], r['me'], r['mn'])
    ax2.quiver(mdates.date2num(bt), np.full(len(bt), 1.0), be, bn, color=OBS_C, scale=260, width=0.004, headwidth=3, angles='uv')
    ax2.quiver(mdates.date2num(mt), np.full(len(mt), -1.0), me, mn, color=MOD_C, scale=260, width=0.004, headwidth=3, angles='uv')
    ax2.axhline(0, color='k', lw=0.3, alpha=0.4); mark(ax2)
    ax2.set_ylim(-2.4, 2.4); ax2.set_yticks([1, -1]); ax2.set_yticklabels(['obs', 'model'], fontsize=8)
    ax2.set_title('current sticks (dir TOWARD, N up)', fontsize=9, loc='left')
    ax2.xaxis.set_major_formatter(mdates.DateFormatter('%d %b')); ax2.set_xlim(WIN0, WIN1)
    ax3 = fig.add_subplot(gs[i, 2])
    _, oe, on = bin_mean(r['ot'], r['oe'], r['on'], hours=1); _, me, mn = bin_mean(r['mt'], r['me'], r['mn'], hours=1)
    ax3.scatter(oe, on, s=6, color=OBS_C, alpha=0.35, edgecolors='none')
    ax3.scatter(me, mn, s=6, color=MOD_C, alpha=0.35, edgecolors='none')
    lim = np.nanmax(np.abs(np.r_[oe, on, me, mn])) * 1.05
    for ee, nn, c in [(oe, on, OBS_C), (me, mn, MOD_C)]:
        pa = princ_axis(ee, nn); L = np.nanpercentile(np.hypot(ee, nn), 95)
        ax3.plot([-L*np.sin(np.radians(pa)), L*np.sin(np.radians(pa))],
                 [-L*np.cos(np.radians(pa)), L*np.cos(np.radians(pa))], color=c, lw=2, alpha=0.9)
    ax3.axhline(0, color='k', lw=0.3, alpha=0.3); ax3.axvline(0, color='k', lw=0.3, alpha=0.3)
    ax3.set_xlim(-lim, lim); ax3.set_ylim(-lim, lim); ax3.set_aspect('equal'); ax3.grid(alpha=0.3)
    ax3.set_xlabel('E (cm/s)', fontsize=8); ax3.set_ylabel('N (cm/s)', fontsize=8); ax3.tick_params(labelsize=7)
    box = (f"spd  o {sk['obs_spd']:.1f}  m {sk['mod_spd']:.1f}\n"
           f"bias {sk['bias']:+.1f}  rmse {sk['rmse']:.1f}\n"
           f"vcorr {sk['vcorr']:.2f}  veer {sk['veer']:+.0f}°\n"
           f"paxis o {sk['pax_o']:.0f}  m {sk['pax_m']:.0f}°")
    ax3.text(0.03, 0.97, box, transform=ax3.transAxes, fontsize=6.5, va='top', family='monospace',
             bbox=dict(boxstyle='round,pad=0.3', fc='white', ec='0.7', alpha=0.85))

ev = ', '.join(e[1] for e in CFG['events'] if e[1])
fig.suptitle(f'CSIEM {YEAR} velocity validation — model vs SMCWS moored current meters   '
             f'(dashed = {ev})', fontsize=13, fontweight='bold')
out = os.path.join(OUT_DIR, f'velocity_validation_{YEAR}.png')
fig.savefig(out, dpi=155, bbox_inches='tight'); print('wrote', out, flush=True)
