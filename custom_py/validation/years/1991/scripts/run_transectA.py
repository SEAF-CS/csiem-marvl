# Auto-assembled headless runner from profile_curtain_1991_TransectA_compare.ipynb (REV config).
# Regenerates outputs_1991_TransectA_compare_rev/ from the re-run 1991 model output.
import matplotlib
matplotlib.use('Agg')

# === Imports, EOS-80, config =================================================
import os, csv, struct, numpy as np, pandas as pd
from pathlib import Path
from datetime import datetime
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.ndimage import uniform_filter1d
from math import radians, cos, sin, sqrt, atan2
import rasterio
from pyproj import Transformer
import tfv.xarray
import sys as _sys; _sys.path.insert(0, r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib')
try:
    from point_overrides import adjust_point
except Exception:
    def adjust_point(station, lon=None, lat=None): return lon, lat

MODEL_NC = Path(r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc')  # REV
PROFILE_BASE = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
SURVEY_LOG = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/survey_log_1991.csv'
BATHY_TIF = r'X:\O2Me_EIAbathymetry_DEM\20251013_CTR41-01-v0_2025_EIA_Bathymetry_BurnsBeach_to_PointPeron_East_O2MetOcean_5m_EPSG7850_AHD.tif'
OUT_DIR = Path(r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/transectA')  # REV
OUT_DIR.mkdir(parents=True, exist_ok=True)

TEST_MODE = False   # FULL run: all panels

def eos80_potential_density(S, T):
    T2,T3,T4,T5 = T*T,T*T*T,T*T*T*T,T*T*T*T*T
    Ssq = np.sqrt(np.clip(S,0,None)); S1p5 = S*Ssq; S2 = S*S
    a=[999.842594,6.793952e-2,-9.095290e-3,1.001685e-4,-1.120083e-6,6.536332e-9]
    rho_w = a[0]+a[1]*T+a[2]*T2+a[3]*T3+a[4]*T4+a[5]*T5
    b=[8.24493e-1,-4.0899e-3,7.6438e-5,-8.2467e-7,5.3875e-9]
    c=[-5.72466e-3,1.0227e-4,-1.6546e-6]; d0=4.8314e-4
    return rho_w + (b[0]+b[1]*T+b[2]*T2+b[3]*T3+b[4]*T4)*S + (c[0]+c[1]*T+c[2]*T2)*S1p5 + d0*S2

# === Station coords / chainage / panels / style (from smcws plot_transects.py) ===
COORDS = {
 'OA5':(-32.0709,115.7312),'OA10':(-32.0558,115.7308),'OA15':(-32.0593,115.7155),
 'OA20':(-32.0663,115.7153),'OA25':(-32.0929,115.7153),'OA25N':(-32.0809,115.7208),
 'OA25S':(-32.0946,115.7167),'OA27':(-32.0889,115.7153),'OA30':(-32.0848,115.6908),
 'OA30N':(-32.0840,115.6891),'OA30S':(-32.1033,115.695),'OA31':(-32.0789,115.6892),
 'OA32':(-32.0724,115.6880),'OA33':(-32.0633,115.6862),'OA35':(-32.0779,115.6570),
 'OA65':(-32.1113,115.7053),'OA72':(-32.1200,115.7320),'OA72A':(-32.1255,115.7),
 'OA72N':(-32.1129,115.6972),'OA72W':(-32.1192,115.6992),'OA80':(-32.1313,115.7013),
 'OA85A':(-32.1413,115.682),'OA85B':(-32.1453,115.6863),
 'CS20':(-32.1501,115.7055),'CS20A':(-32.1371,115.7032),'CS20B':(-32.1463,115.7045),
 'CS45':(-32.1679,115.7095),'CS46':(-32.1738,115.7109),'CS46.5':(-32.1783,115.713),
 'CS47':(-32.1818,115.7132),'CS55':(-32.1876,115.7140),'CS58':(-32.2013,115.7165),
 'CS85':(-32.2113,115.7192),'CS88':(-32.2232,115.7227),'CS105':(-32.2346,115.7245),
 'CS112':(-32.2409,115.7115),'CS135':(-32.2481,115.7008),'CS140':(-32.2489,115.6985),
 'CS145':(-32.2554,115.6845),'CS150':(-32.2554,115.6667),'CS150S':(-32.2707,115.6573),
 'CS151':(-32.2654,115.6667),'CS155':(-32.2464,115.7207),'CS229':(-32.2396,115.7282),
}
VALID_STATIONS = {
 'OA10','OA15','OA20','OA25','OA30','OA65','OA72','OA72N','OA30S','OA80','OA72A',
 'OA72W','OA85A','OA85B','CS20A','CS20B','CS20','CS45','CS46','CS46.5','CS47','CS55',
 'CS58','CS85','CS88','CS105','CS112','CS229','CS155','CS135','CS140','CS145','CS150',
 'CS151','CS150S',
}
def haversine_m(lat1,lon1,lat2,lon2):
    R=6371000.0; dlat=radians(lat2-lat1); dlon=radians(lon2-lon1)
    a=sin(dlat/2)**2+cos(radians(lat1))*cos(radians(lat2))*sin(dlon/2)**2
    return R*2*atan2(sqrt(a),sqrt(1-a))
cs55_lat, cs55_lon = COORDS['CS55']
def chainage_km(stn):
    if stn not in COORDS: return None
    lat,lon=COORDS[stn]; d=haversine_m(cs55_lat,cs55_lon,lat,lon)
    return (-d if lat>cs55_lat else d)/1000.0   # north of CS55 negative, south positive

PANELS = [
 ('6.16a','pre',datetime(1991,8,13,15,36),datetime(1991,8,13,17,27)),
 ('6.16b','pre',datetime(1991,8,13,20,9),datetime(1991,8,14,0,25)),
 ('6.16c','pre',datetime(1991,8,14,11,50),datetime(1991,8,14,17,32)),
 ('6.16d','pre',datetime(1991,8,14,21,16),datetime(1991,8,15,0,59)),
 ('6.16e','pre',datetime(1991,8,15,9,39),datetime(1991,8,15,15,50)),
 ('6.16f','pre',datetime(1991,8,15,19,20),datetime(1991,8,15,20,48)),
 ('6.16g','pre',datetime(1991,8,16,0,29),datetime(1991,8,16,1,35)),
 ('6.16h','pre',datetime(1991,8,16,11,39),datetime(1991,8,16,13,35)),
 ('6.16i','pre',datetime(1991,8,16,19,4),datetime(1991,8,16,23,32)),
 ('6.16j','pre',datetime(1991,8,17,1,44),datetime(1991,8,17,2,41)),
 ('6.16k','pre',datetime(1991,8,17,10,25),datetime(1991,8,17,11,50)),
 ('6.16l','pre',datetime(1991,8,17,11,50),datetime(1991,8,17,15,46)),
 ('6.17a','post',datetime(1991,8,20,7,48),datetime(1991,8,20,10,9)),
 ('6.17b','post',datetime(1991,8,20,19,31),datetime(1991,8,20,22,47)),
 ('6.17c','post',datetime(1991,8,21,2,27),datetime(1991,8,21,3,13)),
 ('6.17d','post',datetime(1991,8,21,7,51),datetime(1991,8,21,10,32)),
 ('6.17e','post',datetime(1991,8,21,18,50),datetime(1991,8,21,21,47)),
 ('6.17f','post',datetime(1991,8,22,0,45),datetime(1991,8,22,2,37)),
 ('6.17g','post',datetime(1991,8,22,13,4),datetime(1991,8,22,17,10)),
 ('6.17h','post',datetime(1991,8,22,23,1),datetime(1991,8,23,1,59)),
]

# style (field reference)
VAR_CONFIG = {
 'temperature': dict(levels=np.arange(15.4,17.5,0.2), cmap=plt.cm.coolwarm, label='Temperature (°C)'),
 'salinity':    dict(levels=np.arange(33.5,35.6,0.1), cmap=plt.cm.RdYlBu_r, label='Salinity (psu)'),
 'density':     dict(levels=np.arange(24.0,26.1,0.1), cmap=plt.cm.viridis,  label=r'Density ($\sigma_t$, kg m$^{-3}$)'),
}
XLIM_SOUTH, XLIM_NORTH = 11.2, -15.1   # +south on LEFT, -north on RIGHT
MAX_DEPTH = 25.0; GHOST_KM = 0.3; BATHY_SMOOTH = 3; BATHY_BUFFER = 1.0

# === DFV reader + cross-section gridder (from plot_transects.py) =============
def read_dfv(filepath):
    with open(filepath,'rb') as f: data=f.read()
    off=data.find(b'EPA')
    if off==0x18:   ncols=struct.unpack('>H',data[0x136:0x138])[0]; nrecs=struct.unpack('>i',data[0x13c:0x140])[0]; ds0=0x528
    elif off==0x14: ncols=struct.unpack('>H',data[0x132:0x134])[0]; nrecs=struct.unpack('>i',data[0x138:0x13c])[0]; ds0=0x49C
    else: return None
    if ncols<4 or nrecs<10 or ds0+nrecs*ncols*4>len(data): return None
    rec=np.frombuffer(data,dtype='>f4',count=nrecs*ncols,offset=ds0).reshape(nrecs,ncols)
    depth=rec[:,2].copy(); sal=rec[:,0].copy(); den=rec[:,1].copy(); temp=rec[:,3].copy()
    imax=np.argmax(depth)
    if imax>10: depth,sal,den,temp=depth[:imax+1],sal[:imax+1],den[:imax+1],temp[:imax+1]
    good=(depth>0.1)&(depth<50)&(sal>20)&(sal<40)&(temp>5)&(temp<30)
    if good.sum()<5: return None
    depth,sal,den,temp=depth[good],sal[good],den[good],temp[good]
    edges=np.arange(0,depth.max()+0.25,0.25); idx=np.digitize(depth,edges)-1
    d,s,dn,t=[],[],[],[]
    for bi in range(len(edges)-1):
        m=idx==bi
        if m.any(): d.append(depth[m].mean()); s.append(sal[m].mean()); dn.append(den[m].mean()); t.append(temp[m].mean())
    if len(d)<3: return None
    return {'depth':np.array(d),'salinity':np.array(s),'density':np.array(dn),'temperature':np.array(t)}

GRID_NX, GRID_NY = 400, 200
grid_x = np.linspace(XLIM_NORTH, XLIM_SOUTH, GRID_NX)
grid_y = np.linspace(0, MAX_DEPTH, GRID_NY)
grid_X, grid_Y = np.meshgrid(grid_x, grid_y)

def build_cross_section(profiles, var_key, bathy_chain, bathy_depths):
    stns=sorted(profiles.keys(), key=lambda s: chainage_km(s)); sx=[chainage_km(s) for s in stns]
    all_x=[sx[0]-GHOST_KM]+sx+[sx[-1]+GHOST_KM]; all_s=[stns[0]]+stns+[stns[-1]]
    cols=np.zeros((len(grid_y),len(all_x)))
    for ci,(x,stn) in enumerate(zip(all_x,all_s)):
        dep=profiles[stn]['depth']; val=profiles[stn][var_key]; o=np.argsort(dep); dep,val=dep[o],val[o]
        lb=np.interp(x,bathy_chain,bathy_depths); tgt=max(lb,dep[-1])+BATHY_BUFFER
        if tgt>dep[-1]+0.2:
            bv=np.median(val[dep>dep[-1]-0.5]); ed=np.linspace(dep[-1]+0.1,tgt,10)
            dep=np.concatenate([dep,ed]); val=np.concatenate([val,np.full(10,bv)])
        cols[:,ci]=np.interp(grid_y,dep,val,left=val[0],right=val[-1])
    ax=np.array(all_x); gv=np.zeros((len(grid_y),len(grid_x)))
    for j,gx in enumerate(grid_x):
        k=np.searchsorted(ax,gx)
        if k==0: gv[:,j]=cols[:,0]
        elif k>=len(ax): gv[:,j]=cols[:,-1]
        else:
            f=(gx-ax[k-1])/(ax[k]-ax[k-1]); gv[:,j]=cols[:,k-1]*(1-f)+cols[:,k]*f
    bot=np.interp(grid_x,bathy_chain,bathy_depths)
    for j in range(len(grid_x)):
        if np.isnan(bot[j]): gv[:,j]=np.nan
        else: gv[grid_Y[:,j]>bot[j],j]=np.nan
    for j,gx in enumerate(grid_x):
        if gx<all_x[0] or gx>all_x[-1]: gv[:,j]=np.nan
    return gv

# === Bathymetry along transect + August cast index ==========================
ref_stns=sorted([s for s in VALID_STATIONS if s in COORDS], key=lambda s: chainage_km(s))
ref_chain=np.array([chainage_km(s) for s in ref_stns])
ref_lats=np.array([COORDS[s][0] for s in ref_stns]); ref_lons=np.array([COORDS[s][1] for s in ref_stns])
bathy_chain=np.linspace(ref_chain[0]-1.0, ref_chain[-1]+1.0, 600)
bathy_lats=np.interp(bathy_chain,ref_chain,ref_lats); bathy_lons=np.interp(bathy_chain,ref_chain,ref_lons)
_tf=Transformer.from_crs('EPSG:4326','EPSG:7850',always_xy=True)
_bx,_by=_tf.transform(bathy_lons,bathy_lats)
with rasterio.open(BATHY_TIF) as src:
    _el=np.array([v[0] for v in src.sample(zip(_bx,_by))]); _nd=src.nodata
_el=np.where(_el==_nd,np.nan,_el); bathy_depths=-_el
bathy_plot=np.where(~np.isnan(bathy_depths), uniform_filter1d(np.nan_to_num(bathy_depths),BATHY_SMOOTH), np.nan)
depth_max_plot=min(np.nanmax(bathy_plot), MAX_DEPTH)
print(f'Bathy {np.nanmin(bathy_plot):.1f}-{np.nanmax(bathy_plot):.1f} m over {bathy_chain[0]:.1f}..{bathy_chain[-1]:.1f} km')

aug_casts=[]
with open(SURVEY_LOG) as f:
    for row in csv.DictReader(f):
        if row['month']!='1991-08' or row['data_type']!='DFV+FV' or row['station'] not in VALID_STATIONS: continue
        dt=datetime.strptime(row['date'],'%Y-%m-%d').replace(hour=int(row['time'][:2]),minute=int(row['time'][2:]))
        aug_casts.append({'station':row['station'],'dt':dt,'jday':int(row['jday']),'time':row['time']})
print(f'{len(aug_casts)} DFV+FV casts indexed')

def field_profiles_for_panel(t0,t1):
    tmid=t0+(t1-t0)/2
    best={}
    for c in aug_casts:
        if t0<=c['dt']<=t1:
            dd=abs((c['dt']-tmid).total_seconds())
            if c['station'] not in best or dd<best[c['station']][1]: best[c['station']]=(c,dd)
    profs={}
    for c,_ in best.values():
        p=os.path.join(PROFILE_BASE,c['station'],f"dfv{c['time']}.{c['jday']}")
        if os.path.exists(p):
            r=read_dfv(p)
            if r is not None: profs[c['station']]=r
    return profs

# === Model: open NC, inject density, sample fixed Transect A stations ========
ds=xr.open_dataset(MODEL_NC)
fv=ds.tfv   # density derived per-profile from S,T below (no full-field RHOW -> avoids OOM on hourly NC)
times=pd.to_datetime(ds['Time'].values); tmin,tmax=times.min(),times.max()
MODEL_STATIONS=ref_stns   # fixed set, same every panel

def model_profiles_at(model_date):
    profs={}
    for stn in MODEL_STATIONS:
        lat,lon=COORDS[stn]
        mlon,mlat=adjust_point(stn,lon,lat)   # channel-edge override (field stays at true station)
        try:
            p=fv.get_profile((mlon,mlat),variables=['SAL','TEMP'],time=model_date)
            pt=p.sel(Time=model_date,method='nearest') if 'Time' in p.dims else p
            depth=-np.asarray(pt['Z']).ravel()
            sal=np.asarray(pt['SAL']).ravel(); temp=np.asarray(pt['TEMP']).ravel()
            den=eos80_potential_density(sal,temp)-1000.0   # sigma_t (from S,T)
            ok=np.isfinite(depth)&np.isfinite(sal)&np.isfinite(temp)&np.isfinite(den)&(depth>0.1)
            if ok.sum()<3: continue
            o=np.argsort(depth[ok])
            profs[stn]={'depth':depth[ok][o],'salinity':sal[ok][o],'temperature':temp[ok][o],'density':den[ok][o]}
        except Exception:
            pass
    return profs

def snap_time(mid):
    return times[int(np.argmin(np.abs(times-mid)))]
print(f'Model coverage {tmin} -> {tmax}; {len(MODEL_STATIONS)} fixed model stations')

# === Comparison figure: model (top) vs field (bottom), shared chainage =======
def make_compare_figure(panel_id, phase, t0, t1, save=True, show=False):
    field_profs=field_profiles_for_panel(t0,t1)
    if len(field_profs)<2:
        print(f'{panel_id}: only {len(field_profs)} field profiles, skipping'); return None
    model_date=snap_time(pd.Timestamp(t0)+(pd.Timestamp(t1)-pd.Timestamp(t0))/2)
    model_profs=model_profiles_at(model_date)

    fig,axes=plt.subplots(2,3,figsize=(20,11.5),sharex='col',sharey=True)
    var_order=['temperature','salinity','density']
    rows=[('MODEL',model_profs,model_date),('FIELD',field_profs,None)]
    for ri,(rlabel,profs,mdate) in enumerate(rows):
        for col,vk in enumerate(var_order):
            ax=axes[ri,col]; cfg=VAR_CONFIG[vk]
            if len(profs)>=2:
                gv=build_cross_section(profs,vk,bathy_chain,bathy_depths)
                norm=BoundaryNorm(cfg['levels'],ncolors=cfg['cmap'].N,clip=True)
                cf=ax.contourf(grid_X,grid_Y,gv,levels=cfg['levels'],cmap=cfg['cmap'],norm=norm,extend='both')
                cl=ax.contour(grid_X,grid_Y,gv,levels=cfg['levels'],colors='k',linewidths=0.4)
                ax.clabel(cl,inline=True,fontsize=6,fmt='%.1f')
            else:
                ax.text(0.5,0.5,'<2 profiles',transform=ax.transAxes,ha='center',va='center')
            ax.fill_between(bathy_chain,bathy_plot,depth_max_plot+5,color='#8B7355',zorder=5)
            ax.plot(bathy_chain,bathy_plot,'k-',lw=1,zorder=6)
            for stn in sorted(profs.keys(),key=lambda s:chainage_km(s)):
                x=chainage_km(stn)
                ax.plot(x,0,'kv',ms=5,zorder=7,clip_on=False)
                ax.text(x,-0.8,stn.replace('CS','').replace('OA','O'),ha='center',va='bottom',fontsize=6,zorder=7,clip_on=False)
            ax.set_xlim(XLIM_SOUTH,XLIM_NORTH); ax.set_ylim(depth_max_plot+1,-2.5)
            ax.axvline(0,color='grey',lw=0.8,ls=':',alpha=0.6,zorder=4); ax.grid(True,lw=0.3,alpha=0.3)
            if col==0: ax.set_ylabel(f'{rlabel}\nDepth (m)',fontsize=10,fontweight='bold')
            if ri==1: ax.set_xlabel('Chainage from CS55 (km)\n← South     North →',fontsize=8)
    fig.subplots_adjust(top=0.92,bottom=0.16,left=0.06,right=0.99,hspace=0.14,wspace=0.05)
    for col,vk in enumerate(var_order):
        cfg=VAR_CONFIG[vk]; pos=axes[1,col].get_position()
        cax=fig.add_axes([pos.x0, 0.065, pos.width, 0.015])
        sm=plt.cm.ScalarMappable(norm=BoundaryNorm(cfg['levels'],ncolors=cfg['cmap'].N,clip=True),cmap=cfg['cmap'])
        sm.set_array([])
        fig.colorbar(sm,cax=cax,orientation='horizontal',extend='both').set_label(cfg['label'],fontsize=9)
    sc='#b8860b' if phase=='pre' else '#228B22'
    fig.text(0.5,0.965,f'Transect A  panel {panel_id} ({phase.upper()}-STORM)   '
             f'field {t0.strftime("%d-%b %H:%M")}–{t1.strftime("%H:%M")}   |   '
             f'model {pd.Timestamp(model_date).strftime("%d-%b %H:%M")}',
             ha='center',va='center',fontsize=13,fontweight='bold',color=sc)
    if save:
        fn=OUT_DIR/f'compare_TransectA_{panel_id}_{phase}.png'; fig.savefig(fn,dpi=150,bbox_inches='tight')
    if show: plt.show()
    else: plt.close(fig)
    return OUT_DIR/f'compare_TransectA_{panel_id}_{phase}.png' if save else None

# === Generate ================================================================
jobs=[(p,ph,t0,t1) for (p,ph,t0,t1) in PANELS if tmin<=(pd.Timestamp(t0)+(pd.Timestamp(t1)-pd.Timestamp(t0))/2)<=tmax]
if TEST_MODE:
    for j in jobs:
        if len(field_profiles_for_panel(j[2],j[3]))>=2:
            jobs=[j]; break
print(f'{"TEST" if TEST_MODE else "FULL"} run: {len(jobs)} panel(s)')
for p,ph,t0,t1 in jobs:
    out=make_compare_figure(p,ph,t0,t1,save=True,show=TEST_MODE)
    if out: print(f'  saved {out.name}')
print('Done.')
