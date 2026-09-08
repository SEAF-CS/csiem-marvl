"""Temperature VALIDATION — CSIEM model vs SMCWS moored current-meter thermistors
(year-parameterized). Per SITE a panel; COLOURS ALIGNED to the cs55_timeseries plots:
upper level (top/mid) = BLUE, near-bed = RED; obs (mooring) solid, model dashed. Nearby
CTD casts overlaid as markers (blue circle = surface T, red square = bottom T), as in the
original Velocity/temperature_{year}.png. 6-hourly means. Global (common) y-axis per year.
Bias/rmse per meter on the overlap. In-domain moorings -> true model-vs-obs T.

Windows: 1992 = 4 Mar - 3 Apr; 1991 = month of Aug.
Run:  python temperature_validation.py [1991|1992]
-> years/<year>/outputs/diagnostics/temperature_validation_<year>.png (+ _skill.csv)
"""
import matplotlib; matplotlib.use('Agg')
import os, re, sys, struct, csv as _csv, numpy as np, pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import xarray as xr
os.environ['TQDM_DISABLE'] = '1'
import tfv.xarray

YEAR = sys.argv[1] if len(sys.argv) > 1 else '1992'
SMCWS = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS'
VBASE = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years'
OUT_DIR = os.path.join(VBASE, YEAR, 'outputs', 'TimeSeries'); os.makedirs(OUT_DIR, exist_ok=True)
BLUE, RED = '#1f77b4', '#d62728'          # cs55 convention: surface/upper=blue, bottom/near-bed=red
def lvl_color(level): return BLUE if level in ('top', 'mid') else RED

YEARS = {
    '1991': dict(
        nc=r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc',
        win=(datetime(1991, 8, 1), datetime(1991, 8, 31)),
        events=[(datetime(1991, 8, 19), '19 Aug storm')],
        sites={'CSC1': [('c02s0891.dat', 'top'), ('c02b0891.dat', 'near-bed')],
               'CSC2': [('c03s0891.dat', 'top'), ('c03b0891.dat', 'near-bed')],
               'CSC3': [('c04s0891.dat', 'top')],
               'SDC1': [('c01m0891.dat', 'mid')]},
        ctd={'CSC1': [('CS15', 320), ('OA85B', 320)], 'CSC2': [('CS25', 209)]}),
    '1992': dict(
        nc=r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc',
        win=(datetime(1992, 3, 4), datetime(1992, 4, 3)),
        events=[(datetime(1992, 3, 24), 'ADCP')],
        sites={'CSC4': [('c05s0392.dat', 'top'), ('c05b0392.dat', 'near-bed')],
               'CSC5': [('c06m0392.dat', 'mid'), ('c06b0392.dat', 'near-bed')],
               'SDC1': [('c01s0392.dat', 'top'), ('c01b0392.dat', 'near-bed')],
               'SW1':  [('c07b0392.dat', 'near-bed')]},
        ctd={'CSC4': [('CS4', 128), ('CS20C', 367)], 'SDC1': [('MN105', 81)]}),
}
CFG = YEARS[YEAR]; WIN0, WIN1 = CFG['win']; CUR = f'{SMCWS}/{YEAR}/currents_data'; PARENT = f'{SMCWS}/{YEAR}'
print(f'YEAR={YEAR}  window {WIN0:%d %b}-{WIN1:%d %b}', flush=True)

REC_RE = re.compile(r'^\s*(\d{1,4}):\s*(\d{1,2})\s+(\d{1,2})\s?(\d{1,2})\s?(\d{2})\s+'
                    r'(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+'
                    r'(?:-?[\d.]+\s+){0,2}(-?[\d.]+)\s*$')

def _dms(txt, pat):
    m = re.search(pat, txt)
    if not m: return np.nan
    val = float(m.group(1)) + float(m.group(2))/60 + float(m.group(3))/3600
    return -val if m.group(4).upper() in ('S', 'W') else val

def read_meter_T(path):
    txt = open(path, errors='replace').read()
    ht  = re.search(r'(?i)meter\s*height[^:]*:\s*([\d.]+)', txt)
    dep = re.search(r'(?i)water\s*depth\s*:?\s*([\d.]+)', txt)
    lat = _dms(txt, r'(?i)latitude\s*:?\s*(\d+)\s+(\d+)\s+([\d.]+)\s*([NS])')
    lon = _dms(txt, r'(?i)longitude\s*:?\s*(\d+)\s+(\d+)\s+([\d.]+)\s*([EW])')
    t, tp = [], []
    for line in txt.splitlines():
        m = REC_RE.match(line)
        if not m: continue
        try:
            hh, mi = divmod(int(m.group(1)), 100)
            t.append(datetime(1900+int(m.group(5)), int(m.group(4)), int(m.group(3)), hh, mi, int(m.group(2))))
        except ValueError:
            continue
        tp.append(float(m.group(10)))
    t = np.array(t); tp = np.array(tp); good = (tp > 5) & (tp < 30)
    return dict(lat=lat, lon=lon, height=float(ht.group(1)) if ht else np.nan,
                depth=float(dep.group(1)) if dep else np.nan, t=t[good], temp=tp[good])

# --- nearby CTD cast readers (verbatim from Velocity/plot_velocity_summary.py) ---
def read_dfv_cast(fp):
    data = open(fp, 'rb').read(); epa = data.find(b'EPA')
    if epa == 0x18:   ncols = struct.unpack('>H', data[0x136:0x138])[0]; nrecs = struct.unpack('>i', data[0x13c:0x140])[0]; off = 0x528
    elif epa == 0x14: ncols = struct.unpack('>H', data[0x132:0x134])[0]; nrecs = struct.unpack('>i', data[0x138:0x13c])[0]; off = 0x49C
    else: return None
    if ncols < 4 or nrecs < 5 or off + nrecs*ncols*4 > len(data): return None
    rec = np.frombuffer(data, '>f4', count=nrecs*ncols, offset=off).reshape(nrecs, ncols)
    return rec[:, 2], rec[:, 3]
def read_dhv_cast(fp):
    data = open(fp, 'rb').read(); n = (len(data)-0x410)//16
    if n < 2: return None
    rec = np.frombuffer(data, '>f4', count=n*4, offset=0x410).reshape(n, 4)
    return rec[:, 1], rec[:, 2]
def cast_top_bottom(dep, tmp):
    g = (dep > 0.1) & (dep < 50) & (tmp > 5) & (tmp < 30); dep, tmp = dep[g], tmp[g]
    if len(dep) < 3: return None, None
    return float(tmp[dep <= max(2.0, dep.min()+0.5)].mean()), float(tmp[dep >= dep.max()-1.5].mean())

def load_ctd(site_ctd):
    pts = {}
    slog = os.path.join(PARENT, f'survey_log_{YEAR}.csv')
    if not os.path.exists(slog): return {s: [] for s in site_ctd}
    rows = list(_csv.DictReader(open(slog)))
    for site, stns in site_ctd.items():
        pts[site] = []
        for stn, _dist in stns:
            for r in rows:
                if r['station'] != stn: continue
                jd = int(r['jday']); hhmm = r['time']
                sd = os.path.join(PARENT, r['month'], 'profile_data', stn)
                for pref, rd in (('dfv', read_dfv_cast), ('dhv', read_dhv_cast), ('dtv', read_dhv_cast), ('dmv', read_dhv_cast)):
                    fp = os.path.join(sd, f'{pref}{hhmm}.{jd:03d}')
                    if os.path.exists(fp): break
                else: continue
                out = rd(fp)
                if out is None: continue
                top, bot = cast_top_bottom(*out)
                if top is None: continue
                try: dt = datetime.strptime(r['date']+hhmm, '%Y-%m-%d%H%M')
                except ValueError: continue
                if WIN0 <= dt <= WIN1: pts[site].append((dt, top, bot, stn))
    return pts

def subset(t, v):
    if len(t) == 0: return t, v
    m = (t >= np.datetime64(WIN0)) & (t <= np.datetime64(WIN1)); return t[m], v[m]
def bin6(t, v, hours=6):
    if len(t) == 0: return np.array([]), np.array([])
    t0 = pd.Timestamp(t[0]).replace(minute=0, second=0)
    idx = np.array([int((pd.Timestamp(x)-t0).total_seconds() // (hours*3600)) for x in t]); ks = np.unique(idx)
    ct = np.array([t0 + timedelta(hours=float(k)*hours + hours/2) for k in ks])
    return ct, np.array([np.nanmean(v[idx == k]) for k in ks])
def to_grid(t, v, gns):
    if len(t) == 0: return np.full(len(gns), np.nan)
    ts = np.array([pd.Timestamp(x).value for x in t], float)
    return np.interp(gns, ts, v, left=np.nan, right=np.nan)

print('opening model NC ...', flush=True)
ds = xr.open_dataset(CFG['nc']); fv = ds.tfv
def model_T(lon, lat, height):
    lim = (max(0.1, height-0.75), height+0.75)
    r = fv.get_timeseries(['TEMP'], (lon, lat), time=slice(pd.Timestamp(WIN0), pd.Timestamp(WIN1)),
                          datum='height', limits=lim)
    mt = np.array(pd.to_datetime(r['Time'].values).to_pydatetime())
    return subset(mt, np.asarray(r['TEMP'], float).ravel())

GRID = pd.date_range(WIN0, WIN1, freq='h'); GNS = GRID.astype(np.int64).values.astype(float)
ctd = load_ctd(CFG['ctd']); sites = CFG['sites']
# ---- pass 1: extract everything + global y range ----
panels = {}; skill = []; gmin, gmax = np.inf, -np.inf
for site, mlist in sites.items():
    rows = []
    for fn, lname in mlist:
        path = os.path.join(CUR, site, fn)
        if not os.path.exists(path): print(f'  MISSING {path}'); continue
        ob = read_meter_T(path); ot, oT = subset(ob['t'], ob['temp'])
        if len(ot) < 10: continue
        mt, mT = model_T(ob['lon'], ob['lat'], ob['height'])
        bt, bo = bin6(ot, oT); bm, bmo = bin6(mt, mT)
        oG, mG = to_grid(ot, oT, GNS), to_grid(mt, mT, GNS); v = np.isfinite(oG) & np.isfinite(mG)
        bias = rmse = np.nan
        if v.sum():
            bias = np.mean(mG[v]-oG[v]); rmse = np.sqrt(np.mean((mG[v]-oG[v])**2))
            skill.append(dict(site=site, level=lname, height=ob['height'], depth=ob['depth'],
                              n=int(v.sum()), bias=bias, rmse=rmse))
        rows.append(dict(level=lname, height=ob['height'], bt=bt, bo=bo, bm=bm, bmo=bmo, bias=bias, rmse=rmse))
        for arr in (bo, bmo):
            if len(arr): gmin = min(gmin, np.nanmin(arr)); gmax = max(gmax, np.nanmax(arr))
        print(f"  {site} {lname}: bias {bias:+.2f} rmse {rmse:.2f}", flush=True)
    for _, tp, bo_, _ in ctd.get(site, []):
        gmin = min(gmin, tp, bo_); gmax = max(gmax, tp, bo_)
    panels[site] = rows
ylim = (np.floor(gmin*2)/2 - 0.2, np.ceil(gmax*2)/2 + 0.2)

# ---- pass 2: plot ----
order = list(sites.keys()); n = len(order)
fig, axes = plt.subplots(n, 1, figsize=(15, 2.8*n), sharex=True, sharey=True)
if n == 1: axes = [axes]
for ax, site in zip(axes, order):
    for i, r in enumerate(panels[site]):
        c = lvl_color(r['level'])
        ax.plot(r['bt'], r['bo'], '-', color=c, lw=1.7, label=f"obs {r['level']} ({r['height']:.1f} m ASB)")
        ax.plot(r['bm'], r['bmo'], '--', color=c, lw=1.5, label=f"model {r['level']}")
        if np.isfinite(r['bias']):
            ax.text(0.006, 0.16-0.12*i, f"{r['level']}: model-obs {r['bias']:+.2f}  rmse {r['rmse']:.2f}",
                    transform=ax.transAxes, fontsize=7.5, color=c)
    pts = ctd.get(site, [])
    if pts:
        stns = ', '.join(sorted({p[3] for p in pts}))
        ax.scatter([p[0] for p in pts], [p[1] for p in pts], marker='o', s=40, facecolor=BLUE,
                   edgecolor='k', lw=0.6, zorder=6, label=f'CTD surface — {stns}')
        ax.scatter([p[0] for p in pts], [p[2] for p in pts], marker='s', s=40, facecolor=RED,
                   edgecolor='k', lw=0.6, zorder=6, label='CTD bottom')
    for d, _ in CFG['events']: ax.axvline(d, color='0.4', ls=':', lw=1.1)
    ax.set_ylabel(f'{site}\nT (°C)', fontsize=9, fontweight='bold'); ax.grid(alpha=0.3)
    ax.set_ylim(*ylim); ax.legend(fontsize=7, loc='upper right', ncol=2)
axes[-1].xaxis.set_major_formatter(mdates.DateFormatter('%d %b')); axes[-1].set_xlim(WIN0, WIN1); axes[-1].set_xlabel(f'{YEAR}')
ev = ', '.join(e[1] for e in CFG['events'] if e[1])
fig.suptitle(f'CSIEM {YEAR} temperature validation — model vs SMCWS moored thermistors '
             f'({WIN0:%d %b}–{WIN1:%d %b}; obs solid, model dashed; blue=upper, red=near-bed; dotted={ev})',
             fontsize=12, fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.98])
out = os.path.join(OUT_DIR, f'temperature_validation_{YEAR}.png')
fig.savefig(out, dpi=150, bbox_inches='tight'); print('wrote', out, flush=True)
pd.DataFrame(skill).to_csv(os.path.join(OUT_DIR, f'temperature_skill_{YEAR}.csv'), index=False, float_format='%.2f')
