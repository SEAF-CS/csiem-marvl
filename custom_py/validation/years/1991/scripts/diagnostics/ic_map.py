"""Map the current graded IC (initial_condition_2D_Aug_B010_Sgrad.csv).
Left: full domain on a MARINE scale (34-36.2) so the shelf/coast E-W gradient shows.
Right: Swan-estuary/OA zoom on the FULL scale (13-36.2) so the estuary drop shows.
Breakpoint longitudes/values marked."""
import numpy as np, pandas as pd, xarray as xr
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm

IC = r'S:/Matt_Working/csiem/model_components/includes/ic/initial_condition_2D_Aug_B010_Sgrad.csv'
NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
OUT = r'S:/Matt_Working/csiem/model_components/includes/ic/initial_condition_2D_Aug_B010_Sgrad_map.png'
import sys; sys.path.insert(0, r'S:/Matt_Working/csiem/model_components/includes/ic')
from make_graded_ic import CONFIGS                      # read live breakpoints (never goes stale)
_sal = CONFIGS['1991']['SAL']; BP_LON, BP_VAL = _sal['bp_lon'], _sal['bp_val']

ic = pd.read_csv(IC, skipinitialspace=True)
ds = xr.open_dataset(NC); X = ds['cell_X'].values; Y = ds['cell_Y'].values; sal = ic['SAL'].values
print(f'IC cells {len(ic)} | SAL {sal.min():.2f}..{sal.max():.2f}')
cmap = plt.cm.RdYlBu_r

fig, (ax0, ax1) = plt.subplots(1, 2, figsize=(17, 8))
# --- left: full domain, MARINE scale (shows shelf/coast gradient) ---
levM = np.arange(34.0, 36.3, 0.1); normM = BoundaryNorm(levM, cmap.N, clip=True)
sc0 = ax0.scatter(X, Y, c=sal, s=5, cmap=cmap, norm=normM)
for lo in BP_LON[:3]: ax0.axvline(lo, color='k', ls=':', lw=0.7, alpha=0.6)
ax0.set_aspect('equal'); ax0.set_xlabel('lon'); ax0.set_ylabel('lat')
ax0.set_title('Full domain - MARINE scale 34-36.2 (shelf E-W gradient; estuary clamps blue)')
fig.colorbar(sc0, ax=ax0, label='SAL (psu)', shrink=0.85, extend='min')
# --- right: estuary + OA/CS zoom, FULL scale (shows estuary drop) ---
levF = np.arange(13, 36.5, 0.5); normF = BoundaryNorm(levF, cmap.N, clip=True)
m = (X > 115.60) & (X < 115.86) & (Y > -32.20) & (Y < -31.95)
sc1 = ax1.scatter(X[m], Y[m], c=sal[m], s=16, cmap=cmap, norm=normF)
for lo, va in zip(BP_LON, BP_VAL):
    ax1.axvline(lo, color='k', ls=':', lw=0.8, alpha=0.6)
    ax1.text(lo, -31.951, f'{va:g}', fontsize=8, ha='center', va='bottom', fontweight='bold')
ax1.set_aspect('equal'); ax1.set_xlim(115.60, 115.86); ax1.set_xlabel('lon'); ax1.set_ylabel('lat')
ax1.set_title('Estuary + OA/CS zoom - FULL scale 13-36 (estuary drop 34.65->20->13)')
fig.colorbar(sc1, ax=ax1, label='SAL (psu)', shrink=0.85)
fig.suptitle('Graded IC salinity  |  breakpoints ' + ' -> '.join(f'{v:g}@{l:g}' for l, v in zip(BP_LON, BP_VAL)),
             fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.96]); fig.savefig(OUT, dpi=140, bbox_inches='tight'); print('wrote', OUT)
