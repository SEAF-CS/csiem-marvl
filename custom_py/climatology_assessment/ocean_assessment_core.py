"""
Extended ocean-BC / model assessment for CSIEM.

Builds an extended per-cast table comparing each SMCWS outer-ring CTD cast against:
  - OBS    : the field cast itself (surface = top-2m mean, bottom = bottom-2m mean)
  - BC     : the model boundary forcing actually used -- ROMS climatology (1991,1992)
             + HYCOM (1993,1994) from environment_repo
  - MODEL  : TUFLOW-FV result TEMP/SAL (where a run window covers the cast date)

Surface compared top-2m to top-2m; bottom sampled from each source at the OBS cast's
bottom depth (interp) to handle grid-bathymetry mismatch. Each cast tagged to a
latitude-band subregion (N/NW/W/SW/S). Reuses compare_to_roms.py's binary readers.
"""
import os, csv, sys, numpy as np, pandas as pd, xarray as xr, warnings
warnings.filterwarnings('ignore')
import matplotlib  # noqa (kept off; this is the data layer)

# ---- reuse the canonical binary readers / read_cast / haversine / inventory paths ----
CMP = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/climatology/compare_to_roms.py'
src = open(CMP, encoding='utf-8').read()
prefix = src[:src.index("print(f'Loading inventory")].replace("matplotlib.use('Agg')", "")
F = {'__file__': CMP, '__name__': 'cmp_prefix'}
exec(compile(prefix, CMP, 'exec'), F)
read_cast = F['read_cast']; INV_CSV = F['INV_CSV']
QC_DEPTH, QC_SAL, QC_TEMP = F['QC_DEPTH'], F['QC_SAL'], F['QC_TEMP']

OUT_DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment'
os.makedirs(OUT_DIR, exist_ok=True)

# ---------------------------------------------------------------- subregions
def subregion(lat):
    if lat >= -32.00: return 'N'    # N is strictly north of 32S; casts south of -32 go to NW
    if lat >= -32.15: return 'NW'
    if lat >= -32.25: return 'W'
    if lat >= -32.35: return 'SW'
    return 'S'
SUBREGION_ORDER = ['N', 'NW', 'W', 'SW', 'S']

# ---------------------------------------------------------------- obs surface/bottom
def obs_surf_bot(depth, T, S):
    maxd = float(depth.max())
    surf = depth <= 2.0
    bot = depth >= (maxd - 2.0)
    return dict(
        maxdep=maxd,
        surfT=float(T[surf].mean()) if surf.any() else np.nan,
        surfS=float(S[surf].mean()) if surf.any() else np.nan,
        botT=float(T[bot].mean()) if (bot.any() and maxd > 3.0) else np.nan,
        botS=float(S[bot].mean()) if (bot.any() and maxd > 3.0) else np.nan,
    )

# ---------------------------------------------------------------- BC (env-repo) source
ENV = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean'
WENV = r'W:/WAMSI/1.7/csiem_model_tfvaed_1.7/model_components/environment_repo/3_ocean'
def bc_spec(year, dt):
    """Return (path, latname, lonname) for the model BC actually used in that year."""
    if year == 1991:
        return (ENV + '/CLIMATOLOGY/ROMS_UTC+8_19901001_19911231_climatology.nc', 'lat', 'lon')
    if year == 1992:
        return (ENV + '/CLIMATOLOGY/ROMS_UTC+8_19911001_19921231_climatology.nc', 'lat', 'lon')
    # 1993/1994 -> HYCOM. S: has 1993-10..1994-12; W: has 1992-10..1993-12 for early 1993.
    if year == 1993 and dt < pd.Timestamp('1993-10-01'):
        return (WENV + '/HYCOM/HYCOM_UTC+8_19921001_19931231.nc', 'latitude', 'longitude')
    return (ENV + '/HYCOM/HYCOM_UTC+8_19931001_19941231.nc', 'latitude', 'longitude')

_BC_CACHE = {}
def _bc_ds(path):
    if path not in _BC_CACHE:
        _BC_CACHE[path] = xr.open_dataset(path, decode_times=True)
    return _BC_CACHE[path]

def bc_surf_bot(year, dt, lat, lon, obs_bot_depth):
    path, latn, lonn = bc_spec(year, dt)
    try:
        d = _bc_ds(path)
    except Exception:
        return None
    lats = d[latn].values; lons = d[lonn].values
    ilat = int(np.argmin(np.abs(lats - lat))); ilon = int(np.argmin(np.abs(lons - lon)))
    t = pd.to_datetime(d['time'].values); it = int(np.argmin(np.abs(t - (dt + pd.Timedelta(hours=12)))))
    dep = d['depth'].values
    T = np.asarray(d['water_temp'][it, :, ilat, ilon], dtype='float64')
    S = np.asarray(d['salinity'][it, :, ilat, ilon], dtype='float64')
    ok = np.isfinite(T) & np.isfinite(S)
    if ok.sum() < 1: return None
    dv, Tv, Sv = dep[ok], T[ok], S[ok]
    o = np.argsort(dv); dv, Tv, Sv = dv[o], Tv[o], Sv[o]
    surf = dv <= 2.0
    bd = min(obs_bot_depth, float(dv.max()))
    src = 'roms' if latn == 'lat' else 'hycom'
    return dict(src=src, gdist_km=float(F['haversine_km'](lat, lon, float(lats[ilat]), float(lons[ilon]))),
                t_used=str(t[it]), src_maxdep=float(dv.max()),
                surfT=float(Tv[surf].mean()) if surf.any() else float(Tv[0]),
                surfS=float(Sv[surf].mean()) if surf.any() else float(Sv[0]),
                botT=float(np.interp(bd, dv, Tv)), botS=float(np.interp(bd, dv, Sv)))

# ---------------------------------------------------------------- MODEL (TUFLOW-FV) source
FV_RUNS = [
    ('1991-07-20', '1991-08-25', r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug/csiem_B010_19910720_19910831.nc'),
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

def model_surf_bot(dt, lat, lon, obs_bot_depth):
    path = None
    for a, b, p in FV_RUNS:
        if pd.Timestamp(a) <= dt <= pd.Timestamp(b):
            path = p; break
    if path is None: return None
    try:
        fvacc, times = _fv(path)
        md = times[int(np.argmin(np.abs(times - (dt + pd.Timedelta(hours=12)))))]
        if abs((md - (dt + pd.Timedelta(hours=12)))) > pd.Timedelta(days=1):
            return None  # nearest model step too far (run not yet that far)
        prof = fvacc.get_profile((lon, lat), variables=['SAL', 'TEMP'], time=md)
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
        return None  # HDF error (live-write) or extraction failure -> model n/a

# ---------------------------------------------------------------- main extraction
def run(limit=None):
    rows = list(csv.DictReader(open(INV_CSV)))
    if limit: rows = rows[:limit]
    out = []
    for i, r in enumerate(rows):
        year = int(r['year']); dt = pd.Timestamp(r['date']); lat = float(r['lat']); lon = float(r['lon'])
        cast = read_cast(r['source_file'], r['prefix'])
        if cast is None: continue
        cd, cT, cS = cast
        o = obs_surf_bot(cd, cT, cS)
        if not np.isfinite(o['surfT']): continue
        bc = bc_surf_bot(year, dt, lat, lon, o['maxdep'])
        mo = model_surf_bot(dt, lat, lon, o['maxdep'])
        row = dict(year=year, date=r['date'], time=r['time'], station=r['station'], lat=lat, lon=lon,
                   subregion=subregion(lat), doy=int(dt.dayofyear), obs_maxdep=o['maxdep'],
                   obs_surfT=o['surfT'], obs_surfS=o['surfS'], obs_botT=o['botT'], obs_botS=o['botS'])
        for tag, s in [('bc', bc), ('model', mo)]:
            if s is None:
                for k in ['surfT', 'surfS', 'botT', 'botS']: row[f'{tag}_{k}'] = np.nan
                row[f'{tag}_src'] = (bc['src'] if (tag == 'bc' and bc) else ('fv' if tag == 'model' else ''))
            else:
                for k in ['surfT', 'surfS', 'botT', 'botS']: row[f'{tag}_{k}'] = s[k]
                row[f'{tag}_src'] = s.get('src', 'fv')
        out.append(row)
        if (i + 1) % 50 == 0:
            sys.stdout.write(f'  {i+1}/{len(rows)}\n'); sys.stdout.flush()
    df = pd.DataFrame(out)
    # biases (source - obs); positive = source too warm/salty
    for tag in ['bc', 'model']:
        for v, lvl in [('T', 'surf'), ('S', 'surf'), ('T', 'bot'), ('S', 'bot')]:
            df[f'{tag}_{lvl}{v}_bias'] = df[f'{tag}_{lvl}{v}'] - df[f'obs_{lvl}{v}']
    return df

if __name__ == '__main__':
    lim = int(sys.argv[1]) if len(sys.argv) > 1 else None
    df = run(limit=lim)
    outp = os.path.join(OUT_DIR, 'extended_assessment.csv')
    df.to_csv(outp, index=False)
    print(f'Wrote {outp}: {len(df)} casts')
    # quick coverage + bias summary
    print('casts by year:', df.groupby('year').size().to_dict())
    print('casts by subregion:', df.groupby('subregion').size().to_dict())
    print('model-covered casts:', int(df['model_surfT'].notna().sum()), '/', len(df))
    for tag in ['bc', 'model']:
        sub = df[df[f'{tag}_surfT'].notna()]
        if len(sub):
            print(f'{tag.upper()} surf bias  T={sub[f"{tag}_surfT_bias"].mean():+.3f}  S={sub[f"{tag}_surfS_bias"].mean():+.3f}  (n={len(sub)})')
