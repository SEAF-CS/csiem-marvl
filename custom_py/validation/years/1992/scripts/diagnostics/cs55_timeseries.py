"""CS55 surface & bottom time series (1992): model T, S, rho over the sim vs SMCWS field casts.
Sim start (22-Feb) to the last CS55 field cast in the NC window. surf = top-2 m mean,
bot = bottom-2 m mean; rho = EOS-80 sigma-t. Ported from the 1991 diagnostic.
NB 1992 rev uses the RAW SCE inflow BC (no SAL/TEMP climatology, no flow scaling)."""
import os, sys, numpy as np, pandas as pd, xarray as xr
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt, matplotlib.dates as mdates
import tfv.xarray
sys.path.insert(0, r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib')
import region_validation_core as core
from point_overrides import adjust_point
from eos80 import eos80_potential_density

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc'
DATA = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/data'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1992/outputs/TimeSeries/cs55_timeseries_TSrho_1992_rev.png'
import os as _os; _os.makedirs(_os.path.dirname(OUT), exist_ok=True)
CS55 = (115.7140, -32.1876); YEAR = 1992; SIM0 = pd.Timestamp('1992-02-22')
IC_WEST = dict(T=20.9, S=35.8)                      # 1992 Mar IC west-limit (S 35.8->36.25, T 20.9->23.2)

# ---- model: full profile time series at CS55, surf/bot per timestep ----
mlon, mlat = adjust_point('CS55', *CS55)
ds = xr.open_dataset(NC); fv = ds.tfv
p = fv.get_profile((mlon, mlat), variables=['SAL', 'TEMP']); mt = pd.to_datetime(ds['Time'].values)
Z = -np.asarray(p['Z']).reshape(len(mt), -1)
S = np.asarray(p['SAL']).reshape(len(mt), -1); T = np.asarray(p['TEMP']).reshape(len(mt), -1)
msT = np.full(len(mt), np.nan); mbT = msT.copy(); msS = msT.copy(); mbS = msT.copy()
for i in range(len(mt)):
    z, s, t = Z[i], S[i], T[i]; ok = np.isfinite(z) & np.isfinite(s) & np.isfinite(t) & (z > 0.05)
    if ok.sum() < 1: continue
    z, s, t = z[ok], s[ok], t[ok]; zmax = z.max(); su = z <= 2.0; bo = z >= (zmax - 2.0)
    msS[i], msT[i] = s[su].mean(), t[su].mean(); mbS[i], mbT[i] = s[bo].mean(), t[bo].mean()
msR = eos80_potential_density(msS, msT) - 1000.0; mbR = eos80_potential_density(mbS, mbT) - 1000.0

# ---- field: CS55 casts in the sim window ----
inv = pd.read_csv(os.path.join(DATA, 'region_profiles_inventory.csv'))
cs = inv[(inv.station == 'CS55') & (inv.year == YEAR)].copy()
ts = cs['time'].astype(int).astype(str).str.zfill(4)
cs['dt'] = pd.to_datetime(cs['date']) + pd.to_timedelta(ts.str[:2].astype(int), 'h') + pd.to_timedelta(ts.str[2:].astype(int), 'm')
cs = cs[(cs['dt'] >= SIM0) & (cs['dt'] <= mt.max())].sort_values('dt')
fdt, fsT, fbT, fsS, fbS, fsR, fbR = ([] for _ in range(7))
for _, r in cs.iterrows():
    cast = core._read_cast(r['source_file'], r['prefix'])
    if cast is None: continue
    o = core.obs_surf_bot(*cast)
    fdt.append(r['dt']); fsT.append(o['surfT']); fbT.append(o['botT']); fsS.append(o['surfS']); fbS.append(o['botS'])
    fsR.append(eos80_potential_density(o['surfS'], o['surfT']) - 1000.0); fbR.append(eos80_potential_density(o['botS'], o['botT']) - 1000.0)
fdt = pd.to_datetime(fdt); last = fdt.max()
print(f'CS55 {YEAR} field casts in window: {len(fdt)}  ({fdt.min():%d-%b} .. {last:%d-%b %H:%M})')

# ---- forcing: river inflow (RAW, scale 1) + CS wind from the met NC ----
def load_flow(tag):
    f = pd.read_csv(rf'S:/Matt_Working/csiem/model_components/environment_repo/4_sce/CSV/{tag}_Inflow_19700101_19941231.csv')
    f['t'] = pd.to_datetime(f['Date'], format='%d/%m/%Y'); return f.set_index('t')['Flow']
flow = (load_flow('NAR') + load_flow('CAN')); flow = flow[(flow.index >= SIM0 - pd.Timedelta('1d')) & (flow.index <= last + pd.Timedelta('2d'))]
mm = xr.open_dataset(NC.replace('.nc', '_met.nc')); mmfv = mm.tfv; wmt = pd.to_datetime(mm['Time'].values)
mX, mY = mm['cell_X'].values, mm['cell_Y'].values
wci = int(np.argmin(((mX - CS55[0]) * np.cos(np.radians(CS55[1])))**2 + (mY - CS55[1])**2))
wind = pd.Series(np.hypot(np.asarray(mm['W10_x'][:, wci]), np.asarray(mm['W10_y'][:, wci])), index=wmt)

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
axes[0].legend(fontsize=8, ncol=2, loc='upper left')
west_ic = [IC_WEST['T'], IC_WEST['S'], float(eos80_potential_density(IC_WEST['S'], IC_WEST['T']) - 1000.0)]
for ax, wv in zip(axes[:3], west_ic):
    ax.plot(SIM0, wv, marker='*', ms=15, color='m', mec='k', mew=0.6, zorder=7, clip_on=False)
    ax.annotate(f'IC W-limit {wv:.2f}', (SIM0, wv), xytext=(-8, 0), textcoords='offset points', fontsize=7.5, va='center', ha='right', color='m', fontweight='bold')
axf = axes[3]; FC = '#1f5c8a'; WC = '#2ca02c'
axf.fill_between(flow.index, flow.values, step='mid', color=FC, alpha=0.30); axf.plot(flow.index, flow.values, drawstyle='steps-mid', color=FC, lw=1.4, label='river inflow (NAR+CAN, raw)')
axf.set_ylabel('River inflow (m$^3$ s$^{-1}$)', color=FC); axf.tick_params(axis='y', labelcolor=FC); axf.set_ylim(0, None); axf.grid(alpha=0.3)
axw = axf.twinx(); axw.plot(wind.index, wind.values, color=WC, lw=0.8, alpha=0.85, label='CS wind speed (model met)'); axw.set_ylabel('Wind speed (m s$^{-1}$)', color=WC); axw.tick_params(axis='y', labelcolor=WC); axw.set_ylim(0, None)
h1, l1 = axf.get_legend_handles_labels(); h2, l2 = axw.get_legend_handles_labels(); axf.legend(h1 + h2, l1 + l2, fontsize=8, loc='upper left')
axes[-1].set_xlim(SIM0 - pd.Timedelta('2d'), last + pd.Timedelta('1d'))
axes[-1].xaxis.set_major_locator(mdates.DayLocator(interval=5)); axes[-1].xaxis.set_major_formatter(mdates.DateFormatter('%d-%b'))
for dt in fdt: [ax.axvline(dt, color='0.85', lw=0.4, zorder=0) for ax in axes]
fig.suptitle(f'CS55 (115.714, -32.188) - model vs SMCWS field: surface & bottom T, S, density\n'
             f'sim start 22-Feb -> last field cast {last:%d-%b} 1992 (1992 rev; RAW inflow BC)', fontweight='bold')
fig.autofmt_xdate(); fig.tight_layout(rect=[0, 0, 1, 0.96]); fig.savefig(OUT, dpi=150, bbox_inches='tight'); print('wrote', OUT)
