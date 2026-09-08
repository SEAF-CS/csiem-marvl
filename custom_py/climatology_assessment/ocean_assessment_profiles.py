"""Per-cast 2-panel (T | S) depth-profile comparisons: OBS + BC (ROMS-clim/HYCOM) +
TUFLOW-FV (where a run covers the cast). Redo of compare_to_roms.py's per-cast plots,
with the model profile added. Reuses ocean_assessment_core's readers/samplers."""
import os, csv, sys, numpy as np, pandas as pd, warnings
warnings.filterwarnings('ignore')
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ocean_assessment_core as core

OUT = os.path.join(core.OUT_DIR, 'profiles')
INV = r'Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/climatology/outer_profiles_inventory.csv'

# ---- full-depth source profiles (the core module only returns surface/bottom scalars) ----
def bc_profile(year, dt, lat, lon):
    path, latn, lonn = core.bc_spec(year, dt)
    try: d = core._bc_ds(path)
    except Exception: return None
    lats = d[latn].values; lons = d[lonn].values
    ilat = int(np.argmin(np.abs(lats - lat))); ilon = int(np.argmin(np.abs(lons - lon)))
    t = pd.to_datetime(d['time'].values); it = int(np.argmin(np.abs(t - (dt + pd.Timedelta(hours=12)))))
    dep = d['depth'].values
    T = np.asarray(d['water_temp'][it, :, ilat, ilon], 'float64'); S = np.asarray(d['salinity'][it, :, ilat, ilon], 'float64')
    ok = np.isfinite(T) & np.isfinite(S)
    if ok.sum() < 2: return None
    o = np.argsort(dep[ok])
    return dict(depth=dep[ok][o], T=T[ok][o], S=S[ok][o], src=('ROMS clim' if latn == 'lat' else 'HYCOM'))

def model_profile(dt, lat, lon):
    path = next((p for a, b, p in core.FV_RUNS if pd.Timestamp(a) <= dt <= pd.Timestamp(b)), None)
    if path is None: return None
    try:
        fvacc, times = core._fv(path)
        md = times[int(np.argmin(np.abs(times - (dt + pd.Timedelta(hours=12)))))]
        if abs(md - (dt + pd.Timedelta(hours=12))) > pd.Timedelta(days=1): return None
        prof = fvacc.get_profile((lon, lat), variables=['SAL', 'TEMP'], time=md)
        pt = prof.sel(Time=md, method='nearest') if 'Time' in prof.dims else prof
        z = -np.asarray(pt['Z']).ravel(); T = np.asarray(pt['TEMP']).ravel(); S = np.asarray(pt['SAL']).ravel()
        ok = np.isfinite(z) & np.isfinite(T) & np.isfinite(S)
        if ok.sum() < 2: return None
        o = np.argsort(z[ok])
        return dict(depth=z[ok][o], T=T[ok][o], S=S[ok][o], t_used=str(md))
    except Exception:
        return None

def profile_fig(row, save=True, show=False):
    year = int(row['year']); dt = pd.Timestamp(row['date']); lat = float(row['lat']); lon = float(row['lon'])
    cast = core.read_cast(row['source_file'], row['prefix'])
    if cast is None: return None, False
    od, oT, oS = cast
    bc = bc_profile(year, dt, lat, lon)
    mo = model_profile(dt, lat, lon)
    ymax = float(od.max()) + 3.0

    fig, (axT, axS) = plt.subplots(1, 2, figsize=(9, 7), sharey=True)
    for ax, ov, label, unit in [(axT, oT, 'Temperature', '°C'), (axS, oS, 'Salinity', 'psu')]:
        ax.plot(ov, od, '-o', color='k', ms=3, lw=1.5, label='obs', zorder=5)
        if bc is not None:
            ax.plot(bc['T'] if ax is axT else bc['S'], bc['depth'], '-s', color='steelblue', ms=4, lw=1.5,
                    label=f"BC ({bc['src']})", zorder=4)
        if mo is not None:
            ax.plot(mo['T'] if ax is axT else mo['S'], mo['depth'], '-x', color='red', ms=5, lw=1.5,
                    label='TUFLOW-FV', zorder=6)
        ax.set_xlabel(f'{label} ({unit})'); ax.grid(alpha=0.3)
    axT.set_ylabel('Depth (m)'); axT.set_ylim(ymax, 0); axT.legend(fontsize=8, loc='lower left')
    sub = core.subregion(lat)
    mtag = '' if mo is None else '  + TUFLOW-FV'
    fig.suptitle(f"{row['station']}  {row['date']} {row['time']}  ({sub})  obs vs BC{mtag}", fontsize=11, fontweight='bold')
    fig.tight_layout(rect=[0, 0, 1, 0.96])
    p = None
    if save:
        yd = os.path.join(OUT, str(year)); os.makedirs(yd, exist_ok=True)
        p = os.path.join(yd, f"{row['date']}_{row['station']}_{row['time']}.png")
        fig.savefig(p, dpi=120)
    if show: plt.show()
    else: plt.close(fig)
    return p, (mo is not None)

def run(limit=None, only_model_covered=False, rows_filter=None):
    rows = list(csv.DictReader(open(INV)))
    if rows_filter: rows = [r for r in rows if rows_filter(r)]
    if limit: rows = rows[:limit]
    n_done = n_model = 0
    for i, r in enumerate(rows):
        dt = pd.Timestamp(r['date'])
        if only_model_covered and not any(pd.Timestamp(a) <= dt <= pd.Timestamp(b) for a, b, _ in core.FV_RUNS):
            continue
        out, had_model = profile_fig(r)
        if out:
            n_done += 1
            if had_model: n_model += 1
        if (i + 1) % 50 == 0: print(f'  {i+1}/{len(rows)} ({n_done} saved, {n_model} with model)'); sys.stdout.flush()
    print(f'Done: {n_done} profile figures ({n_model} include a TUFLOW-FV profile) under {OUT}')

if __name__ == '__main__':
    lim = int(sys.argv[1]) if len(sys.argv) > 1 else None
    run(limit=lim)
