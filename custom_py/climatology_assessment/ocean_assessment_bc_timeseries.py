"""Date-axis BC time-series (1991-07-01 -> 1994-07-01) per subregion.
  - ROMS climatology (bias-corrected polygons): perpetual cycle TILED across each year
    -- coastal/E (solid red) and ocean/W (solid blue)
  - HYCOM at the same polygons, plotted at ACTUAL dates where available (~1992-10 on)
    -- coastal/E (dashed) and ocean/W (dashed)
  - obs (dots, by year) and TUFLOW-FV (x) at their true sampling dates
Shows year-on-year how the HYCOM BC compares to the (repeating) ROMS-climatology BC."""
import os, numpy as np, pandas as pd, geopandas as gpd, xarray as xr, warnings
from shapely.geometry import Point
from shapely.ops import unary_union
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
import matplotlib.dates as mdates

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment'
SHP = os.path.join(DIR, 'diagnostics', 'biascorr_polygons')
ROMS = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/CLIMATOLOGY/ROMS_UTC+8_19911001_19921231_climatology.nc'
HY_FILES = [r'W:/WAMSI/1.7/csiem_model_tfvaed_1.7/model_components/environment_repo/3_ocean/HYCOM/HYCOM_UTC+8_19921001_19931231.nc',
            r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/HYCOM/HYCOM_UTC+8_19931001_19941231.nc']
T0, T1 = pd.Timestamp('1991-07-01'), pd.Timestamp('1994-07-01')

df = pd.read_csv(os.path.join(DIR, 'extended_assessment.csv'))
df.loc[df['obs_botS'] < 33.0, ['obs_botT', 'obs_botS']] = np.nan
df['dt'] = pd.to_datetime(df['date'])
SUB = ['N', 'NW', 'W', 'SW', 'S']; YEARC = {1991:'#e41a1c',1992:'#377eb8',1993:'#4daf4a',1994:'#984ea3'}
# Model initial conditions (spatially UNIFORM domain-wide values, from the IC CSVs) at each sim start
IC = {pd.Timestamp('1991-07-20'): dict(SAL=35.5, TEMP=17.5),
      pd.Timestamp('1992-02-22'): dict(SAL=35.7, TEMP=22.0),
      pd.Timestamp('1993-11-01'): dict(SAL=35.4, TEMP=19.5)}
KEYS = [('surfT','Surface T (°C)'),('surfS','Surface S (psu)'),('botT','Bottom T (°C)'),('botS','Bottom S (psu)')]

polys = {i: gpd.read_file(f'{SHP}/Polygons_{i}_MultiPolygon.shp').to_crs(4326).geometry.iloc[0] for i in range(1,7)}
# The 6 seaward-arc OBC bias-correction polygons run N->S: poly 1,2 = north coast (lat ~-31.7),
# poly 3,4,5 = western ocean arc, poly 6 = SOUTHERN-most OBC (lat -32.65, nearest Peel-Harvey).
# Split them out so the SOUTH-coast correction (poly 6) is shown SEPARATELY from the north coast,
# instead of pooling 1+2+6 into one "coastal" line as before (which hid the south).
ARC = {'coastal_N': unary_union([polys[1], polys[2]]),
       'coastal_S': polys[6],
       'ocean':     unary_union([polys[3], polys[4], polys[5]])}
GROUPS = ['coastal_N', 'coastal_S', 'ocean']
GSTYLE = {'coastal_N': dict(roms='#d62728', hy='#ff9896', lab='N-coastal (poly 1,2)'),
          'coastal_S': dict(roms='#7b0000', hy='#e377c2', lab='S-coastal (poly 6, Peel-Harvey/S OBC)'),
          'ocean':     dict(roms='#1f77b4', hy='#9ecae1', lab='ocean (poly 3-5, W)')}
REPBOT = float(np.nanmedian(df['obs_maxdep']))

def _mask(lat, lon, geom):
    LON, LAT = np.meshgrid(lon, lat); m = np.zeros(LON.shape, bool)
    for j in range(LON.shape[0]):
        for k in range(LON.shape[1]):
            if geom.contains(Point(LON[j,k], LAT[j,k])): m[j,k] = True
    return m

def sample(path, latn, lonn, geom, repdepth):
    """Return (datetimes, {surfT,surfS,botT,botS}) sampled & polygon-averaged at actual times."""
    d = xr.open_dataset(path); lat=d[latn].values; lon=d[lonn].values; dep=d['depth'].values
    jj, kk = np.where(_mask(lat, lon, geom)); t = pd.to_datetime(d['time'].values)
    out = {k: [] for k in ['surfT','surfS','botT','botS']}; ts = []
    for it in range(len(t)):
        Sa = np.asarray(d['salinity'][it],'float64'); Ta = np.asarray(d['water_temp'][it],'float64')
        sT=[];sS=[];bT=[];bS=[]
        for j,k in zip(jj,kk):
            Tc=Ta[:,j,k]; Sc=Sa[:,j,k]; ok=np.isfinite(Tc)&np.isfinite(Sc)
            if ok.sum()<2: continue
            dv=dep[ok]; o=np.argsort(dv); dv=dv[o]; Tv=Tc[ok][o]; Sv=Sc[ok][o]
            srf=dv<=2.0; bd=min(repdepth,dv.max())
            sT.append(Tv[srf].mean() if srf.any() else Tv[0]); sS.append(Sv[srf].mean() if srf.any() else Sv[0])
            bT.append(np.interp(bd,dv,Tv)); bS.append(np.interp(bd,dv,Sv))
        if sT:
            ts.append(t[it]); out['surfT'].append(np.mean(sT)); out['surfS'].append(np.mean(sS)); out['botT'].append(np.mean(bT)); out['botS'].append(np.mean(bS))
    d.close()
    return pd.to_datetime(ts), {k: np.array(v) for k,v in out.items()}

print('Sampling ROMS climatology (perpetual) ...')
ROMS_t, ROMS_C = {}, {}
for g in GROUPS:
    t, c = sample(ROMS, 'lat','lon', ARC[g], REPBOT)
    doy = t.dayofyear.values; o = np.argsort(doy)
    ROMS_t[g] = doy[o]; ROMS_C[g] = {k: v[o] for k,v in c.items()}
# corrected S-coastal (poly 6) sampled from the *_S6corr NC -> overlay the damped line vs the original
import os as _os
ROMS_S6 = ROMS.replace('_climatology.nc', '_climatology_S6corr.nc')
if _os.path.exists(ROMS_S6):
    t, c = sample(ROMS_S6, 'lat', 'lon', ARC['coastal_S'], REPBOT)
    doy = t.dayofyear.values; o = np.argsort(doy)
    ROMS_t['coastal_S_corr'] = doy[o]; ROMS_C['coastal_S_corr'] = {k: v[o] for k, v in c.items()}
    print('  + sampled S6corr poly-6 (corrected S-coastal)')
print('Sampling HYCOM (both files) ...')
HY = {}
for g in GROUPS:
    ts_all=[]; dat_all={k:[] for k in ['surfT','surfS','botT','botS']}
    for f in HY_FILES:
        try:
            ts, c = sample(f, 'latitude','longitude', ARC[g], REPBOT)
            ts_all.append(ts); [dat_all[k].append(c[k]) for k in dat_all]
        except Exception as e: print('  HYCOM skip', os.path.basename(f), e)
    ts = pd.to_datetime(np.concatenate(ts_all)); order = np.argsort(ts.values)
    ts = ts[order]; dat = {k: np.concatenate(dat_all[k])[order] for k in dat_all}
    # dedup overlapping dates (keep first)
    _, uniq = np.unique(ts.values, return_index=True)
    HY[g] = (ts[uniq], {k: dat[k][uniq] for k in dat})

# tile ROMS perpetual cycle onto the daily date axis (periodic in DOY)
DATES = pd.date_range(T0, T1, freq='D')
ddoy = DATES.dayofyear.values
def roms_tiled(g, key):
    return np.interp(ddoy, ROMS_t[g], ROMS_C[g][key], period=365)

# representative-cell model time-series (precomputed) -- continuous model line per subregion
_MTS_PATH = os.path.join(DIR, 'model_repcell_timeseries.csv')
MODEL_TS = pd.read_csv(_MTS_PATH, parse_dates=['date']) if os.path.exists(_MTS_PATH) else None

def _gapped(dates, vals, maxgap_days=10):
    """Insert NaN breaks across run gaps so the line isn't drawn across them."""
    order = np.argsort(dates); dates = np.array(dates)[order]; vals = np.array(vals)[order]
    gx = []; gy = []
    for i in range(len(dates)):
        if i > 0 and (pd.Timestamp(dates[i]) - pd.Timestamp(dates[i-1])).days > maxgap_days:
            gx.append(pd.Timestamp(dates[i-1]) + pd.Timedelta(days=1)); gy.append(np.nan)
        gx.append(pd.Timestamp(dates[i])); gy.append(vals[i])
    return gx, gy

def fig_sub(sr):
    dd = df[(df.subregion==sr) & (df.dt>=T0) & (df.dt<=T1)]
    fig, axes = plt.subplots(2, 2, figsize=(17, 9), sharex=True)
    for ax, (key, lab) in zip(axes.ravel(), KEYS):
        for g in GROUPS:
            st = GSTYLE[g]
            ax.plot(DATES, roms_tiled(g, key), '-', color=st['roms'], lw=1.7, label=f"ROMS clim {st['lab']}", zorder=3)
            hts, hd = HY[g]; inr = (hts >= T0) & (hts <= T1)
            if inr.any(): ax.plot(hts[inr], hd[key][inr], '--', color=st['hy'], lw=1.3, label=f"HYCOM {st['lab']}", zorder=2)
        if 'coastal_S_corr' in ROMS_C:
            ax.plot(DATES, roms_tiled('coastal_S_corr', key), '--', color='#2ca02c', lw=2.4,
                    label='ROMS S-coastal CORRECTED (poly6 k=0.5)', zorder=4)
        # representative-cell TUFLOW-FV line (continuous over each run)
        if MODEL_TS is not None:
            lev = 'surf' if key.startswith('surf') else 'bot'; var = 'TEMP' if key.endswith('T') else 'SAL'
            mt = MODEL_TS[(MODEL_TS.subregion==sr) & (MODEL_TS.level==lev)]
            if len(mt):
                gx, gy = _gapped(mt['date'].values, mt[var].values)
                ax.plot(gx, gy, '-', color='black', lw=1.0, alpha=0.85, label='TUFLOW-FV (rep cell)', zorder=4)
        for yr in sorted(dd.year.unique()):
            dy = dd[dd.year==yr]; ax.scatter(dy.dt, dy[f'obs_{key}'], s=30, c=YEARC.get(yr,'k'), edgecolors='k', lw=.3, label=f'obs {yr}', zorder=5)
        mv = dd.dropna(subset=[f'model_{key}'])
        if len(mv): ax.scatter(mv.dt, mv[f'model_{key}'], s=40, marker='x', c='dimgray', label='TUFLOW-FV (@casts)', zorder=6)
        # initial condition (spatially UNIFORM per sim) plotted as a star at sim start
        icvar = 'TEMP' if key.endswith('T') else 'SAL'
        for i, (d0, vals) in enumerate(IC.items()):
            ax.plot(d0, vals[icvar], marker='*', ms=17, mfc='gold', mec='k', mew=1.1, ls='None',
                    label='model IC (uniform)' if i == 0 else None, zorder=8)
        ax.set_ylabel(lab); ax.grid(alpha=.3); ax.set_xlim(T0,T1)
        ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1,7])); ax.xaxis.set_major_formatter(mdates.DateFormatter('%b\n%Y'))
    axes[0,0].legend(fontsize=7, ncol=2, loc='best')
    fig.suptitle(f'BC time-series 1991–1994 — subregion {sr}  (ROMS clim by OBC arc: N-coastal / S-coastal[poly6] / ocean; +HYCOM +obs +model, n={len(dd)} casts)', fontsize=12, fontweight='bold')
    fig.tight_layout(rect=[0,0,1,0.97])
    p = os.path.join(DIR, f'bc_timeseries_{sr}.png'); fig.savefig(p, dpi=140); plt.close(fig); print('wrote', p)

if __name__ == '__main__':
    for sr in SUB: fig_sub(sr)
    print('DONE')
