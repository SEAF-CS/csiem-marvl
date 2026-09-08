"""OA80 surface & bottom time series: model T, S, rho over the sim vs SMCWS field casts (dots).
Same as the CS55 plot, for OA80. The T panel ALSO shows the NAR (Swan) inflow temperature BC.
surf = top-2 m mean, bot = bottom-2 m mean; rho = EOS-80 sigma-t (potential density - 1000)."""
import os, sys, numpy as np, pandas as pd, xarray as xr
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt, matplotlib.dates as mdates
import tfv.xarray
LIB = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib'
sys.path.insert(0, LIB)
import region_validation_core as core
from point_overrides import adjust_point
from eos80 import eos80_potential_density

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
DATA = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/data'
SCE = r'S:/Matt_Working/csiem/model_components/environment_repo/4_sce/CSV'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/TimeSeries/oa80_timeseries_TSrho_1991_rev.png'
import os as _os; _os.makedirs(_os.path.dirname(OUT), exist_ok=True)
SITE = 'OA80'; LONLAT = (115.7013, -32.1313)
SIM0 = pd.Timestamp('1991-07-20')

# ---- model: full profile time series, surf/bot per timestep ----
mlon, mlat = adjust_point(SITE, *LONLAT)
ds = xr.open_dataset(NC); fv = ds.tfv
p = fv.get_profile((mlon, mlat), variables=['SAL', 'TEMP'])
mt = pd.to_datetime(ds['Time'].values)
Z = -np.asarray(p['Z']).reshape(len(mt), -1)
S = np.asarray(p['SAL']).reshape(len(mt), -1); T = np.asarray(p['TEMP']).reshape(len(mt), -1)
msT = np.full(len(mt), np.nan); mbT = msT.copy(); msS = msT.copy(); mbS = msT.copy()
for i in range(len(mt)):
    z, s, t = Z[i], S[i], T[i]
    ok = np.isfinite(z) & np.isfinite(s) & np.isfinite(t) & (z > 0.05)
    if ok.sum() < 1: continue
    z, s, t = z[ok], s[ok], t[ok]; zmax = z.max()
    su = z <= 2.0; bo = z >= (zmax - 2.0)
    msS[i], msT[i] = s[su].mean(), t[su].mean(); mbS[i], mbT[i] = s[bo].mean(), t[bo].mean()
msR = eos80_potential_density(msS, msT) - 1000.0; mbR = eos80_potential_density(mbS, mbT) - 1000.0

# ---- field: OA80 casts in the sim window ----
inv = pd.read_csv(os.path.join(DATA, 'region_profiles_inventory.csv'))
cs = inv[(inv.station == SITE) & (inv.year == 1991)].copy()
ts = cs['time'].astype(int).astype(str).str.zfill(4)
cs['dt'] = pd.to_datetime(cs['date']) + pd.to_timedelta(ts.str[:2].astype(int), 'h') + pd.to_timedelta(ts.str[2:].astype(int), 'm')
cs = cs[cs['dt'] >= SIM0].sort_values('dt')
fdt, fsT, fbT, fsS, fbS, fsR, fbR = ([] for _ in range(7))
for _, r in cs.iterrows():
    cast = core._read_cast(r['source_file'], r['prefix'])
    if cast is None: continue
    o = core.obs_surf_bot(*cast)
    fdt.append(r['dt']); fsT.append(o['surfT']); fbT.append(o['botT']); fsS.append(o['surfS']); fbS.append(o['botS'])
    fsR.append(eos80_potential_density(o['surfS'], o['surfT']) - 1000.0); fbR.append(eos80_potential_density(o['botS'], o['botT']) - 1000.0)
fdt = pd.to_datetime(fdt); last = fdt.max()
print(f'{SITE} field casts in sim window: {len(fdt)}  ({fdt.min():%d-%b} .. {last:%d-%b %H:%M})')

# ---- NAR (Swan) inflow temperature BC (col TEMP) ----
nar = pd.read_csv(f'{SCE}/NAR_Inflow_19700101_19941231_SALclim.csv')
nar['t'] = pd.to_datetime(nar['Date'], format='%d/%m/%Y')
narT = nar.set_index('t')['TEMP']; narT = narT[(narT.index >= SIM0 - pd.Timedelta('2d')) & (narT.index <= last + pd.Timedelta('2d'))]

# ---- forcing: river inflow + CS wind ----
def load_flow(tag, scale):
    f = pd.read_csv(rf'{SCE}/{tag}_Inflow_19700101_19941231.csv'); f['t'] = pd.to_datetime(f['Date'], format='%d/%m/%Y'); return f.set_index('t')['Flow'] * scale
flow = (load_flow('NAR', 1.5) + load_flow('CAN', 2.0)); flow = flow[(flow.index >= SIM0 - pd.Timedelta('1d')) & (flow.index <= last + pd.Timedelta('2d'))]
wind = pd.read_csv(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/mesh_refinement/common/data/wind_cs_1991.csv'); wind['t'] = pd.to_datetime(wind['time']); wind = wind.set_index('t')

# ---- plot ----
SURF, BOT = '#1f77b4', '#d62728'
rows = [('Temperature (°C)', msT, mbT, fsT, fbT), ('Salinity (psu)', msS, mbS, fsS, fbS),
        ('Density  $\\sigma_t$ (kg m$^{-3}$)', msR, mbR, fsR, fbR)]
fig, axes = plt.subplots(4, 1, figsize=(14, 12.5), sharex=True)
for ax, (lab, ms, mb, fs, fb) in zip(axes[:3], rows):
    ax.plot(mt, ms, '-', color=SURF, lw=1.2, label='model surface (top 2 m)')
    ax.plot(mt, mb, '-', color=BOT, lw=1.2, label='model bottom (bot 2 m)')
    ax.scatter(fdt, fs, s=42, color=SURF, edgecolor='k', lw=0.6, zorder=5, label='field surface')
    ax.scatter(fdt, fb, s=42, color=BOT, edgecolor='k', lw=0.6, zorder=5, marker='s', label='field bottom')
    ax.set_ylabel(lab); ax.grid(alpha=0.3)
# NAR inflow temperature on the T panel
axes[0].plot(narT.index, narT.values, '-', color='darkorange', lw=2.0, drawstyle='steps-post', label='NAR (Swan) inflow T (BC)')
axes[0].legend(fontsize=8, ncol=3, loc='upper left')
# west-most IC reference markers
west_ic = [19.4, 36.10, float(eos80_potential_density(36.10, 19.4) - 1000.0)]
for ax, wv in zip(axes[:3], west_ic):
    ax.plot(SIM0, wv, marker='*', ms=15, color='m', mec='k', mew=0.6, zorder=7, clip_on=False)
    ax.annotate(f'IC W-limit {wv:.2f}', (SIM0, wv), xytext=(-8, 0), textcoords='offset points', fontsize=7.5, va='center', ha='right', color='m', fontweight='bold')
# panel 4: flow + wind
axf = axes[3]; FC = '#1f5c8a'; WC = '#2ca02c'
axf.fill_between(flow.index, flow.values, step='mid', color=FC, alpha=0.30); axf.plot(flow.index, flow.values, drawstyle='steps-mid', color=FC, lw=1.4, label='river inflow (NAR×1.5 + CAN×2.0)')
axf.set_ylabel('River inflow (m$^3$ s$^{-1}$)', color=FC); axf.tick_params(axis='y', labelcolor=FC); axf.set_ylim(0, None); axf.grid(alpha=0.3)
axw = axf.twinx(); axw.plot(wind.index, wind['speed'], color=WC, lw=0.8, alpha=0.85, label='CS wind speed'); axw.set_ylabel('Wind speed (m s$^{-1}$)', color=WC); axw.tick_params(axis='y', labelcolor=WC); axw.set_ylim(0, None)
h1, l1 = axf.get_legend_handles_labels(); h2, l2 = axw.get_legend_handles_labels(); axf.legend(h1 + h2, l1 + l2, fontsize=8, loc='upper left')
axes[-1].set_xlim(SIM0 - pd.Timedelta('2d'), last + pd.Timedelta('12h'))
axes[-1].xaxis.set_major_locator(mdates.DayLocator(interval=3)); axes[-1].xaxis.set_major_formatter(mdates.DateFormatter('%d-%b'))
for dt in fdt: [ax.axvline(dt, color='0.85', lw=0.4, zorder=0) for ax in axes]
fig.suptitle(f'{SITE} ({LONLAT[0]}, {LONLAT[1]}) - model vs SMCWS field: surface & bottom T, S, density\n'
             'sim start 20-Jul -> last field cast 23-Aug 1991 (1991 rev); T panel shows NAR (Swan) inflow T', fontweight='bold')
fig.autofmt_xdate(); fig.tight_layout(rect=[0, 0, 1, 0.96]); fig.savefig(OUT, dpi=150, bbox_inches='tight'); print('wrote', OUT)
