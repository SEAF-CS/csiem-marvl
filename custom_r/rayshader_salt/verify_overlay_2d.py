import rasterio, numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap, LightSource
dem=rasterio.open("data/dem_coarse_fixed.tif").read(1).astype(float)   # north-up
sal=rasterio.open("data/sal_bottom/sal_059.tif").read(1).astype(float)
cmap=LinearSegmentedColormap.from_list("x",["#e0f3f8","#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"])
ls=LightSource(azdeg=315,altdeg=45)
hill=ls.hillshade(dem,vert_exag=8)
fig,ax=plt.subplots(figsize=(6.5,12))
ax.imshow(hill,cmap="gray")
# terrain tint (land greenish, water faint) under salt
land=np.where(dem>0, 0.55, np.nan)
ax.imshow(np.ma.masked_invalid(land),cmap=LinearSegmentedColormap.from_list("g",["#6b8e23","#6b8e23"]),alpha=0.35)
sn=np.clip((sal-33)/(35.2-33),0,1); sn=np.where(np.isfinite(sal),sn,np.nan)
ax.imshow(np.ma.masked_invalid(sn),cmap=cmap,alpha=0.85)
ax.set_title("Salt drape over bathy  (NORTH-UP, ground truth)\nSwan estuary = NE/top-right   Garden Island = W strip")
for t,x,y in [("N",.5,1.01),("S",.5,-.02),("W",-.02,.5),("E",1.02,.5)]:
    ax.text(x,y,t,transform=ax.transAxes,ha="center",va="center",color="red",fontsize=15,weight="bold")
ax.set_xticks([]); ax.set_yticks([])
plt.tight_layout(); plt.savefig("images/verify_overlay_2d.png",dpi=115)
print("saved images/verify_overlay_2d.png")
