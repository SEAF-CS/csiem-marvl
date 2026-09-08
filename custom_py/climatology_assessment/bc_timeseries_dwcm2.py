"""bc_timeseries figure for Jul-1993 -> Jun-1994 with the DWCM2 DEEP-SHELF MOORING
temperature overlaid (UWA mooring, 31°45'50"S 115°15'12"E, 106 m water, 45 km
offshore; 4 meter levels = 19/44/71/96 m below surface; 12 Oct 93 - 13 Jan 94;
records temperature only — current meters carry no conductivity sensor, so the
salinity panels carry a note instead).

Base: subregion NW obs/model dots (most 1993-94 casts) + the global OBC arcs
(N-coastal, S-coastal, ocean) from ocean_assessment_bc_timeseries.py, whose
module prefix is exec'd to reuse the ROMS/HYCOM polygon sampling verbatim.

Mooring data: smcws_data/1993/currents_data/DWCM2/dwcm2_{10,35,62,87}.dos
(analysed in smcws_data/1994/Velocity/ — see VELOCITY_1994.md). Records are
strictly sequential 5-min; the time axis is synthesised from the first record
(verified against the parsed last-record date) to sidestep the space-padded
ambiguous date tokens.

Output: bc_timeseries_NW_dwcm2_9394.png
"""
import os, re
import numpy as np
import pandas as pd

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment'
BTS = os.path.join(DIR, 'ocean_assessment_bc_timeseries.py')
DWCM2_DIR = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1993/currents_data/DWCM2'

# ---- reuse the sampling machinery + sampled arcs from the timeseries script ----
src = open(BTS, encoding='utf-8').read()
prefix = src[:src.index('def fig_sub(')]
G = {'__file__': BTS, '__name__': 'bts_prefix'}
exec(compile(prefix, BTS, 'exec'), G)
df, GROUPS, GSTYLE, HY, ROMS_C = G['df'], G['GROUPS'], G['GSTYLE'], G['HY'], G['ROMS_C']
roms_tiled_full, DATES_FULL, KEYS = G['roms_tiled'], G['DATES'], G['KEYS']
MODEL_TS, _gapped, YEARC = G['MODEL_TS'], G['_gapped'], G['YEARC']
plt, mdates = G['plt'], G['mdates']

T0, T1 = pd.Timestamp('1993-07-01'), pd.Timestamp('1994-07-01')
DATES = pd.date_range(T0, T1, freq='D')
ddoy = DATES.dayofyear.values
def roms_tiled(g, key):
    return np.interp(ddoy, G['ROMS_t'][g], ROMS_C[g][key], period=365)

# ---------------------------------------------------------------- DWCM2 mooring
REC_RE = re.compile(r'^\s*(\d{1,4}):\s*(\d{1,2})\s+(\d[\d ]{3,5})\s+'
                    r'(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+'
                    r'(?:-?[\d.]+\s+){0,2}(-?[\d.]+)\s*$')

def read_dwcm2(path):
    """Return (times, temp). 5-min sequential records; axis synthesised from rec 0."""
    temps, first_dt = [], None
    for line in open(path, errors='replace'):
        m = REC_RE.match(line)
        if not m:
            continue
        if first_dt is None:
            hhmm = int(m.group(1)); dstr = m.group(3).replace(' ', '')
            dd, mo, yy = int(dstr[:-4]), int(dstr[-4:-2]), int(dstr[-2:])
            first_dt = pd.Timestamp(1900 + yy, mo, dd, hhmm // 100, hhmm % 100)
        temps.append(float(m.group(8)))
    t = first_dt + pd.to_timedelta(np.arange(len(temps)) * 5, unit='m')
    return t, np.array(temps)

LEVELS = [  # (file, m ASB, m below surface in 106 m water)
    ('dwcm2_87.dos', 87, 19), ('dwcm2_62.dos', 62, 44),
    ('dwcm2_35.dos', 35, 71), ('dwcm2_10.dos', 10, 96)]
MOOR = {}
for fn, asb, below in LEVELS:
    t, T = read_dwcm2(os.path.join(DWCM2_DIR, fn))
    ok = (T > 5) & (T < 30)
    s = pd.Series(T[ok], index=t[ok]).resample('6h').mean()
    MOOR[below] = s
    print(f'{fn}: {ok.sum()} recs, {t[0]:%d %b %y} - {t[-1]:%d %b %y}, '
          f'T {np.nanmin(s.values):.1f}-{np.nanmax(s.values):.1f}')

MCOLORS = {19: '#d95f02', 44: '#e7a13d', 71: '#7570b3', 96: '#1b3f8b'}

# ---------------------------------------------------------------- figure
SR = 'NW'
dd = df[(df.subregion == SR) & (df.dt >= T0) & (df.dt <= T1)]
fig, axes = plt.subplots(2, 2, figsize=(17, 9), sharex=True)
for ax, (key, lab) in zip(axes.ravel(), KEYS):
    for g in GROUPS:
        st = GSTYLE[g]
        ax.plot(DATES, roms_tiled(g, key), '-', color=st['roms'], lw=1.7,
                label=f"ROMS clim {st['lab']}", zorder=3)
        hts, hd = HY[g]
        inr = (hts >= T0) & (hts <= T1)
        if inr.any():
            ax.plot(hts[inr], hd[key][inr], '--', color=st['hy'], lw=1.3,
                    label=f"HYCOM {st['lab']}", zorder=2)
    if MODEL_TS is not None:
        lev = 'surf' if key.startswith('surf') else 'bot'
        var = 'TEMP' if key.endswith('T') else 'SAL'
        mt = MODEL_TS[(MODEL_TS.subregion == SR) & (MODEL_TS.level == lev)]
        mt = mt[(mt['date'] >= T0) & (mt['date'] <= T1)]
        if len(mt):
            gx, gy = _gapped(mt['date'].values, mt[var].values)
            ax.plot(gx, gy, '-', color='black', lw=1.0, alpha=0.85,
                    label='TUFLOW-FV (rep cell)', zorder=4)
    for yr in sorted(dd.year.unique()):
        dy = dd[dd.year == yr]
        ax.scatter(dy.dt, dy[f'obs_{key}'], s=30, c=YEARC.get(yr, 'k'),
                   edgecolors='k', lw=.3, label=f'obs {yr}', zorder=5)
    # ---- DWCM2 overlay ----
    if key.endswith('T'):
        levels = [19] if key == 'surfT' else [44, 71, 96]
        for below in levels:
            s = MOOR[below]
            ax.plot(s.index, s.values, '-', color=MCOLORS[below], lw=1.1,
                    alpha=0.9, zorder=6, label=f'DWCM2 mooring @{below} m depth')
    else:
        ax.text(0.985, 0.04, 'DWCM2 mooring records temperature only (no salinity)',
                transform=ax.transAxes, ha='right', va='bottom', fontsize=8,
                color='#666666', fontstyle='italic')
    ax.set_ylabel(lab); ax.grid(alpha=.3); ax.set_xlim(T0, T1)
    ax.xaxis.set_major_locator(mdates.MonthLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%b\n%Y'))
axes[0, 0].legend(fontsize=6.5, ncol=2, loc='best')
axes[1, 0].legend(fontsize=6.5, ncol=2, loc='best')
fig.suptitle(f'BC time-series Jul 1993 – Jun 1994 (subregion {SR}, n={len(dd)} casts) '
             f'+ DWCM2 deep-shelf mooring T (106 m water, 45 km offshore)',
             fontsize=12, fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.96])
p = os.path.join(DIR, 'bc_timeseries_NW_dwcm2_9394.png')
fig.savefig(p, dpi=140); plt.close(fig)
print('wrote', p)
