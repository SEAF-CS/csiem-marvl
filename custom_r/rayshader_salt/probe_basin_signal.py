import numpy as np, glob, rasterio
with rasterio.open("data/dem_coarse_fixed.tif") as ds: dem=ds.read(1).astype(float)
tifs=sorted(glob.glob("data/sal_bottom/sal_*.tif"))
def load(p):
    with rasterio.open(p) as ds: return ds.read(1).astype(float)
H,W=dem.shape
rr,cc=np.mgrid[0:H,0:W]
# candidate CS basin mask: deep central-south, exclude far-west offshore (cols<55)
basin = (dem < -8) & (rr>430) & (rr<810) & (cc>55) & (cc<235)
print("basin mask cells:", int(basin.sum()))
print(" frame  basin: mean   p50   p90   max     |  offshore(cols<50) mean")
off = (dem<0) & (cc<50)
for i,p in enumerate(tifs):
    a=load(p); b=a[basin]; b=b[np.isfinite(b)]
    o=a[off]; o=o[np.isfinite(o)]
    if i%6==0 or i in (28,30,40,59):
        print(" %3d    %.3f %.3f %.3f %.3f   |  %.3f"%(
            i, np.mean(b),np.percentile(b,50),np.percentile(b,90),np.max(b), np.mean(o) if o.size else np.nan))
allb=np.concatenate([load(p)[basin][np.isfinite(load(p)[basin])] for p in tifs])
print("\nBASIN bottom-sal overall: p2 %.3f  p50 %.3f  p98 %.3f  max %.3f"%(
    np.percentile(allb,2),np.percentile(allb,50),np.percentile(allb,98),np.max(allb)))
