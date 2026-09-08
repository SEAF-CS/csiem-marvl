"""Seasonal time-series per subregion showing the BACKGROUND BC ENVELOPE the model
experiences, comparing TWO boundary sources at the same seaward-arc polygons:
  - ROMS climatology (bias-corrected; coastal/east swings, ocean/west steady) -- solid
  - HYCOM (Oct 1993 - Dec 1994, NO bias correction)                          -- dashed
coastal (east) vs ocean (west) polygons, overlaid with obs (by year) + TUFLOW-FV.
Lets you see how the HYCOM BC compares to the ROMS-climatology BC year-on-year."""
import os, sys, numpy as np, pandas as pd, geopandas as gpd, xarray as xr, warnings
from shapely.geometry import Point
from shapely.ops import unary_union
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment'
SHP = os.path.join(DIR, 'diagnostics', 'biascorr_polygons')
ROMS = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/CLIMATOLOGY/ROMS_UTC+8_19911001_19921231_climatology.nc'
HYCOM = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/HYCOM/HYCOM_UTC+8_19931001_19941231.nc'

df = pd.read_csv(os.path.join(DIR, 'extended_assessment.csv'))
df.loc[df['obs_botS'] < 33.0, ['obs_botT', 'obs_botS']] = np.nan
SUB = ['N', 'NW', 'W', 'SW', 'S']
YEARC = {1991: '#e41a1c', 1992: '#377eb8', 1993: '#4daf4a', 1994: '#984ea3'}

polys = {i: gpd.read_file(f'{SHP}/Polygons_{i}_MultiPolygon.shp').to_crs(4326).geometry.iloc[0] for i in range(1, 7)}
clon = {i: polys[i].centroid.x for i in polys}
COASTAL = [i for i in polys if clon[i] > 115.45]
OCEAN = [i for i in polys if clon[i] <= 115.45]
ARC = {'coastal': unary_union([polys[i] for i in COASTAL]), 'ocean': unary_union([polys[i] for i in OCEAN])}
REPBOT = float(np.nanmedian(df['obs_maxdep']))

def _cellmask(lat, lon, geom):
    LON, LAT = np.meshgrid(lon, lat)
    m = np.zeros(LON.shape, bool)
    for j in range(LON.shape[0]):
        for k in range(LON.shape[1]):
            if geom.contains(Point(LON[j, k], LAT[j, k])): m[j, k] = True
    return m

def seasonal_curve(path, latn, lonn, geom, repdepth, tmask=None):
    d = xr.open_dataset(path)
    lat = d[latn].values; lon = d[lonn].values; dep = d['depth'].values
    mask = _cellmask(lat, lon, geom)
    t = pd.to_datetime(d['time'].values)
    idx = np.where(tmask(t))[0] if tmask else np.arange(len(t))
    jj, kk = np.where(mask)
    rows = []
    for it in idx:
        Sa = np.asarray(d['salinity'][it], 'float64'); Ta = np.asarray(d['water_temp'][it], 'float64')
        sT=[];sS=[];bT=[];bS=[]
        for j, k in zip(jj, kk):
            Tc = Ta[:, j, k]; Sc = Sa[:, j, k]; ok = np.isfinite(Tc) & np.isfinite(Sc)
            if ok.sum() < 2: continue
            dv = dep[ok]; o = np.argsort(dv); dv = dv[o]; Tv = Tc[ok][o]; Sv = Sc[ok][o]
            srf = dv <= 2.0; bd = min(repdepth, dv.max())
            sT.append(Tv[srf].mean() if srf.any() else Tv[0]); sS.append(Sv[srf].mean() if srf.any() else Sv[0])
            bT.append(np.interp(bd, dv, Tv)); bS.append(np.interp(bd, dv, Sv))
        if sT: rows.append((int(t[it].dayofyear), np.mean(sT), np.mean(sS), np.mean(bT), np.mean(bS)))
    d.close()
    a = np.array(sorted(rows))
    return {'doy': a[:,0], 'surfT': a[:,1], 'surfS': a[:,2], 'botT': a[:,3], 'botS': a[:,4]}

print('Sampling ROMS climatology (perpetual 1992) ...')
_y92 = lambda t: (t >= pd.Timestamp('1992-01-01')) & (t <= pd.Timestamp('1992-12-31'))
ROMS_C = {g: seasonal_curve(ROMS, 'lat', 'lon', ARC[g], REPBOT, _y92) for g in ('coastal', 'ocean')}
print('Sampling HYCOM (Oct 1993 - Dec 1994) ...')
HY_C = {g: seasonal_curve(HYCOM, 'latitude', 'longitude', ARC[g], REPBOT) for g in ('coastal', 'ocean')}

def fig_sub(sr):
    dd = df[df.subregion == sr]
    if len(dd) == 0: return
    fig, axes = plt.subplots(2, 2, figsize=(15, 9), sharex=True)
    keys = [('surfT','Surface T (°C)'),('surfS','Surface S (psu)'),('botT','Bottom T (°C)'),('botS','Bottom S (psu)')]
    for ax, (key, lab) in zip(axes.ravel(), keys):
        ax.plot(ROMS_C['coastal']['doy'], ROMS_C['coastal'][key], '-',  color='#d62728', lw=2,   label='ROMS clim coastal (E)', zorder=3)
        ax.plot(ROMS_C['ocean']['doy'],   ROMS_C['ocean'][key],   '-',  color='#1f77b4', lw=2,   label='ROMS clim ocean (W)',   zorder=3)
        ax.plot(HY_C['coastal']['doy'],   HY_C['coastal'][key],   '--', color='#ff9896', lw=1.8, label='HYCOM coastal (E)',     zorder=2)
        ax.plot(HY_C['ocean']['doy'],     HY_C['ocean'][key],     '--', color='#9ecae1', lw=1.8, label='HYCOM ocean (W)',       zorder=2)
        for yr in sorted(dd.year.unique()):
            dy = dd[dd.year == yr]; ax.scatter(dy.doy, dy[f'obs_{key}'], s=28, c=YEARC.get(yr,'k'), edgecolors='k', lw=.3, label=f'obs {yr}', zorder=5)
        mv = dd.dropna(subset=[f'model_{key}'])
        if len(mv): ax.scatter(mv.doy, mv[f'model_{key}'], s=34, marker='x', c='black', label='TUFLOW-FV', zorder=6)
        ax.set_ylabel(lab); ax.grid(alpha=.3)
        if key in ('botT','botS'): ax.set_xlabel('day of year')
    axes[0,0].legend(fontsize=7, ncol=2, loc='best')
    fig.suptitle(f'Seasonal BC: ROMS climatology vs HYCOM (coastal/E vs ocean/W) — subregion {sr}  (n={len(dd)} casts)',
                 fontsize=13, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    p = os.path.join(DIR, f'seasonal_envelope_{sr}.png'); fig.savefig(p, dpi=140); plt.close(fig); print('wrote', p)

if __name__ == '__main__':
    for sr in SUB: fig_sub(sr)
    print('DONE')
