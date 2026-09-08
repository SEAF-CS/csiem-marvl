import numpy as np, rasterio, netCDF4 as nc, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from rasterio.warp import transform as wt
from scipy.spatial import cKDTree
from scipy.ndimage import uniform_filter1d
DEM=r"data/cockburn_swan_2.tif"; NCF=r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
c0,r0,c1,r1=np.load("data/_chan_win.npy")
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs
dem=ds.read(1,window=rasterio.windows.Window(c0,r0,c1-c0,r1-r0)).astype(float); dem[dem>1e30]=np.nan
H,W=dem.shape
# --- thalweg ---
SC0,SC1=620,820; RR0,RR1=150,920
rows=np.arange(RR0,RR1); sub=dem[RR0:RR1,SC0:SC1]
cols=SC0+np.nanargmin(np.where(np.isfinite(sub),sub,1e9),axis=1)
cols=uniform_filter1d(cols.astype(float),21).astype(int)
fullc=c0+cols; fullr=r0+rows
X=T.c+(fullc+0.5)*T.a; Y=T.f+(fullr+0.5)*T.e
lon,lat=wt(crs,"EPSG:4326",X.tolist(),Y.tolist()); lon=np.array(lon); lat=np.array(lat)
dist=np.concatenate([[0],np.cumsum(np.hypot(np.diff(X),np.diff(Y)))])/1000.0
dem_prof=dem[rows,cols]
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=np.asarray(d.variables['cell_Zb'][:])
_,idx=cKDTree(np.c_[cx,cy]).query(np.c_[lon,lat]); mod_prof=zb[idx]
# --- mesh edges -> crop pixels (for the left panel) ---
nodes={}; edges=set()
def ae(ns):
    for a in range(len(ns)):
        i,j=ns[a],ns[(a+1)%len(ns)]; edges.add((i,j) if i<j else (j,i))
with open(MESH) as f:
    for line in f:
        t=line.split()
        if not t: continue
        if t[0]=="ND": nodes[int(t[1])]=(float(t[2]),float(t[3]))
        elif t[0]=="E3T": ae([int(t[2]),int(t[3]),int(t[4])])
        elif t[0]=="E4Q": ae([int(t[2]),int(t[3]),int(t[4]),int(t[5])])
ks=sorted(nodes); idm={k:n for n,k in enumerate(ks)}
nlon=np.array([nodes[k][0] for k in ks]); nlat=np.array([nodes[k][1] for k in ks])
NX,NY=wt("EPSG:4326",crs,nlon.tolist(),nlat.tolist()); NX=np.array(NX); NY=np.array(NY)
npc=(NX-T.c)/T.a-c0; npr=(NY-T.f)/T.e-r0     # crop pixel coords
segs=[]
for a,b in edges:
    ia,ib=idm[a],idm[b]
    if (0<=npc[ia]<W and 0<=npr[ia]<H) or (0<=npc[ib]<W and 0<=npr[ib]<H):
        segs.append([(npc[ia],npr[ia]),(npc[ib],npr[ib])])
print("transect %.1f km %d pts | mesh segs in view %d"%(dist[-1],len(dist),len(segs)))
# --- figure ---
fig=plt.figure(figsize=(13.5,7.5))
ax0=fig.add_subplot(1,2,1)
im=ax0.imshow(dem,cmap="turbo",vmin=-20,vmax=-5)
ax0.add_collection(LineCollection(segs,colors="k",linewidths=0.25,alpha=0.5))
ax0.plot(cols,rows,"w-",lw=2.0); ax0.plot(cols,rows,"-",color="magenta",lw=1.0)
ax0.set_xlim(400,1100); ax0.set_ylim(1100,100)
ax0.set_title("DEM (turbo) + model mesh + transect (magenta)"); plt.colorbar(im,ax=ax0,shrink=0.6,label="DEM elev (m)")
ax1=fig.add_subplot(1,2,2)
ax1.plot(dist,dem_prof,color="#1f77b4",lw=1.8,label="High-res DEM (thalweg)")
ax1.step(dist,mod_prof,color="#d62728",lw=1.6,where="mid",label="Model cell_Zb (nearest cell)")
ax1.set_xlabel("distance along channel (km)   N -> S"); ax1.set_ylabel("bed elevation (m)")
ax1.set_title("Channel thalweg: model vs DEM bathymetry"); ax1.legend(loc="lower right"); ax1.grid(alpha=0.3)
plt.tight_layout(); plt.savefig("images/transect_compare.png",dpi=120,facecolor="white"); print("saved")
