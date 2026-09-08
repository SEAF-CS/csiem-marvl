"""Cross-check bathymetry (cell_Zb) at the Fremantle-mouth choke: current B010 (1991) vs
B009 (1.5.0). Same 30206-cell mesh, so diff per cell. Bed profile along the NAR->mouth
thalweg for both + plan-view difference map. -> years/1991/outputs/diagnostics/."""
import numpy as np, xarray as xr
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt

A = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
B = r'G:/CSIEM/1.5.0/BGrid/csiem_B009_20221101_20240401_WQ.nc'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/bathy_compare_B009_B010.png'
da=xr.open_dataset(A); db=xr.open_dataset(B)
X,Y=da['cell_X'].values,da['cell_Y'].values
za=np.asarray(da['cell_Zb']); zb=np.asarray(db['cell_Zb']); za=za if za.ndim==1 else za[0]; zb=zb if zb.ndim==1 else zb[0]

CTRL=[('NAR',115.847,-31.963),('',115.828,-31.978),('',115.812,-31.996),('',115.796,-32.006),
 ('neck',115.780,-32.019),('',115.767,-32.025),('',115.759,-32.029),('',115.753,-32.040),
 ('',115.747,-32.043),('',115.742,-32.049),('Fmouth',115.736,-32.053),('',115.732,-32.057),('OA10',115.7305,-32.0563)]
def hav(a,b,c,d):R=6371.;p1,p2=np.radians(b),np.radians(d);dlo,dla=np.radians(c-a),np.radians(d-b);return 2*R*np.arcsin(np.sqrt(np.sin(dla/2)**2+np.cos(p1)*np.cos(p2)*np.sin(dlo/2)**2))
dens=[];cum=0;lm=[]
for i in range(len(CTRL)-1):
    lab,lo0,la0=CTRL[i];_,lo1,la1=CTRL[i+1];seg=hav(lo0,la0,lo1,la1);n=max(2,int(seg/0.05))
    if lab:lm.append((cum,lab))
    for k in range(n):f=k/n;dens.append((cum+f*seg,lo0+f*(lo1-lo0),la0+f*(la1-la0)))
    cum+=seg
dens.append((cum,CTRL[-1][1],CTRL[-1][2]));lm.append((cum,CTRL[-1][0]))
d=[];zA=[];zB=[]
last=-1
for dd,lo,la in dens:
    ci=int(np.argmin(((X-lo)*np.cos(np.radians(la)))**2+(Y-la)**2))
    if ci==last: continue
    last=ci; d.append(dd);zA.append(za[ci]);zB.append(zb[ci])
d=np.array(d);zA=np.array(zA);zB=np.array(zB)

fig=plt.figure(figsize=(15,11));gs=fig.add_gridspec(3,2,height_ratios=[1,1,1.1])
axp=fig.add_subplot(gs[0,:])
axp.plot(d,zA,'-',color='#d62728',lw=1.6,label='B010 (current 1991)')
axp.plot(d,zB,'-',color='#1f77b4',lw=1.6,label='B009 (1.5.0)')
axp.axhline(0,color='k',ls='--',lw=.7);axp.axhline(-1,color='r',ls=':',lw=.7)
for c,l in lm:axp.axvline(c,color='.6',ls='--',lw=.6);axp.text(c,axp.get_ylim()[1],l,fontsize=8,rotation=90,va='top',ha='right')
axp.set_ylabel('bed Zb (m)');axp.set_xlabel('along-thalweg dist from NAR (km)');axp.grid(alpha=.3);axp.legend(fontsize=9)
axp.set_title('Bed profile along NAR->mouth thalweg: B010 vs B009')
axd=fig.add_subplot(gs[1,:])
axd.fill_between(d,zA-zB,0,where=(zA-zB)>0,color='#d62728',alpha=.5,label='B010 shallower (regression)')
axd.fill_between(d,zA-zB,0,where=(zA-zB)<0,color='#1f77b4',alpha=.5,label='B010 deeper')
for c,l in lm:axd.axvline(c,color='.6',ls='--',lw=.6)
axd.set_ylabel('Zb diff B010-B009 (m)');axd.set_xlabel('dist from NAR (km)');axd.grid(alpha=.3);axd.legend(fontsize=9)
axd.set_title('Bathymetry change (positive = B010 raised/shallower vs B009)')
# plan-view maps
box=(X>115.72)&(X<115.83)&(Y>-32.06)&(Y<-31.99)
for j,(z,ttl) in enumerate([(za,'B010 (current)'),(zb,'B009 (1.5.0)')]):
    ax=fig.add_subplot(gs[2,j]);sc=ax.scatter(X[box],Y[box],s=13,c=z[box],cmap='viridis',vmin=-16,vmax=0)
    ax.plot([p[1] for p in CTRL],[p[2] for p in CTRL],'r.-',lw=.8,ms=3)
    for lab,lo,la in CTRL:
        if lab:ax.annotate(lab,(lo,la),fontsize=7,fontweight='bold')
    ax.set_aspect('equal');ax.set_title(f'{ttl} bed Zb');fig.colorbar(sc,ax=ax,label='Zb (m)')
fig.suptitle('Fremantle mouth bathymetry cross-check: B010 (current) vs B009 (1.5.0, previously fixed?)',fontweight='bold')
fig.tight_layout(rect=[0,0,1,0.97]);fig.savefig(OUT,dpi=140,bbox_inches='tight');print('wrote',OUT)
# quantify along the connecting reach (km 5-13)
r=(d>5)&(d<13)
print(f'connecting reach (km5-13): B010 shallowest {zA[r].max():.2f} m, B009 shallowest {zB[r].max():.2f} m')
print(f'  cells where B010 >-1m: {(zA[r]>-1).sum()}/{r.sum()}   B009 >-1m: {(zB[r]>-1).sum()}/{r.sum()}')
print(f'  mean Zb reach: B010 {zA[r].mean():.2f}  B009 {zB[r].mean():.2f}')
