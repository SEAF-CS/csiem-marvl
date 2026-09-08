# Where does the SAL=34.6 surface appear? Overlay coverage on the DEM to design a
# Cockburn Sound mask (keep the cascade tongue into CS, drop spurious areas elsewhere).
import numpy as np, glob, rasterio, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

with rasterio.open("data/dem_coarse_fixed.tif") as ds:
    dem = ds.read(1).astype(float)

tifs = sorted(glob.glob("data/halo_series/halo_*.tif"))
def load(p):
    with rasterio.open(p) as ds: return ds.read(1).astype(float)

# frequency of coverage across all frames (how often each cell has the surface)
freq = np.zeros(dem.shape)
zmin = np.full(dem.shape, np.nan)   # deepest (most negative) interface seen
for p in tifs:
    a = load(p); m = np.isfinite(a)
    freq[m] += 1
    zmin = np.where(m, np.fmin(np.nan_to_num(zmin, nan=1e9), a), zmin)
freq /= len(tifs)

fig, ax = plt.subplots(1, 3, figsize=(17, 11))
ax[0].imshow(dem, cmap="terrain", vmin=-25, vmax=10); ax[0].set_title("DEM (north up)")
im1 = ax[1].imshow(freq, cmap="magma", vmin=0, vmax=1)
ax[1].set_title("coverage frequency of SAL=34.6 (fraction of 67 frames)")
plt.colorbar(im1, ax=ax[1], shrink=0.5)
# DEM faint + peak-frame surface to see the tongue
ax[2].imshow(dem, cmap="Greys_r", vmin=-30, vmax=15, alpha=0.6)
peak = load("data/halo_series/halo_059.tif")
im2 = ax[2].imshow(np.ma.masked_invalid(peak), cmap="cool"); ax[2].set_title("peak frame 059 (Aug23 20:00) interface elev")
plt.colorbar(im2, ax=ax[2], shrink=0.5)
# add gridline ticks so we can read row/col extents for a mask box
for a in ax:
    a.set_xticks(np.arange(0, dem.shape[1], 50)); a.set_yticks(np.arange(0, dem.shape[0], 100))
    a.grid(True, color="w", alpha=0.2, lw=0.3)
plt.tight_layout(); plt.savefig("images/diag_halo_coverage.png", dpi=95)
print("dem shape", dem.shape, "-> images/diag_halo_coverage.png")
