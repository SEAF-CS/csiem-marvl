# Composite each 3D salt frame with a wind-speed timeseries panel that sweeps a time
# marker in sync, so wind events line up with the cascade response.
import glob, os, csv, datetime as dt, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt, matplotlib.image as mpimg, matplotlib.dates as mdates
from matplotlib.gridspec import GridSpec

SRC=os.environ.get("SRC","images/drape_low"); OUT="images/composite"; os.makedirs(OUT,exist_ok=True)
T=[];S=[];D=[]
with open("data/wind_cs_1991.csv") as f:
    for row in csv.DictReader(f):
        T.append(dt.datetime.fromisoformat(row["time"])); S.append(float(row["speed"])); D.append(float(row["dir"]))
T=np.array(T);S=np.array(S);D=np.array(D)
frames=sorted(glob.glob(SRC+"/f_*.png")); N=len(frames); t0=dt.datetime(1991,7,20,0)
Ts=np.array([t.timestamp() for t in T])
for i,fp in enumerate(frames):
    ti=t0+dt.timedelta(hours=4*i); ci=int(np.argmin(np.abs(Ts-ti.timestamp())))
    img=mpimg.imread(fp)
    fig=plt.figure(figsize=(10,11)); gs=GridSpec(5,1,figure=fig,hspace=0.05)
    a0=fig.add_subplot(gs[0:4,0]); a0.imshow(img); a0.axis("off")
    a0.set_title("Cockburn Sound — bottom salinity, 1991 dense-water cascade\n%s"%ti.strftime("%d %b %Y  %H:%M"),fontsize=13)
    a1=fig.add_subplot(gs[4,0])
    a1.plot(T,S,color="#3478b5",lw=0.7)
    a1.axvline(ti,color="red",lw=1.4); a1.plot(T[ci],S[ci],"o",color="red",ms=6)
    a1.set_xlim(T[0],T[-1]); a1.set_ylim(0,float(S.max())*1.12); a1.set_ylabel("wind (m/s)",fontsize=9)
    a1.xaxis.set_major_formatter(mdates.DateFormatter("%d %b")); a1.tick_params(labelsize=8)
    a1.text(0.012,0.9,"Wind %.1f m/s from %.0f°"%(S[ci],D[ci]),transform=a1.transAxes,fontsize=10,va="top",
            bbox=dict(boxstyle="round",fc="white",ec="0.7",alpha=0.8))
    fig.savefig("%s/f_%03d.png"%(OUT,i),dpi=92,facecolor="white"); plt.close(fig)
print("composited",N,"frames ->",OUT)
