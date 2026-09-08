import numpy as np, glob, rasterio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
with rasterio.open("data/dem_coarse_fixed.tif") as ds: dem=ds.read(1).astype(float)
tifs=sorted(glob.glob("data/halo_series/halo_*.tif"))
def load(p):
    with rasterio.open(p) as ds: return ds.read(1).astype(float)
freq=np.zeros(dem.shape)
for p in tifs:
    freq[np.isfinite(load(p))]+=1
freq/=len(tifs)
# big single panel: DEM grey + coverage freq (only where >0) in hot colours
fig,ax=plt.subplots(figsize=(9,16))
ax.imshow(dem,cmap="Greys_r",vmin=-30,vmax=15)
im=ax.imshow(np.ma.masked_where(freq<=0,freq),cmap="autumn_r",vmin=0,vmax=1,alpha=0.9)
plt.colorbar(im,ax=ax,shrink=0.4,label="coverage fraction")
ax.set_xticks(np.arange(0,dem.shape[1],25)); ax.set_yticks(np.arange(0,dem.shape[0],50))
ax.grid(True,color="cyan",alpha=0.35,lw=0.4)
ax.set_title("SAL=34.6 coverage over DEM (row/col grid)")
plt.tight_layout(); plt.savefig("images/diag_halo_zoom.png",dpi=110)
# also print row/col bounds of coverage
ys,xs=np.where(freq>0.05)
print("cells with >5%% coverage: rows %d-%d  cols %d-%d"%(ys.min(),ys.max(),xs.min(),xs.max()))
ys2,xs2=np.where(freq>0.4)
print("cells with >40%% coverage (core): rows %d-%d  cols %d-%d"%(ys2.min(),ys2.max(),xs2.min(),xs2.max()))
print("saved images/diag_halo_zoom.png")
