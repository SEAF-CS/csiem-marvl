# Remove the spurious "land wall": the exactly-0 fill cells (open water padded to sea
# level) are reset to NaN and re-filled with interpolated bathymetry from the
# surrounding REAL cells, so open water reads as continuous seabed (no wall).
import numpy as np, rasterio
from scipy.interpolate import griddata

SRC = r"data/dem_coarse.tif"
DST = r"data/dem_coarse_fixed.tif"

with rasterio.open(SRC) as ds:
    a = ds.read(1).astype(float); prof = ds.profile

eq0 = np.isclose(a, 0.0, atol=1e-6)
print("fill (==0) cells to repair:", int(eq0.sum()))

# Donor points = every finite, non-fill cell (real bathymetry + land).
H, W = a.shape
rr, cc = np.mgrid[0:H, 0:W]
donor = np.isfinite(a) & ~eq0
pts  = np.c_[rr[donor], cc[donor]]
vals = a[donor]
tgt  = np.c_[rr[eq0], cc[eq0]]

filled = a.copy()
lin = griddata(pts, vals, tgt, method="linear")
nn  = griddata(pts, vals, tgt, method="nearest")     # fallback outside hull
lin[~np.isfinite(lin)] = nn[~np.isfinite(lin)]
filled[eq0] = lin

print(f"repaired region new elev: min={np.nanmin(filled[eq0]):.2f} "
      f"max={np.nanmax(filled[eq0]):.2f} mean={np.nanmean(filled[eq0]):.2f}")
print(f"whole DEM min/max: {np.nanmin(filled):.2f} / {np.nanmax(filled):.2f}")

prof.update(dtype="float32")
with rasterio.open(DST, "w", **prof) as dst:
    dst.write(filled.astype("float32"), 1)
print("wrote", DST)
