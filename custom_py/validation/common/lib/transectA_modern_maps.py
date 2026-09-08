"""Per-window CTD station maps for the 2022 Transect A comparison.

Follows the March-1992 panel map (smcws_data/1992/March/map_panels_march.py) but
adapted to the 2022 survey windows and to the tighter geographic extent that the
2022 monitoring actually covers.

The point of these panels is to let the transect figures be audited: for each
window they show which casts were occupied, where they sit relative to the
Transect A spine, and which of them are in the curated station set that builds
the section.  A grey tie line runs from each used cast to its foot point on the
spine -- that tie is exactly the projection the transect script applies, and its
length is the bracketed offset printed on the transect figure.

Bathymetry is the model's own bed (cell_Zb on the B010 mesh) rather than the 5 m
EIA DEM used for the 1992 maps: the DEM tiles stop at Point Peron (32.29 S) and
the 2022 station set continues into Warnbro Sound.  The mesh boundary doubles as
the coastline, so land is simply the un-contoured background.
"""
import matplotlib
matplotlib.use('Agg')

import os, sys, numpy as np, pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import matplotlib.tri as mtri
import netCDF4
from pyproj import Transformer

sys.stdout.reconfigure(line_buffering=True)

# ---- model-version switch (MODEL_VER env; default '1.7' = published behaviour)
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
SIMS = {
    '2013A': dict(year=2013, nc='2013A-20251123024141/results/csiem_A002_20121101_20131231_WQ.nc',
                  t0='2013-01-01', t1='2013-12-31'),
    '2015A': dict(year=2015, nc='2015A-20251124125228/results/csiem_A002_20141101_20151231_WQ_WQ.nc',
                  t0='2015-01-01', t1='2015-12-31'),
    '2020A': dict(year=2020, nc='2020A-20251124134430/results/csiem_A002_20191101_20201231_WQ.nc',
                  t0='2020-01-01', t1='2020-12-31'),
    '2021B': dict(year=2021, nc='2021B-20260131010652/results/csiem_B010_20201101_20211231_WQ.nc',
                  t0='2021-01-01', t1='2021-12-31'),
    '2022B': dict(year=2022, nc='2022B-20260131015416/results/csiem_B010_20211101_20221231_WQ.nc',
                  t0='2022-01-01', t1='2022-12-31'),
    '2023B': dict(year=2023, nc='2023B-20251124150126/results/csiem_B010_20221101_20240401_WQ.nc',
                  t0='2023-01-01', t1='2024-04-01'),
}
if MODEL_VER.startswith('1.8.0'):
    # 1.8 reference runs, read directly from the model tree (2013 is B010 in 1.8)
    SIMS = {
        '2013B': dict(year=2013, nc='2013B/csiem_B010_20121101_20131231_WQ.nc',
                      t0='2013-01-01', t1='2013-12-31'),
        '2021B': dict(year=2021, nc='2021B/csiem_B010_20201101_20211231_WQ.nc',
                      t0='2021-01-01', t1='2021-12-31'),
    }
SIM = os.environ.get('TRANSECT_SIM', '2022B')
if SIM not in SIMS:
    raise SystemExit(f'TRANSECT_SIM={SIM!r} not one of {sorted(SIMS)}')
CFG = SIMS[SIM]
YEAR = CFG['year']

MODEL_NC = str(Path(RUNS) / CFG['nc'])
MAP_DIR = (r"Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/DAdamo/"
           r"Nick D'Adamo Cockburn Sound/"
           r"Archivals of SMCWS data from old DEP CDs of the 1990s/"
           r"MARINE CD-3 from DEP-CTD data SGI IRIS Crimson/dadamo_usr2/map")
FIELD_CACHE = Path(r'S:/tmp/tA/cs_2013_2024_ST.parquet')
POS_T0, POS_T1 = '2020-11-01', '2024-04-02'   # position-pooling window (see transectA_modern.py)
OUT_DIR = VALIDATION / f'years/{YEAR}/outputs/transectA'
OUT_DIR.mkdir(parents=True, exist_ok=True)
print(f'=== Transect A maps {SIM} ({CFG["t0"]} -> {CFG["t1"]}) ===')

CTD_AGENCIES = ['DWER-CSMWQ', 'WAMSI-WWMSP3-CTD']

# Curated station set (kept in step with run_transectA_2022.py), north to south.
TRANSECT_SITES = [
    'MR', 'OA4', 'OA2S', 'OA1-DEP', '6142971', '6147030', '6142974', 'LP',
    '6142976', 'SF11', '6142983', '6147031', 'SC', 'SC2', '6142985', '6142986',
]
# Spine anchors that are 2022 sites: the northern leg is bent at OA2S and runs
# through OA4 to MR, and the southern leg is continued past CS145 into Warnbro
# Sound.
SPINE_NORTH = ['MR', 'OA4', 'OA2S']
SPINE_SOUTH = ['SC2', '6142985', '6142986']
# The middle runs straight from CS55 to a turn point out toward 6142976 --
# AIM_FRAC of the way from CS105 -- then back west to 6142983.  CS105 is only the
# anchor that fixes the turn; it is not a node, so CS85/CS88/CS105 are bypassed.
AIM_FROM, AIM_TOWARD, AIM_FRAC, AIM_TO = 'CS105', '6142976', 0.60, '6142983'
# Projected onto the nearest point of the spine rather than at their own latitude.
PERP_SITES = {'6147031'}
# Dropped south down their own meridian to the first spine crossing instead.
MERID_SITES = {'SF11'}

# Extent trimmed to where 2022 monitoring actually is (the 1992 map ran out to
# Mandurah and Rottnest; there is nothing out there in 2022), and carried south
# to take in Warnbro Sound.
LAT_MIN, LAT_MAX = -32.36, -31.98
LON_MIN, LON_MAX = 115.61, 115.81

# Survey rounds, found the same way as in transectA_modern.py -- the two must
# agree or the maps stop describing the sections.
MERGE_GAP_DAYS = 6
SEASON = {1: 'summer', 2: 'late summer', 3: 'late summer', 4: 'autumn',
          5: 'autumn', 6: 'early winter', 7: 'winter', 8: 'winter',
          9: 'early spring', 10: 'spring', 11: 'late spring', 12: 'early summer'}
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


def survey_windows(days, t0, t1):
    days = pd.DatetimeIndex(np.sort(pd.to_datetime(
        [d for d in pd.unique(days) if pd.Timestamp(t0) <= d <= pd.Timestamp(t1)])))
    if not len(days):
        return []
    out, start, prev = [], days[0], days[0]
    for d in days[1:]:
        if (d - prev).days > MERGE_GAP_DAYS:
            out.append((start, prev)); start = d
        prev = d
    out.append((start, prev))
    return [(f'{a:%Y-%m-%d}', f'{b:%Y-%m-%d}', SEASON[a.month]) for a, b in out]

AGENCY_STYLE = {
    'DWER-CSMWQ':       {'marker': 'o', 'color': '#b2182b'},
    'WAMSI-WWMSP3-CTD': {'marker': 's', 'color': '#2166ac'},
}

# === Transect A spine, from the D'Adamo .loc station files ==================
_t28350 = Transformer.from_crs('EPSG:28350', 'EPSG:4326', always_xy=True)
_t7850 = Transformer.from_crs('EPSG:4326', 'EPSG:7850', always_xy=True)
_from7850 = Transformer.from_crs('EPSG:7850', 'EPSG:4326', always_xy=True)
NAME_ALIAS = {'0A': 'OA', 'S/G': 'S_G'}


def load_loc(path):
    coords = {}
    for line in open(path):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith(';'):
            line = line[1:].strip()
        p = line.split()
        if len(p) < 3:
            continue
        try:
            e, n = float(p[1]), float(p[2])
        except ValueError:
            continue
        if n < 1_000_000:
            n += 6_000_000
        lon, lat = _t28350.transform(e, n)
        name = p[0].strip().upper().replace('/', '_')
        for pre, rep in NAME_ALIAS.items():
            if name.startswith(pre):
                name = rep + name[len(pre):]
                break
        coords.setdefault(name, (lat, lon))
    return coords


COORDS = {}
for f in ['cock.loc', 'gard.loc', 'mand.loc', 'pert.loc', 'sout.loc', 'vert.loc']:
    p = os.path.join(MAP_DIR, f)
    if os.path.exists(p):
        for k, v in load_loc(p).items():
            COORDS.setdefault(k, v)
print(f'Loaded {len(COORDS)} station coordinates')

R_EARTH = 6371.0


def _hav(lat1, lon1, lat2, lon2):
    p1, p2 = np.radians(lat1), np.radians(lat2)
    a = (np.sin((p2-p1)/2)**2
         + np.cos(p1)*np.cos(p2)*np.sin(np.radians(lon2-lon1)/2)**2)
    return 2*R_EARTH*np.arcsin(np.sqrt(a))


# === Cast inventory =========================================================
# Positions from the pooled 2021-2024 record so the spine is identical in every
# year (WWMSP3 only starts in 2022, and the spine is anchored on its sites);
# occupancy from this sim's slice only.
F_ALL = pd.read_parquet(FIELD_CACHE)
F_ALL = F_ALL[(F_ALL.Agency.isin(CTD_AGENCIES)) & (F_ALL['var'] == 'SAL')].copy()
F_ALL['day'] = F_ALL.Date.dt.floor('D')
# Positions from the pinned POS window so the spine matches transectA_modern.py
# exactly; sites only occupied in the 2013-2020 bottle years fall back to their
# whole-record median (they are not spine anchors, so nothing shifts).
_pos_pool = F_ALL[(F_ALL.day >= pd.Timestamp(POS_T0)) & (F_ALL.day <= pd.Timestamp(POS_T1))]
SITES = (_pos_pool.groupby(['Agency', 'Site_Description'])
                  .agg(lat=('Lat', 'median'), lon=('Long', 'median')).reset_index()
                  .set_index('Site_Description'))
_older = (F_ALL[~F_ALL.Site_Description.isin(SITES.index)]
          .groupby(['Agency', 'Site_Description'])
          .agg(lat=('Lat', 'median'), lon=('Long', 'median')).reset_index()
          .set_index('Site_Description'))
SITES = pd.concat([SITES, _older])
F = F_ALL[(F_ALL.day >= pd.Timestamp(CFG['t0']))
          & (F_ALL.day <= pd.Timestamp(CFG['t1']))].copy()
SITES['active'] = SITES.index.isin(F.Site_Description.unique())
WINDOWS = WINDOW_OVERRIDES.get(SIM) or survey_windows(F.day, CFG['t0'], CFG['t1'])
print(f'{len(WINDOWS)} survey rounds'
      + (' (curated override)' if SIM in WINDOW_OVERRIDES else '')
      + f'; {int(SITES.active.sum())} of {len(SITES)} sites active in {SIM}')

# === Transect A spine, continued south of CS145 through Warnbro Sound =======
# 1992 stations retained.  Y27/OA33/OA30 are replaced by the bent northern leg
# through MR; CS155/CS135 are bypassed by the eastward bulge at CS105.
SPINE_1992 = ['OA80', 'CS20A', 'CS20', 'CS45', 'CS55']
_site_ll = lambda s: (float(SITES.loc[s, 'lat']), float(SITES.loc[s, 'lon']))
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
OA2S_LAT = float(SITES.loc['OA2S', 'lat'])

_SEG = _hav(_SLAT[:-1], _SLON[:-1], _SLAT[1:], _SLON[1:])
_ARC = np.concatenate([[0.0], np.cumsum(_SEG)])         # arc length, northward


def _straight_ch(lat):
    return float(_hav(CS55_LAT, CS55_LON, lat, float(np.interp(lat, _SLAT, _SLON))))


CS145_CH = _straight_ch(CS145_LAT)
OA2S_CH = -_straight_ch(OA2S_LAT)


def _lat_foot(lat):
    """(chainage_km, foot_lon).  Beyond the bends at OA2S and CS145 the 1992 line
    ends and chainage continues by arc length along the spine."""
    flon = float(np.interp(lat, _SLAT, _SLON))
    if lat > OA2S_LAT:
        ch = OA2S_CH - (np.interp(lat, _SLAT, _ARC) - np.interp(OA2S_LAT, _SLAT, _ARC))
    elif lat >= CS145_LAT:
        ch = _hav(CS55_LAT, CS55_LON, lat, flon)
        ch = -ch if lat > CS55_LAT else ch
    else:
        ch = CS145_CH + (np.interp(CS145_LAT, _SLAT, _ARC) - np.interp(lat, _SLAT, _ARC))
    return float(ch), flon


_DL = np.linspace(_SLAT[0], _SLAT[-1], 4000)
_DLON = np.interp(_DL, _SLAT, _SLON)
_DC = np.array([_lat_foot(la)[0] for la in _DL])


def chainage_offset(lat, lon, perp=False, merid=False):
    """(chainage_km, offset_km, foot_lon, foot_lat)."""
    if perp:
        d = _hav(lat, lon, _DL, _DLON)
        i = int(np.argmin(d))
        return float(_DC[i]), float(d[i]), float(_DLON[i]), float(_DL[i])
    if merid:
        cross = np.where(np.diff(np.sign(_DLON - lon)) != 0)[0]
        south = [i for i in cross if _DL[i] < lat]
        if south:
            i = max(south, key=lambda j: _DL[j])
            return float(_DC[i]), float(_hav(lat, lon, _DL[i], lon)), float(lon), float(_DL[i])
    ch, flon = _lat_foot(lat)
    return ch, float(_hav(lat, lon, lat, flon)), flon, float(lat)


def on_spine(lat):
    return _SLAT[0] - 1e-9 <= lat <= _SLAT[-1] + 1e-9


geo = [chainage_offset(r.lat, r.lon, perp=r.Index in PERP_SITES,
                       merid=r.Index in MERID_SITES) for r in SITES.itertuples()]
SITES['chain'] = [g[0] for g in geo]
SITES['offset'] = [g[1] for g in geo]
SITES['foot_lon'] = [g[2] for g in geo]
SITES['foot_lat'] = [g[3] for g in geo]
SITES['used'] = [s in TRANSECT_SITES for s in SITES.index]
print(f'{len(SITES)} sites, {SITES.used.sum()} in the curated transect set; '
      f'chainage {SITES[SITES.used].chain.min():+.1f} to {SITES[SITES.used].chain.max():+.1f} km')

# chainage ticks along the spine, so the map ties to the section x-axis
_ord = np.argsort(_DC)
TICKS = [(c, float(np.interp(c, _DC[_ord], _DL[_ord]))) for c in range(-15, 20, 5)]

# === Bathymetry: model bed on the B010 mesh =================================
print('Loading model bed...')
_nc = netCDF4.Dataset(MODEL_NC)
_cx = np.asarray(_nc.variables['cell_X'][:]); _cy = np.asarray(_nc.variables['cell_Y'][:])
_cz = -np.asarray(_nc.variables['cell_Zb'][:])
_nc.close()
_m = ((_cx > LON_MIN - 0.05) & (_cx < LON_MAX + 0.05)
      & (_cy > LAT_MIN - 0.05) & (_cy < LAT_MAX + 0.05))
TRI = mtri.Triangulation(_cx[_m], _cy[_m])
TRI_Z = _cz[_m]
# suppress triangles that bridge land (long edges across a headland or marina)
_t = TRI.triangles
_edge = np.max([np.hypot(_cx[_m][_t[:, i]] - _cx[_m][_t[:, j]],
                         _cy[_m][_t[:, i]] - _cy[_m][_t[:, j]])
                for i, j in ((0, 1), (1, 2), (2, 0))], axis=0)
TRI.set_mask(_edge > 0.010)
print(f'  {_m.sum()} cells, depth {TRI_Z.min():.1f} to {TRI_Z.max():.1f} m')

PLACES = [('Fremantle', 115.760, -32.048, 7), ('Woodman Pt', 115.745, -32.140, 6),
          ('Garden\nIsland', 115.678, -32.185, 7), ('Cockburn\nSound', 115.730, -32.215, 8),
          ('Owen\nAnchorage', 115.700, -32.095, 8), ('Success\nBank', 115.690, -32.075, 6),
          ('Parmelia\nBank', 115.700, -32.135, 6), ('Rockingham', 115.745, -32.278, 6),
          ('Point\nPeron', 115.673, -32.268, 6), ('Warnbro\nSound', 115.740, -32.330, 8)]


def plot_panel(ax, t0, t1, label):
    t0, t1 = pd.Timestamp(t0), pd.Timestamp(t1)
    ax.set_facecolor('#e3d9c4')                       # land = un-meshed ground
    ax.tricontourf(TRI, TRI_Z, levels=np.arange(0, 26, 1), cmap='Blues', alpha=0.45)

    # Transect A spine + the reference stations that define it
    ax.plot(_SLON, _SLAT, '-', color='#111111', lw=1.3, zorder=8, alpha=0.85)
    ax.plot(_SLON, _SLAT, '|', color='#111111', ms=4, mew=0.8, zorder=8, alpha=0.85)
    ax.plot(CS55_LON, CS55_LAT, '*', color='#111111', ms=10, zorder=9)
    for ch, tlat in TICKS:
        tlon = float(np.interp(tlat, _SLAT, _SLON))
        ax.plot(tlon, tlat, 'o', mfc='none', mec='#111111', mew=0.9, ms=5, zorder=9)
        ax.text(tlon - 0.004, tlat, f'{ch:+d}' if ch else 'CS55\n0 km', fontsize=5.5,
                zorder=9, va='center', ha='right', fontweight='bold')

    # every site this sim's programs visit at some point in the year, as a ghost
    for site, r in SITES[SITES.active].iterrows():
        ax.plot(r.lon, r.lat, '.', color='#cccccc', ms=2.0, zorder=3)

    w = F[(F.Date >= t0) & (F.Date < t1 + pd.Timedelta(days=1))]
    occupied = sorted(w.Site_Description.unique())
    n_used = n_rej = 0
    for site in occupied:
        if site not in SITES.index:
            continue
        r = SITES.loc[site]
        if not (LAT_MIN <= r.lat <= LAT_MAX and LON_MIN <= r.lon <= LON_MAX):
            continue
        st = AGENCY_STYLE[r.Agency]
        if r.used:
            n_used += 1
            # tie line to the spine foot point -- this IS the projection applied
            ax.plot([r.lon, r.foot_lon], [r.lat, r.foot_lat], '-', color='#666666',
                    lw=0.6, alpha=0.7, zorder=5)
            ax.plot(r.foot_lon, r.foot_lat, '+', color='#666666', ms=3, mew=0.7, zorder=5)
            ax.plot(r.lon, r.lat, st['marker'], color=st['color'], ms=6, zorder=7,
                    markeredgecolor='black', markeredgewidth=0.4)
            ax.text(r.lon + 0.0035, r.lat + 0.0015,
                    f'{site}\n{r.chain:+.1f} km, {r.offset:.1f} off', fontsize=5.0,
                    color=st['color'], fontweight='bold', zorder=9, alpha=0.95)
        else:
            n_rej += 1
            ax.plot(r.lon, r.lat, st['marker'], color='white', ms=5, zorder=6,
                    markeredgecolor=st['color'], markeredgewidth=0.8, alpha=0.85)
            ax.text(r.lon + 0.0035, r.lat + 0.0015, f'{site}\n({r.offset:.1f} off)',
                    fontsize=4.2, color='#999999', zorder=6, alpha=0.9)

    days = sorted(w.day.unique())
    dstr = ', '.join(pd.Timestamp(d).strftime('%d %b') for d in days)
    ax.set_title(f'{label}: {t0:%d %b} \u2013 {t1:%d %b %Y}\n'
                 f'{n_used} of {len(TRANSECT_SITES)} transect stations occupied, '
                 f'{n_rej} other casts  |  sampled {dstr}',
                 fontsize=7, pad=4)

    for lbl, plon, plat, fs in PLACES:
        if LAT_MIN <= plat <= LAT_MAX and LON_MIN <= plon <= LON_MAX:
            ax.annotate(lbl, xy=(plon, plat), fontsize=fs, fontstyle='italic',
                        ha='center', color='gray', alpha=0.55)

    ax.set_xlim(LON_MIN, LON_MAX); ax.set_ylim(LAT_MIN, LAT_MAX)
    ax.set_aspect(1 / np.cos(np.radians((LAT_MIN + LAT_MAX) / 2)))
    ax.tick_params(labelsize=5)
    ax.grid(True, alpha=0.2, lw=0.3)
    return n_used, n_rej


print('\nPlotting panels...')
NCOL = 4
NROW = int(np.ceil(len(WINDOWS) / NCOL))
fig, axes = plt.subplots(NROW, NCOL, figsize=(22, 12 * NROW), squeeze=False)
for i, (t0, t1, label) in enumerate(WINDOWS):
    nu, nr_ = plot_panel(axes[i // NCOL, i % NCOL], t0, t1, label)
    print(f'  {label:13s} {t0} -> {t1}: {nu} used, {nr_} rejected')
for j in range(len(WINDOWS), NROW * NCOL):        # blank the unused cells
    axes[j // NCOL, j % NCOL].axis('off')

leg = [mlines.Line2D([], [], color='#111111', lw=1.3, marker='o', markerfacecolor='none',
                     markersize=6, label='Transect A spine (MR \u2192 OA4 \u2192 OA2S \u2192 CS55 \u2192 6142983 \u2192 Warnbro Sound), 5 km chainage ticks'),
       mlines.Line2D([], [], color='#666666', lw=0.8,
                     label='projection tie to spine foot point (= offset)')]
for ag, st in AGENCY_STYLE.items():
    leg.append(mlines.Line2D([], [], marker=st['marker'], color='w', markerfacecolor=st['color'],
                             markeredgecolor='black', markeredgewidth=0.4, ms=8,
                             label=f'{ag} \u2014 in the transect station set'))
    leg.append(mlines.Line2D([], [], marker=st['marker'], color='w', markerfacecolor='white',
                             markeredgecolor=st['color'], markeredgewidth=1.2, ms=8,
                             label=f'{ag} \u2014 occupied, not in the set'))
leg.append(mlines.Line2D([], [], marker='.', color='w', markerfacecolor='#cccccc',
                         markeredgecolor='#cccccc', ms=6,
                         label=f'{SIM} CTD site not occupied this window'))
_lb = 0.06 / NROW * 2
fig.legend(handles=leg, loc='lower center', ncol=4, fontsize=9, framealpha=0.9,
           bbox_to_anchor=(0.5, _lb * 0.6))

fig.suptitle(f'{SIM} CTD casts by survey window, relative to SMCWS Transect A\n'
             'labels: site, projected chainage from CS55, perpendicular offset from the transect line (km)',
             fontsize=14, fontweight='bold', y=1 - 0.035 / NROW * 2)
fig.tight_layout(rect=[0, _lb, 1, 1 - 0.045 / NROW * 2], h_pad=4.0)
out = OUT_DIR / f'map_panels_{YEAR}.png'
fig.savefig(out, dpi=150, bbox_inches='tight'); plt.close(fig)
print(f'\nSaved: {out}')
