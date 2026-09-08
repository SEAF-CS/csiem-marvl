# PREVIEW extraction for the 2021 pycnocline plots: 3 representative frames for each of the
# three candidate story windows, so the look / sigma-t threshold can be locked before a full
# series extract + HQ render. Port of extract_pycnocline_1991.py (same coarse grid / crossing
# detection); per-window THR chosen from a CS surface-vs-bottom sigma-t scan:
#   summer  1-3 Jan 2021  diurnal strat/breakdown (sea breeze)      bot ~25.2, surf dips 24.8 -> THR 25.20
#   autumn  3-11 Apr 2021 extended strat (peak ~7 Apr, mixed 9 Apr) bot ~25.3, surf ~24.8-25.2 -> THR 25.25
#   winter  3-11 Aug 2021 freshwater strat + storm mixing (~9 Aug)  bot ~25.65, surf ~24.4    -> THR 25.40
import numpy as np, netCDF4 as nc, datetime as dt, os
import rasterio
from rasterio.transform import Affine
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

F   = r"W:\WAMSI\1.7\SH-20251123-1.7.0\2021B-20260131010652\results\csiem_B010_20201101_20211231_WQ.nc"
DEM = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/cockburn_swan_2.tif"
ODIR= r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/pyc_2021_preview"
DEC = 4
MASK_DIST = 400.0

WINDOWS = {   # name -> (THR sigma-t, [preview times: stratified / transitional / mixed])
    "summer": (25.20, [dt.datetime(2021,1,1,12), dt.datetime(2021,1,2,0),  dt.datetime(2021,1,2,12)]),
    "autumn": (25.25, [dt.datetime(2021,4,7,0),  dt.datetime(2021,4,9,0),  dt.datetime(2021,4,11,0)]),
    "winter": (25.40, [dt.datetime(2021,8,3,0),  dt.datetime(2021,8,7,0),  dt.datetime(2021,8,9,0)]),
}


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
PX, PY = warp_transform("EPSG:4326", crs, cx.tolist(), cy.tolist())
PX = np.array(PX); PY = np.array(PY)

T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year, x.month, x.day, x.hour) for x in times])
SALv = d.variables['SAL']; TEMPv = d.variables['TEMP']; LFZ = d.variables['layerface_Z']

for wname, (THR, previews) in WINDOWS.items():
    wdir = os.path.join(ODIR, wname)
    os.makedirs(wdir, exist_ok=True)
    print(f"== {wname}  THR={THR:.2f}")
    for n, tg in enumerate(previews):
        ti = int(np.argmin(np.abs(tt - tg)))
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
        out = os.path.join(wdir, f"pyc_{n:03d}.tif")
        with rasterio.open(out, "w", **prof) as dst:
            dst.write(grid.astype("float32"), 1)
        print(f"  frame {n} {str(times[ti])[:13]}  cols>THR={len(ucol):5d}  gridcells={int(np.isfinite(grid).sum()):6d}")
print("preview extraction done ->", ODIR)
