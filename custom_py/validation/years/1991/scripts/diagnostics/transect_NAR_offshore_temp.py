"""Along-thalweg TEMPERATURE curtain NAR -> Swan estuary -> Fremantle mouth -> offshore OA.
Row1 = MODEL temp, Row2 = FIELD temp (offshore of mouth only; same scale), Row3 = surf/bot temp line.
Path samples the nearest WET model cell centroid. Snapshot at the 18-Aug TransectOA time.
NOTE: reflects the current NC (warm 21.6 C inflow until the temp-clim fix is re-run)."""
import os, sys, csv, struct, numpy as np, pandas as pd, xarray as xr
from datetime import datetime
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.interpolate import griddata
import tfv.xarray
sys.path.insert(0, r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/common/lib')
from eos80 import eos80_potential_density  # noqa (kept for parity; unused here)

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/transect_NAR_offshore_temp.png'
SURVEY_LOG = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/survey_log_1991.csv'
PROFILE_BASE = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/1991/1991-08/profile_data'
MODEL_TIME = pd.Timestamp('1991-08-18 09:00')
TLEV = np.arange(14, 22.5, 0.5); CMAP = plt.cm.coolwarm

CTRL = [('NAR',115.847,-31.963),('',115.828,-31.978),('',115.812,-31.996),('',115.796,-32.006),
    ('',115.780,-32.019),('',115.767,-32.025),('',115.759,-32.029),('',115.753,-32.040),
    ('',115.747,-32.043),('',115.742,-32.049),('Fmouth',115.736,-32.053),('',115.732,-32.057),
    ('OA10',115.7305,-32.0563),('OA15',115.7156,-32.0590),('OA20',115.7157,-32.0657),
    ('OA30',115.6906,-32.0844),('OA35',115.6568,-32.0779),('OA40',115.6357,-32.0802),('OA45',115.6166,-32.0775)]
def hav(a,b,c,d):R=6371.;p1,p2=np.radians(b),np.radians(d);dlo,dla=np.radians(c-a),np.radians(d-b);return 2*R*np.arcsin(np.sqrt(np.sin(dla/2)**2+np.cos(p1)*np.cos(p2)*np.sin(dlo/2)**2))
dens=[];cum=0.0;landmarks=[];stn_chain={}
for i in range(len(CTRL)-1):
    lab,lo0,la0=CTRL[i];_,lo1,la1=CTRL[i+1];seg=hav(lo0,la0,lo1,la1);n=max(2,int(seg/0.08))
    if lab:(landmarks.append((cum,lab)) if lab in ('NAR','Fmouth') else None);stn_chain[lab]=cum
    for k in range(n):f=k/n;dens.append((cum+f*seg,lo0+f*(lo1-lo0),la0+f*(la1-la0)))
    cum+=seg
lab,lo1,la1=CTRL[-1];dens.append((cum,lo1,la1));stn_chain[lab]=cum;landmarks.append((cum,lab));TOTAL=cum

ds=xr.open_dataset(NC);fv=ds.tfv;X=ds['cell_X'].values;Y=ds['cell_Y'].values
mt=pd.to_datetime(ds['Time'].values);md=mt[int(np.argmin(np.abs(mt-MODEL_TIME)))];print('model snapshot',md)
D=[];Z=[];T=[];surf_d=[];surf_T=[];bot_T=[];last=-1
for d,lo,la in dens:
    dd=np.sqrt(((X-lo)*np.cos(np.radians(la)))**2+(Y-la)**2)*111000;ci=int(dd.argmin())
    if dd[ci]>350 or ci==last:continue
    last=ci;clo,cla=float(X[ci]),float(Y[ci])
    try:
        p=fv.get_profile((clo,cla),variables=['TEMP'],time=md);pt=p.sel(Time=md,method='nearest') if 'Time' in p.dims else p
        z=-np.asarray(pt['Z']).ravel();tt=np.asarray(pt['TEMP']).ravel();ok=np.isfinite(z)&np.isfinite(tt)&(z>0.05)
        if ok.sum()<2:continue
        z,tt=z[ok],tt[ok];o=np.argsort(z);z,tt=z[o],tt[o]
        D+=[d]*len(z);Z+=list(z);T+=list(tt);surf_d.append(d);surf_T.append(tt[0]);bot_T.append(tt[-1])
    except Exception:continue
D,Z,T=map(np.array,(D,Z,T));print(f'model wet samples {len(surf_d)}')

def read_dfv(fp):
    data=open(fp,'rb').read();off=data.find(b'EPA')
    if off==0x18:ncols=struct.unpack('>H',data[0x136:0x138])[0];nrecs=struct.unpack('>i',data[0x13c:0x140])[0];ds0=0x528
    elif off==0x14:ncols=struct.unpack('>H',data[0x132:0x134])[0];nrecs=struct.unpack('>i',data[0x138:0x13c])[0];ds0=0x49C
    else:return None
    if ncols<4 or nrecs<10 or ds0+nrecs*ncols*4>len(data):return None
    rec=np.frombuffer(data,dtype='>f4',count=nrecs*ncols,offset=ds0).reshape(nrecs,ncols)
    depth=rec[:,2].copy();sal=rec[:,0].copy();temp=rec[:,3].copy();imax=np.argmax(depth)
    if imax>10:depth,sal,temp=depth[:imax+1],sal[:imax+1],temp[:imax+1]
    good=(depth>0.1)&(depth<50)&(sal>20)&(sal<40)&(temp>5)&(temp<30)
    if good.sum()<5:return None
    depth,temp=depth[good],temp[good];edges=np.arange(0,depth.max()+0.25,0.25);idx=np.digitize(depth,edges)-1
    d_,t_=[],[]
    for bi in range(len(edges)-1):
        m=idx==bi
        if m.any():d_.append(depth[m].mean());t_.append(temp[m].mean())
    return {'depth':np.array(d_),'temp':np.array(t_)} if len(d_)>=3 else None

casts18=[]
for row in csv.DictReader(open(SURVEY_LOG)):
    if row['date']=='1991-08-18' and row['data_type']=='DFV+FV':
        casts18.append({'station':row['station'],'jday':int(row['jday']),'time':row['time'],'dt':datetime(1991,8,18,int(row['time'][:2]),int(row['time'][2:]))})
tmid=datetime(1991,8,18,9,0);FD=[];FZ=[];FT=[]
for stn in [c for c in stn_chain if c.startswith('OA')]:
    cands=[c for c in casts18 if c['station']==stn]
    if not cands:continue
    c=sorted(cands,key=lambda c:abs((c['dt']-tmid).total_seconds()))[0]
    fp=os.path.join(PROFILE_BASE,stn,f"dfv{c['time']}.{c['jday']}")
    if not os.path.exists(fp):continue
    r=read_dfv(fp)
    if r is None:continue
    ch=stn_chain[stn];FD+=[ch]*len(r['depth']);FZ+=list(r['depth']);FT+=list(r['temp'])
FD,FZ,FT=map(np.array,(FD,FZ,FT))

gx=np.linspace(0,TOTAL,420);gy=np.linspace(0,min(np.nanmax(Z),22),200);gX,gY=np.meshgrid(gx,gy)
def curtain(Dd,Zz,Vv,xlo,xhi):
    if len(Dd)<4:return np.full_like(gX,np.nan)
    g=griddata((Dd,Zz),Vv,(gX,gY),method='linear');gn=griddata((Dd,Zz),Vv,(gX,gY),method='nearest');g=np.where(np.isnan(g),gn,g)
    for j,x in enumerate(gx):
        near=np.abs(Dd-x)<0.4
        if near.any() and xlo<=x<=xhi:g[gY[:,j]>Zz[near].max(),j]=np.nan
        else:g[:,j]=np.nan
    return g
gM=curtain(D,Z,T,0,TOTAL);gF=curtain(FD,FZ,FT,FD.min() if len(FD) else 0,FD.max() if len(FD) else 0)

fig,axes=plt.subplots(3,1,figsize=(15,12),sharex=True)
norm=BoundaryNorm(TLEV,ncolors=CMAP.N,clip=True)
for ax,g,tag in [(axes[0],gM,'MODEL'),(axes[1],gF,'FIELD (offshore of mouth only)')]:
    cf=ax.contourf(gX,gY,g,levels=TLEV,cmap=CMAP,norm=norm,extend='both')
    cl=ax.contour(gX,gY,g,levels=TLEV[::2],colors='k',linewidths=0.3);ax.clabel(cl,fontsize=6,fmt='%.1f')
    ax.invert_yaxis();ax.set_ylabel(f'{tag}\nDepth (m)',fontweight='bold',fontsize=9);ax.grid(alpha=0.2)
    fig.colorbar(cf,ax=ax,pad=0.01).set_label('Temperature (°C)',fontsize=8)
axes[2].plot(surf_d,surf_T,'-o',ms=3,color='#1f77b4',label='model surface T')
axes[2].plot(surf_d,bot_T,'-o',ms=3,color='#d62728',label='model bottom T')
if len(FD):
    fst=sorted(set(FD));axes[2].plot(fst,[FT[FD==x][np.argmin(FZ[FD==x])] for x in fst],'g^',ms=7,label='field surface T')
axes[2].set_ylabel('Temperature (°C)');axes[2].grid(alpha=0.3);axes[2].legend(fontsize=8)
axes[2].set_xlabel('Along-thalweg distance from Narrows (km)   [Swan estuary -> Fremantle mouth -> offshore OA]')
for ax in axes:
    for d,l in landmarks:
        ax.axvline(d,color='0.4',ls='--',lw=0.8)
        if ax is axes[0]:ax.text(d,ax.get_ylim()[1],l,fontsize=8,rotation=90,va='top',ha='right',color='0.2')
fig.suptitle(f'NAR->offshore along-thalweg TEMPERATURE: MODEL vs FIELD  |  {md:%d-%b %H:%M}  (warm 21.6C inflow - pre temp-clim re-run)',fontweight='bold')
fig.tight_layout(rect=[0,0,1,0.97]);fig.savefig(OUT,dpi=140,bbox_inches='tight');print('wrote',OUT)
