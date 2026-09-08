import numpy as np, rasterio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
with rasterio.open("data/dem_coarse_fixed.tif") as ds:
    dem=ds.read(1).astype(float); prof=ds.profile
H,W=dem.shape; rr,cc=np.mgrid[0:H,0:W]
# CS region: water, exclude far-west offshore (cols<58) and east/Swan (cols>242), N->S basin+entrance
mask = (dem<0) & (rr>160)&(rr<822) & (cc>58)&(cc<242)
print("dem",dem.shape,"mask cells",int(mask.sum()))
# save mask geotiff (1.0 inside, nan outside) for the renderer
prof.update(dtype="float32",nodata=np.nan)
m = np.where(mask,1.0,np.nan).astype("float32")
with rasterio.open("data/cs_mask.tif","w",**prof) as dst: dst.write(m,1)
# visualize: DEM + mask outline + masked salinity at cascade peak
with rasterio.open("data/sal_bottom/sal_059.tif") as ds: sal=ds.read(1).astype(float)
salm=np.where(mask,sal,np.nan)
fig,ax=plt.subplots(1,3,figsize=(16,11))
ax[0].imshow(dem,cmap="terrain",vmin=-25,vmax=10); ax[0].contour(mask,levels=[0.5],colors="r"); ax[0].set_title("DEM + CS mask (red)")
im=ax[1].imshow(salm,cmap="viridis"); plt.colorbar(im,ax=ax[1],shrink=0.5); ax[1].set_title("masked bottom-sal f059")
v=salm[np.isfinite(salm)]
print("masked basin sal: p2 %.3f p50 %.3f p90 %.3f p98 %.3f"%(np.percentile(v,2),np.percentile(v,50),np.percentile(v,90),np.percentile(v,98)))
im2=ax[2].imshow(salm,cmap="viridis",vmin=np.percentile(v,2),vmax=np.percentile(v,98)); plt.colorbar(im2,ax=ax[2],shrink=0.5); ax[2].set_title("tight scale p2..p98")
plt.tight_layout(); plt.savefig("images/design_cs_mask.png",dpi=95)
print("saved images/design_cs_mask.png + data/cs_mask.tif")
