import netCDF4 as nc, numpy as np, datetime as dt
F = r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int)
cx = d.variables['cell_X'][:]; cy = d.variables['cell_Y'][:]
zb = d.variables['cell_Zb'][:]
n2 = len(NL); n3 = int(NL.sum())
print("n2", n2, "n3", n3, "sum NL == n3:", NL.sum()==n3)
print("cell_X range", float(cx.min()), float(cx.max()))
print("cell_Y range", float(cy.min()), float(cy.max()))
print("cell_Zb range", float(zb.min()), float(zb.max()))
col0 = np.repeat(np.arange(n2), NL)
top_face = np.arange(n3) + col0
T = d.variables['ResTime']; times = nc.num2date(T[:], T.units)
tt = np.array([dt.datetime(x.year,x.month,x.day,x.hour) for x in times])
# pick a post-storm timestep near 21-Aug 08:00
ti = int(np.argmin(np.abs(tt - dt.datetime(1991,8,21,8))))
print("probe timestep", ti, str(times[ti])[:13])
SAL = d.variables['SAL']; LFZ = d.variables['layerface_Z']
s = np.ma.filled(SAL[ti,:].astype(float), np.nan)
lfz = np.ma.filled(LFZ[ti,:].astype(float), np.nan)
cen = 0.5*(lfz[top_face] + lfz[top_face+1])
print("\nSAL overall: min %.2f  p5 %.2f  median %.2f  p95 %.2f  max %.2f"%(
    np.nanmin(s), np.nanpercentile(s,5), np.nanmedian(s), np.nanpercentile(s,95), np.nanmax(s)))
# bottom cells (deepest per column) salinity, in deep water (zb < -10)
last_face = top_face + 1  # bottom face of bottom cell? bottom cell = last in column
# bottom cell index per column = cumsum(NL)-1
bot_idx = np.cumsum(NL)-1
deep = zb < -10
print("deep (zb<-10) cols:", int(deep.sum()))
sb = s[bot_idx][deep]
print("bottom SAL in deep water: min %.2f median %.2f max %.2f"%(np.nanmin(sb),np.nanmedian(sb),np.nanmax(sb)))
# surface salinity
top_cell = np.r_[0, np.cumsum(NL)[:-1]]
ssurf = s[top_cell][deep]
print("surface SAL in deep water: min %.2f median %.2f max %.2f"%(np.nanmin(ssurf),np.nanmedian(ssurf),np.nanmax(ssurf)))
# suggest thresholds
for thr in [35.8,36.0,36.1,36.2,36.3]:
    below = s < thr  # 'fresh' above
    print(f"  SAL>={thr}: {100*np.mean(s>=thr):.1f}% of 3D cells are salty")
