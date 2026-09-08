"""Variant of region_validation_plots scatter: symbol COLOUR = longitude (cross-shelf),
symbol SHAPE = region (OA/CS/N/NW/W/SW/S).  Reads region_validation_<tag>.csv.
No ROMS/BC.  CLI: python region_validation_plots_lon.py [tag]   (e.g. 1991, 1991_0813)
Writes scatter_validation_lon_<tag>.png
"""
import os, sys, numpy as np, pandas as pd, warnings
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib as mpl, matplotlib.pyplot as plt
from matplotlib.lines import Line2D

DIR = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs'
TAG = sys.argv[1] if len(sys.argv) > 1 else '1991'
df = pd.read_csv(os.path.join(DIR, f'region_validation_{TAG}.csv'))

# bottom QC: obs bottom S < 33 is an unphysical sensor spike -> drop for bottom stats
_bad = df['obs_botS'] < 33.0
df.loc[_bad, ['obs_botT', 'obs_botS']] = np.nan
print(f'QC: masked {int(_bad.sum())} fresh-bottom spikes (obs_botS<33) for bottom stats')

REGION_ORDER = ['OA', 'CS', 'N', 'NW', 'W', 'SW', 'S']
MARKERS = {'OA': 'o', 'CS': 's', 'N': '^', 'NW': 'v', 'W': 'D', 'SW': 'P', 'S': 'X'}
REGIONS = [r for r in REGION_ORDER if r in df.region.unique()]
UNITS = {'T': '°C', 'S': 'psu'}
LVLNAME = {'surf': 'Surface', 'bot': 'Bottom'}
CMAP = 'viridis'
LON_MIN, LON_MAX = float(df.lon.min()), float(df.lon.max())
norm = mpl.colors.Normalize(vmin=LON_MIN, vmax=LON_MAX)

def _stats(o, m):
    d = (m - o); d = d[np.isfinite(d)]
    return (np.nan, np.nan, 0) if len(d) == 0 else (float(d.mean()), float(np.sqrt((d**2).mean())), len(d))

def scatter_fig():
    fig, axes = plt.subplots(2, 2, figsize=(13.5, 13))
    for ax, (lvl, v) in zip(axes.ravel(), [('surf', 'T'), ('surf', 'S'), ('bot', 'T'), ('bot', 'S')]):
        oc, mc = f'obs_{lvl}{v}', f'model_{lvl}{v}'
        sub = df[[oc, mc, 'region', 'lon']].dropna()
        for rg in REGIONS:
            s = sub[sub.region == rg]
            if len(s):
                ax.scatter(s[oc], s[mc], c=s['lon'], cmap=CMAP, norm=norm, marker=MARKERS[rg],
                           s=34, edgecolors='k', linewidths=0.25, alpha=0.9)
        bias, rmse, n = _stats(sub[oc].values, sub[mc].values)
        if n:
            lo = min(sub[oc].min(), sub[mc].min()); hi = max(sub[oc].max(), sub[mc].max())
            pad = (hi - lo) * 0.05 or 0.5
            ax.plot([lo - pad, hi + pad], [lo - pad, hi + pad], 'k-', lw=1)
            ax.set_xlim(lo - pad, hi + pad); ax.set_ylim(lo - pad, hi + pad)
        ax.set_aspect('equal', adjustable='box')
        ax.set_xlabel(f'Observed {v} ({UNITS[v]})'); ax.set_ylabel(f'TUFLOW-FV {v} ({UNITS[v]})')
        ax.set_title(f'{LVLNAME[lvl]} {v}  (n={n}, bias={bias:+.3f}, RMSE={rmse:.3f})', fontsize=11)
        ax.grid(alpha=0.3)
    # region-marker legend (grey proxies) on the first panel
    handles = [Line2D([], [], marker=MARKERS[rg], color='0.35', ls='', markersize=8,
                      markeredgecolor='k', label=f'{rg} (n={int((df.region == rg).sum())})') for rg in REGIONS]
    axes[0, 0].legend(handles=handles, title='region (shape)', fontsize=8, title_fontsize=8, loc='upper left')
    # shared longitude colourbar
    sm = mpl.cm.ScalarMappable(norm=norm, cmap=CMAP); sm.set_array([])
    cb = fig.colorbar(sm, ax=axes.ravel().tolist(), shrink=0.6, pad=0.02, aspect=30)
    cb.set_label('Longitude (°E)  — west → east', fontsize=10)
    fig.suptitle(f'TUFLOW-FV vs observed CTD — {TAG}  (colour = longitude, shape = region)',
                 fontsize=14, fontweight='bold')
    p = os.path.join(DIR, f'scatter_validation_lon_{TAG}.png'); fig.savefig(p, dpi=150, bbox_inches='tight')
    plt.close(fig); print('wrote', p)

if __name__ == '__main__':
    print(f'lon range: {LON_MIN:.3f} .. {LON_MAX:.3f}  | regions: {REGIONS}')
    scatter_fig()
