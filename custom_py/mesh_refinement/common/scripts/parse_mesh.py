# Parse the TFV .2dm mesh -> node coords + unique edges, converted to the plot_3d
# coordinate frame (matching generate_surface) so it drapes on the rtm terrain.
import numpy as np, rasterio
MESH=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\gis_repo\1_domain\mesh\csiem_mesh_B010_opt.2dm"
ds=rasterio.open("data/dem_coarse_fixed.tif"); dem=ds.read(1).astype(float); T=ds.transform
H,W=dem.shape                      # 847 x 419  (array rows=H=N-S, cols=W=E-W)
ZSCALE=0.4; RAISE=1.5
nodes={}; edges=set()
def add_edges(ns):
    for a in range(len(ns)):
        i,j=ns[a],ns[(a+1)%len(ns)]
        edges.add((i,j) if i<j else (j,i))
with open(MESH) as f:
    for line in f:
        t=line.split()
        if not t: continue
        if t[0]=="ND":
            nodes[int(t[1])]=(float(t[2]),float(t[3]))
        elif t[0]=="E3T":
            add_edges([int(t[2]),int(t[3]),int(t[4])])
        elif t[0]=="E4Q":
            add_edges([int(t[2]),int(t[3]),int(t[4]),int(t[5])])
print("nodes",len(nodes),"unique edges",len(edges))
xs=np.array([nodes[k][0] for k in sorted(nodes)]); ys=np.array([nodes[k][1] for k in sorted(nodes)])
print("node X range %.0f..%.0f  Y %.0f..%.0f"%(xs.min(),xs.max(),ys.min(),ys.max()))
print("DEM   X range %.0f..%.0f  Y %.0f..%.0f"%(T.c, T.c+W*T.a, T.f+H*T.e, T.f))
# node -> array pixel (continuous), then plot_3d coords
idmap={k:n for n,k in enumerate(sorted(nodes))}
pcol=(xs-T.c)/T.a                  # 0..W   (E-W)
prow=(ys-T.f)/T.e                  # 0..H   (N-S)
# sample DEM elevation (nearest, clamped)
ri=np.clip(np.round(prow).astype(int),0,H-1); ci=np.clip(np.round(pcol).astype(int),0,W-1)
elev=dem[ri,ci]; elev=np.where(np.isfinite(elev),elev,0.0)
# plot_3d frame (generate_surface): x=pcol-(W-1)/2, z=prow-(H-1)/2, y=elev/zscale + raise
px = pcol-(W-1)/2.0
pz = prow-(H-1)/2.0
py = elev/ZSCALE + RAISE/ZSCALE
np.savez("data/mesh_plot.npz",
         px=px.astype("float32"),py=py.astype("float32"),pz=pz.astype("float32"),
         e1=np.array([idmap[a] for a,b in sorted(edges)],dtype=np.int32),
         e2=np.array([idmap[b] for a,b in sorted(edges)],dtype=np.int32))
print("saved data/mesh_plot.npz")
