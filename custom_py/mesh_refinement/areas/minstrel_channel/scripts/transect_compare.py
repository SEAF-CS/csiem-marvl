import numpy as np, rasterio, netCDF4 as nc, matplotlib, os
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from matplotlib.gridspec import GridSpec
from rasterio.windows import Window
from rasterio.warp import transform as wt
from scipy.spatial import cKDTree
DEM=r"X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif"; NCF=r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
NW=float(os.environ.get("NW","1150")); SE=float(os.environ.get("SE","1000"))   # locked thalweg endpoints
VMIN,VMAX=-20,-5; XLIM=(374500,380500); YLIM=(6441000,6452800)
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs; W=ds.width; Hh=ds.height
lo=[115.62,115.78,115.62,115.78]; la=[-32.05,-32.05,-32.20,-32.20]
Xb,Yb=wt("EPSG:4326",crs,lo,la)
c0=max(0,int(min((x-T.c)/T.a for x in Xb))); c1=min(W,int(max((x-T.c)/T.a for x in Xb)))
r0=max(0,int(min((y-T.f)/T.e for y in Yb))); r1=min(Hh,int(max((y-T.f)/T.e for y in Yb)))
dem=ds.read(1,window=Window(c0,r0,c1-c0,r1-r0)).astype(float); dem[dem>1e30]=np.nan
H2,W2=dem.shape; Xl=T.c+c0*T.a; Xr=T.c+c1*T.a; Ytop=T.f+r0*T.e; Ybot=T.f+r1*T.e
# thalweg trace -> PCA straight axis -> nudged endpoints
SC0,SC1=int(0.40*W2),int(0.70*W2); RR0,RR1=int(0.05*H2),int(0.78*H2)
rows=np.arange(RR0,RR1); sub=dem[RR0:RR1,SC0:SC1]
tcol=SC0+np.nanargmin(np.where(np.isfinite(sub),sub,1e9),axis=1)
Xt=T.c+(c0+tcol+0.5)*T.a; Yt=T.f+(r0+rows+0.5)*T.e
P=np.c_[Xt,Yt]; m=P.mean(0); _,_,vt=np.linalg.svd(P-m); dv=vt[0]; pr=(P-m)@dv
pN=m+dv*pr.min(); pS=m+dv*pr.max()
if pN[1]<pS[1]: pN,pS=pS,pN
pN=np.array(pN,float); pS=np.array(pS,float); pN[0]-=NW; pS[0]+=SE
N=350; tX=np.linspace(pN[0],pS[0],N); tY=np.linspace(pN[1],pS[1],N)
dist=np.concatenate([[0],np.cumsum(np.hypot(np.diff(tX),np.diff(tY)))])/1000.0
dem_prof=np.array([v[0] for v in ds.sample(np.c_[tX,tY])],float); dem_prof[dem_prof>1e30]=np.nan
tlon,tlat=wt(crs,"EPSG:4326",tX.tolist(),tY.tolist())
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=np.asarray(d.variables['cell_Zb'][:])
CX,CY=wt("EPSG:4326",crs,cx.tolist(),cy.tolist()); CX=np.array(CX); CY=np.array(CY)
_,it=cKDTree(np.c_[CX,CY]).query(np.c_[tX,tY]); mod_prof=zb[it]
# mesh polygons coloured by cell_Zb
nodes={}; elems=[]
with open(MESH) as f:
    for line in f:
        t=line.split()
        if not t: continue
        if t[0]=="ND": nodes[int(t[1])]=(float(t[2]),float(t[3]))
        elif t[0]=="E3T": elems.append([int(t[2]),int(t[3]),int(t[4])])
        elif t[0]=="E4Q": elems.append([int(t[2]),int(t[3]),int(t[4]),int(t[5])])
ks=sorted(nodes); idm={k:n for n,k in enumerate(ks)}
NLO=np.array([nodes[k][0] for k in ks]); NLA=np.array([nodes[k][1] for k in ks])
NX,NY=wt("EPSG:4326",crs,NLO.tolist(),NLA.tolist()); NX=np.array(NX); NY=np.array(NY)
polys=[]; pvals=[]
tree=cKDTree(np.c_[CX,CY])
for e in elems:
    xs=NX[[idm[n] for n in e]]; ys=NY[[idm[n] for n in e]]
    mx,my=xs.mean(),ys.mean()
    if XLIM[0]-300<=mx<=XLIM[1]+300 and YLIM[0]-300<=my<=YLIM[1]+300:
        _,ci=tree.query([mx,my]); polys.append(np.c_[xs,ys]); pvals.append(zb[ci])
print("MEANDEM %.2f | polys %d | DEM %.1f..%.1f model %.1f..%.1f"%(np.nanmean(dem_prof),len(polys),np.nanmin(dem_prof),np.nanmax(dem_prof),mod_prof.min(),mod_prof.max()))
# figure: DEM map | model cell_Zb map | profile
fig=plt.figure(figsize=(17,8.2)); gs=GridSpec(1,3,width_ratios=[1,1,1.35],wspace=0.28)
def drawline(ax):
    ax.plot([pN[0],pS[0]],[pN[1],pS[1]],"-",color="white",lw=3); ax.plot([pN[0],pS[0]],[pN[1],pS[1]],"-",color="magenta",lw=1.4)
    ax.plot(*pN,"o",color="lime",ms=7,mec="k"); ax.plot(*pS,"o",color="cyan",ms=7,mec="k")
    ax.set_xlim(*XLIM); ax.set_ylim(*YLIM); ax.set_aspect("equal"); ax.set_xlabel("Easting (m)")
axA=fig.add_subplot(gs[0]); imA=axA.imshow(dem,cmap="turbo",vmin=VMIN,vmax=VMAX,extent=[Xl,Xr,Ybot,Ytop],origin="upper")
drawline(axA); axA.set_ylabel("Northing (m)"); axA.set_title("High-res DEM")
axB=fig.add_subplot(gs[1]); pc=PolyCollection(polys,array=np.array(pvals),cmap="turbo",edgecolors="0.25",linewidths=0.12)
pc.set_clim(VMIN,VMAX); axB.add_collection(pc); drawline(axB); axB.set_title("Model mesh: cell_Zb")
fig.colorbar(pc,ax=[axA,axB],shrink=0.7,label="bed elevation (m)",location="bottom",pad=0.08,aspect=40)
axC=fig.add_subplot(gs[2])
axC.plot(dist,dem_prof,color="#1f77b4",lw=1.9,label="High-res DEM")
axC.step(dist,mod_prof,color="#d62728",lw=1.7,where="mid",label="Model cell_Zb")
axC.set_xlabel("distance along transect (km)   N -> S"); axC.set_ylabel("bed elevation (m)")
axC.set_title("Thalweg transect: model vs DEM"); axC.legend(loc="lower right"); axC.grid(alpha=0.3)
fig.suptitle("Cockburn Sound entrance channel — model bathymetry vs high-res DEM",fontsize=14)
plt.savefig("outputs/transect_compare.png",dpi=120,facecolor="white",bbox_inches="tight"); print("saved")
