# Bottom-cell SALINITY per timestep, gridded onto the coarse DEM -> one GeoTIFF/frame.
# Drives a seabed colour DRAPE (dense salty water pooling on the basin floor = the cascade).
# Same window/grid as the halocline series so timelines match.
import numpy as np, netCDF4 as nc, datetime as dt, os
import rasterio
from rasterio.transform import Affine
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

F    = r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
DEM  = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader_salt/data/cockburn_swan_2.tif"
ODIR = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader_salt/data/sal_bottom"
T_START = dt.datetime(1991, 7, 20, 0)    # FULL NC range, native 4-hourly (253 frames)
T_END   = dt.datetime(1991, 8, 31, 23)
DEC = 4; MASK_DIST = 400.0
os.makedirs(ODIR, exist_ok=True)

with rasterio.open(DEM) as ds:
    dem = ds.read(1).astype(float); tr = ds.transform; crs = ds.crs
demc = dem[::DEC, ::DEC]
trc = Affine(tr.a*DEC, tr.b, tr.c, tr.d, tr.e*DEC, tr.f)
Hc, Wc = demc.shape
prof = dict(driver="GTiff", height=Hc, width=Wc, count=1, dtype="float32",
            crs=crs, transform=trc, nodata=np.nan, compress="lzw")
cols = np.arange(Wc); rows = np.arange(Hc)
GX, GY = np.meshgrid(trc.c+(cols+0.5)*trc.a, trc.f+(rows+0.5)*trc.e)

d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int); n2 = len(NL); n3 = int(NL.sum())
cx = d.variables['cell_X'][:]; cy = d.variables['cell_Y'][:]
bot_idx = np.cumsum(NL) - 1                          # deepest cell per column
PX, PY = warp_transform("EPSG:4326", crs, cx.tolist(), cy.tolist())
PX = np.array(PX); PY = np.array(PY)
tree = cKDTree(np.c_[PX, PY])
dist, _ = tree.query(np.c_[GX.ravel(), GY.ravel()])
far = dist.reshape(GX.shape) > MASK_DIST
land = demc >= 0

T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year, x.month, x.day, x.hour) for x in times])
sel = np.where((tt >= T_START) & (tt <= T_END))[0]
print("timesteps:", len(sel), str(times[sel[0]])[:13], "->", str(times[sel[-1]])[:13])

SALv = d.variables['SAL']
gmin, gmax, allvals = 99., -99., []
for n, ti in enumerate(sel):
    S = np.ma.filled(SALv[ti, :].astype(float), np.nan)
    sb = S[bot_idx]                                  # bottom salinity per 2D column
    ok = np.isfinite(sb)
    grid = griddata((PX[ok], PY[ok]), sb[ok], (GX, GY), method="linear")
    grid[far] = np.nan; grid[land] = np.nan
    out = os.path.join(ODIR, f"sal_{n:03d}.tif")
    with rasterio.open(out, "w", **prof) as dst:
        dst.write(grid.astype("float32"), 1)
    fv = grid[np.isfinite(grid)]
    if fv.size:
        gmin = min(gmin, fv.min()); gmax = max(gmax, fv.max()); allvals.append(fv)
    print(f"frame {n:02d} {str(times[ti])[:13]}  bottomSAL grid: "
          f"min {np.nanmin(grid):.2f} max {np.nanmax(grid):.2f} cells {int(np.isfinite(grid).sum())}")
av = np.concatenate(allvals)
print("\nGLOBAL bottom-sal range %.2f .. %.2f  (p2 %.2f, p98 %.2f)"
      % (gmin, gmax, np.percentile(av,2), np.percentile(av,98)))
print("series done ->", ODIR)
