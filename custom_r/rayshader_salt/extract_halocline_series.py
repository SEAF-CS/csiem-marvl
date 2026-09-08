# Time series of the HALOCLINE: elevation of the SAL = THR isosurface (top of the
# dense salty layer) as it cascades down-slope into the basin, 1991 cascade window.
# Ported from the oxycline pipeline; same crossing logic, salinity instead of O2.
# Writes a coarse DEM + one interface GeoTIFF per timestep on the SAME coarse grid.
import numpy as np, netCDF4 as nc, datetime as dt, os
import rasterio
from rasterio.transform import Affine
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

F    = r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
DEM  = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader_salt/data/cockburn_swan_2.tif"
ODIR = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader_salt/data/halo_series"
DEMC = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader_salt/data/dem_coarse.tif"

# ---- tunables (cascade science) ----
THR        = 34.6                          # psu, halocline / top-of-dense-water isosurface
                                           #   (34.6 = the dense tongue entering Cockburn Sound;
                                           #    spatial mask below restricts it to the CS region)
T_START    = dt.datetime(1991, 8, 14, 0)   # pre-storm stratified
T_END      = dt.datetime(1991, 8, 25, 0)   # post-storm cascade  (~66 frames, 4-hourly)
DEC        = 4                             # DEM decimation -> coarse grid
MASK_DIST  = 400.0                         # m, drop grid cells far from any model column
os.makedirs(ODIR, exist_ok=True)

# ---- coarse DEM grid (decimate) ----
with rasterio.open(DEM) as ds:
    dem = ds.read(1).astype(float); tr = ds.transform; crs = ds.crs
demc = dem[::DEC, ::DEC]
trc = Affine(tr.a*DEC, tr.b, tr.c, tr.d, tr.e*DEC, tr.f)
Hc, Wc = demc.shape
prof = dict(driver="GTiff", height=Hc, width=Wc, count=1, dtype="float32",
            crs=crs, transform=trc, nodata=np.nan, compress="lzw")
with rasterio.open(DEMC, "w", **prof) as dst:
    dst.write(demc.astype("float32"), 1)
cols = np.arange(Wc); rows = np.arange(Hc)
GX, GY = np.meshgrid(trc.c+(cols+0.5)*trc.a, trc.f+(rows+0.5)*trc.e)
print("coarse grid", demc.shape)

# ---- static model topology ----
d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int)
cx = d.variables['cell_X'][:]; cy = d.variables['cell_Y'][:]
n2 = len(NL); n3 = int(NL.sum())
col0 = np.repeat(np.arange(n2), NL)         # 0-based column per 3D cell (top->bottom)
top_face = np.arange(n3) + col0             # index of each cell's TOP face in layerface_Z
prev_same = col0[1:] == col0[:-1]
PX, PY = warp_transform("EPSG:4326", crs, cx.tolist(), cy.tolist())
PX = np.array(PX); PY = np.array(PY)

T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year, x.month, x.day, x.hour) for x in times])
sel = np.where((tt >= T_START) & (tt <= T_END))[0]
print("THR=%.2f psu | timesteps:" % THR, len(sel), str(times[sel[0]])[:13], "->", str(times[sel[-1]])[:13])

SALv = d.variables['SAL']; LFZ = d.variables['layerface_Z']
for n, ti in enumerate(sel):
    S   = np.ma.filled(SALv[ti, :].astype(float), np.nan)        # psu (no conversion)
    lfz = np.ma.filled(LFZ[ti, :].astype(float), np.nan)
    cen = 0.5 * (lfz[top_face] + lfz[top_face + 1])              # cell-centre elevation
    salty = S > THR                                             # DENSE water (below the halocline)
    cross = np.zeros(n3, bool)
    cross[1:] = salty[1:] & ~salty[:-1] & prev_same             # upper cell fresh, lower cell salty
    cand = np.flatnonzero(cross)
    ucol, first = np.unique(col0[cand], return_index=True)      # shallowest crossing per column
    s = cand[first]
    o_hi, o_lo = S[s-1], S[s]; z_hi, z_lo = cen[s-1], cen[s]
    den = o_lo - o_hi
    ffac = np.where(den != 0, (THR - o_hi) / den, 0.0)
    z = z_hi + ffac * (z_lo - z_hi)
    keep = np.isfinite(z) & (z < 0)
    ucol, z = ucol[keep], z[keep]
    if ucol.size == 0:
        grid = np.full(GX.shape, np.nan, np.float32)
    else:
        grid = griddata((PX[ucol], PY[ucol]), z, (GX, GY), method="linear")
        dist, _ = cKDTree(np.c_[PX[ucol], PY[ucol]]).query(np.c_[GX.ravel(), GY.ravel()])
        grid.ravel()[dist > MASK_DIST] = np.nan
        grid[demc >= 0] = np.nan
        grid[grid <= demc] = np.nan
    out = os.path.join(ODIR, f"halo_{n:03d}.tif")
    with rasterio.open(out, "w", **prof) as dst:
        dst.write(grid.astype("float32"), 1)
    print(f"frame {n:02d} {str(times[ti])[:13]}  cols>THR={len(ucol):5d}  gridcells={int(np.isfinite(grid).sum()):5d}")
print("series done ->", ODIR)
