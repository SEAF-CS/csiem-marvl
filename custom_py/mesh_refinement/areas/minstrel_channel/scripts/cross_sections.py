import numpy as np, rasterio, netCDF4 as nc, matplotlib, os
matplotlib.use("Agg"); import matplotlib.pyplot as plt
import matplotlib.tri as mtri
from matplotlib.gridspec import GridSpec
from rasterio.windows import Window
from rasterio.warp import transform as wt
from scipy.spatial import cKDTree
DEM=r"X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif"; NCF=r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
NW=float(os.environ.get("NW","1140")); SE=float(os.environ.get("SE","1050"))
NXS=int(os.environ.get("NXS","10")); HALF=float(os.environ.get("HALF","700")); M=241
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs; W=ds.width; Hh=ds.height
lo=[115.62,115.78,115.62,115.78]; la=[-32.05,-32.05,-32.20,-32.20]
Xb,Yb=wt("EPSG:4326",crs,lo,la)
c0=max(0,int(min((x-T.c)/T.a for x in Xb))); c1=min(W,int(max((x-T.c)/T.a for x in Xb)))
r0=max(0,int(min((y-T.f)/T.e for y in Yb))); r1=min(Hh,int(max((y-T.f)/T.e for y in Yb)))
dem=ds.read(1,window=Window(c0,r0,c1-c0,r1-r0)).astype(float); dem[dem>1e30]=np.nan
H2,W2=dem.shape; Xl=T.c+c0*T.a; Xr=T.c+c1*T.a; Ytop=T.f+r0*T.e; Ybot=T.f+r1*T.e
# main thalweg endpoints (same as transect_compare2)
SC0,SC1=int(0.40*W2),int(0.70*W2); RR0,RR1=int(0.05*H2),int(0.78*H2)
rows=np.arange(RR0,RR1); sub=dem[RR0:RR1,SC0:SC1]; tcol=SC0+np.nanargmin(np.where(np.isfinite(sub),sub,1e9),axis=1)
Xt=T.c+(c0+tcol+0.5)*T.a; Yt=T.f+(r0+rows+0.5)*T.e
P=np.c_[Xt,Yt]; m=P.mean(0); _,_,vt=np.linalg.svd(P-m); dv=vt[0]; pr=(P-m)@dv
pN=m+dv*pr.min(); pS=m+dv*pr.max()
if pN[1]<pS[1]: pN,pS=pS,pN
pN=np.array(pN,float); pS=np.array(pS,float); pN[0]-=NW; pS[0]+=SE
axis=pS-pN; L=np.hypot(*axis); u=axis/L; perp=np.array([-u[1],u[0]])
# triangulated mesh for point-in-cell cell_Zb
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
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=np.asarray(d.variables['cell_Zb'][:])
CX,CY=wt("EPSG:4326",crs,cx.tolist(),cy.tolist()); CX=np.array(CX); CY=np.array(CY)
tree=cKDTree(np.c_[CX,CY])
tris=[]; tzb=[]
for e in elems:
    ei=[idm[n] for n in e]; _,ci=tree.query([NX[ei].mean(),NY[ei].mean()]); z=zb[ci]
    tris.append([ei[0],ei[1],ei[2]]); tzb.append(z)
    if len(ei)==4: tris.append([ei[0],ei[2],ei[3]]); tzb.append(z)
tris=np.array(tris); tzb=np.array(tzb)
triang=mtri.Triangulation(NX,NY,tris); finder=triang.get_trifinder()
# cross sections
centers_s=np.linspace(0.06,0.94,NXS)         # fractional along line
fig=plt.figure(figsize=(16,8.5)); gs=GridSpec(2,6,width_ratios=[1.5,1,1,1,1,1],height_ratios=[1,1],wspace=0.35,hspace=0.4)
axm=fig.add_subplot(gs[:,0]); axm.imshow(dem,cmap="turbo",vmin=-20,vmax=-5,extent=[Xl,Xr,Ybot,Ytop],origin="upper")
axm.plot([pN[0],pS[0]],[pN[1],pS[1]],"-",color="magenta",lw=1.5); axm.set_xlim(374500,380500); axm.set_ylim(6441000,6452800); axm.set_aspect("equal")
axm.set_title("transect + cross-sections"); axm.set_xlabel("Easting"); axm.set_ylabel("Northing")
w=np.linspace(-HALF,HALF,M)
for k,frac in enumerate(centers_s):
    C=pN+axis*frac
    X=C[0]+perp[0]*w; Y=C[1]+perp[1]*w
    demx=np.array([v[0] for v in ds.sample(np.c_[X,Y])],float); demx[demx>1e30]=np.nan
    ti=finder(X,Y); modx=np.where(ti>=0,tzb[ti],np.nan)
    axm.plot([X[0],X[-1]],[Y[0],Y[-1]],"-",color="white",lw=1.0)
    axm.text(C[0],C[1],str(k+1),color="white",fontsize=8,ha="center",va="center",weight="bold")
    ax=fig.add_subplot(gs[k//5, 1+(k%5)])
    ax.plot(w,demx,color="#1f77b4",lw=1.6,label="DEM")
    ax.plot(w,modx,color="#d62728",lw=1.5,drawstyle="steps-mid",label="model cell_Zb")
    ax.set_title("XS %d"%(k+1),fontsize=9); ax.grid(alpha=0.3); ax.tick_params(labelsize=7)
    ax.set_ylim(-22,-2)
    if k==0: ax.legend(fontsize=7,loc="lower center")
fig.suptitle("Channel cross-sections (perpendicular to thalweg): DEM vs model stepped cell_Zb   [x: across-channel m, N->S = XS1->%d]"%NXS,fontsize=12)
plt.savefig("outputs/cross_sections.png",dpi=120,facecolor="white",bbox_inches="tight"); print("saved",NXS,"cross-sections")
