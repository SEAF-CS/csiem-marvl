import numpy as np, matplotlib, netCDF4 as nc
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from scipy.spatial import cKDTree
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
NCF =r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
LATMIN,LATMAX=-32.20,-32.05; LONMIN_A,LONMAX_A=115.62,115.79   # area of interest
VMIN,VMAX=-20,-5                    # brightened colour range
# mesh
nodes={}; elems=[]
with open(MESH) as f:
    for line in f:
        t=line.split()
        if not t: continue
        if t[0]=="ND": nodes[int(t[1])]=(float(t[2]),float(t[3]))
        elif t[0]=="E3T": elems.append([int(t[2]),int(t[3]),int(t[4])])
        elif t[0]=="E4Q": elems.append([int(t[2]),int(t[3]),int(t[4]),int(t[5])])
cen=np.array([[np.mean([nodes[n][0] for n in e]),np.mean([nodes[n][1] for n in e])] for e in elems])
# model cell depths (cell_Zb) matched to mesh cells by nearest centroid
d=nc.Dataset(NCF); cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=d.variables['cell_Zb'][:]
print("n elems",len(elems),"n NC cells",len(cx))
_,idx=cKDTree(np.c_[cx,cy]).query(cen)
zb_el=np.asarray(zb)[idx]
# clip to lat band
keep=(cen[:,1]>=LATMIN)&(cen[:,1]<=LATMAX)&(cen[:,0]>=LONMIN_A)&(cen[:,0]<=LONMAX_A)
polys=[[(nodes[n][0],nodes[n][1]) for n in e] for e,k in zip(elems,keep) if k]
vals=zb_el[keep]
lons=np.array([p[0] for poly in polys for p in poly]); LONMIN,LONMAX=lons.min(),lons.max()
print("cells in band",len(polys),"| lon %.3f..%.3f"%(LONMIN,LONMAX))
fig,ax=plt.subplots(figsize=(7,9))
pc=PolyCollection(polys,array=vals,cmap="turbo",edgecolors="0.2",linewidths=0.15)
pc.set_clim(VMIN,VMAX); ax.add_collection(pc)
ax.set_xlim(LONMIN,LONMAX); ax.set_ylim(LATMIN,LATMAX); ax.set_aspect(1/np.cos(np.radians(32.1)))
plt.colorbar(pc,ax=ax,shrink=0.6,label="cell_Zb (m)  [clamped -20..-5]")
ax.set_title("Model mesh cell depth (cell_Zb) — channel N of Cockburn Sound\nlat -32.05..-32.2, N up",fontsize=11)
ax.set_xlabel("lon"); ax.set_ylabel("lat")
plt.tight_layout(); plt.savefig("outputs/mesh_depthmap.png",dpi=130,facecolor="white"); print("saved")
