"""DWCM2 offshore mooring TEMPERATURE validation — obs vs HYCOM boundary forcing.

DWCM2 = deep open-shelf mooring, 106 m water, 45 km offshore on the western shelf
(31 45.8'S 115 15.2'E), NBIS ACM-2 with 4 thermistors at 10/35/62/87 m ASB, 5-min
records, 12 Oct 93 - 13 Jan 94 (WST). It sits ~15 km OUTSIDE the CSIEM mesh (nearest
model cell is 44 m deep), so this validates the OCEAN BOUNDARY FORCING the 1994 rev
run actually used -- HYCOM real reanalysis (obc_hd_19931101_19941231_6OBC_hycom.fvc) --
against an independent offshore 4-level T record.

The HYCOM cutout resolves only the top 50 m, so the two upper meters (87 ASB ~19 m,
62 ASB ~44 m) have a HYCOM counterpart; the two deep meters (35 ASB ~71 m, 10 ASB
~96 m) are shown obs-only (below forcing depth). Both series are daily means; both
timezones are WST (UTC+8). Reader reused verbatim from Velocity/plot_velocity_summary.py.
-> years/1994/outputs/dwcm2_temperature_validation.png
"""
import os, numpy as np, pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import xarray as xr

VELSCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1994/Velocity/plot_velocity_summary.py'
DWCM2_DIR = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1993/currents_data/DWCM2'
HYCOM     = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/HYCOM/HYCOM_UTC+8_19931001_19941231.nc'
REV_NC    = r'S:/Matt_Working/csiem/output_archive/1.7.0/1994_autumn_rev/csiem_B010_19931101_19941231_rev.nc'
OUT       = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1994/outputs/dwcm2_temperature_validation.png'

# --- reuse the documented .dos reader (exec prefix up to its meter loop) ---
src = open(VELSCRIPT, encoding='utf-8').read()
prefix = src[:src.index('meters = []')].replace("matplotlib.use('Agg')", "")
ns = {'__file__': VELSCRIPT, '__name__': 'vel94'}
exec(compile(prefix, VELSCRIPT, 'exec'), ns)
read_meter = ns['read_meter']

FILES = {87: 'dwcm2_87.dos', 62: 'dwcm2_62.dos', 35: 'dwcm2_35.dos', 10: 'dwcm2_10.dos'}
meters = {asb: read_meter(os.path.join(DWCM2_DIR, fn)) for asb, fn in FILES.items()}
water_depth = meters[87]['depth']; lat = meters[87]['lat']; lon = meters[87]['lon']
print(f"DWCM2 at ({lon:.4f},{lat:.4f})  water depth {water_depth:.0f} m")

h = xr.open_dataset(HYCOM)
hsub = h['water_temp'].sel(longitude=lon, latitude=lat, method='nearest')
hmaxz = float(h['depth'].max())
print(f"HYCOM node ({float(hsub['longitude']):.3f},{float(hsub['latitude']):.3f}); max depth {hmaxz:.0f} m")

# --- TUFLOW-FV: westernmost model cell near DWCM2 (model's offshore-boundary water) ---
import tfv.xarray
mds = xr.open_dataset(REV_NC); mfv = mds.tfv
mcx = mds['cell_X'].values; mcy = mds['cell_Y'].values; mzb = mds['cell_Zb'].values
_band = np.abs(mcy - lat) < 0.10
_wi = np.where(_band)[0][np.argmin(mcx[_band])]
mlon, mlat, mbed = float(mcx[_wi]), float(mcy[_wi]), abs(float(mzb[_wi]))
_dkm = (mlon - lon) * np.cos(np.radians(lat)) * 111
print(f"westmost TUFLOW cell ({mlon:.3f},{mlat:.3f}) bed {mbed:.0f} m  (~{_dkm:.0f} km E of DWCM2)")
def model_T_at_depth(z):
    r = mfv.get_timeseries(['TEMP'], (mlon, mlat), time=slice(xmin, xmax), datum='depth', limits=(z-1, z+1))
    return pd.Series(np.asarray(r['TEMP']).ravel(), index=pd.to_datetime(r['Time'].values)).resample('1D').mean()

levels = sorted(meters.keys(), reverse=True)   # 87,62,35,10 ASB = surface -> deep
fig, axes = plt.subplots(len(levels), 1, figsize=(14, 11), sharex=True)
xmin = pd.Timestamp('1993-11-01'); xmax = pd.Timestamp('1994-01-15')
stats = []
for ax, asb in zip(axes, levels):
    m = meters[asb]; z = water_depth - asb                      # depth below surface
    obs = pd.Series(np.asarray(m['temp']), index=pd.DatetimeIndex(m['t_T'])).sort_index().resample('1D').mean()
    ax.plot(obs.index, obs.values, color='#b2182b', lw=1.5, label=f'DWCM2 obs  ({asb} m ASB ≈ {z:.0f} m deep)')
    if z <= hmaxz:
        hy = hsub.interp(depth=z).to_series().resample('1D').mean()
        ax.plot(hy.index, hy.values, color='#2166ac', lw=1.7, ls='--', label=f'HYCOM forcing (≈ {z:.0f} m)')
        both = pd.concat([obs.rename('o'), hy.rename('h')], axis=1).dropna()
        both = both[(both.index >= xmin) & (both.index <= xmax)]
        if len(both):
            bias = (both['h'] - both['o']).mean(); rmse = ((both['h']-both['o'])**2).mean()**0.5
            stats.append((asb, z, bias, rmse, len(both)))
            ax.text(0.005, 0.05, f'HYCOM-obs bias {bias:+.2f}  rmse {rmse:.2f}  (n={len(both)})',
                    transform=ax.transAxes, fontsize=8, color='#2166ac')
    else:
        ax.text(0.005, 0.05, f'(below HYCOM {hmaxz:.0f} m — obs only; deep offshore water)',
                transform=ax.transAxes, fontsize=8, color='gray')
    if z < mbed:                                            # westmost TUFLOW-FV cell (offshore-boundary water)
        mt = model_T_at_depth(z)
        ax.plot(mt.index, mt.values, color='#1a9850', lw=1.5, ls=':',
                label=f'TUFLOW westmost cell (≈{z:.0f} m)')
        mb = pd.concat([obs.rename('o'), mt.rename('m')], axis=1).dropna()
        mb = mb[(mb.index >= xmin) & (mb.index <= xmax)]
        if len(mb):
            ax.text(0.005, 0.14, f'TUFLOW-obs bias {(mb["m"]-mb["o"]).mean():+.2f}  '
                    f'rmse {(((mb["m"]-mb["o"])**2).mean()**0.5):.2f}',
                    transform=ax.transAxes, fontsize=8, color='#1a9850')
    ax.set_ylabel('T (°C)'); ax.grid(alpha=0.3); ax.legend(fontsize=8, loc='upper right')
    ax.set_ylim(16, 22)
axes[-1].set_xlim(xmin, xmax); axes[-1].set_xlabel('1993-94 (WST)')
axes[0].set_title('DWCM2 offshore mooring (106 m, 45 km W shelf) — obs T vs HYCOM ocean boundary forcing (1994 rev)\n'
                  'mooring is ~15 km offshore of the CSIEM mesh: this validates the OBC forcing, not the interior model',
                  fontsize=12, fontweight='bold')
fig.tight_layout()
fig.savefig(OUT, dpi=150, bbox_inches='tight'); plt.close(fig)
print('wrote', OUT)
print('HYCOM-obs T bias by level:')
for asb, z, b, r, n in stats:
    print(f'  {asb} m ASB (~{z:.0f} m): bias {b:+.2f} C  rmse {r:.2f}  n={n}')
