"""Extract MARVL timeseries skill statistics into a tidy CSV (no image scraping).

MARVL's timeseries module (isSaveErr=1) saves `errorMatrix` to the config's
ErrFilename as a .mat:  errorMatrix.<zone>.<variable>.<metric>
with scalar metrics BIAS, MAE, MEF, NMAE, NRMS, R, RMS plus the matched raw
series (rawOBS/rawSIM[,_layers]) from which n_matched is derived.

NB the matrix scores **ncfile(1) only** (aed-marvl computes skill for mod==1),
so the model each .mat describes is declared in RUNS below, not inferred.

Chunked runs (MARVL_WQ_*_chunk*.m) each save their own errormatrix_chunk*.mat;
this script merges every matching .mat listed for a run.

Output: marvl_stats.csv (long form):
    set, sim, model, zone, variable, metric, value, n_matched

Usage:  python extract_marvl_stats.py [out_csv]
"""
import sys
import glob
import numpy as np
import pandas as pd
from pathlib import Path
from scipy.io import loadmat

ROOT = Path(r"Q:/SEAF-CS/V1.8/MARVL/csiem-marvl/marvl/outputs")

# Each entry: which .mat files belong to which (set, sim) and which model
# (= ncfile(1) of the config that produced them) they score.
RUNS = [
    dict(set="008_1.8_comparison", sim="2013B", model="csiem1.8.0",
         mats="008_1.8_comparison/2013A/errormatrix*.mat"),
    # NB: two-model comparison matrices are always all-NaN (skill only works
    # single-model); 1.7 stats come from dedicated stats17 passes instead.
    dict(set="008_1.8_comparison", sim="2021B", model="csiem1.7.0",
         mats="008_1.8_comparison/2021B_stats17/errormatrix*.mat"),
    dict(set="008_1.8_comparison", sim="2013A", model="csiem1.7.0",   # 1.7's 2013 reference is A-mesh
         mats="008_1.8_comparison/2013A_stats17/errormatrix*.mat"),
    dict(set="008_1.8_comparison", sim="2021B", model="csiem1.8.0",   # single-model stats pass
         mats="008_1.8_comparison/2021A_stats18/errormatrix*.mat"),
    dict(set="008_1.8_comparison", sim="2015B", model="csiem1.8.0",   # single-model WEMDEV run
         mats="008_1.8_comparison/2015B/errormatrix*.mat"),
    dict(set="008_1.8_comparison", sim="2022B", model="csiem1.8.0",   # single-model stats pass
         mats="008_1.8_comparison/2022B_stats18/errormatrix*.mat"),
    dict(set="008_1.8_comparison", sim="2015A", model="csiem1.7.0",   # 1.7's 2015 reference is A-mesh
         mats="008_1.8_comparison/2015A_stats17/errormatrix*.mat"),
    dict(set="008_1.8_comparison", sim="2022B", model="csiem1.7.0",
         mats="008_1.8_comparison/2022B_stats17/errormatrix*.mat"),
]

METRICS = ["BIAS", "MAE", "MEF", "NMAE", "NRMS", "R", "RMS"]


def walk_matrix(matfile):
    m = loadmat(matfile, squeeze_me=True, struct_as_record=False)
    em = m["errorMatrix"]
    for zone in [f for f in dir(em) if not f.startswith("_")]:
        zs = getattr(em, zone)
        if not hasattr(zs, "_fieldnames"):
            continue
        for var in zs._fieldnames:
            vs = getattr(zs, var)
            if not hasattr(vs, "_fieldnames"):
                continue
            raw = np.atleast_1d(getattr(vs, "rawOBS", np.array([])))
            n = int(np.isfinite(raw.astype(float)).sum()) if raw.size else 0
            for met in METRICS:
                if met in vs._fieldnames:
                    val = getattr(vs, met)
                    val = float(val) if np.isscalar(val) or getattr(val, "size", 0) == 1 else np.nan
                    yield zone, var, met, val, n


def main(out_csv="marvl_stats.csv"):
    rows = []
    for run in RUNS:
        mats = sorted(glob.glob(str(ROOT / run["mats"])))
        if not mats:
            print(f"  (no .mat yet for {run['sim']} {run['model']} — {run['mats']})")
            continue
        for mf in mats:
            k = 0
            for zone, var, met, val, n in walk_matrix(mf):
                rows.append(dict(set=run["set"], sim=run["sim"], model=run["model"],
                                 zone=zone, variable=var, metric=met,
                                 value=val, n_matched=n, source=Path(mf).name))
                k += 1
            print(f"  {run['sim']} {run['model']} <- {Path(mf).name}: {k} rows")
    df = pd.DataFrame(rows)
    if df.empty:
        print("no stats found"); return
    # chunk overlap: keep the last-written value per key
    df = df.drop_duplicates(subset=["set", "sim", "model", "zone", "variable", "metric"], keep="last")
    out = Path(__file__).parent / out_csv
    df.to_csv(out, index=False)
    print(f"wrote {out} ({len(df)} rows, "
          f"{df.zone.nunique()} zones, {df.variable.nunique()} variables, "
          f"{df.groupby(['sim','model']).ngroups} sim×model runs)")


if __name__ == "__main__":
    main(*sys.argv[1:])
