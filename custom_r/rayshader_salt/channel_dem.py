import numpy as np, rasterio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from rasterio.warp import transform as wt
DEM=r"data/cockburn_swan_2.tif"   # high-res reference DEM
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs
# area of interest lat/lon -> CRS -> pixel window
lons=[115.62,115.78,115.62,115.78]; lats=[-32.05,-32.05,-32.20,-32.20]
X,Y=wt("EPSG:4326",crs,lons,lats)
cols=[(x-T.c)/T.a for x in X]; rows=[(y-T.f)/T.e for y in Y]
c0,c1=int(min(cols)),int(max(cols)); r0,r1=int(min(rows)),int(max(rows))
win=rasterio.windows.Window(c0,r0,c1-c0,r1-r0)
dem=ds.read(1,window=win).astype(float); dem[dem>1e30]=np.nan
print("crop shape",dem.shape,"elev range %.1f..%.1f"%(np.nanmin(dem),np.nanmax(dem)))
fig,ax=plt.subplots(figsize=(7,9))
im=ax.imshow(dem,cmap="turbo",vmin=-20,vmax=-5)
plt.colorbar(im,ax=ax,shrink=0.6,label="DEM elev (m)")
ax.set_title("High-res DEM, channel area (turbo -20..-5)\nrows=N->S, cols=W->E"); ax.set_xlabel("col(E->)"); ax.set_ylabel("row(S->)")
plt.tight_layout(); plt.savefig("images/channel_dem.png",dpi=120); print("saved; window c0,r0=",c0,r0)
np.save("data/_chan_win.npy",np.array([c0,r0,c1,r1]))
