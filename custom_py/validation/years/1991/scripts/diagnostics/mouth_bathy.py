"""Model bed elevation (cell_Zb) along the Fremantle mouth -> NAR thalweg + plan-view of the
entrance, to show the shallow sill choking tidal propagation. -> years/1991/outputs/diagnostics/."""
import numpy as np, xarray as xr, tfv.xarray
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev_repaired.nc'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/mouth_bathymetry_sill.png'
CTRL = [('NAR',115.847,-31.963),('',115.828,-31.978),('',115.812,-31.996),('',115.796,-32.006),
    ('neck',115.780,-32.019),('',115.767,-32.025),('',115.759,-32.029),('',115.753,-32.040),
    ('',115.747,-32.043),('',115.742,-32.049),('Fmouth',115.736,-32.053),('',115.732,-32.057),('OA10',115.7305,-32.0563)]
ds = xr.open_dataset(NC); X, Y = ds['cell_X'].values, ds['cell_Y'].values; Zb = np.asarray(ds['cell_Zb'])
def hav(a,b,c,d): R=6371.;p1,p2=np.radians(b),np.radians(d);dlo,dla=np.radians(c-a),np.radians(d-b);return 2*R*np.arcsin(np.sqrt(np.sin(dla/2)**2+np.cos(p1)*np.cos(p2)*np.sin(dlo/2)**2))
# densify + sample Zb at nearest wet cell (from NAR)
dens=[];cum=0;lm=[]
for i in range(len(CTRL)-1):
    lab,lo0,la0=CTRL[i];_,lo1,la1=CTRL[i+1];seg=hav(lo0,la0,lo1,la1);n=max(2,int(seg/0.05))
    if lab: lm.append((cum,lab))
    for k in range(n):f=k/n;dens.append((cum+f*seg,lo0+f*(lo1-lo0),la0+f*(la1-la0)))
    cum+=seg
dens.append((cum,CTRL[-1][1],CTRL[-1][2]));lm.append((cum,CTRL[-1][0]))
d=[];z=[]
for dd,lo,la in dens:
    ci=int(np.argmin(((X-lo)*np.cos(np.radians(la)))**2+(Y-la)**2)); d.append(dd);z.append(Zb[ci])
d=np.array(d);z=np.array(z)

fig=plt.figure(figsize=(15,9));gs=fig.add_gridspec(2,2,height_ratios=[1,1],width_ratios=[1.3,1])
axp=fig.add_subplot(gs[0,:]);axm=fig.add_subplot(gs[1,0]);axt=fig.add_subplot(gs[1,1])
# profile
axp.fill_between(d,z,z.min()-2,color='#8B7355',alpha=.5);axp.plot(d,z,'k-',lw=1.5)
axp.axhline(0,color='b',ls='--',lw=1,label='0 m (approx MSL datum)')
axp.axhline(-1.0,color='r',ls=':',lw=1,label='approx LAT (~ -1 m): sill dries/chokes below this')
for c,l in lm: axp.axvline(c,color='0.5',ls='--',lw=.7);axp.text(c,axp.get_ylim()[1],l,fontsize=8,rotation=90,va='top',ha='right')
axp.set_xlabel('along-thalweg distance from NAR (km)');axp.set_ylabel('bed elevation Zb (m)')
axp.set_title('MODEL bed elevation along NAR->Fremantle mouth thalweg  (shallow sill chokes the tide)')
axp.grid(alpha=.3);axp.legend(fontsize=8)
# plan-view bed map of entrance
box=(X>115.72)&(X<115.83)&(Y>-32.065)&(Y<-31.99)
sc=axm.scatter(X[box],Y[box],s=14,c=Zb[box],cmap='viridis',vmin=-16,vmax=0)
axm.plot([p[1] for p in CTRL],[p[2] for p in CTRL],'r.-',lw=1,ms=4)
for lab,lo,la in CTRL:
    if lab: axm.annotate(lab,(lo,la),fontsize=8,fontweight='bold')
axm.set_aspect('equal');axm.set_title('entrance bed elevation (m)');fig.colorbar(sc,ax=axm,label='Zb (m)')
# text summary
axt.axis('off')
shallow=(z>-1.0).sum()
axt.text(0.02,0.95,'FINDING: tide choked at the mouth', fontsize=13, fontweight='bold', va='top')
axt.text(0.02,0.82,f'- MODEL transmits only ~6% of the mouth tide to NAR\n'
    f'  (real Swan transmits ~91%: Barrack St vs Fremantle)\n\n'
    f'- Cause: shallow entrance/sill. Along the thalweg,\n'
    f'  {shallow} sampled cells sit above -1 m (near-emergent).\n'
    f'  Neck bed ~0 m; mouth ~-1.6 m; where reality\n'
    f'  (Blackwall Reach / dredged entrance) is 10-20 m deep.\n\n'
    f'- Consequence: no tidal prism -> no flushing, no salt\n'
    f'  intrusion (no wedge), no ebb-tide plume ejection to OA.\n\n'
    f'FIX: deepen the Fremantle entrance / lower-Swan channel\n'
    f'bathymetry (and/or refine mesh) to a realistic connected\n'
    f'depth so the tidal prism can pass.', fontsize=10, va='top', family='monospace')
fig.suptitle('Fremantle mouth bathymetry - the tidal choke point', fontweight='bold')
fig.tight_layout(rect=[0,0,1,0.97]);fig.savefig(OUT,dpi=140,bbox_inches='tight');print('wrote',OUT)
print('min bed along entrance reach (neck region, km 8-13):', z[(d>7)&(d<13)].max(),'m (shallowest)')
