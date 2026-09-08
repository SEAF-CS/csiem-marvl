"""Precompute TUFLOW-FV model time-series at a representative cell per subregion
(surface top-2m and bottom-2m T/S) across the three model runs -> CSV for plotting."""
import sys, time, numpy as np, pandas as pd, xarray as xr, warnings
warnings.filterwarnings('ignore')
import tfv.xarray

DIR = r'G:/CSIEM/1.8.0/csiem-marvl/custom_py/climatology_assessment'
REP = {'N': (115.727, -31.878), 'NW': (115.55, -32.078), 'W': (115.486, -32.183), 'SW': (115.558, -32.25), 'S': (115.7, -32.45)}
RUNS = [r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug/csiem_B010_19910720_19910831.nc',
        r'S:/Matt_Working/csiem/output_archive/1.7.0/1992_marmay/csiem_B010_19920222_19920531.nc',
        r'S:/Matt_Working/csiem/output_archive/1.7.0/1994B/csiem_B010_19931101_19941231.nc']

def open_fv(path):
    for a in range(8):
        try:
            ds = xr.open_dataset(path); _ = ds['SAL']; return ds.tfv
        except Exception as e:
            print(f'  open attempt {a+1} failed ({type(e).__name__}); retry'); time.sleep(3)
    return None

rows = []
for path in RUNS:
    print('run', path.split('/')[-1]); sys.stdout.flush()
    fv = open_fv(path)
    if fv is None: print('  UNREADABLE, skipping'); continue
    for level, datum in [('surf', 'depth'), ('bot', 'height')]:
        for attempt in range(3):
            try:
                ts = fv.get_timeseries(['SAL', 'TEMP'], REP, datum=datum, limits=(0, 2), agg='mean')
                t = pd.to_datetime(ts['Time'].values); locs = list(ts['Location'].values)
                SAL = np.asarray(ts['SAL']); TEMP = np.asarray(ts['TEMP'])  # (Time, Location)
                for li, sr in enumerate(locs):
                    for ti in range(len(t)):
                        rows.append(dict(date=t[ti], subregion=sr, level=level, SAL=float(SAL[ti, li]), TEMP=float(TEMP[ti, li])))
                print(f'  {level}: {len(t)} steps x {len(locs)} pts'); sys.stdout.flush()
                break
            except Exception as e:
                print(f'  {level} attempt {attempt+1} failed ({type(e).__name__}); retry'); time.sleep(3)

df = pd.DataFrame(rows)
out = DIR + '/model_repcell_timeseries.csv'
df.to_csv(out, index=False)
print('wrote', out, '|', len(df), 'rows |', df.groupby(['subregion','level']).size().to_dict() if len(df) else 'EMPTY')
