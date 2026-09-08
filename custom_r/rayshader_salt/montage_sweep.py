import glob, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt, matplotlib.image as mpimg
fs=sorted(glob.glob("images/sweep/theta_*.png"))
fig,ax=plt.subplots(2,4,figsize=(20,9))
for a,f in zip(ax.ravel(),fs):
    a.imshow(mpimg.imread(f)); a.set_title("theta="+f.split("theta_")[1].split(".")[0],fontsize=16); a.axis("off")
plt.tight_layout(); plt.savefig("images/sweep_montage.png",dpi=85)
print("saved images/sweep_montage.png")
