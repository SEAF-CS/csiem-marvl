# Extract the O2 = 6 mg/L isosurface elevation (per water column) from the WQ run
# at 2024-01-23 00:00, project to the DEM grid (EPSG:28350), and write a GeoTIFF
# aligned to data/cockburn_swan_2.tif for overlay in rayshader.
import numpy as np, netCDF4 as nc, datetime as dt
import rasterio
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata

F   = r"W:\WAMSI\1.7\SH-20251123-1.7.0\2023B-20251124150126\results\csiem_B010_20221101_20240401_WQ_WQ.nc"
DEM = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/cockburn_swan_2.tif"
OUT = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/oxy6_iface_20240123.tif"
THR_MGL = 6.0
THR = THR_MGL * 31.25          # -> mmol/m3
WHEN = dt.datetime(2024, 1, 23, 0)

d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int)
cx = d.variables['cell_X'][:]; cy = d.variables['cell_Y'][:]
cell_start = np.concatenate([[0], np.cumsum(NL)[:-1]])
face_start = np.concatenate([[0], np.cumsum(NL + 1)[:-1]])
T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year, x.month, x.day, x.hour) for x in times])
ti = int(np.where(tt == WHEN)[0][0])
print("timestep", ti, str(times[ti])[:16])

O2  = np.asarray(d.variables['WQ_OXY_OXY'][ti, :], dtype=float)
lfZ = np.asarray(d.variables['layerface_Z'][ti, :], dtype=float)
print("domain O2 (mmol/m3): min=%.1f (%.2f mg/L)  median=%.1f" % (
      np.nanmin(O2), np.nanmin(O2)/31.25, np.nanmedian(O2)))

lon, lat, ziface = [], [], []
n_cross = 0
for c in range(len(NL)):
    nl = NL[c]
    if nl < 2:
        continue
    cs = cell_start[c]; fs = face_start[c]
    o2 = O2[cs:cs+nl]                                  # top -> bottom
    faces = lfZ[fs:fs+nl+1]
    cen = 0.5 * (faces[:-1] + faces[1:])               # cell-centre elevations, top->bottom
    if not np.all(np.isfinite(o2)):
        continue
    below = o2 < THR
    if not below.any():
        continue                                       # whole column above threshold -> no surface
    k = int(np.argmax(below))                          # first cell (from top) below threshold
    if k == 0:
        continue                                       # already <THR at surface (estuary/inland) -> skip
    o_hi, o_lo = o2[k-1], o2[k]; z_hi, z_lo = cen[k-1], cen[k]
    f = (o_hi - THR) / (o_hi - o_lo) if o_hi != o_lo else 0.0
    z = z_hi + f * (z_lo - z_hi)                       # linear interp to THR
    if z >= 0:
        continue                                       # keep sub-surface (marine) oxycline only
    lon.append(cx[c]); lat.append(cy[c]); ziface.append(z); n_cross += 1

lon = np.array(lon); lat = np.array(lat); ziface = np.array(ziface)
print("columns with a %.1f mg/L crossing: %d / %d" % (THR_MGL, n_cross, len(NL)))
if n_cross:
    print("interface elevation range: %.2f .. %.2f m" % (ziface.min(), ziface.max()))

# project model lon/lat -> DEM CRS, grid onto the DEM grid
MASK_DIST = 400.0          # m: blank grid cells farther than this from a real crossing column
with rasterio.open(DEM) as ds:
    prof = ds.profile; tr = ds.transform; W, H = ds.width, ds.height; dem_crs = ds.crs
    dem = ds.read(1).astype(float)                     # bed/land elevation (>=0 = land)
px, py = warp_transform("EPSG:4326", dem_crs, lon.tolist(), lat.tolist())
px = np.array(px); py = np.array(py)
cols = np.arange(W); rows = np.arange(H)
gx = tr.c + (cols + 0.5) * tr.a                        # cell-centre eastings
gy = tr.f + (rows + 0.5) * tr.e                        # cell-centre northings (e<0)
GX, GY = np.meshgrid(gx, gy)
grid = griddata((px, py), ziface, (GX, GY), method="linear")   # NaN outside hull -> gaps

# restrict to where the surface is physically supported
from scipy.spatial import cKDTree
dist, _ = cKDTree(np.c_[px, py]).query(np.c_[GX.ravel(), GY.ravel()])
grid.ravel()[dist > MASK_DIST] = np.nan                # near a real crossing column only
grid[dem >= 0] = np.nan                                # not over land
grid[grid <= dem] = np.nan                             # not below the seabed
print("gridded cells with surface: %d / %d" % (np.isfinite(grid).sum(), grid.size))

prof.update(dtype="float32", count=1, nodata=np.nan, compress="lzw")
with rasterio.open(OUT, "w", **prof) as dst:
    dst.write(grid.astype("float32"), 1)
print("wrote", OUT)
