# Time series of the O2 = 5.5 mg/L isosurface elevation for the JANUARY 2024 hypoxia event,
# TRIMMED to 15-Jan 12:00 -> 24-Jan 00:00 (4-hourly = 52 frames) so the straight-to-HQ render
# fits a ~16 h budget. Captures: quiet lead-in (15th) -> onset (16th) -> peak (20th, ~11.5k cells
# <5.5 mg/L) -> decay -> recovery (24th). Same vectorised crossing detection / coarse grid as
# extract_oxycline_series.py; writes to a SEPARATE dir so the original 13-23 Jan series is kept.
import numpy as np, netCDF4 as nc, datetime as dt, os
import rasterio
from rasterio.transform import Affine
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

F   = r"W:\WAMSI\1.7\SH-20251123-1.7.0\2023B-20251124150126\results\csiem_B010_20221101_20240401_WQ_WQ.nc"
DEM = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/cockburn_swan_2.tif"
ODIR= r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/oxy6_jan2024"
DEMC= r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/dem_coarse.tif"
THR = 5.5                       # mg/L
DEC = 4                         # decimation factor -> coarse grid (~847x419)
MASK_DIST = 400.0
WIN0 = dt.datetime(2024, 1, 15, 12)    # trimmed start
WIN1 = dt.datetime(2024, 1, 24, 0)     # trimmed end
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
cols=np.arange(Wc); rows=np.arange(Hc)
GX, GY = np.meshgrid(trc.c+(cols+0.5)*trc.a, trc.f+(rows+0.5)*trc.e)
print("coarse grid", demc.shape)

# ---- static model topology ----
d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int)
cx = d.variables['cell_X'][:]; cy = d.variables['cell_Y'][:]
n2 = len(NL); n3 = int(NL.sum())
col0 = np.repeat(np.arange(n2), NL)          # 0-based column per 3D cell (cells contiguous, top->bottom)
top_face = np.arange(n3) + col0              # index of each cell's TOP face in layerface_Z
prev_same = col0[1:] == col0[:-1]
# project model lon/lat -> DEM CRS once
PX, PY = warp_transform("EPSG:4326", crs, cx.tolist(), cy.tolist())
PX = np.array(PX); PY = np.array(PY)

T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year,x.month,x.day,x.hour) for x in times])
sel = np.where((tt >= WIN0) & (tt <= WIN1))[0]
print("timesteps:", len(sel), str(times[sel[0]])[:13], "->", str(times[sel[-1]])[:13])

O2v = d.variables['WQ_OXY_OXY']; LFZ = d.variables['layerface_Z']
for n, ti in enumerate(sel):
    O2 = np.ma.filled(O2v[ti, :].astype(float), np.nan) / 31.25     # mg/L
    lfz = np.ma.filled(LFZ[ti, :].astype(float), np.nan)
    cen = 0.5 * (lfz[top_face] + lfz[top_face + 1])                 # cell-centre elevation
    below = O2 < THR
    cross = np.zeros(n3, bool)
    cross[1:] = below[1:] & ~below[:-1] & prev_same                # lower cell of a top-down crossing
    cand = np.flatnonzero(cross)
    ucol, first = np.unique(col0[cand], return_index=True)         # shallowest crossing per column
    s = cand[first]
    o_hi, o_lo = O2[s-1], O2[s]; z_hi, z_lo = cen[s-1], cen[s]
    den = o_hi - o_lo
    ffac = np.where(den != 0, (o_hi - THR) / den, 0.0)
    z = z_hi + ffac * (z_lo - z_hi)
    keep = np.isfinite(z) & (z < 0)
    ucol, z = ucol[keep], z[keep]
    # grid onto coarse grid + masks
    grid = griddata((PX[ucol], PY[ucol]), z, (GX, GY), method="linear")
    dist, _ = cKDTree(np.c_[PX[ucol], PY[ucol]]).query(np.c_[GX.ravel(), GY.ravel()])
    grid.ravel()[dist > MASK_DIST] = np.nan
    grid[demc >= 0] = np.nan
    grid[grid <= demc] = np.nan
    out = os.path.join(ODIR, f"oxy6_{n:03d}.tif")
    with rasterio.open(out, "w", **prof) as dst:
        dst.write(grid.astype("float32"), 1)
    print(f"frame {n:02d} {str(times[ti])[:13]}  cols<5.5={len(ucol):4d}  gridcells={int(np.isfinite(grid).sum()):5d}")
print("series done ->", ODIR)
