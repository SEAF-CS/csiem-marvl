import numpy as np, rasterio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
cmap=LinearSegmentedColormap.from_list("x",["#e0f3f8","#abd9e9","#74add1","#4575b4","#8856a7","#762a83","#40004b"])
with rasterio.open("data/sal_bottom/sal_059.tif") as ds: sal=ds.read(1).astype(float)
with rasterio.open("data/cs_mask.tif") as ds: mask=ds.read(1).astype(float)
salm=np.where(np.isfinite(mask),sal,np.nan)
plt.figure(figsize=(5,9))
plt.imshow(salm,cmap=cmap,vmin=34.1,vmax=34.77)   # rasterio array: row0=NORTH(top), col0=WEST(left)
plt.title("2D GROUND TRUTH sal_059\nNORTH=top  WEST=left"); plt.axis("off")
plt.tight_layout(); plt.savefig("images/verify_2d_north_up.png",dpi=110)
print("saved 2D north-up reference")
