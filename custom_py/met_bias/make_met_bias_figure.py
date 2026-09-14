"""Figure for the met-forcing bias analysis: monthly 2 m air-T bias of each
met product vs BOM obs (Garden Island + Rottnest mean), with the model
water-T bias (TransectA windows) on the same degC axis — showing the 2021
water warm offset as a lagged integral of WRF's Apr-Aug warm air bias.

Rows: air temperature (degC) with water-bias diamonds; wind speed (m/s).
Cols: 2013 (BARRA-SUB forcing) vs 2021 (WRF forcing); BARRA-C2 counterfactual
shown for both. Reads met_bias_summary.csv + the TransectA run logs.
"""
import re
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

HERE = Path(__file__).parent
LOGS = Path(r'S:/tmp/csiem_18_rollout/testlogs')
TA_LOG = {2013: 'REAL_transectA_2013.log', 2021: 'REAL_transectA_2021.log'}
STATIONS = ['GARDEN ISLAND HSF', 'ROTTNEST ISLAND']   # Sound-relevant pair
MONTHS = np.arange(1, 13)
MCOLS = [f'm{m:02d}' for m in MONTHS]

C_FORCING = '#2a78d6'   # blue: the product actually forcing the run
C_C2 = '#eb6834'        # orange: BARRA-C2 counterfactual
INK = '#0b0b0b'

df = pd.read_csv(HERE / 'met_bias_summary.csv')

def monthly(year, product_contains, var):
    s = df[(df.year == year) & df['product'].str.contains(product_contains) &
           (df['var'] == var) & df.station.isin(STATIONS)]
    return s[MCOLS].mean(axis=0).values, s[MCOLS].std(axis=0).values

def water_bias(year):
    pts = []
    for l in open(LOGS / TA_LOG[year], encoding='utf-8', errors='replace'):
        m = re.match(r'\s+(\d{4})(\d{2})\d{2}_\d{8}: \d+ casts  bias T ([+-][\d.]+)', l)
        if m:
            pts.append((int(m.group(2)), float(m.group(3))))
    return pts

fig, axes = plt.subplots(2, 2, figsize=(12.5, 7.5), sharex=True)
FORCING = {2013: 'BARRA-SUB', 2021: 'WRF'}
for col, year in enumerate([2013, 2021]):
    # ---- air temperature ----
    ax = axes[0, col]
    for tag, c in [('(forcing)', C_FORCING), ('BARRA-C2', C_C2)]:
        mu, sd = monthly(year, re.escape(tag), 'airT')
        lbl = f'{FORCING[year]} (forcing)' if tag == '(forcing)' else 'BARRA-C2 (counterfactual)'
        ax.fill_between(MONTHS, mu - sd, mu + sd, color=c, alpha=0.10, lw=0)
        ax.plot(MONTHS, mu, '-', color=c, lw=2, marker='o', ms=4, label=lbl)
    wb = water_bias(year)
    if wb:
        ax.plot([m for m, _ in wb], [b for _, b in wb], 'D', color=INK, ms=6,
                mfc='none', mew=1.6, label='model water-T bias (TransectA)')
    ax.axhline(0, color='#c3c2b7', lw=1)
    ax.set_title(f'{year} — forcing: {FORCING[year]}', fontsize=11, fontweight='bold')
    ax.set_ylabel('air-T bias vs BOM obs (°C)' if col == 0 else '')
    ax.set_ylim(-2.6, 2.0)
    ax.grid(alpha=0.25)
    if col == 0:
        ax.legend(fontsize=8, loc='lower center', framealpha=0.9)
    # ---- wind ----
    ax = axes[1, col]
    for tag, c in [('(forcing)', C_FORCING), ('BARRA-C2', C_C2)]:
        mu, sd = monthly(year, re.escape(tag), 'wind')
        ax.fill_between(MONTHS, mu - sd, mu + sd, color=c, alpha=0.10, lw=0)
        ax.plot(MONTHS, mu, '-', color=c, lw=2, marker='o', ms=4)
    ax.axhline(0, color='#c3c2b7', lw=1)
    ax.set_ylabel('wind-speed bias (m/s)' if col == 0 else '')
    ax.set_xlabel('month')
    ax.set_xticks(MONTHS)
    ax.set_ylim(-1.6, 1.6)
    ax.grid(alpha=0.25)

fig.suptitle('Met forcing bias vs BOM stations (Garden Island + Rottnest mean, band = station spread)\n'
             'Diamonds: whole-domain water-T bias from TransectA — the 2021 spring water warm offset '
             'follows WRF\'s Apr–Aug air-T surplus', fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.92])
out = HERE / 'met_bias_vs_water_bias.png'
fig.savefig(out, dpi=150)
print('wrote', out)
