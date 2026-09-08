# Time series of the PYCNOCLINE: elevation of the sigma-t = THR isopycnal (top of the dense
# water layer) for the 1991 winter STORM event. Port of extract_oxycline_jan2024.py / the salt
# halocline extract, but the crossing field is DENSITY (sigma-t from SAL+TEMP, EOS-80 @ p=0)
# instead of O2 / salinity. Density is the physically-correct metric for the storm de-/re-
# stratification + dense-water cascade (SALT.md TODO #4).
#
# Story captured (THR=25.50, window Aug 11 -> Aug 26, 6-hourly = 61 frames):
#   pre-storm stratified (broad surface) -> storm ~Aug 17-19 mixes the column (surface collapses
#   to near-nothing) -> post-storm the dense blob cascades back in / restratifies (surface rebuilds).
#
# Same vectorised top-down crossing detection + coarse grid as the oxycline pipeline; writes to a
# SEPARATE dir. Reuses the oxycline coarse DEM / grid so geometry matches data/dem_coarse_fixed.tif.
import numpy as np, netCDF4 as nc, datetime as dt, os
import rasterio
from rasterio.transform import Affine
from rasterio.warp import transform as warp_transform
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

F   = r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev_ITER9\csiem_B010_19910720_19910831_rev.nc"
DEM = r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/cockburn_swan_2.tif"
ODIR= r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/pyc_1991_flood"
DEMC= r"G:/CSIEM/1.8.0/csiem-marvl/rayshader/data/dem_coarse.tif"   # plain coarse DEM (masking); render uses *_fixed
THR = 25.30                     # kg/m3, sigma-t isopycnal = top of the dense plume descending the
                                #   slope into the north basin on the flood tide (cf. thesis Fig 6.22 /
                                #   smcws_data/1991/Fig6-22/fig622_model.png; user-picked reference value)
DEC = 4                         # decimation factor -> coarse grid (~847x419)
MASK_DIST = 400.0               # m, drop grid cells far from any model column
# --- FLOOD-TIDE CLIP (deliverable): short, smooth, hourly window over the 22 Aug flood where the
#     dense pulse advances into the north basin as the tide floods (cf. Fig 6.22, 22 Aug 05:00). ---
STRIDE = 1                      # hours between output frames (native cadence is 1 h) -> smooth
WIN0 = dt.datetime(1991, 8, 22, 0)     # start of the 22 Aug morning flood
WIN1 = dt.datetime(1991, 8, 23, 12)    # ~1.5 tidal cycles, pulse fully in (37 frames)
#   (15-day storm-arc alt: STRIDE=6, WIN0=Aug 11 00, WIN1=Aug 26 00, ODIR=.../pyc_1991)
WSMOOTH = 3                     # hours, centred running-mean on the water level (tames the seiche
                                #   so it reads as a tidal rise/fall, not hour-to-hour jitter)
WLCSV = os.path.join(ODIR, "water_level.csv")   # per-frame sea-surface level for the dynamic water slab
os.makedirs(ODIR, exist_ok=True)


def sigma_t(S, T):
    """UNESCO EOS-80 potential density anomaly at surface pressure (sigma-t = rho(S,T,0) - 1000)."""
    r0 = (999.842594 + 6.793952e-2*T - 9.095290e-3*T**2 + 1.001685e-4*T**3
          - 1.120083e-6*T**4 + 6.536332e-9*T**5)
    A = (8.24493e-1 - 4.0899e-3*T + 7.6438e-5*T**2 - 8.2467e-7*T**3 + 5.3875e-9*T**4)
    B = (-5.72466e-3 + 1.0227e-4*T - 1.6546e-6*T**2)
    C = 4.8314e-4
    return r0 + A*S + B*S**1.5 + C*S**2 - 1000.0


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
col0 = np.repeat(np.arange(n2), NL)          # 0-based column per 3D cell (top->bottom, contiguous)
top_face = np.arange(n3) + col0              # index of each cell's TOP face in layerface_Z
prev_same = col0[1:] == col0[:-1]
first_cell = np.concatenate(([0], np.cumsum(NL)[:-1]))   # shallowest (surface) cell per column
surf_face = top_face[first_cell]             # its TOP face in layerface_Z = the free surface
inCS = (cy > -32.35) & (cy < -32.05) & (cx > 115.66) & (cx < 115.80)   # Cockburn Sound region
PX, PY = warp_transform("EPSG:4326", crs, cx.tolist(), cy.tolist())
PX = np.array(PX); PY = np.array(PY)

T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year, x.month, x.day, x.hour) for x in times])
inwin = np.where((tt >= WIN0) & (tt <= WIN1))[0]
# subsample to STRIDE hours (nearest native step to each target time)
targets = [WIN0 + dt.timedelta(hours=STRIDE*k)
           for k in range(int((WIN1-WIN0).total_seconds()//3600)//STRIDE + 1)]
sel = sorted({int(inwin[np.argmin(np.abs(tt[inwin]-tg))]) for tg in targets})
print("THR=%.2f sigma-t | frames %d | %s -> %s (stride %dh)"
      % (THR, len(sel), str(times[sel[0]])[:13], str(times[sel[-1]])[:13], STRIDE))

# ---- per-frame DYNAMIC water level (CS-mean free surface, WSMOOTH-h centred running mean) ----
LFZ = d.variables['layerface_Z']
pad = max(1, WSMOOTH // 2)
padlo, padhi = max(0, sel[0]-pad*STRIDE), min(len(times)-1, sel[-1]+pad*STRIDE)
pidx = list(range(padlo, padhi+1, STRIDE))
wraw = []
for ti in pidx:
    z = np.ma.filled(LFZ[ti, :].astype(float), np.nan)[surf_face]
    z[(z < -5) | (z > 5)] = np.nan                       # drop dry/fill columns
    wraw.append(np.nanmean(z[inCS]))
wraw = np.array(wraw)
kern = np.ones(WSMOOTH) / WSMOOTH
wsm = np.convolve(wraw, kern, mode="same")
wlev = {ti: wsm[pidx.index(ti)] for ti in sel}           # smoothed level per output frame
with open(WLCSV, "w") as fh:
    fh.write("frame,time,elev_m\n")
    for n, ti in enumerate(sel):
        fh.write("%d,%s,%.4f\n" % (n, str(times[ti])[:13], wlev[ti]))
print("water level %s: %+.3f .. %+.3f m (smooth %dh) -> %s"
      % ("CS-mean", min(wlev.values()), max(wlev.values()), WSMOOTH, WLCSV))

SALv = d.variables['SAL']; TEMPv = d.variables['TEMP']; LFZ = d.variables['layerface_Z']
for n, ti in enumerate(sel):
    S  = np.ma.filled(SALv[ti, :].astype(float), np.nan)
    Tm = np.ma.filled(TEMPv[ti, :].astype(float), np.nan)
    bad = (S <= 0) | (Tm <= 0) | (S > 60)            # land / dry / fill cells
    S[bad] = np.nan; Tm[bad] = np.nan
    sg  = sigma_t(S, Tm)                             # kg/m3
    lfz = np.ma.filled(LFZ[ti, :].astype(float), np.nan)
    cen = 0.5 * (lfz[top_face] + lfz[top_face + 1])  # cell-centre elevation
    dense = sg > THR                                 # DENSE water (below the pycnocline)
    cross = np.zeros(n3, bool)
    cross[1:] = dense[1:] & ~dense[:-1] & prev_same  # upper cell light, lower cell dense
    cand = np.flatnonzero(cross)
    ucol, first = np.unique(col0[cand], return_index=True)   # shallowest crossing per column
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
