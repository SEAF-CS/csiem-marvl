import numpy as np, rasterio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from rasterio.warp import transform as wt
DEM=r"X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif"   # high-res reference DEM
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs
# area of interest lat/lon -> CRS -> pixel window
lons=[115.672,115.718,115.672,115.718]; lats=[-32.240,-32.240,-32.276,-32.276]   # minstrel: sill S of Garden Island
X,Y=wt("EPSG:4326",crs,lons,lats)
cols=[(x-T.c)/T.a for x in X]; rows=[(y-T.f)/T.e for y in Y]
c0,c1=int(min(cols)),int(max(cols)); r0,r1=int(min(rows)),int(max(rows))
win=rasterio.windows.Window(c0,r0,c1-c0,r1-r0)
dem=ds.read(1,window=win).astype(float); dem[dem>1e30]=np.nan
print("crop shape",dem.shape,"elev range %.1f..%.1f"%(np.nanmin(dem),np.nanmax(dem)))
fig,ax=plt.subplots(figsize=(7,9))
im=ax.imshow(dem,cmap="turbo",vmin=-14,vmax=0)
plt.colorbar(im,ax=ax,shrink=0.6,label="DEM elev (m)")
ax.set_title("High-res DEM — Minstrel channel area (turbo -14..0)\nrows=N->S, cols=W->E"); ax.set_xlabel("col(E->)"); ax.set_ylabel("row(S->)")
plt.tight_layout(); plt.savefig("outputs/channel_dem.png",dpi=120); print("saved; window c0,r0=",c0,r0)
np.save("data/_chan_win.npy",np.array([c0,r0,c1,r1]))
