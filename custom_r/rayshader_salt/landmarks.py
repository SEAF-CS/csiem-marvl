import rasterio, numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from rasterio.warp import transform as wt
ds=rasterio.open("data/dem_coarse_fixed.tif"); dem=ds.read(1).astype(float); crs=ds.crs; T=ds.transform
print("CRS:",crs)
# known Cockburn Sound landmarks (lon, lat)
LM={"Garden Is":(115.685,-32.18),"Fremantle/Swan":(115.745,-32.055),
    "Woodman Pt":(115.755,-32.135),"Cape Peron(S)":(115.690,-32.270),"Carnac Is":(115.660,-32.118)}
xs,ys=wt("EPSG:4326",crs,[v[0] for v in LM.values()],[v[1] for v in LM.values()])
rows=[]; 
import csv
with open("data/landmarks_px.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["name","row","col"])
    for (nm,_),X,Y in zip(LM.items(),xs,ys):
        r,c=~T*(X,Y); r=int(round(c)); cc=int(round((X-T.c)/T.a))  # col from x
        row=int(round((Y-T.f)/T.e))                                 # row from y
        col=int(round((X-T.c)/T.a))
        w.writerow([nm,row,col]); rows.append((nm,row,col))
        print(f"{nm:16s} -> row {row:4d} col {col:4d}")
# 2D north-up with named landmarks
fig,ax=plt.subplots(figsize=(6,11)); ax.imshow(dem,cmap="terrain",vmin=-25,vmax=10)
for nm,row,col in rows:
    ax.plot(col,row,"o",color="red",ms=8); ax.text(col+6,row,nm,color="red",fontsize=11,weight="bold")
ax.set_title("Named landmarks on DEM (north-up truth)"); ax.set_xticks([]); ax.set_yticks([])
plt.tight_layout(); plt.savefig("images/landmarks_2d.png",dpi=110); print("saved images/landmarks_2d.png")
