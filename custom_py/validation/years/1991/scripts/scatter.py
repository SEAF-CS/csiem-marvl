"""Plots for the region-based model validation (reads region_validation_<tag>.csv):
  1. scatter_validation_<tag>.png   -- obs vs TUFLOW-FV, 2x2 (surf/bot x T/S), coloured by region
  2. region_bias_<tag>.png/.csv     -- mean model-obs bias per region (surf/bot x T/S)
  3. region_map_<tag>.png           -- cast locations coloured by region over OA/CS polygons
No ROMS / no BC -- model validation only.  CLI: python region_validation_plots.py [tag]
"""
import os, sys, numpy as np, pandas as pd, warnings
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

DIR = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs'
TAG = sys.argv[1] if len(sys.argv) > 1 else '1991'
df = pd.read_csv(os.path.join(DIR, f'region_validation_{TAG}.csv'))

# bottom QC: obs bottom salinity < 33 is unphysical here (sensor spike) -> drop for bottom stats
_bad = df['obs_botS'] < 33.0
df.loc[_bad, ['obs_botT', 'obs_botS']] = np.nan
print(f'QC: masked {int(_bad.sum())} fresh-bottom spikes (obs_botS<33) for bottom stats')

REGION_ORDER = ['OA', 'CS', 'N', 'NW', 'W', 'SW', 'S']
REGION_C = {'OA': '#e41a1c', 'CS': '#377eb8', 'N': '#4daf4a', 'NW': '#984ea3',
            'W': '#ff7f00', 'SW': '#a65628', 'S': '#f781bf'}
REGIONS = [r for r in REGION_ORDER if r in df.region.unique()]
UNITS = {'T': '°C', 'S': 'psu'}
LVLNAME = {'surf': 'Surface', 'bot': 'Bottom'}

def _stats(o, m):
    d = (m - o); d = d[np.isfinite(d)]
    return (np.nan, np.nan, 0) if len(d) == 0 else (float(d.mean()), float(np.sqrt((d**2).mean())), len(d))

# ---------------------------------------------------------------- 1. scatter (2x2)
def scatter_fig():
    fig, axes = plt.subplots(2, 2, figsize=(13, 13))
    for ax, (lvl, v) in zip(axes.ravel(), [('surf', 'T'), ('surf', 'S'), ('bot', 'T'), ('bot', 'S')]):
        oc, mc = f'obs_{lvl}{v}', f'model_{lvl}{v}'
        sub = df[[oc, mc, 'region']].dropna()
        for rg in REGIONS:
            s = sub[sub.region == rg]
            if len(s): ax.scatter(s[oc], s[mc], s=16, c=REGION_C[rg], alpha=0.6,
                                  edgecolors='none', label=f'{rg} (n={len(s)})')
        bias, rmse, n = _stats(sub[oc].values, sub[mc].values)
        if n:
            lo = min(sub[oc].min(), sub[mc].min()); hi = max(sub[oc].max(), sub[mc].max())
            pad = (hi - lo) * 0.05 or 0.5
            ax.plot([lo - pad, hi + pad], [lo - pad, hi + pad], 'k-', lw=1, label='1:1')
            ax.set_xlim(lo - pad, hi + pad); ax.set_ylim(lo - pad, hi + pad)
        ax.set_aspect('equal', adjustable='box')
        ax.set_xlabel(f'Observed {v} ({UNITS[v]})'); ax.set_ylabel(f'TUFLOW-FV {v} ({UNITS[v]})')
        ax.set_title(f'{LVLNAME[lvl]} {v}  (n={n}, bias={bias:+.3f}, RMSE={rmse:.3f})', fontsize=11)
        ax.legend(fontsize=7, loc='upper left', framealpha=0.9); ax.grid(alpha=0.3)
    fig.suptitle(f'TUFLOW-FV vs observed CTD — {TAG}  (coloured by region; OA & CS = inner embayments)',
                 fontsize=14, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.98])
    p = os.path.join(DIR, f'scatter_validation_{TAG}.png'); fig.savefig(p, dpi=150); plt.close(fig); print('wrote', p)

# ---------------------------------------------------------------- 2. region bias summary
def region_bias():
    recs = []
    for rg in REGIONS:
        d = df[df.region == rg]
        for lvl in ['surf', 'bot']:
            for v in ['T', 'S']:
                b, rm, n = _stats(d[f'obs_{lvl}{v}'].values, d[f'model_{lvl}{v}'].values)
                recs.append(dict(region=rg, level=lvl, var=v, bias=b, rmse=rm, n=n))
    summ = pd.DataFrame(recs)
    summ.to_csv(os.path.join(DIR, f'region_bias_{TAG}.csv'), index=False)
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    for ax, (lvl, v) in zip(axes.ravel(), [('surf', 'T'), ('surf', 'S'), ('bot', 'T'), ('bot', 'S')]):
        x = np.arange(len(REGIONS))
        vals = [summ[(summ.region == rg) & (summ.level == lvl) & (summ['var'] == v)]['bias'].values[0] for rg in REGIONS]
        ns = [int(summ[(summ.region == rg) & (summ.level == lvl) & (summ['var'] == v)]['n'].values[0]) for rg in REGIONS]
        ax.bar(x, vals, 0.6, color=[REGION_C[rg] for rg in REGIONS])
        for xi, (val, nn) in enumerate(zip(vals, ns)):
            if np.isfinite(val):
                ax.text(xi, val + (0.02 if val >= 0 else -0.02), f'{val:+.2f}\nn={nn}',
                        ha='center', va='bottom' if val >= 0 else 'top', fontsize=7)
        ax.axhline(0, color='k', lw=0.8); ax.set_xticks(x); ax.set_xticklabels(REGIONS)
        ax.set_title(f'{LVLNAME[lvl]} {v} bias (model − obs)', fontsize=11)
        ax.set_ylabel(UNITS[v]); ax.grid(axis='y', alpha=0.3)
    fig.suptitle(f'Model bias by region — {TAG}  (positive = model too warm/salty)', fontsize=14, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    p = os.path.join(DIR, f'region_bias_{TAG}.png'); fig.savefig(p, dpi=150); plt.close(fig); print('wrote', p)
    return summ

# ---------------------------------------------------------------- 3. region / cast map
def region_map():
    try:
        import geopandas as gpd
        z = gpd.read_file(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/gis/Zones/MLAU_Zones_v3_ll.shp')
        diss = z.dissolve(by='BP_Region')
    except Exception as e:
        print('map skipped (geopandas):', e); return
    fig, ax = plt.subplots(figsize=(9, 11))
    for nm, col in [('Owen Anchorage', '#e41a1c'), ('Cockburn Sound', '#377eb8')]:
        gpd.GeoSeries([diss.loc[nm, 'geometry']]).boundary.plot(ax=ax, color=col, lw=1.5)
    for ylat in [-32.00, -32.15, -32.25, -32.35]:
        ax.axhline(ylat, color='grey', lw=0.5, ls='--')
    for rg in REGIONS:
        s = df[df.region == rg]
        ax.scatter(s.lon, s.lat, s=20, c=REGION_C[rg], alpha=0.7, edgecolors='k', linewidths=0.2, label=f'{rg} (n={len(s)})')
    ax.set_xlabel('Longitude'); ax.set_ylabel('Latitude'); ax.set_aspect('equal')
    ax.legend(fontsize=8, loc='upper left'); ax.grid(alpha=0.25)
    ax.set_title(f'CTD cast regions — {TAG}  (OA red / CS blue polygons; dashed = lat bands)', fontsize=12, fontweight='bold')
    fig.tight_layout()
    p = os.path.join(DIR, f'region_map_{TAG}.png'); fig.savefig(p, dpi=150); plt.close(fig); print('wrote', p)

if __name__ == '__main__':
    scatter_fig()
    summ = region_bias()
    region_map()
    print('\n=== per-region SURFACE bias (model - obs) ===')
    piv = summ[summ.level == 'surf'].pivot_table(index='region', columns='var', values='bias').reindex(REGIONS).round(3)
    piv['n'] = [int(summ[(summ.region == rg) & (summ.level == 'surf') & (summ['var'] == 'S')]['n'].values[0]) for rg in REGIONS]
    print(piv.to_string())
