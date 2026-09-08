"""Plots for the extended CSIEM ocean assessment (reads extended_assessment.csv):
  1. scatter_{surface,bottom}.png  -- obs vs BC and obs vs MODEL, T & S, by subregion
  2. subregion_bias_summary.png/.csv -- mean bias per subregion, BC vs MODEL
  3. seasonal_{subregion}.png  -- day-of-year seasonal curves: climatology line + obs + model
"""
import os, numpy as np, pandas as pd, xarray as xr, warnings
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment'
df = pd.read_csv(os.path.join(DIR, 'extended_assessment.csv'))
# --- QC (from adversarial audit) ---
# CTD fresh-bottom spikes: obs bottom salinity < 33 is unphysical on the open shelf
# (sensor/QC spike) and otherwise inflates the N-subregion bottom bias. Exclude those
# obs bottoms from BOTTOM comparisons only (surface is untouched and robust).
_bad_bot = df['obs_botS'] < 33.0
df.loc[_bad_bot, ['obs_botT', 'obs_botS']] = np.nan
print(f'QC: masked {int(_bad_bot.sum())} CTD fresh-bottom spikes (obs_botS<33) for bottom stats')
# Note: 1993/94 model output is essentially absent (NaN) -> model stats are the 1991/92 ROMS-BC period.
SUB = ['N', 'NW', 'W', 'SW', 'S']
SUBC = {'N': '#e41a1c', 'NW': '#ff7f00', 'W': '#4daf4a', 'SW': '#377eb8', 'S': '#984ea3'}
YEARC = {1991: '#e41a1c', 1992: '#377eb8', 1993: '#4daf4a', 1994: '#984ea3'}

def _stats(o, m):
    d = (m - o); d = d[np.isfinite(d)]
    return (np.nan, np.nan, 0) if len(d) == 0 else (float(d.mean()), float(np.sqrt((d**2).mean())), len(d))

# ---------------------------------------------------------------- 1. scatter
def scatter_fig(level):
    LVL={'surf':'Surface','bot':'Bottom'}[level]
    fig, axes = plt.subplots(2, 2, figsize=(13, 13))
    combos = [('bc', 'T'), ('bc', 'S'), ('model', 'T'), ('model', 'S')]
    names = {'bc': 'BC (ROMS clim / HYCOM)', 'model': 'TUFLOW-FV model'}
    units = {'T': '°C', 'S': 'psu'}
    for ax, (tag, v) in zip(axes.ravel(), combos):
        oc, mc = f'obs_{level}{v}', f'{tag}_{level}{v}'
        sub = df[[oc, mc, 'subregion']].dropna()
        for sr in SUB:
            s = sub[sub.subregion == sr]
            if len(s): ax.scatter(s[oc], s[mc], s=14, c=SUBC[sr], alpha=0.6, label=f'{sr} (n={len(s)})')
        bias, rmse, n = _stats(sub[oc].values, sub[mc].values)
        lo = np.nanmin([sub[oc].min(), sub[mc].min()]); hi = np.nanmax([sub[oc].max(), sub[mc].max()])
        pad = (hi - lo) * 0.05 or 0.5
        ax.plot([lo - pad, hi + pad], [lo - pad, hi + pad], 'k-', lw=1, label='1:1')
        ax.set_xlim(lo - pad, hi + pad); ax.set_ylim(lo - pad, hi + pad); ax.set_aspect('equal')
        ax.set_xlabel(f'Observed {v} ({units[v]})'); ax.set_ylabel(f'{names[tag]} {v} ({units[v]})')
        ax.set_title(f'{names[tag]} vs obs — {v} {LVL}  (n={n}, bias={bias:+.3f}, RMSE={rmse:.3f})', fontsize=10)
        ax.legend(fontsize=7, loc='upper left'); ax.grid(alpha=0.3)
    fig.suptitle(f'{LVL} obs-vs-source scatter (coloured by subregion)', fontsize=14, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.98])
    p = os.path.join(DIR, f'scatter_{level}.png'); fig.savefig(p, dpi=150); plt.close(fig); print('wrote', p)

# ---------------------------------------------------------------- 2. subregion bias summary
def bias_summary():
    recs = []
    for sr in SUB:
        d = df[df.subregion == sr]
        for tag in ['bc', 'model']:
            for lvl in ['surf', 'bot']:
                for v in ['T', 'S']:
                    b, rm, n = _stats(d[f'obs_{lvl}{v}'].values, d[f'{tag}_{lvl}{v}'].values)
                    recs.append(dict(subregion=sr, source=tag, level=lvl, var=v, bias=b, rmse=rm, n=n))
    summ = pd.DataFrame(recs)
    summ.to_csv(os.path.join(DIR, 'subregion_bias_summary.csv'), index=False)
    # grouped bar: 2x2 (rows surf/bot, cols T/S), x=subregion, bars BC vs MODEL
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    for ax, (lvl, v) in zip(axes.ravel(), [('surf', 'T'), ('surf', 'S'), ('bot', 'T'), ('bot', 'S')]):
        x = np.arange(len(SUB)); w = 0.38
        for k, (tag, col) in enumerate([('bc', '#888888'), ('model', '#1f77b4')]):
            vals = [summ[(summ.subregion == sr) & (summ.source == tag) & (summ.level == lvl) & (summ['var'] == v)]['bias'].values[0] for sr in SUB]
            ax.bar(x + (k - 0.5) * w, vals, w, color=col, label=tag.upper())
        ax.axhline(0, color='k', lw=0.8); ax.set_xticks(x); ax.set_xticklabels(SUB)
        ax.set_title(f'{lvl} {v} bias (source - obs)', fontsize=11); ax.set_ylabel('°C' if v == 'T' else 'psu')
        ax.legend(fontsize=9); ax.grid(axis='y', alpha=0.3)
    fig.suptitle('Mean bias by subregion (positive = source too warm/salty)', fontsize=14, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    p = os.path.join(DIR, 'subregion_bias_summary.png'); fig.savefig(p, dpi=150); plt.close(fig); print('wrote', p)
    return summ

# ---------------------------------------------------------------- 3. seasonal time-series
ROMS_CLIM = r'S:/Matt_Working/csiem/model_components/environment_repo/3_ocean/CLIMATOLOGY/ROMS_UTC+8_19911001_19921231_climatology.nc'
def clim_curve(rep_lat, rep_lon, rep_botdepth):
    d = xr.open_dataset(ROMS_CLIM)
    lats = d['lat'].values; lons = d['lon'].values; dep = d['depth'].values
    ilat = int(np.argmin(np.abs(lats - rep_lat))); ilon = int(np.argmin(np.abs(lons - rep_lon)))
    t = pd.to_datetime(d['time'].values)
    m = (t >= pd.Timestamp('1992-01-01')) & (t <= pd.Timestamp('1992-12-31'))   # one perpetual-cycle year
    ti = np.where(m)[0]
    doy, sT, sS, bT, bS = [], [], [], [], []
    for it in ti:
        T = np.asarray(d['water_temp'][it, :, ilat, ilon], 'float64'); S = np.asarray(d['salinity'][it, :, ilat, ilon], 'float64')
        ok = np.isfinite(T) & np.isfinite(S)
        if ok.sum() < 1: continue
        dv, Tv, Sv = dep[ok], T[ok], S[ok]; o = np.argsort(dv); dv, Tv, Sv = dv[o], Tv[o], Sv[o]
        srf = dv <= 2.0; bd = min(rep_botdepth, float(dv.max()))
        doy.append(int(t[it].dayofyear))
        sT.append(Tv[srf].mean() if srf.any() else Tv[0]); sS.append(Sv[srf].mean() if srf.any() else Sv[0])
        bT.append(np.interp(bd, dv, Tv)); bS.append(np.interp(bd, dv, Sv))
    d.close()
    order = np.argsort(doy)
    return (np.array(doy)[order], np.array(sT)[order], np.array(sS)[order], np.array(bT)[order], np.array(bS)[order])

def seasonal_fig(sr):
    d = df[df.subregion == sr]
    if len(d) == 0: return
    rep_lat, rep_lon, rep_bot = d.lat.median(), d.lon.median(), d.obs_maxdep.median()
    cdoy, csT, csS, cbT, cbS = clim_curve(rep_lat, rep_lon, rep_bot)
    fig, axes = plt.subplots(2, 2, figsize=(15, 9), sharex=True)
    panels = [('surfT', csT, 'Surface T (°C)'), ('surfS', csS, 'Surface S (psu)'),
              ('botT', cbT, 'Bottom T (°C)'), ('botS', cbS, 'Bottom S (psu)')]
    cdat = {'surfT': csT, 'surfS': csS, 'botT': cbT, 'botS': cbS}
    for ax, (key, cy, lab) in zip(axes.ravel(), panels):
        ax.plot(cdoy, cdat[key], '-', color='steelblue', lw=2, label='ROMS climatology', zorder=2)
        for yr in sorted(d.year.unique()):
            dy = d[d.year == yr]
            ax.scatter(dy.doy, dy[f'obs_{key}'], s=26, c=YEARC.get(yr, 'k'), edgecolors='k', linewidths=0.3,
                       label=f'obs {yr}', zorder=4)
        mv = d.dropna(subset=[f'model_{key}'])
        if len(mv): ax.scatter(mv.doy, mv[f'model_{key}'], s=34, marker='x', c='red', label='TUFLOW-FV', zorder=5)
        ax.set_ylabel(lab); ax.grid(alpha=0.3)
        if key in ('botT', 'botS'): ax.set_xlabel('Day of year')
    axes[0, 0].legend(fontsize=8, ncol=2, loc='best')
    fig.suptitle(f'Seasonal alignment — subregion {sr}  (rep lat {rep_lat:.3f}, lon {rep_lon:.3f}, ~{rep_bot:.0f} m, n={len(d)} casts)',
                 fontsize=13, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    p = os.path.join(DIR, f'seasonal_{sr}.png'); fig.savefig(p, dpi=150); plt.close(fig); print('wrote', p)

if __name__ == '__main__':
    scatter_fig('surf'); scatter_fig('bot')
    summ = bias_summary()
    for sr in SUB: seasonal_fig(sr)
    print('\n=== subregion bias summary (surface) ===')
    print(summ[summ.level == 'surf'].pivot_table(index='subregion', columns=['source', 'var'], values='bias').round(3))
