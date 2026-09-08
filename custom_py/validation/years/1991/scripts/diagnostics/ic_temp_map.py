"""Map the graded IC TEMPERATURE (initial_condition_2D_Aug_B010_Sgrad.csv):
full domain + Swan-estuary/OA zoom. TEMP grades west 19.4 (ocean) -> 15.4 (coast) -> 15.2 (estuary)."""
import numpy as np, pandas as pd, xarray as xr
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm

IC = r'S:/Matt_Working/csiem/model_components/includes/ic/initial_condition_2D_Aug_B010_Sgrad.csv'
NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
OUT = r'S:/Matt_Working/csiem/model_components/includes/ic/initial_condition_2D_Aug_B010_Sgrad_TEMPmap.png'
ic = pd.read_csv(IC, skipinitialspace=True)
ds = xr.open_dataset(NC); X = ds['cell_X'].values; Y = ds['cell_Y'].values; tmp = ic['TEMP'].values
print(f'IC TEMP {tmp.min():.2f}..{tmp.max():.2f}')
lev = np.arange(15.0, 19.6, 0.2); cmap = plt.cm.coolwarm; norm = BoundaryNorm(lev, cmap.N, clip=True)
fig, (ax0, ax1) = plt.subplots(1, 2, figsize=(17, 8))
sc0 = ax0.scatter(X, Y, c=tmp, s=5, cmap=cmap, norm=norm)
ax0.set_aspect('equal'); ax0.set_title('IC temperature - full domain'); ax0.set_xlabel('lon'); ax0.set_ylabel('lat')
fig.colorbar(sc0, ax=ax0, label='TEMP (°C)', shrink=0.85)
m = (X > 115.60) & (X < 115.86) & (Y > -32.20) & (Y < -31.95)
sc1 = ax1.scatter(X[m], Y[m], c=tmp[m], s=16, cmap=cmap, norm=norm)
ax1.set_aspect('equal'); ax1.set_xlim(115.60, 115.86); ax1.set_title('IC temperature - Swan estuary + OA/CS zoom')
ax1.set_xlabel('lon'); ax1.set_ylabel('lat'); fig.colorbar(sc1, ax=ax1, label='TEMP (°C)', shrink=0.85)
fig.suptitle('Graded IC temperature  |  west 19.4 (ocean) -> 15.4 (coast/ref 115.75) -> 15.2 (Swan estuary)', fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.96]); fig.savefig(OUT, dpi=140, bbox_inches='tight'); print('wrote', OUT)
