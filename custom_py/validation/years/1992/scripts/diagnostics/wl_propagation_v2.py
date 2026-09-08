"""Quantify tidal-band WL attenuation up the Swan estuary (model), vs the REAL inland tide
at Barrack St (PTBAR02, by the Narrows). High-pass (remove 25 h rolling mean) isolates the
tidal band from slow surge/inflow drift. -> years/1991/outputs/diagnostics/."""
import numpy as np, pandas as pd, xarray as xr
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
import tfv.xarray

import os
NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc'
PTBAR = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/csv/dot/tide/PTBAR02_Tidal_Height_DATA.csv'
FFFBH = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/csv/dot/tide/FFFBH01_Tidal_Height_DATA.csv'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1992/outputs/diagnostics/wl_tidal_attenuation.png'
os.makedirs(os.path.dirname(OUT), exist_ok=True)
W0, W1 = pd.Timestamp('1992-02-22'), pd.Timestamp('1992-04-19')   # 1992 NC window
PTS = {'Fremantle mouth':(115.7481,-32.0655),'mouth-inner':(115.760,-32.030),
       'Melville (SW of NAR)':(115.820,-31.985),'NAR (Narrows)':(115.847,-31.963)}

def tidal_band(s):                       # remove slow (>~25h) drift -> tidal band
    return (s - s.rolling(25, center=True, min_periods=13).mean()).dropna()

ds = xr.open_dataset(NC); fv = ds.tfv
X, Y = ds['cell_X'].values, ds['cell_Y'].values; mt = pd.to_datetime(ds['Time'].values)
tmask = (mt >= W0) & (mt <= W1)
print('=== MODEL tidal-band WL (high-passed) ===')
model_tb = {}
for name,(lo,la) in PTS.items():
    ci = int(np.argmin(((X-lo)*np.cos(np.radians(la)))**2+(Y-la)**2))
    h = pd.Series(np.asarray(ds['H'][:,ci]), index=mt)[tmask]
    tb = tidal_band(h); model_tb[name] = tb
    print(f'  {name:22s} tidal-band std {tb.std():.3f} m  p5-95 range {tb.quantile(.95)-tb.quantile(.05):.3f} m')
mouth_std = model_tb['Fremantle mouth'].std()
print(f'  --> NAR/mouth tidal-band ratio: {model_tb["NAR (Narrows)"].std()/mouth_std:.2%} (100% = no attenuation)')

# real obs tidal-band ranges (2000+ proxy; astronomical tide stationary)
def obs_tb(path, y0='2001-01-01', y1='2001-04-01'):
    o = pd.read_csv(path, usecols=['Date','Data']); o['t']=pd.to_datetime(o['Date'],errors='coerce')
    o['wl']=pd.to_numeric(o['Data'],errors='coerce'); o=o.dropna(subset=['t','wl'])
    o=o[(o.t>=y0)&(o.t<y1)].set_index('t')['wl'].resample('1h').mean().dropna()
    return tidal_band(o)
try:
    fre_o=obs_tb(FFFBH); bar_o=obs_tb(PTBAR)
    print('=== REAL obs tidal-band (2001 proxy) ===')
    print(f'  Fremantle FFFBH01  std {fre_o.std():.3f} m')
    print(f'  Barrack St PTBAR02  std {bar_o.std():.3f} m   --> real Barrack/Fremantle ratio {bar_o.std()/fre_o.std():.2%}')
    real_ok=True
except Exception as e:
    print('obs tidal-band failed:', e); real_ok=False

# plot: tidal-band time series (storm window) + attenuation bar
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6), gridspec_kw={'width_ratios':[2,1]})
colors={'Fremantle mouth':'#1f77b4','mouth-inner':'#9467bd','Melville (SW of NAR)':'#d62728','NAR (Narrows)':'#000000'}
for name,tb in model_tb.items():
    seg=tb[(tb.index>='1991-08-14')&(tb.index<='1991-08-19')]
    ax1.plot(seg.index, seg, lw=1.1, color=colors[name], label=f'{name}  (std {tb.std():.3f} m)')
ax1.set_ylabel('tidal-band WL (m)'); ax1.grid(alpha=0.3); ax1.legend(fontsize=8); ax1.set_title('MODEL tidal-band WL, 14-19 Aug (slow drift removed)')
# attenuation bars
names=list(PTS); mstd=[model_tb[n].std() for n in names]
ax2.bar(range(len(names)), np.array(mstd)/mouth_std*100, color=[colors[n] for n in names])
ax2.set_xticks(range(len(names))); ax2.set_xticklabels(['mouth','mouth-inner','Melville','NAR'], rotation=20)
ax2.set_ylabel('tidal amplitude, % of mouth'); ax2.set_title('MODEL tidal attenuation up-estuary'); ax2.grid(axis='y',alpha=0.3)
if real_ok:
    ax2.axhline(bar_o.std()/fre_o.std()*100, color='green', ls='--', lw=2, label=f'REAL Barrack/Fremantle = {bar_o.std()/fre_o.std():.0%}')
    ax2.legend(fontsize=9)
fig.suptitle('Swan estuary tidal propagation - is the tide choked at the Fremantle mouth?', fontweight='bold')
fig.tight_layout(rect=[0,0,1,0.96]); fig.savefig(OUT, dpi=140, bbox_inches='tight'); print('wrote', OUT)
