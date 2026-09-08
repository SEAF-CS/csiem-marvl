import netCDF4 as nc, numpy as np, datetime as dt
F = r"S:\Matt_Working\csiem\output_archive\1.7.0\1991_aug_rev\csiem_B010_19910720_19910831_rev.nc"
d = nc.Dataset(F)
NL = d.variables['NL'][:].astype(int); n2=len(NL); n3=int(NL.sum())
cx=d.variables['cell_X'][:]; cy=d.variables['cell_Y'][:]; zb=d.variables['cell_Zb'][:]
col0=np.repeat(np.arange(n2),NL); top_face=np.arange(n3)+col0
bot_idx=np.cumsum(NL)-1; top_cell=np.r_[0,np.cumsum(NL)[:-1]]
T=d.variables['ResTime']; times=nc.num2date(T[:],T.units)
tt=np.array([dt.datetime(x.year,x.month,x.day,x.hour) for x in times])
SAL=d.variables['SAL']
# deep basin = deep cells, central sound (rough lon/lat box around Cockburn Sound)
deep = (zb < -15)
print("deep(zb<-15) cols:", int(deep.sum()))
print(" date         maxBot   p95Bot  strat(bot-surf)p90  frac>35.2  frac>35.3")
for ti in range(0,253,12):   # every 2 days
    s=np.ma.filled(SAL[ti,:].astype(float),np.nan)
    sb=s[bot_idx][deep]; ss=s[top_cell][deep]
    strat=np.nanpercentile(sb-ss,90)
    print(" %s  %6.2f  %6.2f  %8.2f  %8.3f  %8.3f"%(
        str(times[ti])[:13], np.nanmax(sb), np.nanpercentile(sb,95), strat,
        np.nanmean(s>35.2), np.nanmean(s>35.3)))
