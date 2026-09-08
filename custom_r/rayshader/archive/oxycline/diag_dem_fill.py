# Pin down the spurious "land wall": map cells that are exactly 0 (suspected fill)
# vs genuine land (>0) vs water (<0), on the coarse render DEM.
import numpy as np, rasterio, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap

with rasterio.open(r"data/dem_coarse.tif") as ds:
    a = ds.read(1).astype(float); nod = ds.nodata
if nod is not None and np.isfinite(nod): a[a == nod] = np.nan

eq0  = np.isclose(a, 0.0, atol=1e-6)
land = a > 1e-6
water= a < -1e-6
print("exactly0 cells :", int(eq0.sum()))
print("land(>0) cells :", int(land.sum()))
print("water(<0) cells:", int(water.sum()))
print("0 as % of total:", 100*eq0.mean())

cat = np.full(a.shape, 0)      # 0 = water
cat[land] = 1                  # 1 = land
cat[eq0]  = 2                  # 2 = exactly 0 (fill)
cmap = ListedColormap(["#2166ac", "#b2182b", "#ffd400"])   # water blue, land red, fill yellow

fig, ax = plt.subplots(1, 2, figsize=(13, 11))
im = ax[0].imshow(a, cmap="terrain", vmin=-25, vmax=10); ax[0].set_title("elevation")
plt.colorbar(im, ax=ax[0], shrink=0.5)
ax[1].imshow(cat, cmap=cmap, interpolation="nearest")
ax[1].set_title("water(blue)  land>0(red)  EXACTLY-0 fill(yellow)")
plt.tight_layout(); plt.savefig("images/diag_dem_fill.png", dpi=95)
print("saved images/diag_dem_fill.png")
