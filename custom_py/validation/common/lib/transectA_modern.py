# Modern-era analogue of years/1992/scripts/run_transectA.py, shared by the
# 2021B / 2022B / 2023B hindcasts.  Pick the simulation with the TRANSECT_SIM
# environment variable (the years/<year>/scripts wrappers set it); the geometry,
# station set and bathymetry are identical across all three so the sections can
# be read side by side.
#
# The 1992 figure is built from a purpose-designed transect survey: ~15 stations
# occupied along a single line within a few hours.  Nothing like that exists for
# 2022.  What does exist is routine monitoring -- DWER Cockburn Sound MWQ and
# WAMSI WWMSP3 CTD -- which samples a scatter of fixed sites over a two-to-seven
# day round, most of them some distance off the Transect A line.  Three
# concessions are therefore made, and each is stated on the figure so the reader
# can discount accordingly:
#
#   1. Off-line casts.  Each cast is dropped onto the Transect A spine at its own
#      latitude (the spine is latitude-monotone) and plotted at the chainage of
#      that foot point.  This keeps the x-axis identical to the 1992 figure -- an
#      on-line station reproduces its 1992 chainage exactly -- without smearing
#      the cross-shore offset into the along-transect axis, which a plain
#      haversine-from-CS55 would do.  Stations are hand-picked (TRANSECT_SITES);
#      each carries its residual offset in the station label so the reader can
#      weigh it.
#   2. Non-synoptic survey.  A window of several days is treated as one section.
#      The model is sampled at each cast's OWN time (nearest model hour) and OWN
#      position, so the pairing is honest even though the composite section is not
#      a snapshot.  The window span is printed in the title.
#   3. Contour levels.  1992 levels (S 35.5-37.0) do not fit 2022 (S ~34.5-36).
#      Levels are derived per window from the pooled model+field range and shared
#      between the two rows so the panels remain directly comparable.
#
# The curated 2022 station set continues south past CS145 through Shoalwater Bay
# into Warnbro Sound, so the spine and the bathymetry are rebuilt here rather
# than inherited: the 5 m EIA DEM used for 1992 stops at Point Peron (its tiles
# end at 32.29 S) and has no data over Warnbro.  Bathymetry is therefore taken
# from the model's own bed elevation (cell_Zb), which spans the whole line and
# matches the DEM to a median 0.06 m (sd 1.07 m) where the two overlap.  The
# cross-section builder is inherited verbatim from the 1992 machinery so the two
# figures are constructed identically.
import matplotlib
matplotlib.use('Agg')

import os, sys, numpy as np, pandas as pd
from pathlib import Path
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
import tfv.xarray

# ---- model-version switch (MODEL_VER env; default '1.7' keeps the published
# ---- 1.7 behaviour byte-identical). '1.8.0' reads the finished run outputs
# ---- directly from the 1.8 model tree (no results snapshot).
MODEL_VER = os.environ.get('MODEL_VER', '1.7')
RUNS_BY_VER = {
    '1.7':        r'W:/WAMSI/1.7/SH-20251123-1.7.0',
    '1.8.0':      r'Q:/SEAF-CS/V1.8/MODEL/csiem_model_tfvaed_1.8/output_archive/1.8.0',
    '1.8.0-test': r'Q:/SEAF-CS/V1.8/MODEL/csiem_model_tfvaed_1.8/output_archive/_test',  # mid-run NC copies; plumbing tests only
}
if MODEL_VER not in RUNS_BY_VER:
    raise SystemExit(f'MODEL_VER={MODEL_VER!r} not one of {sorted(RUNS_BY_VER)}')
RUNS = RUNS_BY_VER[MODEL_VER]
VALIDATION = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation')

# The hindcasts.  Each spins up from the preceding November, so the window
# search is restricted to the part of the record that sim owns -- 2023B alone
# reaches into 2024, and that is where the last three WWMSP3 rounds sit.
#
# The "A" years run on the coarser A002 mesh (11,694 cells vs B010's 30,206;
# 2015A is 4-hourly, not hourly, and its hydro lives in the _WQ_WQ.nc).  Their
# field record is also thinner: no WWMSP3 (it starts 2022), and DWER-CSMWQ was
# then a surface+bottom bottle program, not CTD casts -- two points per
# profile, so the field panels are a linear top-to-bottom blend.  minpts is
# the minimum depth bins a cast needs to be used (the modern default of 5
# rejects junk casts; the bottle years must accept 2).
SIMS = {
    '2013A': dict(year=2013, nc='2013A-20251123024141/results/csiem_A002_20121101_20131231_WQ.nc',
                  t0='2013-01-01', t1='2013-12-31', minpts=2),
    '2015A': dict(year=2015, nc='2015A-20251124125228/results/csiem_A002_20141101_20151231_WQ_WQ.nc',
                  t0='2015-01-01', t1='2015-12-31', minpts=2),
    '2020A': dict(year=2020, nc='2020A-20251124134430/results/csiem_A002_20191101_20201231_WQ.nc',
                  t0='2020-01-01', t1='2020-12-31', minpts=2),
    '2021B': dict(year=2021, nc='2021B-20260131010652/results/csiem_B010_20201101_20211231_WQ.nc',
                  t0='2021-01-01', t1='2021-12-31'),
    '2022B': dict(year=2022, nc='2022B-20260131015416/results/csiem_B010_20211101_20221231_WQ.nc',
                  t0='2022-01-01', t1='2022-12-31'),
    '2023B': dict(year=2023, nc='2023B-20251124150126/results/csiem_B010_20221101_20240401_WQ.nc',
                  t0='2023-01-01', t1='2024-04-01'),
}
if MODEL_VER.startswith('1.8.0'):
    # 1.8 reference runs live directly under output_archive/1.8.0/<sim>/.
    # NB 2013 is B010 under 1.8 (the A002 2013A is a 1.7-only sim).
    SIMS = {
        '2013B': dict(year=2013, nc='2013B/csiem_B010_20121101_20131231_WQ.nc',
                      t0='2013-01-01', t1='2013-12-31', minpts=2),
        '2015B': dict(year=2015, nc='2015B/csiem_B010_20141101_20151231_WQ.nc',
                      t0='2015-01-01', t1='2015-12-31', minpts=2),
        '2021B': dict(year=2021, nc='2021B/csiem_B010_20201101_20211231_WQ.nc',
                      t0='2021-01-01', t1='2021-12-31'),
        '2022B': dict(year=2022, nc='2022B/csiem_B010_20211101_20221231_WQ.nc',
                      t0='2022-01-01', t1='2022-12-31'),
        '2023B': dict(year=2023, nc='2023B/csiem_B010_20221101_20240401_WQ.nc',
                      t0='2023-01-01', t1='2024-03-31'),
        '2020B': dict(year=2020, nc='2020B/csiem_B010_20191101_20201231_WQ.nc',
                      t0='2020-01-01', t1='2020-12-31'),
    }
SIM = os.environ.get('TRANSECT_SIM', '2022B')
if SIM not in SIMS:
    raise SystemExit(f'TRANSECT_SIM={SIM!r} not one of {sorted(SIMS)}')
CFG = SIMS[SIM]
YEAR = CFG['year']

MODEL_NC   = Path(RUNS) / CFG['nc']
PLOT_TRANSECTS_1992 = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1992/TransectA/plot_transects.py'
WAREHOUSE  = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/parquet/variable/csiem_var{:05d}_public.parquet'
# One cache spanning all the sims.  Station positions -- and therefore the
# spine and every chainage -- are pinned to the 2020-11 -> 2024-04 pooled
# record (POS_T0/POS_T1, the original three-year cache window), NOT the whole
# cache: extending the pool to 2013 would nudge the medians and silently shift
# the x-axis of the already-published 2021-2023 figures.
FIELD_CACHE = Path(r'S:/tmp/tA/cs_2013_2024_ST.parquet')
CACHE_T0, CACHE_T1 = '2012-11-01', '2024-04-02'
POS_T0, POS_T1 = '2020-11-01', '2024-04-02'
OUT_PNG_DIR = VALIDATION / f'years/{YEAR}/outputs/transectA'
OUT_PNG_DIR.mkdir(parents=True, exist_ok=True)
print(f'=== Transect A {SIM} ({CFG["t0"]} -> {CFG["t1"]}) ===')

VAR_IDS = {6: 'SAL', 7: 'TEMP'}
# discrete-cast CTD programs only.  Excluded: NASA-GHRSST (satellite SST),
# WAMSI-WWMSP5-AWAC/-WQ (moorings and profiling moorings, not casts),
# IMOS-SOOP-PERTH (ship track), DWER-SWANEST (Swan estuary, off-domain), and
# MOI-NEMO-* / WAMSI-WWMSP5-WA-ROMS which are MODEL products, not observations.
CTD_AGENCIES = ['DWER-CSMWQ', 'WAMSI-WWMSP3-CTD']

MIN_STATIONS = 4      # below this a window is not worth contouring
DEPTH_BIN = 0.25      # m; cast bin size before interpolation
LABEL_SEP_KM = 1.4    # km; minimum along-axis gap between station labels

# Station labels are coloured by monitoring program; same colours as the
# map_panels figures (transectA_modern_maps.py AGENCY_STYLE).
AGENCY_COLOR = {'DWER-CSMWQ': '#b2182b', 'WAMSI-WWMSP3-CTD': '#2166ac'}

# Curated station set, north to south.  Chosen by eye off map_panels_2022.png
# rather than by an offset threshold: a few well-placed sites are worth keeping
# despite a 3-4 km offset (MR, 6147031) where they are the only coverage of a
# chainage band, and a few near-line sites are dropped as duplicates of a
# neighbour.  The last three continue the line south of CS145 into Warnbro Sound.
TRANSECT_SITES = [
    'MR', 'OA4', 'OA2S', 'OA1-DEP', '6142971', '6147030', '6142974', 'LP',
    '6142976', 'SF11', '6142983', '6147031', 'SC', 'SC2', '6142985', '6142986',
]
# Spine anchors that are 2022 sites rather than 1992 stations.  North of OA2S
# the line is bent away from the 1992 heading (which ran on to Y27, well west of
# anything sampled in 2022) and runs through OA4 on its way to MR, so the
# northern leg bends smoothly OA2S -> OA4 -> MR; south of CS145 it is continued
# into Warnbro Sound.
SPINE_NORTH = ['MR', 'OA4', 'OA2S']
SPINE_SOUTH = ['SC2', '6142985', '6142986']
# ... and in the middle the line runs straight from CS55 to a turn point out
# toward 6142976 -- AIM_FRAC of the way from CS105 -- then back west to 6142983.
# CS105 is only the geometric anchor that fixes where the turn sits; it is no
# longer a node, so the run from CS55 is a single straight leg (CS85/CS88/CS105
# are bypassed, as are CS155/CS135 on the way back).  This puts the eastern
# Cockburn Sound sites much closer to the line than the 1992 route did.
AIM_FROM, AIM_TOWARD, AIM_FRAC, AIM_TO = 'CS105', '6142976', 0.60, '6142983'

# Sites projected onto the nearest point of the spine rather than due east/west
# at their own latitude.  6147031 sits in the crook of the CS105 bend, where a
# latitude foot runs the full width of the bulge; the nearest-point tie runs NW
# and is a truer measure of how far off the line it is.
PERP_SITES = {'6147031'}

# Sites dropped straight down their own meridian to the first spine crossing to
# the south.  SF11 sits just inside the top of the return leg, so an east-west
# foot ties it sideways along the line; due south is the short way onto it.
MERID_SITES = {'SF11'}

# Survey windows.  DWER-CSMWQ splits its 21 sites over two consecutive days and
# WWMSP3 splits its 18 over two days a few days apart, so every window spans
# several days by necessity.  Rounds are found by clustering the sampling days:
# a gap of more than MERGE_GAP_DAYS starts a new round.  Six days is the value
# that keeps 2022's 23-29 Sep and 12-18 Oct rounds whole while holding 9-10 Nov
# apart from 24-25 Nov.
MERGE_GAP_DAYS = 6
SEASON = {1: 'summer', 2: 'late summer', 3: 'late summer', 4: 'autumn',
          5: 'autumn', 6: 'early winter', 7: 'winter', 8: 'winter',
          9: 'early spring', 10: 'spring', 11: 'late spring', 12: 'early summer'}

# 2022 was published from a hand-picked eight-window subset (one per season,
# to fit a 2x4 map).  Kept so those figures stay reproducible; delete the entry
# to give 2022 the same full-coverage treatment as the other two years.
WINDOW_OVERRIDES = {
    '2022B': [
        ('2022-01-04', '2022-01-05', 'summer'),
        ('2022-03-07', '2022-03-08', 'late summer'),
        ('2022-05-02', '2022-05-04', 'autumn'),
        ('2022-08-22', '2022-08-23', 'winter'),
        ('2022-09-23', '2022-09-29', 'early spring'),
        ('2022-10-12', '2022-10-18', 'spring'),
        ('2022-11-09', '2022-11-10', 'late spring'),
        ('2022-12-14', '2022-12-22', 'early summer'),
    ],
}


def survey_windows(field, t0, t1):
    """Cluster the sampling days in [t0, t1] into survey rounds."""
    days = np.sort(field.day[(field.day >= pd.Timestamp(t0))
                             & (field.day <= pd.Timestamp(t1))].unique())
    if not len(days):
        return []
    days = pd.to_datetime(days)
    out, start, prev = [], days[0], days[0]
    for d in days[1:]:
        if (d - prev).days > MERGE_GAP_DAYS:
            out.append((start, prev)); start = d
        prev = d
    out.append((start, prev))
    return [(f'{a:%Y-%m-%d}', f'{b:%Y-%m-%d}', SEASON[a.month]) for a, b in out]


def eos80_potential_density(S, T):
    T2, T3, T4, T5 = T*T, T*T*T, T*T*T*T, T*T*T*T*T
    Ssq = np.sqrt(np.clip(S, 0, None)); S1p5 = S*Ssq; S2 = S*S
    a = [999.842594, 6.793952e-2, -9.095290e-3, 1.001685e-4, -1.120083e-6, 6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b = [8.24493e-1, -4.0899e-3, 7.6438e-5, -8.2467e-7, 5.3875e-9]
    c = [-5.72466e-3, 1.0227e-4, -1.6546e-6]; d0 = 4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2


# === Reuse the canonical 1992 field machinery (geometry + bathymetry) ========
_src = open(PLOT_TRANSECTS_1992, encoding='utf-8').read()
_prefix = _src[:_src.index('for panel_idx, jday in enumerate(JDAYS):')].replace("matplotlib.use('Agg')", "")
__file__ = PLOT_TRANSECTS_1992
exec(compile(_prefix, PLOT_TRANSECTS_1992, 'exec'), globals())
print(f'Field machinery loaded: {len(COORDS)} coords, {len(ref_stns)} union stations; '
      f'chainage {XLIM_NORTH} to {XLIM_SOUTH} km')

# === Field casts ============================================================
def load_field_cache():
    """CTD casts in the Cockburn Sound box over the whole 2021B-2023B period,
    cached locally -- the warehouse files are ~2 GB each and sit on a network
    drive."""
    if FIELD_CACHE.exists():
        return pd.read_parquet(FIELD_CACHE)
    import pyarrow.dataset as pds, pyarrow.compute as pc, pyarrow as pa
    FIELD_CACHE.parent.mkdir(parents=True, exist_ok=True)
    frames = []
    for vid, vname in VAR_IDS.items():
        d = pds.dataset(WAREHOUSE.format(vid), format='parquet')
        flt = ((pc.field('Date') >= pd.Timestamp(CACHE_T0)) &
               (pc.field('Date') < pd.Timestamp(CACHE_T1)) &
               pc.is_in(pc.field('Agency'), pa.array(CTD_AGENCIES)))
        df = d.to_table(columns=['Date', 'Depth', 'Data', 'QC', 'Lat', 'Long',
                                 'Agency', 'Site_Description'], filter=flt).to_pandas()
        for c in ('Lat', 'Long'):
            df[c] = pd.to_numeric(df[c], errors='coerce')
        df['val'] = pd.to_numeric(df['Data'], errors='coerce')
        df = df.dropna(subset=['Lat', 'Long', 'val']).drop(columns=['Data'])
        df['var'] = vname
        frames.append(df)
        print(f'  cached {len(df)} {vname} rows')
    out = pd.concat(frames, ignore_index=True)
    out.to_parquet(FIELD_CACHE, index=False)
    return out


FIELD_ALL = load_field_cache()
FIELD_ALL = FIELD_ALL[FIELD_ALL.Agency.isin(CTD_AGENCIES)].copy()
FIELD_ALL['day'] = FIELD_ALL.Date.dt.floor('D')
# Station positions come from the POOLED modern record (POS_T0..POS_T1), not
# this sim's slice: WWMSP3 did not start until 2022, so a 2021-only median
# would leave the spine anchors (MR, OA2S, SC2) undefined.  Every year --
# including the 2013-2020 bottle years, whose DWER site codes are the same
# stations -- therefore gets exactly the same spine and the same chainages.
SITE_POS = (FIELD_ALL[FIELD_ALL.Site_Description.isin(TRANSECT_SITES)
                      & (FIELD_ALL.day >= pd.Timestamp(POS_T0))
                      & (FIELD_ALL.day <= pd.Timestamp(POS_T1))]
            .groupby('Site_Description')[['Lat', 'Long']].median())
_absent = [s for s in TRANSECT_SITES if s not in SITE_POS.index]
if _absent:
    raise SystemExit(f'TRANSECT_SITES not present in the warehouse: {_absent}')

FIELD = FIELD_ALL[(FIELD_ALL.day >= pd.Timestamp(CFG['t0']))
                  & (FIELD_ALL.day <= pd.Timestamp(CFG['t1']))].copy()
print(f'Field: {len(FIELD)} rows, {FIELD.Site_Description.nunique()} sites, '
      f'{FIELD.day.nunique()} sampling days; {len(TRANSECT_SITES)} transect stations')
WINDOWS = WINDOW_OVERRIDES.get(SIM) or survey_windows(FIELD, CFG['t0'], CFG['t1'])
print(f'{len(WINDOWS)} survey rounds'
      + (' (curated override)' if SIM in WINDOW_OVERRIDES else ''))


# === Transect A spine: chainage / offset for an arbitrary lon-lat ============
R_EARTH = 6371.0
# 1992 stations retained.  Y27/OA33/OA30 are dropped (the bent northern leg
# replaces them) and so are CS155/CS135 (the eastward bulge bypasses them).
SPINE_1992 = ['OA80', 'CS20A', 'CS20', 'CS45', 'CS55']
_site_ll = lambda s: (float(SITE_POS.loc[s, 'Lat']), float(SITE_POS.loc[s, 'Long']))
_a, _b = COORDS[AIM_FROM], _site_ll(AIM_TOWARD)
_bend = (_a[0] + AIM_FRAC*(_b[0]-_a[0]), _a[1] + AIM_FRAC*(_b[1]-_a[1]))
_nodes = ([_site_ll(s) for s in SPINE_NORTH] + [COORDS[s] for s in SPINE_1992]
          + [_bend, _site_ll(AIM_TO), COORDS['CS145']]
          + [_site_ll(s) for s in SPINE_SOUTH])
_la = [n[0] for n in _nodes]
_lo = [n[1] for n in _nodes]
_o = np.argsort(_la)
_SLAT, _SLON = np.asarray(_la)[_o], np.asarray(_lo)[_o]
CS55_LAT, CS55_LON = COORDS['CS55']
CS145_LAT = COORDS['CS145'][0]
OA2S_LAT = float(SITE_POS.loc['OA2S', 'Lat'])


def _hav(lat1, lon1, lat2, lon2):
    p1, p2 = np.radians(lat1), np.radians(lat2)
    a = (np.sin((p2-p1)/2)**2
         + np.cos(p1)*np.cos(p2)*np.sin(np.radians(lon2-lon1)/2)**2)
    return 2*R_EARTH*np.arcsin(np.sqrt(a))


# Arc length along the spine, measured northward (_SLAT is ascending = N-ward).
_SEG = _hav(_SLAT[:-1], _SLON[:-1], _SLAT[1:], _SLON[1:])
_ARC = np.concatenate([[0.0], np.cumsum(_SEG)])


def _arc_at(lat):
    return np.interp(lat, _SLAT, _ARC)


def _straight_ch(lat):
    return float(_hav(CS55_LAT, CS55_LON, lat, float(np.interp(lat, _SLAT, _SLON))))


CS145_CH = _straight_ch(CS145_LAT)
OA2S_CH = -_straight_ch(OA2S_LAT)


def _lat_foot(lat):
    """(chainage_km, foot_lon) of the spine point at this latitude.

    Chainage is the 1992 chainage_km (great-circle from CS55, negative north),
    exact for on-line stations between OA2S and CS145.  Beyond the two end bends
    -- north of OA2S, where the line turns toward MR, and south of CS145, where
    it turns around Point Peron into Warnbro Sound -- chainage continues by arc
    length along the spine, since a straight distance from CS55 would cut the
    corner and under-measure it.
    """
    flon = float(np.interp(lat, _SLAT, _SLON))
    if lat > OA2S_LAT:
        ch = OA2S_CH - (_arc_at(lat) - _arc_at(OA2S_LAT))
    elif lat >= CS145_LAT:
        ch = _hav(CS55_LAT, CS55_LON, lat, flon)
        ch = -ch if lat > CS55_LAT else ch
    else:
        ch = CS145_CH + (_arc_at(CS145_LAT) - _arc_at(lat))
    return float(ch), flon


# densely walked spine; reused for nearest-point projection and for bathymetry
_DL = np.linspace(_SLAT[0], _SLAT[-1], 4000)
_DLON = np.interp(_DL, _SLAT, _SLON)
_DC = np.array([_lat_foot(la)[0] for la in _DL])


def chainage_offset(lat, lon, perp=False, merid=False):
    """(chainage_km, offset_km, foot_lon, foot_lat) of a cast on the spine.

    The foot is due east/west at the cast's own latitude; with perp=True it is
    the nearest point on the spine instead (see PERP_SITES), and with merid=True
    it is the first spine crossing of the cast's own meridian to the SOUTH (see
    MERID_SITES).  The eastward bulge means a meridian can cut the spine several
    times, so take the closest southern crossing, and fall back to the latitude
    foot if there is none.
    """
    if perp:
        d = _hav(lat, lon, _DL, _DLON)
        i = int(np.argmin(d))
        return float(_DC[i]), float(d[i]), float(_DLON[i]), float(_DL[i])
    if merid:
        cross = np.where(np.diff(np.sign(_DLON - lon)) != 0)[0]
        south = [i for i in cross if _DL[i] < lat]
        if south:
            i = max(south, key=lambda j: _DL[j])   # closest, i.e. least far south
            return float(_DC[i]), float(_hav(lat, lon, _DL[i], lon)), float(lon), float(_DL[i])
    ch, flon = _lat_foot(lat)
    return ch, float(_hav(lat, lon, lat, flon)), flon, float(lat)


def on_spine(lat):
    return _SLAT[0] - 1e-9 <= lat <= _SLAT[-1] + 1e-9


SITE_GEOM = {s: chainage_offset(SITE_POS.loc[s, 'Lat'], SITE_POS.loc[s, 'Long'],
                                perp=s in PERP_SITES, merid=s in MERID_SITES)
             for s in TRANSECT_SITES}
print('  chainage {:+.1f} to {:+.1f} km; offsets {:.1f}-{:.1f} km'.format(
    min(v[0] for v in SITE_GEOM.values()), max(v[0] for v in SITE_GEOM.values()),
    min(v[1] for v in SITE_GEOM.values()), max(v[1] for v in SITE_GEOM.values())))


# === Model ==================================================================
# (density derived per-profile from S,T -- never build a full-field RHOW: on this
#  hourly NC that is a multi-GiB alloc -> OOM)
ds = xr.open_dataset(MODEL_NC)
fv = ds.tfv
times_model = pd.to_datetime(ds['Time'].values)
print(f'Model {times_model.min()} -> {times_model.max()}  ({len(times_model)} steps, '
      f'{ds.sizes.get("NumCells2D", "?")} cells)')


# === Bathymetry and grid along the 2022 spine ===============================
# Overrides the inherited 1992 DEM section (see header): model bed elevation,
# nearest cell centre to the spine, which covers Warnbro Sound where the DEM
# does not.
from scipy.spatial import cKDTree
from scipy.ndimage import uniform_filter1d

_cx = np.asarray(ds['cell_X'].values); _cy = np.asarray(ds['cell_Y'].values)
_czb = np.asarray(ds['cell_Zb'].values)
_tree = cKDTree(np.c_[_cx, _cy])

_site_ch = np.array([v[0] for v in SITE_GEOM.values()])
XLIM_NORTH = float(max(np.floor(_site_ch.min() - 1.5), _DC.min()))
XLIM_SOUTH = float(min(np.ceil(_site_ch.max() + 1.5), _DC.max()))

_oc = np.argsort(_DC)                       # lat as a function of chainage
bathy_n = 800
bathy_chain = np.linspace(XLIM_NORTH, XLIM_SOUTH, bathy_n)
bathy_lats = np.interp(bathy_chain, _DC[_oc], _DL[_oc])
bathy_lons = np.interp(bathy_lats, _SLAT, _SLON)
# Median over a ~600 m swath rather than the single nearest cell: the mesh is
# unstructured and cell-to-cell steps (dredged channels, bank edges) otherwise
# put spikes in the bed that fragment the contour field.
_ball = _tree.query_ball_point(np.c_[bathy_lons, bathy_lats], 0.006)
_dist, _idx = _tree.query(np.c_[bathy_lons, bathy_lats])
bathy_depths = np.array([np.median(-_czb[p]) if p else np.nan for p in _ball])
bathy_depths = np.where(np.isnan(bathy_depths) & (_dist < 0.01), -_czb[_idx], bathy_depths)
bathy_plot = uniform_filter1d(np.nan_to_num(bathy_depths, nan=0.0), size=15)
bathy_plot = np.where(np.isnan(bathy_depths), np.nan, bathy_plot)
bathy_depths = bathy_plot                     # mask and drawn bed stay identical
depth_max_plot = float(np.ceil(np.nanmax(bathy_plot)))
print(f'  bathymetry (model bed): {np.nanmin(bathy_plot):.1f} to '
      f'{np.nanmax(bathy_plot):.1f} m over {XLIM_NORTH:+.1f} to {XLIM_SOUTH:+.1f} km')

GRID_NX, GRID_NY = 700, 260
grid_x = np.linspace(XLIM_NORTH, XLIM_SOUTH, GRID_NX)
grid_y = np.linspace(0, depth_max_plot + BATHY_BUFFER, GRID_NY)
grid_X, grid_Y = np.meshgrid(grid_x, grid_y)


# === Cross-section builder keyed on explicit x (mirrors build_cross_section) =
def build_cross_section_x(profiles, var_key):
    """As build_cross_section, but each profile carries its own 'x' (chainage)
    instead of being looked up by 1992 station name."""
    keys = sorted(profiles.keys(), key=lambda k: profiles[k]['x'])
    stn_x = [profiles[k]['x'] for k in keys]
    all_x = [stn_x[0] - GHOST_KM] + stn_x + [stn_x[-1] + GHOST_KM]
    all_k = [keys[0]] + keys + [keys[-1]]

    n_cols = len(all_x)
    stn_cols = np.zeros((len(grid_y), n_cols))
    for ci, (sx, k) in enumerate(zip(all_x, all_k)):
        dep, val = profiles[k]['depth'], profiles[k][var_key]
        order = np.argsort(dep); dep_s, val_s = dep[order], val[order]
        local_bathy = np.interp(sx, bathy_chain, bathy_depths)
        max_d = dep_s[-1]
        target = max(local_bathy, max_d) + BATHY_BUFFER
        if target > max_d + 0.2:
            bottom_val = np.median(val_s[dep_s > max_d - 0.5])
            extra_d = np.linspace(max_d + 0.1, target, 10)
            dep_s = np.concatenate([dep_s, extra_d])
            val_s = np.concatenate([val_s, np.full(10, bottom_val)])
        stn_cols[:, ci] = np.interp(grid_y, dep_s, val_s, left=val_s[0], right=val_s[-1])

    ax_arr = np.array(all_x)
    grid_val = np.zeros((len(grid_y), len(grid_x)))
    for j, gx in enumerate(grid_x):
        idx = np.searchsorted(ax_arr, gx)
        if idx == 0:
            grid_val[:, j] = stn_cols[:, 0]
        elif idx >= n_cols:
            grid_val[:, j] = stn_cols[:, -1]
        else:
            frac = (gx - ax_arr[idx-1]) / (ax_arr[idx] - ax_arr[idx-1])
            grid_val[:, j] = stn_cols[:, idx-1]*(1-frac) + stn_cols[:, idx]*frac

    bottom_on_grid = np.interp(grid_x, bathy_chain, bathy_depths)
    for j in range(len(grid_x)):
        if np.isnan(bottom_on_grid[j]):
            grid_val[:, j] = np.nan
        else:
            grid_val[grid_Y[:, j] > bottom_on_grid[j], j] = np.nan
    for j, gx in enumerate(grid_x):
        if gx < all_x[0] or gx > all_x[-1]:
            grid_val[:, j] = np.nan
    return grid_val


def field_profiles_for_window(t0, t1):
    """One binned S/T/sigma-t profile per TRANSECT_SITES station occupied in
    [t0, t1].  Where a site is occupied more than once in the window the first
    occupation is used."""
    w = FIELD[(FIELD.Date >= t0) & (FIELD.Date < t1 + pd.Timedelta(days=1))
              & FIELD.Site_Description.isin(TRANSECT_SITES)]
    profs, times = {}, []
    for site, g in w.groupby('Site_Description'):
        lat, lon = g.Lat.median(), g.Long.median()
        ch, off = SITE_GEOM[site][:2]            # fixed geometry, not per-window
        g = g[g.day == g.day.min()]                       # first occupation only
        piv = (g.assign(d=(-g.Depth / DEPTH_BIN).round() * DEPTH_BIN)
                 .pivot_table(index='d', columns='var', values='val', aggfunc='mean')
                 .sort_index())
        if 'SAL' not in piv or 'TEMP' not in piv:
            continue
        piv = piv.dropna()
        piv = piv[piv.index > 0.1]
        if len(piv) < CFG.get('minpts', 5):
            continue
        dep = piv.index.values.astype(float)
        sal = piv['SAL'].values.astype(float); tem = piv['TEMP'].values.astype(float)
        profs[site] = {'x': ch, 'offset': off, 'lat': lat, 'lon': lon,
                       'agency': g.Agency.iloc[0],
                       'time': g.Date.median(), 'depth': dep, 'salinity': sal,
                       'temperature': tem,
                       'density': eos80_potential_density(sal, tem) - 1000.0}
        times.append(g.Date.median())
    return profs, times


def model_profiles_for(field_profs):
    """Sample the model at each cast's own position and nearest model hour."""
    out = {}
    for site, fp in field_profs.items():
        tt = times_model[int(np.argmin(np.abs(times_model - pd.Timestamp(fp['time']))))]
        try:
            p = fv.get_profile((fp['lon'], fp['lat']), variables=['SAL', 'TEMP'], time=tt)
            pt = p.sel(Time=tt, method='nearest') if 'Time' in p.dims else p
            dep = -np.asarray(pt['Z']).ravel()
            sal = np.asarray(pt['SAL']).ravel(); tem = np.asarray(pt['TEMP']).ravel()
            den = eos80_potential_density(sal, tem) - 1000.0
            ok = (np.isfinite(dep) & np.isfinite(sal) & np.isfinite(tem)
                  & np.isfinite(den) & (dep > 0.1))
            if ok.sum() < 3:
                continue
            o = np.argsort(dep[ok])
            out[site] = {'x': fp['x'], 'offset': fp['offset'], 'time': tt,
                         'agency': fp['agency'],
                         'depth': dep[ok][o], 'salinity': sal[ok][o],
                         'temperature': tem[ok][o], 'density': den[ok][o]}
        except Exception as e:
            print(f'    model sample failed at {site}: {e}')
    return out


# === Contour levels, derived per window from the pooled model+field range ====
LEVEL_STEP = {'temperature': 0.2, 'salinity': 0.1, 'density': 0.05}
CMAPS = {'temperature': plt.cm.coolwarm, 'salinity': plt.cm.RdYlBu_r,
         'density': plt.cm.viridis}
LABELS = {'temperature': 'Temperature (\u00b0C)', 'salinity': 'Salinity (psu)',
          'density': r'Density ($\sigma_t$, kg m$^{-3}$)'}


def short_name(site):
    """DWER site codes are 7-digit; the leading digits are common to the set."""
    return site[-4:] if site.isdigit() and len(site) > 4 else site


def paired_bias(model_profs, field_profs):
    """Model - field, over the depths each cast pair has in common."""
    out = {}
    for vk in ('temperature', 'salinity', 'density'):
        d = []
        for s in model_profs:
            if s not in field_profs:
                continue
            f, m = field_profs[s], model_profs[s]
            zmax = min(f['depth'].max(), m['depth'].max())
            z = np.arange(0.5, zmax, 0.5)
            if len(z) < 3:
                continue
            d.append(np.interp(z, m['depth'], m[vk]) - np.interp(z, f['depth'], f[vk]))
        out[vk] = float(np.mean(np.concatenate(d))) if d else np.nan
    return out


def levels_for(vk, *profsets):
    vals = np.concatenate([p[vk] for ps in profsets for p in ps.values()])
    lo, hi = np.nanpercentile(vals, [1, 99])
    st = LEVEL_STEP[vk]
    lo, hi = np.floor(lo/st)*st, np.ceil(hi/st)*st
    if hi - lo < 4*st:
        hi = lo + 4*st
    n = int(round((hi-lo)/st)) + 1
    if n > 30:                                   # keep the colour bar readable
        st *= np.ceil(n/30.0)
        lo, hi = np.floor(lo/st)*st, np.ceil(hi/st)*st
    return np.arange(lo, hi + st/2, st)


def spread_labels(x, gap, lo, hi):
    """Nudge sorted label positions apart to at least `gap`, kept inside [lo, hi].

    Forward pass opens the crowded runs, backward pass pulls the result back
    off the right edge; a couple of sweeps is enough for the clusters here.
    """
    out = np.asarray(x, float).copy()
    for _ in range(3):
        for i in range(1, len(out)):
            out[i] = max(out[i], out[i-1] + gap)
        out[-1] = min(out[-1], hi)
        for i in range(len(out) - 2, -1, -1):
            out[i] = min(out[i], out[i+1] - gap)
        out[0] = max(out[0], lo)
    return out


# === Comparison figure ======================================================
def make_compare_figure(t0, t1, label):
    t0, t1 = pd.Timestamp(t0), pd.Timestamp(t1)
    tag = f'{t0:%Y%m%d}_{t1:%Y%m%d}'
    field_profs, ftimes = field_profiles_for_window(t0, t1)
    if len(field_profs) < MIN_STATIONS:
        print(f'{tag}: {len(field_profs)} usable casts (<{MIN_STATIONS}), skipping')
        return None
    model_profs = model_profiles_for(field_profs)
    if len(model_profs) < MIN_STATIONS:
        print(f'{tag}: {len(model_profs)} model profiles, skipping')
        return None

    var_order = ['temperature', 'salinity', 'density']
    lev = {vk: levels_for(vk, model_profs, field_profs) for vk in var_order}

    fig, axes = plt.subplots(2, 3, figsize=(20, 11.5), sharex='col', sharey=True)
    for ri, (rlabel, profs) in enumerate([('MODEL', model_profs), ('FIELD', field_profs)]):
        for col, vk in enumerate(var_order):
            ax = axes[ri, col]
            cmap = CMAPS[vk]; levels = lev[vk]
            norm = BoundaryNorm(levels, ncolors=cmap.N, clip=True)
            gv = build_cross_section_x(profs, vk)
            ax.contourf(grid_X, grid_Y, gv, levels=levels, cmap=cmap, norm=norm, extend='both')
            cl = ax.contour(grid_X, grid_Y, gv, levels=levels, colors='k', linewidths=0.4)
            ax.clabel(cl, inline=True, fontsize=6, fmt='%.1f')
            ax.fill_between(bathy_chain, bathy_plot, depth_max_plot + 5, color='#8B7355', zorder=5)
            ax.plot(bathy_chain, bathy_plot, 'k-', lw=1, zorder=6)
            # sites cluster tightly once projected (four of them inside 1 km near
            # the CS105 bend); rotated labels collide in x, so push them apart
            # along the axis and tie each back to its tick with a leader
            order = sorted(profs, key=lambda s: profs[s]['x'])
            xt = np.array([profs[s]['x'] for s in order], float)
            xl = spread_labels(xt, LABEL_SEP_KM, XLIM_NORTH, XLIM_SOUTH)
            for site, x, xlab in zip(order, xt, xl):
                acol = AGENCY_COLOR.get(profs[site].get('agency'), 'k')
                ax.plot(x, 0, 'kv', ms=5, zorder=7, clip_on=False)
                if abs(xlab - x) > 0.05:
                    ax.plot([x, xlab], [-0.15, -0.85], color='0.45', lw=0.4,
                            zorder=7, clip_on=False)
                ax.text(xlab, -0.9, short_name(site),
                        ha='center', va='bottom', fontsize=8, color=acol,
                        fontweight='bold', rotation=90, zorder=7, clip_on=False)
            ax.set_xlim(XLIM_SOUTH, XLIM_NORTH); ax.set_ylim(depth_max_plot + 1, -5.5)
            ax.axvline(0, color='grey', lw=0.8, ls=':', alpha=0.6, zorder=4)
            ax.grid(True, lw=0.3, alpha=0.3)
            if col == 0:
                ax.set_ylabel(f'{rlabel}\nDepth (m)', fontsize=10, fontweight='bold')
            if ri == 1:
                ax.set_xlabel('Chainage from CS55 (km)\n\u2190 South     North \u2192', fontsize=8)

    fig.subplots_adjust(top=0.90, bottom=0.16, left=0.06, right=0.99, hspace=0.14, wspace=0.05)
    for col, vk in enumerate(var_order):
        pos = axes[1, col].get_position()
        cax = fig.add_axes([pos.x0, 0.065, pos.width, 0.015])
        sm = plt.cm.ScalarMappable(norm=BoundaryNorm(lev[vk], ncolors=CMAPS[vk].N, clip=True),
                                   cmap=CMAPS[vk])
        sm.set_array([])
        fig.colorbar(sm, cax=cax, orientation='horizontal', extend='both').set_label(LABELS[vk], fontsize=9)

    bias = paired_bias(model_profs, field_profs)
    span = f'{min(ftimes):%d %b} \u2013 {max(ftimes):%d %b %Y}' if ftimes else 'n/a'
    fig.text(0.5, 0.975,
             f'Transect A {SIM} \u2014 {label}: {span}   |   {len(field_profs)} casts   |   '
             f'paired bias (model \u2212 field)  T {bias["temperature"]:+.2f} \u00b0C   '
             f'S {bias["salinity"]:+.3f} psu   \u03c3$_t$ {bias["density"]:+.3f}',
             ha='center', va='center', fontsize=13, fontweight='bold', color='#1f4e79')
    # key for the station-label colours (one text per agency so each takes its
    # own colour), centred as a group where the old caption sat
    fig.text(0.42, 0.945, 'station labels:', ha='right', va='center',
             fontsize=10, color='#7f7f7f')
    fig.text(0.43, 0.945, 'DWER-CSMWQ', ha='left', va='center', fontsize=10,
             fontweight='bold', color=AGENCY_COLOR['DWER-CSMWQ'])
    fig.text(0.52, 0.945, 'WAMSI-WWMSP3-CTD', ha='left', va='center', fontsize=10,
             fontweight='bold', color=AGENCY_COLOR['WAMSI-WWMSP3-CTD'])

    fn = OUT_PNG_DIR / f'compare_TransectA_{YEAR}_{tag}.png'
    fig.savefig(fn, dpi=150, bbox_inches='tight'); plt.close(fig)
    print(f'  {tag}: {len(field_profs)} casts  bias T {bias["temperature"]:+.2f}  '
          f'S {bias["salinity"]:+.3f}  sig {bias["density"]:+.3f}')
    return fn


if __name__ == '__main__':
    only = sys.argv[1] if len(sys.argv) > 1 else None
    for t0, t1, label in WINDOWS:
        if only and only not in t0:
            continue
        out = make_compare_figure(t0, t1, label)
        if out:
            print(f'  saved {out.name}')
    print('Done.')
