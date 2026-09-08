import numpy as np, rasterio, netCDF4 as nc, matplotlib, os
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection, LineCollection
from rasterio.windows import Window
from rasterio.warp import transform as wt
from scipy.spatial import cKDTree
DEM=r"X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif"; NCF=r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
NW=float(os.environ.get("NW","1140")); SE=float(os.environ.get("SE","1050"))
CH=float(os.environ.get("CH","130"))          # corridor half-width (m) perpendicular to line
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs; W=ds.width; Hh=ds.height
lo=[115.62,115.78,115.62,115.78]; la=[-32.05,-32.05,-32.20,-32.20]; Xb,Yb=wt("EPSG:4326",crs,lo,la)
c0=max(0,int(min((x-T.c)/T.a for x in Xb))); c1=min(W,int(max((x-T.c)/T.a for x in Xb)))
r0=max(0,int(min((y-T.f)/T.e for y in Yb))); r1=min(Hh,int(max((y-T.f)/T.e for y in Yb)))
dem=ds.read(1,window=Window(c0,r0,c1-c0,r1-r0)).astype(float); dem[dem>1e30]=np.nan
H2,W2=dem.shape; Xl=T.c+c0*T.a; Xr=T.c+c1*T.a; Ytop=T.f+r0*T.e; Ybot=T.f+r1*T.e
# thalweg endpoints (same recipe)
SC0,SC1=int(0.40*W2),int(0.70*W2); RR0,RR1=int(0.05*H2),int(0.78*H2)
rows=np.arange(RR0,RR1); sub=dem[RR0:RR1,SC0:SC1]; tcol=SC0+np.nanargmin(np.where(np.isfinite(sub),sub,1e9),axis=1)
Xt=T.c+(c0+tcol+0.5)*T.a; Yt=T.f+(r0+rows+0.5)*T.e
P=np.c_[Xt,Yt]; m=P.mean(0); _,_,vt=np.linalg.svd(P-m); dv=vt[0]; pr=(P-m)@dv
pN=m+dv*pr.min(); pS=m+dv*pr.max()
if pN[1]<pS[1]: pN,pS=pS,pN
pN=np.array(pN,float); pS=np.array(pS,float); pN[0]-=NW; pS[0]+=SE
axis=pS-pN; L=np.hypot(*axis); u=axis/L
# parse mesh: keep element IDs + node ids
nodes={}; eid=[]; econ=[]
with open(MESH) as f:
    for line in f:
        t=line.split()
        if not t: continue
        if t[0]=="ND": nodes[int(t[1])]=(float(t[2]),float(t[3]))
        elif t[0]=="E3T": eid.append(int(t[1])); econ.append([int(t[2]),int(t[3]),int(t[4])])
        elif t[0]=="E4Q": eid.append(int(t[1])); econ.append([int(t[2]),int(t[3]),int(t[4]),int(t[5])])
ks=sorted(nodes); idm={k:n for n,k in enumerate(ks)}
NLO=np.array([nodes[k][0] for k in ks]); NLA=np.array([nodes[k][1] for k in ks])
NX,NY=wt("EPSG:4326",crs,NLO.tolist(),NLA.tolist()); NX=np.array(NX); NY=np.array(NY)
cenx=np.array([NX[[idm[n] for n in e]].mean() for e in econ]); ceny=np.array([NY[[idm[n] for n in e]].mean() for e in econ])
eid=np.array(eid)
# cell_Zb (NC) matched to element by nearest centroid
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=np.asarray(d.variables['cell_Zb'][:])
CX,CY=wt("EPSG:4326",crs,cx.tolist(),cy.tolist()); CX=np.array(CX); CY=np.array(CY)
_,ci=cKDTree(np.c_[CX,CY]).query(np.c_[cenx,ceny]); zb_el=zb[ci]
# perp distance + along-param for each element centroid
vx=cenx-pN[0]; vy=ceny-pN[1]; t=(vx*u[0]+vy*u[1])/L; perp=np.abs(vx*(-u[1])+vy*u[0])
sel=(perp<CH)&(t>=0)&(t<=1)
# cell size estimate (sqrt area approx via bbox)
def csize(e):
    xs=NX[[idm[n] for n in e]]; ys=NY[[idm[n] for n in e]]; return np.hypot(xs.max()-xs.min(),ys.max()-ys.min())
sizes=np.array([csize(econ[i]) for i in np.where(sel)[0]]) if sel.any() else np.array([0])
print("CH=%g m -> %d cells | median cell diag %.0f m | cell_Zb in corridor: min %.2f max %.2f"%(CH,sel.sum(),np.median(sizes),zb_el[sel].min(),zb_el[sel].max()))
print("element IDs:", " ".join(map(str,eid[sel])))
# plot
fig,ax=plt.subplots(figsize=(8,11))
ax.imshow(dem,cmap="turbo",vmin=-20,vmax=-5,extent=[Xl,Xr,Ybot,Ytop],origin="upper")
allpoly=[np.c_[NX[[idm[n] for n in e]],NY[[idm[n] for n in e]]] for e in econ]
ax.add_collection(LineCollection([p[list(range(len(p)))+[0]] for p in [allpoly[i] for i in np.where((np.abs(perp)<600)&(t>-0.1)&(t<1.1))[0]]],colors="k",lw=0.3,alpha=0.5))
hi=PolyCollection([allpoly[i] for i in np.where(sel)[0]],facecolors="none",edgecolors="magenta",linewidths=1.4)
ax.add_collection(hi)
for i in np.where(sel)[0]: ax.text(cenx[i],ceny[i],str(eid[i]),fontsize=8,ha="center",va="center",color="white")
ax.plot([pN[0],pS[0]],[pN[1],pS[1]],"-",color="white",lw=1.2)
ax.set_xlim(376600,378000); ax.set_ylim(6446000,6448200); ax.set_aspect("equal")
ax.set_title("Channel corridor cells (magenta, CH=%g m) with element IDs"%CH)
plt.tight_layout(); plt.savefig("outputs/channel_cells.png",dpi=130); print("saved outputs/channel_cells.png")

# ---- DEM at centroid + along-line distance for corridor cells (to pick the deep central stretch) ----
import sys
ids_sel=eid[sel]; cenx_s=cenx[sel]; ceny_s=ceny[sel]; zb_s=zb_el[sel]; t_s=t[sel]
dem_cen=np.array([v[0] for v in ds.sample(np.c_[cenx_s,ceny_s])],float); dem_cen[dem_cen>1e30]=np.nan
dkm=t_s*L/1000.0
o=np.argsort(dkm)
import matplotlib.pyplot as plt
fig,ax=plt.subplots(figsize=(11,4))
ax.plot(dkm[o],dem_cen[o],".",ms=4,color="#1f77b4",label="DEM @ cell centroid")
ax.plot(dkm[o],zb_s[o],".",ms=3,color="#d62728",alpha=0.6,label="current cell_Zb")
ax.set_xlabel("along-line distance (km)  N->S"); ax.set_ylabel("bed elev (m)"); ax.grid(alpha=0.3); ax.legend()
ax.set_title("Corridor cells along the line (pick deep central stretch to keep)")
plt.tight_layout(); plt.savefig("outputs/corridor_profile.png",dpi=120); 
print("ALONG-LINE: dist 0..%.1f km | DEM@cen %.1f..%.1f | cells %d"%(dkm.max(),np.nanmin(dem_cen),np.nanmax(dem_cen),sel.sum()))
