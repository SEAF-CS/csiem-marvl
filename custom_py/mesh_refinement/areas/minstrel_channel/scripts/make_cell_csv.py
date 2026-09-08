# Minstrel cell-elevation override (WHOLE WINDOW, not a corridor).
# Same CSV format/approach as Success (Cell_ID,Z,old_cell_Zb,lon,lat) keyed by the .2dm element ID,
# but covers ALL cells whose centroid falls in the minstrel AOI (= the zb_dem_vs_model comparison
# window). New Z = DEM sampled at each cell centroid (the "DEM-based Zb").
# NOTE: references the O2Me 2025 EIA AHD survey (the bathy the mesh was actually built from -> mesh
# node Z matches it, mean ~0). Against this reference the model cell_Zb is UNBIASED (window mean diff
# ~0.00 m); differences are localised resolution detail, NOT a blanket offset, so a whole-window
# override is NOT warranted -- keep this builder for targeted/local overrides only. (The earlier ~0.7 m
# "model too deep" was an artifact of the wrong reference DEM cockburn_swan_2.tif, ~0.6 m off AHD.)
import numpy as np, rasterio, netCDF4 as nc, matplotlib, csv
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from rasterio.warp import transform as wt
from scipy.spatial import cKDTree
DEM=r"X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif"; NCF=r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
LON0,LON1=115.672,115.718; LAT0,LAT1=-32.276,-32.240    # minstrel window (matches the comparison)
ds=rasterio.open(DEM); crs=ds.crs
# parse mesh: element IDs + node connectivity
nodes={}; eid=[]; econ=[]
with open(MESH) as f:
    for line in f:
        t=line.split()
        if not t: continue
        if t[0]=="ND": nodes[int(t[1])]=(float(t[2]),float(t[3]))
        elif t[0]=="E3T": eid.append(int(t[1])); econ.append([int(t[2]),int(t[3]),int(t[4])])
        elif t[0]=="E4Q": eid.append(int(t[1])); econ.append([int(t[2]),int(t[3]),int(t[4]),int(t[5])])
ks=sorted(nodes); idm={k:n for n,k in enumerate(ks)}; eid=np.array(eid)
NLO=np.array([nodes[k][0] for k in ks]); NLA=np.array([nodes[k][1] for k in ks])
NX,NY=wt("EPSG:4326",crs,NLO.tolist(),NLA.tolist()); NX=np.array(NX); NY=np.array(NY)
cen_lo=np.array([NLO[[idm[n] for n in e]].mean() for e in econ]); cen_la=np.array([NLA[[idm[n] for n in e]].mean() for e in econ])
cenx=np.array([NX[[idm[n] for n in e]].mean() for e in econ]); ceny=np.array([NY[[idm[n] for n in e]].mean() for e in econ])
# model cell_Zb matched by nearest NC centroid
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=np.asarray(d.variables['cell_Zb'][:])
CX,CY=wt("EPSG:4326",crs,cx.tolist(),cy.tolist())
_,civ=cKDTree(np.c_[np.array(CX),np.array(CY)]).query(np.c_[cenx,ceny]); zb_el=zb[civ]
# DEM at centroid (the new Z)
zd=np.array([v[0] for v in ds.sample(np.c_[cenx,ceny])],float); zd[zd>1e30]=np.nan
# select cells whose centroid is in the window AND have a valid DEM value
sel=np.where((cen_lo>=LON0)&(cen_lo<=LON1)&(cen_la>=LAT0)&(cen_la<=LAT1)&np.isfinite(zd))[0]
ids=eid[sel]; znew=zd[sel]; old=zb_el[sel]; clon=cen_lo[sel]; clat=cen_la[sel]; chg=znew-old   # + = raised/shallower
# write CSV (same columns as the Success override)
with open("outputs/cell_elevation_minstrel.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["Cell_ID","Z","old_cell_Zb","lon","lat"])
    for i in range(len(sel)):
        w.writerow([int(ids[i]),round(float(znew[i]),3),round(float(old[i]),3),round(float(clon[i]),6),round(float(clat[i]),6)])
print("window cells written: %d | new Z %.2f..%.2f | old %.2f..%.2f"%(len(sel),np.nanmin(znew),np.nanmax(znew),old.min(),old.max()))
print("change (new-old): mean %+.2f median %+.2f m | raised %d / lowered %d | now >=0 m (dry): %d"%(
      float(np.mean(chg)),float(np.median(chg)),int(np.sum(chg>0)),int(np.sum(chg<0)),int(np.sum(znew>=0))))
# verification figure: new-Z map + applied-change map
polys=[np.c_[NX[[idm[n] for n in econ[i]]],NY[[idm[n] for n in econ[i]]]] for i in sel]
Xl,Xr=cenx[sel].min()-200,cenx[sel].max()+200; Yb,Yt=ceny[sel].min()-200,ceny[sel].max()+200
fig=plt.figure(figsize=(14,8))
axm=fig.add_subplot(1,2,1)
pc=PolyCollection(polys,array=znew,cmap="turbo",edgecolors="0.3",linewidths=0.12); pc.set_clim(-16,0); axm.add_collection(pc)
fig.colorbar(pc,ax=axm,shrink=0.6,label="new Z = DEM-at-centroid (m)")
axm.set_xlim(Xl,Xr); axm.set_ylim(Yb,Yt); axm.set_aspect("equal"); axm.set_title("Override: new cell Z (DEM-at-centroid)"); axm.set_xlabel("Easting (m)"); axm.set_ylabel("Northing (m)")
axc=fig.add_subplot(1,2,2)
pc2=PolyCollection(polys,array=chg,cmap="coolwarm",edgecolors="0.3",linewidths=0.12); pc2.set_clim(-5,5); axc.add_collection(pc2)
fig.colorbar(pc2,ax=axc,shrink=0.6,label="change new-old (m) [+ = raised/shallower]")
axc.set_xlim(Xl,Xr); axc.set_ylim(Yb,Yt); axc.set_aspect("equal"); axc.set_title("Applied change (new - old), mean %+.2f m"%float(np.mean(chg))); axc.set_xlabel("Easting (m)")
plt.tight_layout(); plt.savefig("outputs/cell_override_check.png",dpi=130); print("saved CSV + cell_override_check.png")
