"""1992 BASELINE vs REVISED model — obs-vs-model salt-bias comparison.
Component [1] region_validation, for year 1992.  Extraction over the overlap window
22-Feb -> 3-Apr 1992 (rev ends 3-Apr), same casts, two paired models:
  - baseline  : output_archive/1.7.0/1992_marmay/csiem_B010_19920222_19920531.nc
  - rev       : output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc
                (graded IC + salinity-corrected Peel-Harvey BC)
Writes region_validation_1992{,_rev}.csv + _revcompare.{csv,png} to this year's outputs/.
Shared extraction engine = common/lib/region_validation_core.py.
"""
import os, sys, numpy as np, pandas as pd, warnings
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, '..', '..', '..', 'common', 'lib')))   # -> validation/common/lib
import region_validation_core as core

OUT = os.path.abspath(os.path.join(HERE, '..', 'outputs'))   # validation/years/1992/outputs
os.makedirs(OUT, exist_ok=True)
WIN = ('1992-02-22', '1992-04-03')
REV_NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay_rev/csiem_B010_19920222_19920531_rev.nc'
REGIONS = ['OA', 'CS', 'N', 'NW', 'W', 'SW', 'S']

print('=== BASELINE 1992 extraction ===')
df_base = core.run(WIN)
df_base.to_csv(os.path.join(OUT, 'region_validation_1992.csv'), index=False)

print('\n=== REV 1992 extraction ===')
core.FV_RUNS[1] = ('1992-02-22', '1992-04-03', REV_NC)   # repoint the 1992 entry at the rev NC
core._FV_CACHE.clear()
df_rev = core.run(WIN)
df_rev.to_csv(os.path.join(OUT, 'region_validation_1992_rev.csv'), index=False)

# bottom QC (same as the validation plots): drop obs_botS<33 spikes for bottom stats
for d in (df_base, df_rev):
    bad = d['obs_botS'] < 33.0
    d.loc[bad, ['obs_botT', 'obs_botS']] = np.nan


def _bias(d, lvl, v, region=None):
    sub = d if region is None else d[d.region == region]
    x = (sub[f'model_{lvl}{v}'] - sub[f'obs_{lvl}{v}']).dropna()
    return (np.nan, 0) if len(x) == 0 else (float(x.mean()), len(x))


print('\n=== HEADLINE: 1992 surface salinity bias (model - obs) ===')
for tag, d in [('baseline', df_base), ('rev', df_rev)]:
    b, n = _bias(d, 'surf', 'S'); bb, nb = _bias(d, 'bot', 'S')
    print(f'  {tag:8s}  surf S bias = {b:+.3f} (n={n})   bot S bias = {bb:+.3f} (n={nb})')

present = [r for r in REGIONS if r in set(df_base.region) | set(df_rev.region)]
fig, axes = plt.subplots(2, 2, figsize=(15, 10))
UNITS = {'T': '°C', 'S': 'psu'}; recs = []
for ax, (lvl, v) in zip(axes.ravel(), [('surf', 'S'), ('bot', 'S'), ('surf', 'T'), ('bot', 'T')]):
    x = np.arange(len(present)); w = 0.38
    for k, (tag, d, col) in enumerate([('baseline', df_base, '#888888'), ('rev', df_rev, '#1f77b4')]):
        vals, ns = [], []
        for rg in present:
            bb, nn = _bias(d, lvl, v, rg); vals.append(bb); ns.append(nn)
            recs.append(dict(region=rg, level=lvl, var=v, run=tag, bias=bb, n=nn))
        ax.bar(x + (k - 0.5) * w, vals, w, color=col, label=tag)
        for xi, (val, nn) in enumerate(zip(vals, ns)):
            if np.isfinite(val):
                ax.text(x[xi] + (k - 0.5) * w, val + (0.02 if val >= 0 else -0.02), f'{val:+.2f}',
                        ha='center', va='bottom' if val >= 0 else 'top', fontsize=6)
    ax.axhline(0, color='k', lw=0.8); ax.set_xticks(x); ax.set_xticklabels(present)
    ax.set_title(f'{"Surface" if lvl=="surf" else "Bottom"} {v} bias (model − obs)', fontsize=11)
    ax.set_ylabel(UNITS[v]); ax.legend(fontsize=9); ax.grid(axis='y', alpha=0.3)
ob, nb = _bias(df_base, 'surf', 'S'); orv, nr = _bias(df_rev, 'surf', 'S')
fig.suptitle(f'1992 March — obs-vs-model salt/temp bias: BASELINE vs REVISED (graded IC + PHE SALcorr)\n'
             f'overall surface-S bias  {ob:+.3f} → {orv:+.3f} psu   (n≈{nb}; + = model too salty)',
             fontsize=13, fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.95])
p = os.path.join(OUT, 'region_validation_1992_revcompare.png')
fig.savefig(p, dpi=150); plt.close(fig)
pd.DataFrame(recs).to_csv(os.path.join(OUT, 'region_validation_1992_revcompare.csv'), index=False)
print('\nwrote', p)
