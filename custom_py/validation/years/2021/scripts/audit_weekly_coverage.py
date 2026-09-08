# Weekly data-coverage audit for the 2021B sheet-map windows (Nov 2020 - Dec
# 2021).  For each calendar week (Mon-Sun) and each observation program, count
# the SURFACE and BOTTOM points the kriged composite would receive under the
# run_maps_2021.py extraction rules, so "good windows" can be picked before any
# expensive figure is made.  Writes a CSV + a two-panel heatmap and prints the
# top weeks.
import matplotlib
matplotlib.use('Agg')

import numpy as np, pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
import pyarrow.dataset as pds, pyarrow.compute as pc, pyarrow as pa

WAREHOUSE = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/parquet/variable/csiem_var{:05d}_public.parquet'
OUT_DIR = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/2021/outputs/maps')
OUT_DIR.mkdir(parents=True, exist_ok=True)

T0, T1 = pd.Timestamp('2020-11-01'), pd.Timestamp('2022-01-01')
LON_MIN, LON_MAX = 115.35, 115.776
LAT_MIN, LAT_MAX = -32.525, -31.87
TEMP_RANGE = (5.0, 35.0)
SURF_MAX = {'DWER-CSMWQ': 2.0}          # default 2.5 for moorings
BOT_MIN_Z = 3.5                          # a "bottom" needs the site deeper than this

AGENCIES = ['DWER-CSMWQ', 'IMOS-SOOP-PERTH', 'IMOS-ANMN-ADCP',
            'WAMSI-WWMSP5-AWAC', 'WAMSI-WWMSP5-WQ', 'DWER-CSMOORING-A']
CHUNKED = {'WAMSI-WWMSP5-WQ'}            # ~10^7 rows/yr; reduce month by month

# DWER CS profiling moorings: csv-only, not in the parquet (see run_maps_2021.py)
CSMOOR_DIR = Path(r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/csv/dwer/csmooring/a')
CSMOOR_A = {
    '6147030': (-32.156600, 115.702729), '6147031': (-32.250800, 115.728321),
    '6147034': (-32.262402, 115.714178), '6147035': (-32.200120, 115.740654),
}


def week_of(days):
    d = pd.DatetimeIndex(days)
    return d - pd.to_timedelta(d.weekday, unit='D')


def reduce_chunk(df):
    """(agency, site, day) -> min z, max z, per-site position."""
    df['day'] = df.Date.dt.floor('D')
    return (df.groupby(['Agency', 'Site_Description', 'day'])
              .agg(zmin=('z', 'min'), zmax=('z', 'max'),
                   lat=('Lat', 'median'), lon=('Long', 'median')).reset_index())


def load_reduced():
    d = pds.dataset(WAREHOUSE.format(7), format='parquet')
    cols = ['Date', 'Depth', 'Data', 'Agency', 'Site_Description', 'Lat', 'Long']
    parts = []

    def pull(flt):
        df = d.to_table(columns=cols, filter=flt).to_pandas()
        for c in ('Lat', 'Long', 'Depth', 'Data'):
            df[c] = pd.to_numeric(df[c], errors='coerce')
        df = df.dropna(subset=['Lat', 'Long', 'Data'])
        df = df[df.Data.between(*TEMP_RANGE)
                & df.Lat.between(LAT_MIN, LAT_MAX) & df.Long.between(LON_MIN, LON_MAX)]
        df['z'] = -df.Depth.fillna(0.0)
        return reduce_chunk(df) if len(df) else None

    light = [a for a in AGENCIES if a not in CHUNKED and a != 'DWER-CSMOORING-A']
    flt = ((pc.field('Date') >= T0) & (pc.field('Date') < T1)
           & pc.is_in(pc.field('Agency'), pa.array(light)))
    r = pull(flt)
    if r is not None:
        parts.append(r)
    print(f'  light agencies: {len(parts[-1]) if parts else 0} site-days')

    for ag in CHUNKED:
        months = pd.date_range(T0, T1, freq='MS')
        for m0, m1 in zip(months[:-1], months[1:]):
            flt = ((pc.field('Date') >= m0) & (pc.field('Date') < m1)
                   & (pc.field('Agency') == ag))
            r = pull(flt)
            if r is not None:
                parts.append(r)
        print(f'  {ag}: chunked over {len(months)-1} months')

    # NRS surface-visit record (var00375); Depth column is junk -> surface
    d375 = pds.dataset(WAREHOUSE.format(375), format='parquet')
    ref = d375.to_table(columns=cols,
                        filter=((pc.field('Date') >= T0) & (pc.field('Date') < T1)
                                & (pc.field('Agency') == 'IMOS-REF-PHY'))).to_pandas()
    for c in ('Lat', 'Long', 'Data'):
        ref[c] = pd.to_numeric(ref[c], errors='coerce')
    ref = ref.dropna(subset=['Data'])
    ref['z'] = 0.0
    parts.append(reduce_chunk(ref))
    print(f'  IMOS-REF-PHY: {len(parts[-1])} visit-days')

    for site, (lat, lon) in CSMOOR_A.items():
        p = CSMOOR_DIR / f'dwermooring{site}_Temperature_DATA.csv'
        m = pd.read_csv(p, parse_dates=['Date'], low_memory=False)
        m = m[(m.Date >= T0) & (m.Date < T1)]
        m['Data'] = pd.to_numeric(m.Data, errors='coerce')
        m['z'] = pd.to_numeric(m.Depth, errors='coerce')        # already positive-down
        m = m.dropna(subset=['Data', 'z'])
        m = m[m.Data.between(*TEMP_RANGE)]
        m['Agency'] = 'DWER-CSMOORING-A'
        m['Site_Description'] = site
        m['Lat'], m['Long'] = lat, lon
        if len(m):
            parts.append(reduce_chunk(m))
    print('  DWER-CSMOORING-A: 4 profilers from csv')

    return pd.concat(parts, ignore_index=True)


print('Reducing warehouse to site-days...')
sd = load_reduced()
sd['week'] = week_of(sd.day)
print(f'{len(sd)} site-days, {sd.week.nunique()} weeks')

# a site-day contributes a surface point if it has a shallow-enough reading,
# and a bottom point if its cast/string reaches deep enough
sd['surf'] = sd.apply(lambda r: r.zmin <= SURF_MAX.get(r.Agency, 2.5), axis=1)
sd.loc[sd.Agency.isin(['IMOS-SOOP-PERTH', 'IMOS-REF-PHY']), 'surf'] = True
sd['bot'] = (sd.zmax >= BOT_MIN_Z) & ~sd.Agency.isin(['IMOS-SOOP-PERTH', 'IMOS-REF-PHY'])

# weekly tallies: distinct sites (not site-days), the same de-duplication the
# composite applies within a window
surf = (sd[sd.surf].groupby(['week', 'Agency']).Site_Description.nunique()
        .unstack(fill_value=0).reindex(columns=AGENCIES + ['IMOS-REF-PHY'], fill_value=0))
bot = (sd[sd.bot].groupby(['week', 'Agency']).Site_Description.nunique()
       .unstack(fill_value=0).reindex(columns=AGENCIES + ['IMOS-REF-PHY'], fill_value=0))
weeks = pd.date_range(week_of([T0])[0], week_of([T1 - pd.Timedelta(days=1)])[0], freq='7D')
surf = surf.reindex(weeks, fill_value=0)
bot = bot.reindex(weeks, fill_value=0)
surf['TOTAL'] = surf.sum(axis=1)
bot['TOTAL'] = bot.sum(axis=1)

audit = pd.concat({'surface': surf, 'bottom': bot}, axis=1)
audit.to_csv(OUT_DIR / 'coverage_audit_weekly.csv')

rank = (surf.TOTAL + bot.TOTAL).sort_values(ascending=False)
print('\nTop 12 weeks (surface+bottom points, distinct sources):')
for wk in rank.head(12).index:
    src = [a for a in AGENCIES + ['IMOS-REF-PHY'] if surf.loc[wk, a] + bot.loc[wk, a] > 0]
    print(f'  wk {wk:%Y-%m-%d}: surf {surf.loc[wk, "TOTAL"]:3d}  bot {bot.loc[wk, "TOTAL"]:3d}  '
          f'({len(src)} sources: {", ".join(s.replace("WAMSI-WWMSP5", "WW5").replace("IMOS-", "") for s in src)})')

# === Heatmap: weeks x sources, counts annotated =============================
SHORT = {'DWER-CSMWQ': 'DWER CTD', 'IMOS-SOOP-PERTH': 'SOOP ferry',
         'IMOS-ANMN-ADCP': 'NRS mooring', 'WAMSI-WWMSP5-AWAC': 'WW5 AWAC',
         'WAMSI-WWMSP5-WQ': 'WW5 WQ prof', 'DWER-CSMOORING-A': 'DWER CS moor',
         'IMOS-REF-PHY': 'NRS visit', 'TOTAL': 'TOTAL'}
fig, axes = plt.subplots(2, 1, figsize=(22, 7.5), sharex=True)
for ax, (name, m) in zip(axes, [('SURFACE', surf), ('BOTTOM', bot)]):
    rows = [c for c in m.columns if c != 'TOTAL'] + ['TOTAL']
    mat = m[rows].T.values.astype(float)
    disp = np.log1p(mat)                                # counts span 0..40; log for shade
    im = ax.imshow(disp, aspect='auto', cmap='Blues', vmin=0, vmax=np.log1p(45))
    ax.set_yticks(range(len(rows)), [SHORT[r] for r in rows], fontsize=9)
    ax.axhline(len(rows) - 1.5, color='white', lw=2)
    for i in range(len(rows)):
        for j in range(mat.shape[1]):
            v = int(mat[i, j])
            if v:
                ax.text(j, i, v, ha='center', va='center', fontsize=6.5,
                        color='white' if disp[i, j] > 0.6 * np.log1p(45) else '#1a3a5c')
    ax.set_ylabel(name, fontsize=11, fontweight='bold')
    ax.tick_params(length=0)
    ax.grid(False)
xt = range(0, len(weeks), 2)
axes[1].set_xticks(list(xt), [f'{weeks[i]:%d %b %y}' for i in xt], rotation=90, fontsize=7.5)
axes[1].set_xlabel('week beginning (Mon)', fontsize=10)
fig.suptitle('2021B sheet-map coverage audit \u2014 observation points per week by program '
             '(distinct sites meeting the surface / bottom extraction rules)',
             fontsize=13, fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.96])
fn = OUT_DIR / 'coverage_audit_weekly.png'
fig.savefig(fn, dpi=150, bbox_inches='tight')
print(f'\nSaved: {fn}\n       {OUT_DIR / "coverage_audit_weekly.csv"}')
