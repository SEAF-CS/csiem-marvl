"""Point-by-point obs-vs-model scatter for the modern (2013+) hindcasts —
the analogue of the 1991 SMCWS scatter_validation figure, for diagnosing
regional forcing errors without zone averaging.

Pairing: each observation is matched to the model at the SAME site position
(nearest wet cell), the SAME day (model day-mean, consistent with the obs
cache reduction) and the SAME depth (nearest model layer centre to the obs
0.5 m depth bin, tolerance 1.0 m). Point-by-point — no zone averaging.

Observations = the composite used by the kriged map plots:
  - 2021/2022: the run_maps_* reduced caches are reused verbatim
    (S:/tmp/tA_maps/field_{T,S}_<window>_reduced.parquet: DWER-CSMWQ CTD,
    IMOS SOOP ferry, IMOS ANMN/REF Rottnest, WWMSP5 moorings, DWER CS
    profilers — every per-source quirk already handled by the maps code).
  - 2013/2015: no maps cache exists (bottle years); the composite is built
    here from the warehouse parquet for the same source list where data
    exist in the window (DWER-CSMWQ bottles, IMOS-SOOP surface [zb=0.25],
    IMOS-ANMN, IMOS-REF surface [its Depth column is junk -> forced 0.25]).

Model read: direct netCDF4 column slicing (idx3/NL contiguous 3D columns +
layerface_Z) — no per-cast get_profile, so a full year x ~60 sites pairs in
minutes. ResTime/xarray decode issues avoided entirely (raw hours-since-1990).

Figure: 2x2 (surface/bottom x T/S) coloured by region (lat/lon boxes:
GR=Gage Rds/nth, OA=Owen Anch, CS=Cockburn Snd, S=south, W=offshore/west),
1:1 line, per-panel n/bias/RMSE/r — same layout as scatter_validation_1991.
Surface = bins <=2 m; bottom = the deepest bin of each site/day where the
cast reaches >=4 m. Also writes the full paired table (every depth bin) to
scatter_pairs_<sim>_<ver>.csv for further slicing.

Env: TRANSECT_SIM (e.g. 2021B), MODEL_VER ('1.7' | '1.8.0').
"""
import os
import numpy as np
import pandas as pd
import netCDF4
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

# ---- model-version switch + sims (same pattern as transectA_modern) --------
MODEL_VER = os.environ.get('MODEL_VER', '1.8.0')
RUNS_BY_VER = {
    '1.7':   r'W:/WAMSI/1.7/SH-20251123-1.7.0',
    '1.8.0': r'Q:/SEAF-CS/V1.8/MODEL/csiem_model_tfvaed_1.8/output_archive/1.8.0',
}
RUNS = RUNS_BY_VER[MODEL_VER]
SIMS_17 = {
    '2013A': dict(year=2013, nc='2013A-20251123024141/results/csiem_A002_20121101_20131231_WQ.nc'),
    '2015A': dict(year=2015, nc='2015A-20251124125228/results/csiem_A002_20141101_20151231_WQ_WQ.nc'),
    '2021B': dict(year=2021, nc='2021B-20260131010652/results/csiem_B010_20201101_20211231_WQ.nc'),
    '2022B': dict(year=2022, nc='2022B-20260131015416/results/csiem_B010_20211101_20221231_WQ.nc'),
}
SIMS_18 = {
    '2013B': dict(year=2013, nc='2013B/csiem_B010_20121101_20131231_WQ.nc'),
    '2015B': dict(year=2015, nc='2015B/csiem_B010_20141101_20151231_WQ.nc'),
    '2021B': dict(year=2021, nc='2021B/csiem_B010_20201101_20211231_WQ.nc'),
    '2022B': dict(year=2022, nc='2022B/csiem_B010_20211101_20221231_WQ.nc'),
        '2023B': dict(year=2023, nc='2023B/csiem_B010_20221101_20240401_WQ.nc',
                      t0='2023-01-01', t1='2024-03-31'),
        '2020B': dict(year=2020, nc='2020B/csiem_B010_20191101_20201231_WQ.nc',
                      t0='2020-01-01', t1='2020-12-31'),
}
SIMS = SIMS_18 if MODEL_VER.startswith('1.8') else SIMS_17
SIM = os.environ.get('TRANSECT_SIM', '2021B')
CFG = SIMS[SIM]
YEAR = CFG['year']
NC = str(Path(RUNS) / CFG['nc'])

VALIDATION = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation')
OUT = VALIDATION / f'years/{YEAR}/outputs'
OUT.mkdir(parents=True, exist_ok=True)
WAREHOUSE = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/parquet/variable/csiem_var{:05d}_public.parquet'
MAPS_CACHE = {  # windows follow the run_maps_* scripts
    2021: r'S:/tmp/tA_maps/field_{v}_2020_2021_reduced.parquet',
    2022: r'S:/tmp/tA_maps/field_{v}_2021_2022_reduced.parquet',
}
T0, T1 = pd.Timestamp(f'{YEAR}-01-01'), pd.Timestamp(f'{YEAR}-12-31 23:59')
BBOX = dict(lat=(-32.45, -31.90), lon=(115.30, 115.85))
ZTOL = 1.0            # m: max |obs bin centre - model layer centre|
SURF_MAX = 2.0        # m: surface bins
BOT_MIN_CAST = 4.0    # m: casts shallower than this have no "bottom" point
VAR_IDS = {'T': 7, 'S': 6}
MODEL_VARS = {'T': 'TEMP', 'S': 'SAL'}
CTD_AGENCIES = ['DWER-CSMWQ', 'IMOS-SOOP-PERTH', 'IMOS-ANMN-ADCP', 'IMOS-REF-PHY',
                'IMOS-REF-BGC', 'WAMSI-WWMSP5-AWAC', 'WAMSI-WWMSP5-WQ', 'DWER-CSMOORING-A']

REGION_C = {'GR': '#4daf4a', 'OA': '#e41a1c', 'CS': '#377eb8', 'S': '#a65628', 'W': '#ff7f00'}
def region_of(lat, lon):
    if lon < 115.62: return 'W'
    if lat > -32.05: return 'GR'
    if lat > -32.145: return 'OA'
    if lat > -32.31: return 'CS'
    return 'S'

# ---------------------------------------------------------------- obs composite
def load_obs():
    frames = []
    for v, vid in VAR_IDS.items():
        cache = MAPS_CACHE.get(YEAR)
        if cache and Path(cache.format(v=v)).exists():
            d = pd.read_parquet(cache.format(v=v))
            d = d.rename(columns={'Site_Description': 'site', 'Agency': 'agency',
                                  'Data': 'obs', 'Lat': 'lat', 'Long': 'lon'})
            print(f'  obs {v}: maps cache, {len(d)} rows')
        else:
            # warehouse parquet is 0.5-2.4 GB with 39 mostly-string columns:
            # prune columns + push the Date window down to row groups, or the
            # load OOMs (2015 scatter died SIGSEGV doing a full read).
            import pyarrow.parquet as pq
            tbl = pq.read_table(
                WAREHOUSE.format(vid),
                columns=['Date', 'Depth', 'Data', 'Tag', 'Lat', 'Long', 'Site_Description'],
                filters=[('Date', '>=', T0.to_pydatetime()), ('Date', '<=', T1.to_pydatetime())])
            w = tbl.to_pandas()
            w['agency'] = w['Tag'].astype(str)   # Tag = AGENCY-PROGRAM (e.g. DWER-CSMWQ)
            w = w[w['agency'].isin(CTD_AGENCIES)]
            w['Data'] = pd.to_numeric(w['Data'], errors='coerce')
            w['Lat'] = pd.to_numeric(w['Lat'], errors='coerce')
            w['Long'] = pd.to_numeric(w['Long'], errors='coerce')
            w['Date'] = pd.to_datetime(w['Date'])
            w = w[w.Data.notna() &
                  w.Lat.between(*BBOX['lat']) & w.Long.between(*BBOX['lon'])]
            if w.empty:
                print(f'  obs {v}: warehouse — nothing in window'); continue
            dep = pd.to_numeric(w['Depth'], errors='coerce').abs()
            dep = dep.where(np.isfinite(dep), 0.25)
            # REF depth column is junk (site mean depth) -> force surface
            dep[w['agency'].astype(str).str.contains('REF', na=False)] = 0.25
            w['zb'] = (np.floor(dep / 0.5) * 0.5 + 0.5).clip(lower=0.5)
            w['day'] = w.Date.dt.floor('D')
            d = (w.groupby(['agency', 'Site_Description', 'day', 'zb'])
                   .agg(obs=('Data', 'mean'), lat=('Lat', 'median'), lon=('Long', 'median'))
                   .reset_index().rename(columns={'Site_Description': 'site'}))
            print(f'  obs {v}: warehouse build, {len(d)} rows')
        d['var'] = v
        frames.append(d)
    o = pd.concat(frames, ignore_index=True)
    o = o[(o.day >= T0) & (o.day <= T1)]
    return o

# ---------------------------------------------------------------- model columns
class ModelColumns:
    def __init__(self, ncpath):
        self.nc = netCDF4.Dataset(ncpath)
        self.NL = self.nc['NL'][:].astype(int)
        self.idx3 = self.nc['idx3'][:].astype(int) - 1          # 3D start per 2D cell
        self.fidx = np.concatenate([[0], np.cumsum(self.NL + 1)])  # face start per column
        self.cx = self.nc['cell_X'][:]
        self.cy = self.nc['cell_Y'][:]
        rt = self.nc['ResTime'][:]
        self.time = pd.Timestamp('1990-01-01') + pd.to_timedelta(np.asarray(rt), unit='h')
        self.day = pd.DatetimeIndex(self.time).floor('D')
    def nearest_cell(self, lon, lat):
        d2 = (self.cx - lon) ** 2 + ((self.cy - lat) * 1.19) ** 2   # crude metric scaling
        return int(np.argmin(d2))
    def day_profile(self, cell, day, varname):
        ti = np.where(self.day == day)[0]
        if not len(ti):
            return None, None
        c0, n = self.idx3[cell], self.NL[cell]
        v = self.nc[varname][ti[0]:ti[-1] + 1, c0:c0 + n]
        f0 = self.fidx[cell]
        zf = self.nc['layerface_Z'][ti[0]:ti[-1] + 1, f0:f0 + n + 1]
        v = np.ma.filled(v, np.nan).mean(axis=0)
        zf = np.ma.filled(zf, np.nan).mean(axis=0)
        depth_centre = zf[0] - 0.5 * (zf[:-1] + zf[1:])            # below (day-mean) surface
        return v, depth_centre

def main():
    print(f'=== scatter {SIM} model {MODEL_VER} ({NC}) ===')
    obs = load_obs()
    print(f'  composite: {len(obs)} obs bins, {obs.site.nunique()} sites, '
          f'{sorted(obs.agency.unique())}')
    mc = ModelColumns(NC)
    pairs = []
    sites = obs.groupby(['site', 'var']).first().reset_index()[['site', 'lat', 'lon']].drop_duplicates('site')
    cell_of = {r.site: mc.nearest_cell(r.lon, r.lat) for r in sites.itertuples()}
    for (site, day, var), grp in obs.groupby(['site', 'day', 'var']):
        v, dc = mc.day_profile(cell_of[site], day, MODEL_VARS[var])
        if v is None:
            continue
        for _, r in grp.iterrows():
            zt = r.zb - 0.25
            j = int(np.nanargmin(np.abs(dc - zt))) if np.isfinite(dc).any() else None
            if j is None or abs(dc[j] - zt) > ZTOL or not np.isfinite(v[j]):
                continue
            pairs.append(dict(site=site, agency=r.agency, day=day, var=var, zb=r.zb,
                              lat=r.lat, lon=r.lon, obs=r.obs, model=float(v[j]),
                              castmax=grp.zb.max()))
    df = pd.DataFrame(pairs)
    df['region'] = [region_of(a, b) for a, b in zip(df.lat, df.lon)]
    csv = OUT / f'scatter_pairs_{SIM}_{MODEL_VER}.csv'
    df.to_csv(csv, index=False)
    print(f'  paired: {len(df)} points -> {csv.name}')

    # ---- 1991-style 2x2 figure ------------------------------------------
    df['lvl'] = np.where(df.zb <= SURF_MAX, 'surf', 'mid')
    bot = df[(df.castmax >= BOT_MIN_CAST) & (df.zb == df.castmax)].copy()
    bot['lvl'] = 'bot'
    plot_df = pd.concat([df[df.lvl == 'surf'], bot])
    UNITS = {'T': '\u00b0C', 'S': 'psu'}
    fig, axes = plt.subplots(2, 2, figsize=(13, 13))
    for ax, (lvl, v) in zip(axes.ravel(), [('surf', 'T'), ('surf', 'S'), ('bot', 'T'), ('bot', 'S')]):
        sub = plot_df[(plot_df.lvl == lvl) & (plot_df['var'] == v)].dropna(subset=['obs', 'model'])
        for rg, c in REGION_C.items():
            s = sub[sub.region == rg]
            if len(s):
                ax.scatter(s.obs, s.model, s=14, c=c, alpha=0.55, edgecolors='none',
                           label=f'{rg} (n={len(s)})')
        if len(sub):
            d = sub.model - sub.obs
            bias, rmse = d.mean(), np.sqrt((d ** 2).mean())
            rr = np.corrcoef(sub.obs, sub.model)[0, 1] if len(sub) > 2 else np.nan
            lo, hi = min(sub.obs.min(), sub.model.min()), max(sub.obs.max(), sub.model.max())
            pad = (hi - lo) * 0.05 or 0.5
            ax.plot([lo - pad, hi + pad], [lo - pad, hi + pad], 'k-', lw=1, label='1:1')
            ax.set_xlim(lo - pad, hi + pad); ax.set_ylim(lo - pad, hi + pad)
            ax.set_title(f'{"Surface" if lvl=="surf" else "Bottom"} {v}  '
                         f'(n={len(sub)}, bias={bias:+.3f}, RMSE={rmse:.3f}, r={rr:.3f})', fontsize=11)
        ax.set_aspect('equal', adjustable='box')
        ax.set_xlabel(f'Observed {v} ({UNITS[v]})'); ax.set_ylabel(f'TUFLOW-FV {v} ({UNITS[v]})')
        ax.legend(fontsize=7, loc='upper left', framealpha=0.9); ax.grid(alpha=0.3)
    fig.suptitle(f'Model {MODEL_VER} vs observed — {SIM} point-by-point '
                 f'(map-plot composite sources; day/depth-matched)', fontsize=14, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.98])
    png = OUT / f'scatter_validation_{SIM}_{MODEL_VER}.png'
    fig.savefig(png, dpi=150); plt.close(fig)
    print('wrote', png)

if __name__ == '__main__':
    main()
