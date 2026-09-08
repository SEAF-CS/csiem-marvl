import rasterio, numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
d=rasterio.open("data/dem_coarse_fixed.tif").read(1).astype(float)  # north-up: row0=N, col0=W
fig,ax=plt.subplots(figsize=(6,11))
im=ax.imshow(d,cmap="terrain",vmin=-25,vmax=10)
plt.colorbar(im,ax=ax,shrink=0.5,label="elevation (m)")
ax.set_title("DEM ground truth (GeoTIFF north-up)\nTOP=North  BOTTOM=South  LEFT=West  RIGHT=East")
ax.text(0.5,1.005,"N",transform=ax.transAxes,ha="center",va="bottom",color="red",fontsize=16,weight="bold")
ax.text(0.5,-0.01,"S",transform=ax.transAxes,ha="center",va="top",color="red",fontsize=16,weight="bold")
ax.text(-0.01,0.5,"W",transform=ax.transAxes,ha="right",va="center",color="red",fontsize=16,weight="bold")
ax.text(1.01,0.5,"E",transform=ax.transAxes,ha="left",va="center",color="red",fontsize=16,weight="bold")
ax.set_xticks([]); ax.set_yticks([])
plt.tight_layout(); plt.savefig("images/bathy_northup_truth.png",dpi=110)
print("saved images/bathy_northup_truth.png")
