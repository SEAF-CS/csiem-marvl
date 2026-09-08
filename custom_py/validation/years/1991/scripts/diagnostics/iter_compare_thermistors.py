"""Compare two 1991 iterations at the Cockburn Sound thermistors.
Per meter: obs (black) vs model T from iteration A (blue dashed) and B (red dashed);
annotates each iteration's bias vs obs and the B-A delta. get_timeseries datum='height'.
Usage: python iter_compare_thermistors.py [NCA labelA NCB labelB]
  defaults: ITER9 snapshot vs ITER10 live rev.
-> years/1991/outputs/diagnostics/iter_compare_thermistors_<A>_<B>.png
"""
import matplotlib; matplotlib.use('Agg')
import os, re, sys, numpy as np, pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import xarray as xr
os.environ['TQDM_DISABLE'] = '1'
import tfv.xarray

ARCH = 'S:/Matt_Working/csiem/output_archive/1.7.0'
NCA = sys.argv[1] if len(sys.argv) > 1 else f'{ARCH}/1991_aug_rev_ITER9/csiem_B010_19910720_19910831_rev.nc'
LA  = sys.argv[2] if len(sys.argv) > 2 else 'ITER9'
NCB = sys.argv[3] if len(sys.argv) > 3 else f'{ARCH}/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
LB  = sys.argv[4] if len(sys.argv) > 4 else 'ITER10'
SMCWS = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS'; CUR = f'{SMCWS}/1991/currents_data'
OUT = f'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/iter_compare_thermistors_{LA}_{LB}.png'
os.makedirs(os.path.dirname(OUT), exist_ok=True)
WIN0, WIN1 = datetime(1991, 8, 1), datetime(1991, 8, 31)
SITES = {'CSC1': [('c02s0891.dat', 'top'), ('c02b0891.dat', 'near-bed')],
         'CSC2': [('c03s0891.dat', 'top'), ('c03b0891.dat', 'near-bed')],
         'CSC3': [('c04s0891.dat', 'top')], 'SDC1': [('c01m0891.dat', 'mid')]}
C_OBS, CA, CB = '0.2', '#1f77b4', '#d62728'
REC_RE = re.compile(r'^\s*(\d{1,4}):\s*(\d{1,2})\s+(\d{1,2})\s?(\d{1,2})\s?(\d{2})\s+'
                    r'(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(?:-?[\d.]+\s+){0,2}(-?[\d.]+)\s*$')
def _dms(txt, pat):
    m = re.search(pat, txt)
    if not m: return np.nan
    v = float(m.group(1)) + float(m.group(2))/60 + float(m.group(3))/3600
    return -v if m.group(4).upper() in ('S', 'W') else v
def read_meter_T(path):
    txt = open(path, errors='replace').read()
    ht = re.search(r'(?i)meter\s*height[^:]*:\s*([\d.]+)', txt)
    lat = _dms(txt, r'(?i)latitude\s*:?\s*(\d+)\s+(\d+)\s+([\d.]+)\s*([NS])')
    lon = _dms(txt, r'(?i)longitude\s*:?\s*(\d+)\s+(\d+)\s+([\d.]+)\s*([EW])')
    t, tp = [], []
    for line in txt.splitlines():
        m = REC_RE.match(line)
        if not m: continue
        try:
            hh, mi = divmod(int(m.group(1)), 100)
            t.append(datetime(1900+int(m.group(5)), int(m.group(4)), int(m.group(3)), hh, mi, int(m.group(2))))
        except ValueError: continue
        tp.append(float(m.group(10)))
    t = np.array(t); tp = np.array(tp); g = (tp > 5) & (tp < 30)
    return dict(lat=lat, lon=lon, height=float(ht.group(1)) if ht else np.nan, t=t[g], temp=tp[g])
def sub(t, v):
    if len(t) == 0: return t, v
    m = (t >= np.datetime64(WIN0)) & (t <= np.datetime64(WIN1)); return t[m], v[m]
def bin6(t, v, hours=6):
    if len(t) == 0: return np.array([]), np.array([])
    t0 = pd.Timestamp(t[0]).replace(minute=0, second=0)
    idx = np.array([int((pd.Timestamp(x)-t0).total_seconds()//(hours*3600)) for x in t]); ks = np.unique(idx)
    return (np.array([t0+timedelta(hours=float(k)*hours+hours/2) for k in ks]), np.array([np.nanmean(v[idx == k]) for k in ks]))
def grid(t, v, gns):
    if len(t) == 0: return np.full(len(gns), np.nan)
    return np.interp(gns, np.array([pd.Timestamp(x).value for x in t], float), v, left=np.nan, right=np.nan)

print(f'opening {LA} + {LB} NCs ...', flush=True)
fvA = xr.open_dataset(NCA).tfv; fvB = xr.open_dataset(NCB).tfv
def model_T(fv, lon, lat, height):
    r = fv.get_timeseries(['TEMP'], (lon, lat), time=slice(pd.Timestamp(WIN0), pd.Timestamp(WIN1)),
                          datum='height', limits=(max(0.1, height-0.75), height+0.75))
    return sub(np.array(pd.to_datetime(r['Time'].values).to_pydatetime()), np.asarray(r['TEMP'], float).ravel())
GNS = pd.date_range(WIN0, WIN1, freq='h').astype(np.int64).values.astype(float)
n = len(SITES); fig, axes = plt.subplots(n, 1, figsize=(15, 2.8*n), sharex=True, sharey=True)
if n == 1: axes = [axes]
print(f"{'meter':16} {'obs':>6} {LA:>7} {LB:>7} {'d(B-A)':>7} {'biasA':>7} {'biasB':>7}")
for ax, (site, meters) in zip(axes, SITES.items()):
    for i, (fn, lname) in enumerate(meters):
        p = os.path.join(CUR, site, fn)
        if not os.path.exists(p): continue
        ob = read_meter_T(p); ot, oT = sub(ob['t'], ob['temp'])
        if len(ot) < 10: continue
        ta, Ta = model_T(fvA, ob['lon'], ob['lat'], ob['height']); tb, Tb = model_T(fvB, ob['lon'], ob['lat'], ob['height'])
        for tt, vv, c, ls, lb, lw in [(ot, oT, C_OBS, '-', f'obs {lname}', 1.8), (ta, Ta, CA, '--', LA, 1.5), (tb, Tb, CB, '--', LB, 1.5)]:
            bt, bv = bin6(tt, vv); ax.plot(bt, bv, ls, color=c, lw=lw, label=lb if i == 0 else None)
        og, ga, gb = grid(ot, oT, GNS), grid(ta, Ta, GNS), grid(tb, Tb, GNS)
        v = np.isfinite(og) & np.isfinite(ga) & np.isfinite(gb)
        bA = np.mean(ga[v]-og[v]); bB = np.mean(gb[v]-og[v]); d = np.mean(gb[v]-ga[v])
        ax.text(0.006, 0.20-0.13*i, f"{lname}: {LA} {bA:+.2f}  {LB} {bB:+.2f}  Δ {d:+.2f}",
                transform=ax.transAxes, fontsize=8, color=CB if abs(d) > 0.05 else '0.4')
        print(f"{site+' '+lname:16} {og[v].mean():6.2f} {ga[v].mean():7.2f} {gb[v].mean():7.2f} {d:+7.2f} {bA:+7.2f} {bB:+7.2f}", flush=True)
    ax.axvline(datetime(1991, 8, 19), color='0.5', ls=':', lw=1)
    ax.set_ylabel(f'{site}\nT (°C)', fontsize=9, fontweight='bold'); ax.grid(alpha=0.3)
    if list(SITES).index(site) == 0: ax.legend(fontsize=8, loc='upper right', ncol=3)
axes[-1].xaxis.set_major_formatter(mdates.DateFormatter('%d %b')); axes[-1].set_xlim(WIN0, WIN1); axes[-1].set_xlabel('Aug 1991')
fig.suptitle(f'1991 thermistors — {LA} vs {LB}', fontsize=12, fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.98]); fig.savefig(OUT, dpi=150, bbox_inches='tight'); print('wrote', OUT, flush=True)
