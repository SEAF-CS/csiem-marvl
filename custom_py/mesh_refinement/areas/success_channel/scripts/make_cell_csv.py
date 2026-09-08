import numpy as np, rasterio, netCDF4 as nc, matplotlib, csv, os
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from rasterio.windows import Window
from rasterio.warp import transform as wt
from scipy.spatial import cKDTree
DEM=r"X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif"; NCF=r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
NW,SE=1140.,1050.; CH=75.; KEEP_KM=(1.0,9.0)
ds=rasterio.open(DEM); T=ds.transform; crs=ds.crs; W=ds.width; Hh=ds.height
lo=[115.62,115.78,115.62,115.78]; la=[-32.05,-32.05,-32.20,-32.20]; Xb,Yb=wt("EPSG:4326",crs,lo,la)
c0=max(0,int(min((x-T.c)/T.a for x in Xb))); c1=min(W,int(max((x-T.c)/T.a for x in Xb)))
r0=max(0,int(min((y-T.f)/T.e for y in Yb))); r1=min(Hh,int(max((y-T.f)/T.e for y in Yb)))
dem=ds.read(1,window=Window(c0,r0,c1-c0,r1-r0)).astype(float); dem[dem>1e30]=np.nan
H2,W2=dem.shape; Xl=T.c+c0*T.a; Xr=T.c+c1*T.a; Ytop=T.f+r0*T.e; Ybot=T.f+r1*T.e
SC0,SC1=int(0.40*W2),int(0.70*W2); RR0,RR1=int(0.05*H2),int(0.78*H2)
rows=np.arange(RR0,RR1); sub=dem[RR0:RR1,SC0:SC1]; tcol=SC0+np.nanargmin(np.where(np.isfinite(sub),sub,1e9),axis=1)
Xt=T.c+(c0+tcol+0.5)*T.a; Yt=T.f+(r0+rows+0.5)*T.e
P=np.c_[Xt,Yt]; m=P.mean(0); _,_,vt=np.linalg.svd(P-m); dv=vt[0]; pr=(P-m)@dv
pN=m+dv*pr.min(); pS=m+dv*pr.max()
if pN[1]<pS[1]: pN,pS=pS,pN
pN=np.array(pN,float); pS=np.array(pS,float); pN[0]-=NW; pS[0]+=SE
axis=pS-pN; L=np.hypot(*axis); u=axis/L
PERP_OFF=-32.0   # O2Me thalweg trace ran ON the east cell row; shift line perp ~32 m W to sit BETWEEN the two flanking rows
_n=np.array([-u[1],u[0]]); pN=pN+PERP_OFF*_n; pS=pS+PERP_OFF*_n
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
cenx=np.array([NX[[idm[n] for n in e]].mean() for e in econ]); ceny=np.array([NY[[idm[n] for n in e]].mean() for e in econ]); eid=np.array(eid)
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=np.asarray(d.variables['cell_Zb'][:])
CX,CY=wt("EPSG:4326",crs,cx.tolist(),cy.tolist()); CX=np.array(CX); CY=np.array(CY)
_,civ=cKDTree(np.c_[CX,CY]).query(np.c_[cenx,ceny]); zb_el=zb[civ]
vx=cenx-pN[0]; vy=ceny-pN[1]; t=(vx*u[0]+vy*u[1])/L; perp=np.abs(vx*(-u[1])+vy*u[0]); dkm=t*L/1000.
sel=(perp<CH)&(dkm>=KEEP_KM[0])&(dkm<=KEEP_KM[1])
# new depth = DEM at centroid
zd=np.array([v[0] for v in ds.sample(np.c_[cenx[sel],ceny[sel]])],float); zd[zd>1e30]=np.nan
dkm_s=dkm[sel]
# --- manual tweaks below were eyeballed on the OLD cockburn DEM (~0.7 m too shallow vs O2Me AHD).
#     They set ABSOLUTE depths, so on the ~0.7 m-deeper O2Me base they would re-introduce shallow
#     spots -> DISABLED for the O2Me redo; re-derive from the new transect/corridor profile. ---
#_adj=(dkm_s>=8.75)&(dkm_s<=9.0); zd[_adj]-=1.0          # deepen 8.75-9.0 km by 1 m
#_last=int(np.argmax(dkm_s)); zd[_last]=-17.0                 # very last cell -> -17 m
#_emound=np.isin(eid[sel],[6928,6929,7166]); zd[_emound]=-14.0  # EAST line ~8.1-8.4 km mound -> drop to -14 m
#print("ADJ: %d cells in 8.75-9.0 km got -1 m; last cell id %d -> -17"%(int(_adj.sum()),int(eid[sel][_last])))
#print("EAST mound fix: %d cells -> -14 m (ids %s)"%(int(_emound.sum())," ".join(map(str,eid[sel][_emound].tolist()))))
ids=eid[sel]; old=zb_el[sel]
clon,clat=wt(crs,"EPSG:4326",cenx[sel].tolist(),ceny[sel].tolist())
# write CSV
with open("outputs/cell_elevation_channel.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["Cell_ID","Z","old_cell_Zb","lon","lat"])
    for i in range(sel.sum()):
        if np.isfinite(zd[i]): w.writerow([int(ids[i]),round(float(zd[i]),3),round(float(old[i]),3),round(float(clon[i]),6),round(float(clat[i]),6)])
nvalid=int(np.isfinite(zd).sum())
print("cells kept %d (valid DEM %d) | new Z %.2f..%.2f | old %.2f..%.2f | mean deepening %.2f m"%(
      sel.sum(),nvalid,np.nanmin(zd),np.nanmax(zd),old.min(),old.max(),np.nanmean(old-zd)))
# verification figure: map (cells coloured by NEW depth) + before/after profile
fig=plt.figure(figsize=(14,7)); 
axm=fig.add_subplot(1,2,1); axm.imshow(dem,cmap="turbo",vmin=-20,vmax=-5,extent=[Xl,Xr,Ybot,Ytop],origin="upper")
polys=[np.c_[NX[[idm[n] for n in econ[i]]],NY[[idm[n] for n in econ[i]]]] for i in np.where(sel)[0]]
pc=PolyCollection(polys,array=zd,cmap="turbo",edgecolors="k",linewidths=0.2); pc.set_clim(-20,-5); axm.add_collection(pc)
axm.plot([pN[0],pS[0]],[pN[1],pS[1]],"w-",lw=1); axm.set_xlim(375500,379500); axm.set_ylim(6443000,6452500); axm.set_aspect("equal")
axm.set_title("Override cells (filled = new DEM-centroid depth)")
ax=fig.add_subplot(1,2,2)
# classify the 2 corridor columns as WEST / EAST by signed perpendicular offset
nrm=np.array([-u[1],u[0]]); vxs=cenx[sel]-pN[0]; vys=ceny[sel]-pN[1]; signed=vxs*nrm[0]+vys*nrm[1]
dks=dkm[sel]
if cenx[sel][signed<0].mean() < cenx[sel][signed>0].mean(): west=signed<0; east=signed>0
else: west=signed>0; east=signed<0
def L_(mask,vals,style,col,lab):
    i=np.where(mask)[0]; o=i[np.argsort(dks[i])]; ax.plot(dks[o],vals[o],style,color=col,lw=1.6,label=lab)
L_(west, zd, "-",  "#1f77b4", "new W (solid)")
L_(east, zd, ":",  "#1f77b4", "new E (dotted)")
L_(west, old,"-",  "#d62728", "old W")
L_(east, old,":",  "#d62728", "old E")
ax.set_xlabel("along-line km N->S"); ax.set_ylabel("bed elev (m)"); ax.grid(alpha=0.3); ax.legend(fontsize=8); ax.set_title("Channel depth per cell-row: West (solid) vs East (dotted)")
plt.tight_layout(); plt.savefig("outputs/cell_override_check.png",dpi=120); print("saved CSV + cell_override_check.png")
