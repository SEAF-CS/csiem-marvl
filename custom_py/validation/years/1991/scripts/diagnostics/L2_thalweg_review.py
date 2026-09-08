"""L2 estuary thalweg review: trace the model THALWEG (deep-channel centreline) from OA10
(Fremantle mouth) up to the Narrows by a least-cost path over the model cells — deep cells
(cell_Zb) are cheap, shallow cells expensive — so the route follows the sinuous deep channel
rather than snapping to the nearest wet cell. Plan-view bed map + along-path bed profile.
-> years/1991/outputs/diagnostics/transect_long/L2_thalweg_review.png
"""
import os, numpy as np, xarray as xr
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.spatial import cKDTree
from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import dijkstra

NC = r'S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev_ITER7/csiem_B010_19910720_19910831_rev.nc'
OUT = r'Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/custom_py/validation/years/1991/outputs/diagnostics/transect_long/L2_thalweg_review.png'
BETA = 0.8         # depth cost: cost/km ~ exp(-BETA*depth); higher => hug the deep channel harder
KNN = 14; MAXD = 0.28   # graph: k nearest cells, drop edges longer than MAXD km (small => no corner-cutting)
SMOOTH = 3

# anchors + landmarks (lon, lat)
OA10 = (115.7305, -32.0563); NARW = (115.847, -31.963)
LM = [('OA10', *OA10), ('Fmouth', 115.736, -32.053), ('neck', 115.780, -32.019), ('NAR', *NARW)]
# original hand-drawn path for comparison
ORIG = [(115.7305,-32.0563),(115.736,-32.053),(115.742,-32.049),(115.747,-32.043),(115.753,-32.040),
        (115.759,-32.029),(115.767,-32.025),(115.780,-32.019),(115.796,-32.006),(115.812,-31.996),
        (115.828,-31.978),(115.847,-31.963)]

def km(lo, la):
    return lo * 111.32 * np.cos(np.radians(-32.0)), la * 111.32
def hav(lo1, la1, lo2, la2):
    R=6371.0; p1,p2=np.radians(la1),np.radians(la2); dlo,dla=np.radians(lo2-lo1),np.radians(la2-la1)
    return 2*R*np.arcsin(np.sqrt(np.sin(dla/2)**2+np.cos(p1)*np.cos(p2)*np.sin(dlo/2)**2))

print('opening NC (bed only) ...', flush=True)
ds = xr.open_dataset(NC)
X, Y, Zb = ds['cell_X'].values, ds['cell_Y'].values, np.asarray(ds['cell_Zb'])

# estuary region cells
box = (X > 115.71) & (X < 115.86) & (Y > -32.075) & (Y < -31.95)
idx = np.where(box)[0]; xb, yb, zb = X[idx], Y[idx], Zb[idx]
mx, my = km(xb, yb); pts = np.column_stack([mx, my]); n = len(idx)
print(f'{n} estuary cells')

# least-cost graph: deep cheap, shallow expensive
depth = np.clip(-zb, 0.1, None)
w = np.exp(-BETA * depth)
tree = cKDTree(pts); dist, nbr = tree.query(pts, k=KNN + 1)
rows=[]; cols=[]; data=[]
for i in range(n):
    for kk in range(1, KNN + 1):
        j = nbr[i, kk]; d = dist[i, kk]
        if d > MAXD: continue
        c = d * 0.5 * (w[i] + w[j])
        rows += [i, j]; cols += [j, i]; data += [c, c]
G = csr_matrix((data, (rows, cols)), shape=(n, n))

def nearest(lo, la):
    x0, y0 = km(lo, la); return int(np.argmin((mx - x0) ** 2 + (my - y0) ** 2))
i0, i1 = nearest(*OA10), nearest(*NARW)
_, pred = dijkstra(G, indices=i0, return_predecessors=True)
path = []; j = i1
while j != i0 and j >= 0:
    path.append(j); j = pred[j]
path.append(i0); path = path[::-1]
print(f'thalweg path: {len(path)} cells')
tlo, tla, tzb = xb[path], yb[path], zb[path]
if SMOOTH > 1:
    k = np.ones(SMOOTH) / SMOOTH
    tlo = np.convolve(tlo, k, 'same'); tla = np.convolve(tla, k, 'same')
    tlo[:SMOOTH], tla[:SMOOTH] = xb[path][:SMOOTH], yb[path][:SMOOTH]
    tlo[-SMOOTH:], tla[-SMOOTH:] = xb[path][-SMOOTH:], yb[path][-SMOOTH:]
tch = np.concatenate([[0], np.cumsum([hav(tlo[i], tla[i], tlo[i+1], tla[i+1]) for i in range(len(tlo)-1)])])
# landmark chainages (nearest along-path point)
lm_ch = {lab: tch[int(np.argmin((tlo-lo)**2 + (tla-la)**2))] for lab, lo, la in LM}

fig = plt.figure(figsize=(16, 11)); gs = fig.add_gridspec(2, 1, height_ratios=[2, 1], hspace=0.18)
axm = fig.add_subplot(gs[0]); axp = fig.add_subplot(gs[1])
sc = axm.scatter(xb, yb, s=11, c=zb, cmap='viridis', vmin=-16, vmax=0)
axm.plot([p[0] for p in ORIG], [p[1] for p in ORIG], 'r.-', lw=1, ms=3, alpha=0.6, label='original hand path')
axm.plot(tlo, tla, '-', color='magenta', lw=2.2, label=f'least-cost thalweg (β={BETA})')
for lab, lo, la in LM: axm.annotate(lab, (lo, la), fontsize=9, fontweight='bold')
axm.set_aspect('equal'); axm.legend(loc='upper left', fontsize=9); axm.grid(alpha=0.2)
axm.set_title('L2 estuary thalweg — least-cost through model bed Zb (m), OA10 (mouth) -> Narrows')
fig.colorbar(sc, ax=axm, label='bed elevation Zb (m)', pad=0.01)
axp.plot(tch, tzb, '-', color='#b0179a', lw=1.6, label='thalweg bed')
axp.axhline(0, color='b', ls='--', lw=0.8); axp.axhline(-1, color='r', ls=':', lw=0.8, label='~LAT (-1 m)')
for lab, c in lm_ch.items():
    axp.axvline(c, color='0.6', ls='--', lw=0.7); axp.text(c, axp.get_ylim()[1], lab, fontsize=8, rotation=90, va='top', ha='right')
axp.set_xlabel('chainage from OA10 (km)  [-> upstream/east to Narrows]'); axp.set_ylabel('bed Zb (m)')
axp.grid(alpha=0.3); axp.legend(fontsize=8)
fig.suptitle('L2 estuary thalweg (least-cost / deep-channel) — REVIEW', fontweight='bold')
fig.savefig(OUT, dpi=140, bbox_inches='tight'); print('wrote', OUT)

# persist the locked dense thalweg (OA10 -> NAR) as an importable module
mod = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'l2_thalweg.py')
with open(mod, 'w') as f:
    f.write('"""Locked L2 estuary thalweg: OA10 (Fremantle mouth) -> NAR (Narrows), least-cost\n'
            f'through model bed cell_Zb (beta={BETA}). Generated by L2_thalweg_review.py."""\n')
    f.write('THALWEG = [\n')
    for lo, la in zip(tlo, tla):
        f.write(f'    ({lo:.5f}, {la:.5f}),\n')
    f.write(']\n')
print('wrote', mod)

# emit coarse waypoints (~every 0.4 km) to lock into the L2 config
print('\nthalweg waypoints (lon, lat) ~every 0.4 km:')
sel = [0]
for i in range(1, len(tlo)):
    if tch[i] - tch[sel[-1]] >= 0.4: sel.append(i)
if sel[-1] != len(tlo) - 1: sel.append(len(tlo) - 1)
for i in sel: print(f'    ({tlo[i]:.4f}, {tla[i]:.4f}),  # {tch[i]:.1f} km')
