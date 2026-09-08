# Time series of the PYCNOCLINE for the 2021 WINTER freshwater-stratification event:
# elevation of the sigma-t = THR isopycnal, 1 -> 5 Aug 2021, 2-hourly (49 frames).
# Port of extract_pycnocline_1991.py pointed at the 2021B run; THR=25.40 picked from the
# CS surface/bottom sigma-t scan (surface ~24.4 fresh vs bottom ~25.65; see
# extract_pycnocline_2021_preview.py + images/preview_2021 for the look-lock).
# Story: freshwater inflow builds a broad pycnocline over the sound -> winter storm mixes it
# (breakdown lands ~8-9 Aug, after this window; extend WIN1 if the collapse is wanted too).
# Writes water_level.csv as well so a dynamic-water variant stays possible.
import numpy as np, netCDF4 as nc, datetime as dt, os
import rasterio
from rasterio.transform import Affine
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

F   = r"W:\WAMSI\1.7\SH-20251123-1.7.0\2021B-20260131010652\results\csiem_B010_20201101_20211231_WQ.nc"
DEM = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/cockburn_swan_2.tif"
ODIR= r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/pyc_2021_winter"
THR = 25.40                     # kg/m3 sigma-t (2021 winter scan; NOT the 1991 value of 25.30)
DEC = 4
MASK_DIST = 400.0
STRIDE = 2                      # hours between frames (native cadence 1 h) -> 49 frames
WIN0 = dt.datetime(2021, 8, 1, 0)
WIN1 = dt.datetime(2021, 8, 5, 0)
WSMOOTH = 3                     # h, centred running-mean on the CS-mean water level
WLCSV = os.path.join(ODIR, "water_level.csv")
os.makedirs(ODIR, exist_ok=True)


def sigma_t(S, T):
    """UNESCO EOS-80 potential density anomaly at surface pressure (sigma-t = rho(S,T,0) - 1000)."""
    r0 = (999.842594 + 6.793952e-2*T - 9.095290e-3*T**2 + 1.001685e-4*T**3
          - 1.120083e-6*T**4 + 6.536332e-9*T**5)
    A = (8.24493e-1 - 4.0899e-3*T + 7.6438e-5*T**2 - 8.2467e-7*T**3 + 5.3875e-9*T**4)
    B = (-5.72466e-3 + 1.0227e-4*T - 1.6546e-6*T**2)
    C = 4.8314e-4
    return r0 + A*S + B*S**1.5 + C*S**2 - 1000.0


# ---- coarse DEM grid (must match data/dem_coarse_fixed.tif used by the renderer) ----
with rasterio.open(DEM) as ds:
    dem = ds.read(1).astype(float); tr = ds.transform; crs = ds.crs
demc = dem[::DEC, ::DEC]
trc = Affine(tr.a*DEC, tr.b, tr.c, tr.d, tr.e*DEC, tr.f)
Hc, Wc = demc.shape
prof = dict(driver="GTiff", height=Hc, width=Wc, count=1, dtype="float32",
            crs=crs, transform=trc, nodata=np.nan, compress="lzw")
cols = np.arange(Wc); rows = np.arange(Hc)
GX, GY = np.meshgrid(trc.c+(cols+0.5)*trc.a, trc.f+(rows+0.5)*trc.e)
print("coarse grid", demc.shape)

# ---- static model topology ----
d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int)
cx = d.variables['cell_X'][:]; cy = d.variables['cell_Y'][:]
n2 = len(NL); n3 = int(NL.sum())
col0 = np.repeat(np.arange(n2), NL)
top_face = np.arange(n3) + col0
prev_same = col0[1:] == col0[:-1]
first_cell = np.concatenate(([0], np.cumsum(NL)[:-1]))
surf_face = top_face[first_cell]
inCS = (cy > -32.35) & (cy < -32.05) & (cx > 115.66) & (cx < 115.80)
PX, PY = warp_transform("EPSG:4326", crs, cx.tolist(), cy.tolist())
PX = np.array(PX); PY = np.array(PY)

T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year, x.month, x.day, x.hour) for x in times])
inwin = np.where((tt >= WIN0) & (tt <= WIN1))[0]
targets = [WIN0 + dt.timedelta(hours=STRIDE*k)
           for k in range(int((WIN1-WIN0).total_seconds()//3600)//STRIDE + 1)]
sel = sorted({int(inwin[np.argmin(np.abs(tt[inwin]-tg))]) for tg in targets})
print("THR=%.2f sigma-t | frames %d | %s -> %s (stride %dh)"
      % (THR, len(sel), str(times[sel[0]])[:13], str(times[sel[-1]])[:13], STRIDE))

# ---- per-frame water level (CS-mean free surface, WSMOOTH-h centred running mean) ----
LFZ = d.variables['layerface_Z']
pad = max(1, WSMOOTH // 2)
padlo, padhi = max(0, sel[0]-pad*STRIDE), min(len(times)-1, sel[-1]+pad*STRIDE)
pidx = list(range(padlo, padhi+1, STRIDE))
wraw = []
for ti in pidx:
    z = np.ma.filled(LFZ[ti, :].astype(float), np.nan)[surf_face]
    z[(z < -5) | (z > 5)] = np.nan
    wraw.append(np.nanmean(z[inCS]))
wraw = np.array(wraw)
kern = np.ones(WSMOOTH) / WSMOOTH
wsm = np.convolve(wraw, kern, mode="same")
wlev = {ti: wsm[pidx.index(ti)] for ti in sel}
with open(WLCSV, "w") as fh:
    fh.write("frame,time,elev_m\n")
    for n, ti in enumerate(sel):
        fh.write("%d,%s,%.4f\n" % (n, str(times[ti])[:13], wlev[ti]))
print("water level %s: %+.3f .. %+.3f m (smooth %dh) -> %s"
      % ("CS-mean", min(wlev.values()), max(wlev.values()), WSMOOTH, WLCSV))

SALv = d.variables['SAL']; TEMPv = d.variables['TEMP']
for n, ti in enumerate(sel):
    S  = np.ma.filled(SALv[ti, :].astype(float), np.nan)
    Tm = np.ma.filled(TEMPv[ti, :].astype(float), np.nan)
    bad = (S <= 0) | (Tm <= 0) | (S > 60)
    S[bad] = np.nan; Tm[bad] = np.nan
    sg  = sigma_t(S, Tm)
    lfz = np.ma.filled(LFZ[ti, :].astype(float), np.nan)
    cen = 0.5 * (lfz[top_face] + lfz[top_face + 1])
    dense = sg > THR
    cross = np.zeros(n3, bool)
    cross[1:] = dense[1:] & ~dense[:-1] & prev_same
    cand = np.flatnonzero(cross)
    ucol, first = np.unique(col0[cand], return_index=True)
    s = cand[first]
    o_hi, o_lo = sg[s-1], sg[s]; z_hi, z_lo = cen[s-1], cen[s]
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
    out = os.path.join(ODIR, f"pyc_{n:03d}.tif")
    with rasterio.open(out, "w", **prof) as dst:
        dst.write(grid.astype("float32"), 1)
    print(f"frame {n:02d} {str(times[ti])[:13]}  cols>THR={len(ucol):5d}  gridcells={int(np.isfinite(grid).sum()):6d}")
print("series done ->", ODIR)
