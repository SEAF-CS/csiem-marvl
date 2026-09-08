"""Central MODEL-sampling location table + override helper.

`model_sample_locations.csv` starts IDENTICAL to the actual SMCWS station coordinates,
then can be refined per-station to change WHERE the model is sampled — e.g. nudge a
station that sits on a channel edge into the dredged channel cell. The FIELD data always
stays at the true station; only the MODEL sample point is overridden.

Use everywhere we sample the model at a station:
    from point_overrides import adjust_point
    mlon, mlat = adjust_point(station, lon, lat)   # -> table value, else (lon, lat)

Refine a station either by editing the CSV directly, or by adding to REFINEMENTS below
and rebuilding (`python point_overrides.py`, which rewrites the CSV).
"""
import os, pandas as pd

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/dadamo_transect'
TABLE = os.path.join(DIR, 'model_sample_locations.csv')
INV = os.path.join(DIR, 'region_profiles_inventory.csv')

# Per-station MODEL-sample refinements:  station -> (model_lon, model_lat, note).
# (model loc differs from the actual station loc.) Add cases here as they're found.
REFINEMENTS = {
    'OA80': (115.7027, -32.1307, 'into Success channel: nearest cell was 7.9m flank; ~12.5m channel cell ~145m E'),
}


def build_table(force=False):
    """Create model_sample_locations.csv seeded = actual station coords, then apply REFINEMENTS.
    Does NOT overwrite an existing table unless force=True (so manual CSV edits persist)."""
    if os.path.exists(TABLE) and not force:
        return pd.read_csv(TABLE)
    inv = pd.read_csv(INV)
    st = inv.groupby('station').agg(region=('region', 'first'), lat=('lat', 'first'), lon=('lon', 'first')).reset_index()
    st['model_lon'] = st['lon']; st['model_lat'] = st['lat']; st['note'] = ''
    for stn, (mlon, mlat, note) in REFINEMENTS.items():
        if stn in st['station'].values:
            st.loc[st.station == stn, ['model_lon', 'model_lat', 'note']] = [mlon, mlat, note]
    st = st[['station', 'region', 'lat', 'lon', 'model_lon', 'model_lat', 'note']]
    st.to_csv(TABLE, index=False)
    return st


_TBL = None
def _load():
    global _TBL
    if _TBL is None:
        _TBL = (pd.read_csv(TABLE) if os.path.exists(TABLE) else build_table()).set_index('station')
    return _TBL


def adjust_point(station, lon=None, lat=None):
    """(model_lon, model_lat) for a station from the table; falls back to the passed (lon, lat)."""
    t = _load()
    if station in t.index:
        r = t.loc[station]
        return float(r['model_lon']), float(r['model_lat'])
    return lon, lat


if __name__ == '__main__':
    t = build_table(force=True)
    print(f'wrote {TABLE}  |  {len(t)} stations')
    ref = t[t.note != '']
    print(f'refined ({len(ref)}):')
    print(ref[['station', 'region', 'lon', 'model_lon', 'lat', 'model_lat', 'note']].to_string(index=False))
