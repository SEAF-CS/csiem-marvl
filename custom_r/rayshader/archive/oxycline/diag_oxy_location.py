# Diagnostic: does the interface GeoTIFF land where the model's <6 mg/L columns are?
import numpy as np, netCDF4 as nc, datetime as dt
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
import geopandas as gpd, rasterio
from rasterio.warp import transform as warp_transform

F=r"W:\WAMSI\1.7\SH-20251123-1.7.0\2023B-20251124150126\results\csiem_B010_20221101_20240401_WQ_WQ.nc"
SHP=r"G:\CSIEM\1.8.0\csiem-marvl\gis\Curtain\New_Curtain_line_LL_100m.shp"
TIF=r"G:\CSIEM\1.8.0\csiem-marvl\rayshader\data\oxy6_iface_20240123.tif"

d=nc.Dataset(F)
NL=d.variables['NL'][:].astype(int); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]
cell_start=np.concatenate([[0],np.cumsum(NL)[:-1]])
T=d.variables['ResTime']; times=nc.num2date(T[:],T.units)
tt=np.array([dt.datetime(x.year,x.month,x.day,x.hour) for x in times])
ti=int(np.where(tt==dt.datetime(2024,1,23,0))[0][0])
O2=np.asarray(d.variables['WQ_OXY_OXY'][ti,:],dtype=float)/31.25
o2_min=np.array([np.nanmin(O2[cell_start[c]:cell_start[c]+NL[c]]) if NL[c]>0 else np.nan for c in range(len(NL))])

xlim=(115.6254,115.8073); ylim=(-32.2779,-31.97073)
m=(cx>xlim[0])&(cx<xlim[1])&(cy>ylim[0])&(cy<ylim[1])
cross=m&(o2_min<6.0)

# interface tif -> reproject its non-NA cell centres back to lon/lat
with rasterio.open(TIF) as ds:
    arr=ds.read(1); tr=ds.transform; crs=ds.crs
rr,cc=np.where(np.isfinite(arr))
ex=tr.c+(cc+0.5)*tr.a; ny=tr.f+(rr+0.5)*tr.e
# subsample for plotting
k=max(1,len(ex)//8000); ex,ny=ex[::k],ny[::k]
tlon,tlat=warp_transform(crs,"EPSG:4326",ex.tolist(),ny.tolist())

gdf=gpd.read_file(SHP);
if gdf.crs.to_epsg()!=4326: gdf=gdf.to_crs(4326)

fig,ax=plt.subplots(figsize=(9,12))
sc=ax.scatter(cx[m],cy[m],c=o2_min[m],s=8,cmap="RdBu",vmin=5.0,vmax=8.0)
ax.scatter(cx[cross],cy[cross],s=22,facecolors='none',edgecolors='lime',lw=0.7,label="model col-min <6 mg/L")
ax.scatter(np.array(tlon),np.array(tlat),s=3,c='black',label="interface TIF footprint")
ax.plot(gdf.geometry.x,gdf.geometry.y,'m-',lw=2,label="curtain line")
ax.set_xlim(xlim); ax.set_ylim(ylim); ax.set_aspect('equal')
ax.set_title("col-min O2 (mg/L) 2024-01-23 | green=model<6 | black=TIF | magenta=curtain")
ax.legend(loc='lower left',fontsize=8); plt.colorbar(sc,ax=ax,fraction=0.035,label="O2 mg/L")
for lab,xy in [("Garden Is.",(115.68,-32.17)),("Kwinana Shelf (E)",(115.785,-32.20)),
               ("Central basin",(115.715,-32.155)),("Causeway (S)",(115.70,-32.245)),
               ("Owen Anch. (N)",(115.74,-32.05))]:
    ax.annotate(lab,xy,fontsize=8,color='purple',fontweight='bold')
fig.tight_layout(); fig.savefig(r"G:\CSIEM\1.8.0\csiem-marvl\rayshader\images\_diag_bottomO2.png",dpi=115)
print("crossings in extent:",cross.sum(),"| tif pts plotted:",len(tlon))
print("wrote images/_diag_bottomO2.png")
