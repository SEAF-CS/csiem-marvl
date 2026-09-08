"""Region-based model VALIDATION extraction for CSIEM (obs vs paired TUFLOW-FV).

For every SMCWS CTD cast in `region_profiles_inventory.csv` (inner embayments
INCLUDED) that falls in a requested time window, build a row comparing:
  - OBS    : the field cast (surface = top-2 m mean, bottom = bottom-2 m mean)
  - MODEL  : the paired TUFLOW-FV profile at the same lon/lat & nearest model step

No ROMS / no BC (this is validation, not the climatology assessment). Each cast keeps
its MLAU region tag (OA / CS / N / NW / W / SW / S). Reuses the binary CTD readers
from identify_outer_profiles.py via exec-prefix.

CLI:  python region_validation_core.py [window_tag]
      window_tag in WINDOWS below (default '1991').  Writes region_validation_<tag>.csv
"""
import os, sys, numpy as np, pandas as pd, xarray as xr, warnings
warnings.filterwarnings('ignore')

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/dadamo_transect'
INV = os.path.join(DIR, 'region_profiles_inventory.csv')

# ---- reuse the binary CTD readers + SMCWS_ROOT from identify_outer_profiles.py ----
IOP = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/climatology/identify_outer_profiles.py'
_src = open(IOP, encoding='utf-8').read()
_G = {'__file__': IOP, '__name__': 'iop_prefix'}
exec(compile(_src[:_src.index("print('\\nScanning survey logs")], IOP, 'exec'), _G)
READERS, read_unsupported, SMCWS_ROOT = _G['READERS'], _G['read_unsupported'], _G['SMCWS_ROOT']

try:
    from point_overrides import adjust_point   # model-sample location override (FIELD stays at true station)
except Exception:
    def adjust_point(station, lon=None, lat=None): return lon, lat

REGION_ORDER = ['OA', 'CS', 'N', 'NW', 'W', 'SW', 'S']

# named extraction windows (extend as needed)
WINDOWS = {
    '1991': ('1991-07-20', '1991-08-31'),
    '1992': ('1992-02-22', '1992-05-31'),
    '1994': ('1993-11-01', '1994-12-31'),
    'all':  ('1990-01-01', '1995-01-01'),
}

# ---------------------------------------------------------------- obs cast -> surf/bot
def _read_cast(source_file, prefix):
    fp = os.path.join(SMCWS_ROOT, source_file)
    try:
        prof = READERS.get(prefix, read_unsupported)(fp)
    except Exception:
        return None
    if prof is None: return None
    depth, sal, _den, temp = prof
    good = (depth > 0.1) & (depth < 200) & (sal > 20) & (sal < 40) & (temp > 5) & (temp < 30)
    if good.sum() < 3: return None
    return depth[good], temp[good], sal[good]

def obs_surf_bot(depth, T, S):
    o = np.argsort(depth); depth, T, S = depth[o], T[o], S[o]
    maxd = float(depth.max())
    surf = depth <= 2.0; bot = depth >= (maxd - 2.0)
    return dict(maxdep=maxd,
                surfT=float(T[surf].mean()) if surf.any() else float(T[0]),
                surfS=float(S[surf].mean()) if surf.any() else float(S[0]),
                botT=float(T[bot].mean()) if (bot.any() and maxd > 3.0) else np.nan,
                botS=float(S[bot].mean()) if (bot.any() and maxd > 3.0) else np.nan)

# ---------------------------------------------------------------- MODEL (TUFLOW-FV)
FV_RUNS = [
    ('1991-07-20', '1991-08-31', r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug/csiem_B010_19910720_19910831.nc'),
    ('1992-02-22', '1992-05-31', r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay/csiem_B010_19920222_19920531.nc'),
    ('1993-11-01', '1994-12-31', r'S:/Matt_Working/csiem/output_archive/1.7.0/1994B/csiem_B010_19931101_19941231.nc'),
]
_FV_CACHE = {}
def _fv(path):
    if path not in _FV_CACHE:
        import tfv.xarray  # noqa
        ds = xr.open_dataset(path); fvacc = ds.tfv
        _FV_CACHE[path] = (fvacc, pd.to_datetime(ds['Time'].values))
    return _FV_CACHE[path]

def model_surf_bot(dt, lat, lon, obs_bot_depth, station=None):
    path = next((p for a, b, p in FV_RUNS if pd.Timestamp(a) <= dt <= pd.Timestamp(b)), None)
    if path is None: return None
    try:
        fvacc, times = _fv(path)
        target = dt + pd.Timedelta(hours=12)
        md = times[int(np.argmin(np.abs(times - target)))]
        if abs(md - target) > pd.Timedelta(days=1): return None
        mlon, mlat = adjust_point(station, lon, lat) if station else (lon, lat)   # channel-edge override
        prof = fvacc.get_profile((mlon, mlat), variables=['SAL', 'TEMP'], time=md)
        pt = prof.sel(Time=md, method='nearest') if 'Time' in prof.dims else prof
        z = -np.asarray(pt['Z']).ravel(); T = np.asarray(pt['TEMP']).ravel(); S = np.asarray(pt['SAL']).ravel()
        ok = np.isfinite(z) & np.isfinite(T) & np.isfinite(S)
        if ok.sum() < 1: return None
        z, T, S = z[ok], T[ok], S[ok]; o = np.argsort(z); z, T, S = z[o], T[o], S[o]
        surf = z <= 2.0; bd = min(obs_bot_depth, float(z.max()))
        return dict(t_used=str(md), src_maxdep=float(z.max()),
                    surfT=float(T[surf].mean()) if surf.any() else float(T[0]),
                    surfS=float(S[surf].mean()) if surf.any() else float(S[0]),
                    botT=float(np.interp(bd, z, T)), botS=float(np.interp(bd, z, S)))
    except Exception:
        return None

# ---------------------------------------------------------------- main extraction
def run(window=('1991-07-20', '1991-08-31')):
    inv = pd.read_csv(INV)
    inv['dt'] = pd.to_datetime(inv['date'])
    lo, hi = pd.Timestamp(window[0]), pd.Timestamp(window[1])
    inv = inv[(inv.dt >= lo) & (inv.dt <= hi)].reset_index(drop=True)
    print(f'casts in window {window}: {len(inv)}')
    out = []
    for i, r in inv.iterrows():
        cast = _read_cast(r['source_file'], r['prefix'])
        if cast is None: continue
        o = obs_surf_bot(*cast)
        mo = model_surf_bot(r['dt'], r['lat'], r['lon'], o['maxdep'], station=r['station'])
        row = dict(year=int(r['year']), date=r['date'], time=r['time'], station=r['station'],
                   lat=r['lat'], lon=r['lon'], region=r['region'], doy=int(r['dt'].dayofyear),
                   obs_maxdep=o['maxdep'], obs_surfT=o['surfT'], obs_surfS=o['surfS'],
                   obs_botT=o['botT'], obs_botS=o['botS'])
        for k in ['surfT', 'surfS', 'botT', 'botS']:
            row[f'model_{k}'] = mo[k] if mo else np.nan
        row['model_t_used'] = mo['t_used'] if mo else ''
        out.append(row)
        if (i + 1) % 100 == 0: sys.stdout.write(f'  {i+1}/{len(inv)}\n'); sys.stdout.flush()
    df = pd.DataFrame(out)
    for lvl in ['surf', 'bot']:
        for v in ['T', 'S']:
            df[f'model_{lvl}{v}_bias'] = df[f'model_{lvl}{v}'] - df[f'obs_{lvl}{v}']
    return df

if __name__ == '__main__':
    tag = sys.argv[1] if len(sys.argv) > 1 else '1991'
    df = run(WINDOWS[tag])
    outp = os.path.join(DIR, f'region_validation_{tag}.csv')
    df.to_csv(outp, index=False)
    print(f'\nWrote {outp}: {len(df)} casts')
    print('by region:', df.groupby('region').size().to_dict())
    cov = df['model_surfT'].notna()
    print(f'model-paired: {int(cov.sum())}/{len(df)}')
    sub = df[cov]
    if len(sub):
        print(f'MODEL surf bias  T={sub["model_surfT_bias"].mean():+.3f}  S={sub["model_surfS_bias"].mean():+.3f}  (n={len(sub)})')
        print('\nper-region surface S bias (model-obs):')
        print(sub.groupby('region')['model_surfS_bias'].agg(['mean', 'count']).round(3).to_string())
