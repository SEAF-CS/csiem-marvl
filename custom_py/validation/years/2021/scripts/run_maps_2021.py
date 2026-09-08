# Kriged field vs model sheet maps for 2021B, after the 1992 daily maps
# (years/1992/scripts/run_maps.py).  Temperature and salinity (VAR_CONFIGS).
#
# The 1992 figure krigs purpose-designed CTD surveys.  2021 has no such survey,
# so the field sheet is a COMPOSITE of whatever observed the box that window:
#
#   DWER-CSMWQ        CTD casts     -> surface = top-2m mean, bottom = bottom-2m
#                                      mean of each cast (first occupation in the
#                                      window, matching the transect figures)
#   IMOS-SOOP-PERTH   ferry intake  -> surface only; the warehouse bins the track
#                                      to 4-km cells; window-mean per cell
#   IMOS-ANMN-ADCP    NRSROT string -> window-mean of sensors <=2.5 m (surface)
#                                      and of the deepest sensors (bottom)
#   IMOS-REF-PHY      NRS visit     -> monthly SURFACE T (var00375); its Depth
#                                      column is junk (site mean depth) so z is
#                                      forced to 0; visits within REF_PAD days
#                                      of the window are accepted
#   WAMSI-WWMSP5-AWAC/-WQ moorings  -> as ANMN
#   DWER-CSMOORING-A  profilers     -> as ANMN; csv-only (never ingested to the
#                                      parquet), Depth positive-down in source
#
# GHRSST is deliberately absent: its skin/foundation SST ran visibly cooler
# than co-located SOOP intake values in the Dec-2021 trial, and its 23 pixels
# out-vote the in-situ points wherever they overlap.
#
# SALINITY (var00006): the SOOP ferry and WWMSP5 AWACs report no salinity, so
# those programs simply never appear; the composite is CSMWQ casts + the four
# mooring/profiler programs.  IMOS-REF-PHY salinity lives in var00006 itself
# (no separate surface variable like SST var00375) but its Depth column is the
# same junk (constant site depth -47 m) -> forced to surface as for T.
# Colours/levels follow the 1992 salinity maps (RdYlBu_r, 0.1-psu steps).
#
# All surface points krig together (one field), likewise bottom; each source
# keeps its own marker.  Contour levels are derived per window from the pooled
# model+field range.  Model sheets are top-2m / bottom-2m means at midday of
# the window midpoint, as in 1992.
#
# The field record is pre-reduced ONCE to (agency, site, day, 0.5 m depth bin)
# means and cached (per-variable, VAR_CONFIGS) -- the WWMSP5-WQ profilers alone are ~2e7
# rows/yr and made per-window warehouse scans the dominant cost.
#
# Usage:
#   python run_maps_2021.py [variable]        batch: Jan-Jun DWER rounds + Jul-Dec weekly
#   python run_maps_2021.py [variable] t0 t1  one window
# variable = temperature (default) | salinity
import matplotlib
matplotlib.use('Agg')

import os, sys, numpy as np, pandas as pd
from pathlib import Path
import xarray as xr
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import tfv.xarray
from scipy.interpolate import griddata

# model-version switch (MODEL_VER env; default '1.7' = published behaviour)
MODEL_NC = {
    '1.7':        Path(r'W:/WAMSI/1.7/SH-20251123-1.7.0/2021B-20260131010652/results/csiem_B010_20201101_20211231_WQ.nc'),
    '1.8.0':      Path(r'Q:/SEAF-CS/V1.8/MODEL/csiem_model_tfvaed_1.8/output_archive/1.8.0/2021B/csiem_B010_20201101_20211231_WQ.nc'),
    '1.8.0-test': Path(r'Q:/SEAF-CS/V1.8/MODEL/csiem_model_tfvaed_1.8/output_archive/_test/2021B/csiem_B010_20201101_20211231_WQ.nc'),
}[os.environ.get('MODEL_VER', '1.7')]
FIELD_SCRIPT = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/March/contour_coastal_salinity.py'
WAREHOUSE = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/parquet/variable/csiem_var{:05d}_public.parquet'
OUT_BASE = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/2021/outputs/maps')
OUT_BASE.mkdir(parents=True, exist_ok=True)

VAR_CONFIGS = {
    'temperature': dict(
        var_id=7, ref_var_id=375,   # REF-PHY surface T is a separate variable
        model_var='TEMP', units='\u00b0C', vrange=(5.0, 35.0), step=0.25,
        cmap='coolwarm', csv_var='Temperature', title='Temperature',
        cache=Path(r'S:/tmp/tA_maps/field_T_2020_2021_reduced.parquet')),
    'salinity': dict(
        var_id=6, ref_var_id=6,     # REF-PHY salinity sits in var00006 itself
        model_var='SAL', units='psu', vrange=(20.0, 40.0), step=0.1,
        cmap='RdYlBu_r', csv_var='Salinity', title='Salinity',
        cache=Path(r'S:/tmp/tA_maps/field_S_2020_2021_reduced.parquet')),
}
_argv = sys.argv[1:]
VAR_NAME = _argv.pop(0) if _argv and _argv[0] in VAR_CONFIGS else 'temperature'
CFG = VAR_CONFIGS[VAR_NAME]

CACHE_T0, CACHE_T1 = pd.Timestamp('2020-11-01'), pd.Timestamp('2022-01-01')
SURF_MAX_DEPTH = 2.0      # m; CTD "surface" = shallower than this
MOOR_SURF_DEPTH = 2.5     # m; moorings' shallowest sensors sit a little deeper
BOT_LAYER = 2.0           # m; "bottom" = within this of the cast/string max
ZBIN = 0.5                # m; cache depth-bin size
MIN_KRIG = 5              # krige_field's own minimum
REF_PAD = pd.Timedelta(days=3)

SOURCES = {                                # marker per program, black edge
    'DWER-CSMWQ':        dict(marker='o', label='DWER-CSMWQ CTD (top/bottom 2 m)'),
    'IMOS-SOOP-PERTH':   dict(marker='^', label='IMOS SOOP ferry intake (surface, 4-km bins)'),
    'IMOS-ANMN-ADCP':    dict(marker='*', label='IMOS NRS Rottnest mooring (window mean)'),
    'IMOS-REF-PHY':      dict(marker='P', label='IMOS NRS Rottnest surface visit (±3 d)'),
    'WAMSI-WWMSP5-AWAC': dict(marker='D', label='WWMSP5 AWAC mooring (window mean)'),
    'WAMSI-WWMSP5-WQ':   dict(marker='v', label='WWMSP5 WQ profiler (window mean)'),
    'DWER-CSMOORING-A':  dict(marker='s', label='DWER CS mooring profiler (window mean)'),
}
CHUNKED = {'WAMSI-WWMSP5-WQ'}

CSMOOR_DIR = Path(r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/csv/dwer/csmooring/a')
CSMOOR_A = {                                            # positions from the HEADER csvs
    '6147030': (-32.156600, 115.702729),   # North Cockburn Sound 4
    '6147031': (-32.250800, 115.728321),   # South Cockburn Sound 13
    '6147034': (-32.262402, 115.714178),   # South 2 - Cockburn Sound 11
    '6147035': (-32.200120, 115.740654),   # Desalination Plant
}

# Batch windows: Jan-Jun has field data only in the monthly DWER rounds; from
# July the SOOP ferry + CS moorings feed every week (see coverage_audit_weekly).
DWER_ROUNDS = [('2021-01-14', '2021-01-15'), ('2021-02-01', '2021-02-02'),
               ('2021-03-01', '2021-03-02'), ('2021-04-06', '2021-04-07'),
               ('2021-05-06', '2021-05-07'), ('2021-06-01', '2021-06-03')]
WEEKLY = [(f'{d:%Y-%m-%d}', f'{d + pd.Timedelta(days=6):%Y-%m-%d}')
          for d in pd.date_range('2021-07-05', '2021-12-27', freq='7D')]

# === 1992 machinery: grid, coastline, land mask, ordinary kriging ============
_src = open(FIELD_SCRIPT, encoding='utf-8').read()
_prefix = _src[:_src.index('for jday in JDAYS:')].replace("matplotlib.use('Agg')", "")
__file__ = FIELD_SCRIPT
exec(compile(_prefix, FIELD_SCRIPT, 'exec'), globals())

# Extend the domain west of the 1992 extent to take in the IMOS NRS Rottnest
# mooring (115.400 E; the B010 mesh runs to 115.33), then rebuild everything
# the prefix derived from LON_MIN: grid, coastline clip and land mask.
# krige_field resolves these as globals at call time, so rebinding works.
LON_MIN = 115.35
grid_lon = np.linspace(LON_MIN, LON_MAX, 300)
grid_lat = np.linspace(LAT_MIN, LAT_MAX, 400)
GLON, GLAT = np.meshgrid(grid_lon, grid_lat)
cos_lat = np.cos(np.radians((LAT_MIN + LAT_MAX) / 2))
coast_gdf = gpd.read_file(COAST_SHP, bbox=(LON_MIN, LAT_MIN, LON_MAX, LAT_MAX))
land_union = unary_union(coast_gdf.geometry)
land_buffered = land_union.buffer(0.003)
land_on_grid = contains(land_buffered, GLON, GLAT)
print(f'Krige machinery loaded: grid {GLON.shape}, lon {LON_MIN}-{LON_MAX}, lat {LAT_MIN}-{LAT_MAX}')


# === Field cache: (agency, site, day, zbin) means over the whole sim =========
def _clean(df):
    for c in ('Lat', 'Long', 'Depth', 'Data'):
        df[c] = pd.to_numeric(df[c], errors='coerce')
    df = df.dropna(subset=['Lat', 'Long', 'Data'])
    df = df[df.Data.between(*CFG['vrange'])
            & df.Lat.between(LAT_MIN, LAT_MAX) & df.Long.between(LON_MIN, LON_MAX)]
    df['z'] = -df.Depth.fillna(0.0)                     # positive down
    return df


def _reduce(df):
    df['day'] = df.Date.dt.floor('D')
    df['zb'] = (df.z / ZBIN).round() * ZBIN
    return (df.groupby(['Agency', 'Site_Description', 'day', 'zb'])
              .agg(Data=('Data', 'mean'), Lat=('Lat', 'median'), Long=('Long', 'median'))
              .reset_index())


def build_field_cache():
    import pyarrow.dataset as pds, pyarrow.compute as pc, pyarrow as pa
    print(f'Building reduced {VAR_NAME} field cache (one-off)...')
    d = pds.dataset(WAREHOUSE.format(CFG['var_id']), format='parquet')
    cols = ['Date', 'Depth', 'Data', 'Agency', 'Site_Description', 'Lat', 'Long']
    parts = []

    light = [a for a in SOURCES if a not in CHUNKED
             and a not in ('DWER-CSMOORING-A', 'IMOS-REF-PHY')]
    flt = ((pc.field('Date') >= CACHE_T0) & (pc.field('Date') < CACHE_T1)
           & pc.is_in(pc.field('Agency'), pa.array(light)))
    parts.append(_reduce(_clean(d.to_table(columns=cols, filter=flt).to_pandas())))
    print(f'  light agencies: {len(parts[-1])} reduced rows')

    for ag in CHUNKED:
        months = pd.date_range(CACHE_T0, CACHE_T1, freq='MS')
        for m0, m1 in zip(months[:-1], months[1:]):
            flt = ((pc.field('Date') >= m0) & (pc.field('Date') < m1)
                   & (pc.field('Agency') == ag))
            df = _clean(d.to_table(columns=cols, filter=flt).to_pandas())
            if len(df):
                parts.append(_reduce(df))
        print(f'  {ag}: chunked over {len(months) - 1} months')

    dref = pds.dataset(WAREHOUSE.format(CFG['ref_var_id']), format='parquet')
    ref = dref.to_table(columns=cols,
                        filter=((pc.field('Date') >= CACHE_T0) & (pc.field('Date') < CACHE_T1)
                                & (pc.field('Agency') == 'IMOS-REF-PHY'))).to_pandas()
    ref['Depth'] = 0.0                                  # source Depth is junk; surface
    parts.append(_reduce(_clean(ref)))
    print(f'  IMOS-REF-PHY: {len(parts[-1])} visit rows')

    for site, (lat, lon) in CSMOOR_A.items():
        p = CSMOOR_DIR / f'dwermooring{site}_{CFG["csv_var"]}_DATA.csv'
        if not p.exists():
            continue
        m = pd.read_csv(p, low_memory=False)
        # Salinity csvs mix ISO and DD/MM/YYYY date strings (6147031/34); parse
        # each format explicitly -- a naive to_datetime would swap day/month.
        raw = m.Date.astype(str)
        dt = pd.to_datetime(raw, format='%Y-%m-%d %H:%M:%S', errors='coerce')
        m['Date'] = dt.fillna(pd.to_datetime(raw, format='%d/%m/%Y %H:%M:%S', errors='coerce'))
        m = m[(m.Date >= CACHE_T0) & (m.Date < CACHE_T1)]
        m['Depth'] = -pd.to_numeric(m.Depth, errors='coerce')   # positive-down source
        m['Agency'] = 'DWER-CSMOORING-A'
        m['Site_Description'] = site
        m['Lat'], m['Long'] = lat, lon
        m = _clean(m)
        if len(m):
            parts.append(_reduce(m))
    print('  DWER-CSMOORING-A: 4 profilers from csv')

    out = pd.concat(parts, ignore_index=True)
    CFG['cache'].parent.mkdir(parents=True, exist_ok=True)
    out.to_parquet(CFG['cache'], index=False)
    print(f'  cached {len(out)} rows -> {CFG["cache"]}')
    return out


FIELD = pd.read_parquet(CFG['cache']) if CFG['cache'].exists() else build_field_cache()
print(f'Field cache ({VAR_NAME}): {len(FIELD)} rows, {FIELD.Agency.nunique()} programs, '
      f'{FIELD.day.min():%Y-%m-%d} -> {FIELD.day.max():%Y-%m-%d}')


def field_sb_composite(t0, t1):
    """{key: (lat, lon, val, agency)} for surface and bottom in [t0, t1]."""
    w = FIELD[(FIELD.day >= t0) & (FIELD.day <= t1)]
    ref = FIELD[(FIELD.Agency == 'IMOS-REF-PHY')
                & (FIELD.day >= t0 - REF_PAD) & (FIELD.day <= t1 + REF_PAD)]
    w = pd.concat([w[w.Agency != 'IMOS-REF-PHY'], ref])
    surf, bot = {}, {}
    for (ag, site), g in w.groupby(['Agency', 'Site_Description']):
        key = f'{ag}:{site}'
        lat, lon = g.Lat.median(), g.Long.median()
        if ag == 'DWER-CSMWQ':                          # casts: first day only
            g = g[g.day == g.day.min()]
            top = g[g.zb <= SURF_MAX_DEPTH]
            if len(top):
                surf[key] = (lat, lon, float(top.Data.mean()), ag)
            zmax = g.zb.max()
            if zmax > SURF_MAX_DEPTH + 1.0:             # don't call a puddle's bed "bottom"
                bcut = g[g.zb >= zmax - BOT_LAYER]
                bot[key] = (lat, lon, float(bcut.Data.mean()), ag)
        elif ag in ('IMOS-SOOP-PERTH', 'IMOS-REF-PHY'):  # surface programs
            surf[key] = (lat, lon, float(g.Data.mean()), ag)
        else:                                           # moorings: window mean
            top = g[g.zb <= MOOR_SURF_DEPTH]
            if len(top):
                surf[key] = (lat, lon, float(top.Data.mean()), ag)
            zmax = g.zb.max()
            if zmax > MOOR_SURF_DEPTH + 1.0:
                bcut = g[g.zb >= zmax - BOT_LAYER]
                bot[key] = (lat, lon, float(bcut.Data.mean()), ag)
    return surf, bot


# === Model sheet =============================================================
ds = xr.open_dataset(MODEL_NC)
fv = ds.tfv
times_model = pd.to_datetime(ds['Time'].values)
cellx, celly = ds['cell_X'].values, ds['cell_Y'].values
print(f'Model {times_model.min()} -> {times_model.max()}  ({len(cellx)} cells)')


def model_sheet(when, where):
    datum, limits = (('depth', (0, 2)) if where == 'surface' else ('height', (0, 2)))
    tt = times_model[int(np.argmin(np.abs(times_model - when)))]
    s = fv.get_sheet([CFG['model_var']], time=tt, datum=datum, limits=limits, agg='mean')
    vals = np.asarray(s[CFG['model_var']]).ravel().astype('float64')
    ok = np.isfinite(vals)
    z = griddata((cellx[ok], celly[ok]), vals[ok], (GLON, GLAT), method='linear')
    zm = np.ma.array(z, mask=~np.isfinite(z))
    zm[land_on_grid] = np.ma.masked
    return zm, tt, (cellx[ok], celly[ok], vals[ok])


def levels_from(*fields, step=CFG['step']):
    pool = np.concatenate([f.compressed() if np.ma.isMA(f)
                           else np.asarray(f, float)[np.isfinite(np.asarray(f, float))].ravel()
                           for f in fields if f is not None and np.size(f)])
    lo, hi = np.nanpercentile(pool, [1, 99])
    lo, hi = np.floor(lo/step)*step, np.ceil(hi/step)*step
    if hi - lo < 4*step:
        hi = lo + 4*step
    return np.arange(lo, hi + step/2, step)


# === Figure ==================================================================
def draw_panel(ax, z, levels, markers=None, desc=None, title=None):
    ax.set_facecolor('white')          # no-data = white, not colormap-mid grey
    cf = None
    if z is not None:
        cf = ax.contourf(GLON, GLAT, z, levels=levels, cmap=CFG['cmap'], alpha=0.9, extend='both')
        cl = ax.contour(GLON, GLAT, z, levels=levels, colors='black', linewidths=0.4, alpha=0.5)
        ax.clabel(cl, inline=True, fontsize=7, fmt='%.1f')
    for geom in coast_gdf.geometry:
        polys = [geom] if geom.geom_type == 'Polygon' else (list(geom.geoms) if geom.geom_type == 'MultiPolygon' else [])
        for poly in polys:
            xs, ys = poly.exterior.xy
            ax.fill(xs, ys, facecolor='#c4a882', edgecolor='#7a5c3a', linewidth=0.5, zorder=8)
    if markers:
        for (lat, lon, val, ag) in markers.values():
            ax.scatter(lon, lat, c=[val], cmap=CFG['cmap'], s=30, zorder=10,
                       marker=SOURCES[ag]['marker'], vmin=levels[0], vmax=levels[-1],
                       edgecolors='black', linewidths=0.5)
    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX)
    ax.set_aspect(1 / np.cos(np.radians((LAT_MIN + LAT_MAX) / 2)))
    ax.grid(True, alpha=0.3); ax.tick_params(labelsize=9)
    if title: ax.set_title(title, fontsize=11)
    if desc:
        ax.text(0.03, 0.03, desc, transform=ax.transAxes, fontsize=10, fontweight='bold',
                va='bottom', bbox=dict(boxstyle='round,pad=0.35', facecolor='white',
                                       alpha=0.85, edgecolor='gray'))
    return cf


def make_map(t0, t1):
    t0, t1 = pd.Timestamp(t0), pd.Timestamp(t1)
    tag = f'{t0:%Y%m%d}_{t1:%Y%m%d}'
    surf, bot = field_sb_composite(t0, t1)
    if len(surf) + len(bot) < MIN_KRIG:
        print(f'  {tag}: {len(surf)} surf / {len(bot)} bot obs -- skipping')
        return None

    mid = (t0 + (t1 - t0) / 2).floor('D') + pd.Timedelta(hours=12)   # midday, mid-window
    zms, tt_s, msurf_xyv = model_sheet(mid, 'surface')
    zmb, _tt_b, _mb = model_sheet(mid, 'bottom')

    fs = krige_field(surf, 'Surface', None, True) if len(surf) >= MIN_KRIG else None
    fb = krige_field(bot, 'Bottom', None, True) if len(bot) >= MIN_KRIG else None
    zfs = fs[0] if fs is not None else None
    zfb = fb[0] if fb is not None else None

    levels = levels_from(zms, zmb, np.array([v[2] for v in surf.values()]),
                         np.array([v[2] for v in bot.values()]))

    # paired surface bias at the obs points (model sheet minus obs)
    if surf:
        mx, my, mv = msurf_xyv
        bias = np.nanmean([griddata((mx, my), mv, (v[1], v[0]), method='linear') - v[2]
                           for v in surf.values()])
        btxt = f'surface bias (model \u2212 obs) {bias:+.2f} {CFG["units"]}'
    else:
        btxt = 'no surface obs'

    fig, axes = plt.subplots(2, 2, figsize=(12.5, 16), sharex=True, sharey=True)
    cf = draw_panel(axes[0, 0], zms, levels, desc='MODEL\nSurface (top 2m)', title='Surface')
    draw_panel(axes[0, 1], zmb, levels, desc='MODEL\nBottom (bot 2m)', title='Bottom')
    draw_panel(axes[1, 0], zfs, levels, markers=surf, desc='FIELD (kriged composite)\nSurface')
    draw_panel(axes[1, 1], zfb, levels, markers=bot, desc='FIELD (kriged composite)\nBottom')
    for ax in (axes[0, 1], axes[1, 1]): ax.tick_params(axis='y', labelleft=False)
    for ax in (axes[0, 0], axes[0, 1]): ax.tick_params(axis='x', labelbottom=False)

    ags = sorted({v[3] for v in {**surf, **bot}.values()})
    handles = [mlines.Line2D([], [], marker=SOURCES[a]['marker'], color='w', markerfacecolor='0.7',
                             markeredgecolor='black', ms=8, label=SOURCES[a]['label']) for a in ags]
    fig.legend(handles=handles, loc='lower center', ncol=2, fontsize=8.5, framealpha=0.9,
               bbox_to_anchor=(0.5, 0.005))

    fig.suptitle(f'{CFG["title"]} sheet maps 2021B \u2014 {t0:%d %b} \u2013 {t1:%d %b %Y}   |   '
                 f'{len(surf)} surface / {len(bot)} bottom obs   |   '
                 f'model {pd.Timestamp(tt_s):%d-%b %H:%M}   |   {btxt}',
                 fontsize=12, fontweight='bold', y=0.99)
    plt.subplots_adjust(left=0.06, right=0.88, bottom=0.06, top=0.95, wspace=0.06, hspace=0.06)
    if cf is not None:
        cax = fig.add_axes([0.90, 0.30, 0.015, 0.40])
        fig.colorbar(cf, cax=cax).set_label(f'{CFG["title"]} ({CFG["units"]})', fontsize=11)

    out_dir = OUT_BASE / f'daily_{VAR_NAME}'; out_dir.mkdir(exist_ok=True)
    fn = out_dir / f'map_{VAR_NAME}_2021_{tag}.png'
    fig.savefig(fn, dpi=200, bbox_inches='tight'); plt.close(fig)
    print(f'  {tag}: {len(surf)} surf / {len(bot)} bot  '
          f'{btxt.replace(chr(0x2212), "-").replace(chr(0xb0), "deg")}  -> {fn.name}')
    return fn


if __name__ == '__main__':
    if len(_argv) >= 2:
        windows = [(_argv[0], _argv[1])]
    else:
        windows = DWER_ROUNDS + WEEKLY
    print(f'{VAR_NAME}: {len(windows)} window(s)')
    for t0, t1 in windows:
        make_map(t0, t1)
    print('Done.')
