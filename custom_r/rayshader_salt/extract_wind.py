import netCDF4 as nc, numpy as np, datetime as dt, csv
F=r"W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\environment_repo\1_weather\BARRA\BARRA_PH_UTC+8_19910101_19911231.nc"
d=nc.Dataset(F)
lat=d.variables['latitude'][:]; lon=d.variables['longitude'][:]
print("lat %.2f..%.2f  lon %.2f..%.2f"%(lat.min(),lat.max(),lon.min(),lon.max()))
# nearest grid point to Cockburn Sound
LAT0,LON0=-32.15,115.75
iy=int(np.argmin(np.abs(lat-LAT0))); ix=int(np.argmin(np.abs(lon-LON0)))
print("using grid point lat %.3f lon %.3f"%(lat[iy],lon[ix]))
T=d.variables['time']; times=nc.num2date(T[:],T.units)
tt=np.array([dt.datetime(x.year,x.month,x.day,x.hour) for x in times])
sel=np.where((tt>=dt.datetime(1991,7,18))&(tt<=dt.datetime(1991,9,2)))[0]
u=d.variables['uwnd10m'][sel,iy,ix]; v=d.variables['vwnd10m'][sel,iy,ix]
spd=np.sqrt(u**2+v**2)
# meteorological direction (FROM)
drc=(270-np.degrees(np.arctan2(v,u)))%360
with open("data/wind_cs_1991.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["time","u","v","speed","dir"])
    for k,i in enumerate(sel):
        w.writerow([tt[i].isoformat(),round(float(u[k]),3),round(float(v[k]),3),round(float(spd[k]),3),round(float(drc[k]),1)])
print("wrote data/wind_cs_1991.csv  rows",len(sel),"| speed max %.1f m/s on %s"%(spd.max(),str(tt[sel[int(np.argmax(spd))]])[:13]))
