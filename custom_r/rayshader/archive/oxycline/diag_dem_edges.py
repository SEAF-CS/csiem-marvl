# Diagnose the spurious "land wall" on the N/W edges of the DEM used for rendering.
import numpy as np, rasterio, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

for path in [r"data/cockburn_swan_2.tif", r"data/dem_coarse.tif"]:
    with rasterio.open(path) as ds:
        a = ds.read(1).astype(float)
        nod = ds.nodata
    if nod is not None:
        a[a == nod] = np.nan
    H, W = a.shape
    fin = np.isfinite(a)
    print(f"\n=== {path}  shape={a.shape}  nodata={nod}")
    print(f"  finite min/max = {np.nanmin(a):.2f} / {np.nanmax(a):.2f}")
    print(f"  land(>0) cells = {np.nansum(a>0)}   water(<=0) = {np.nansum(a<=0)}   nan = {np.sum(~fin)}")
    # edge strips (north=row0, west=col0). report how much of each edge is land>0
    for name, strip in [("NORTH row0", a[0, :]), ("SOUTH rowN", a[-1, :]),
                        ("WEST col0", a[:, 0]),  ("EAST colN", a[:, -1])]:
        s = strip[np.isfinite(strip)]
        if s.size:
            print(f"  {name:11s}: min={np.nanmin(strip):7.2f} max={np.nanmax(strip):7.2f} "
                  f"mean={np.nanmean(strip):7.2f}  land%={100*np.mean(s>0):.1f}  nan%={100*np.mean(~np.isfinite(strip)):.1f}")

# Visual: land/water mask + elevation, for the coarse DEM (what gets rendered)
with rasterio.open(r"data/dem_coarse.tif") as ds:
    a = ds.read(1).astype(float); nod = ds.nodata
if nod is not None: a[a==nod] = np.nan
fig, ax = plt.subplots(1, 3, figsize=(16, 9))
im0 = ax[0].imshow(a, cmap="terrain", vmin=-25, vmax=10); ax[0].set_title("dem_coarse elevation (north up)")
plt.colorbar(im0, ax=ax[0], shrink=0.6)
mask = np.where(np.isfinite(a), (a>0).astype(float), np.nan)
ax[1].imshow(mask, cmap="bwr"); ax[1].set_title("land(>0)=red  water(<=0)=blue")
# highlight thin land slivers adjacent to water along edges
ax[2].imshow(np.isfinite(a), cmap="gray"); ax[2].set_title("finite (white) vs nan (black)")
plt.tight_layout(); plt.savefig("images/diag_dem_edges.png", dpi=90)
print("\nsaved images/diag_dem_edges.png")
