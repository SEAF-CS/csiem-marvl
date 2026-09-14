"""T & S performance: csiem 1.7 (old reference) vs 1.8 (new) from MARVL stats.

Joins marvl_stats.csv 1.7/1.8 entries per year, zone-specific and overall.
2021 is like-mesh (B010 vs B010); 2013 compares the old A002 reference
against the new B010 run (mesh change is part of the upgrade).

Outputs: console summary + TS_17_vs_18.csv + TS_17_vs_18.html
"""
from pathlib import Path
import numpy as np
import pandas as pd

HERE = Path(__file__).parent
PAIRS = [("2013", "2013A", "2013B"), ("2021", "2021B", "2021B")]  # (year, 1.7 sim, 1.8 sim)
METRICS = ["R", "MAE", "RMS", "BIAS"]

REGION = [
    ("North (Gage Rds/Freo)", ("GR_", "Freo", "SCE_")),
    ("Owen Anchorage", ("OA",)),
    ("Cockburn Sound", ("CS_",)),
    ("South", ("Comet", "SW_", "Warnbro", "Sepia", "Falcon", "Murray", "Kingston")),
    ("West/offshore", ("RI_", "IO_", "Stragglers", "Carnac", "Mewstone", "Horseshoe", "Parmelia")),
]

def region_of(z):
    for name, prefixes in REGION:
        if z.startswith(prefixes):
            return name
    return "Other"

def main():
    df = pd.read_csv(HERE / "marvl_stats.csv")
    df = df[df.variable.isin(["TEMP", "SAL"]) & df.metric.isin(METRICS) & df.value.notna()]
    rows, html = [], []
    for year, s17, s18 in PAIRS:
        a = df[(df.sim == s17) & (df.model == "csiem1.7.0")]
        b = df[(df.sim == s18) & (df.model == "csiem1.8.0")]
        if a.empty or b.empty:
            print(f"{year}: missing side (1.7 n={len(a)}, 1.8 n={len(b)}) — run stats passes first")
            continue
        m = a.merge(b, on=["zone", "variable", "metric"], suffixes=("_17", "_18"))
        m["year"] = year
        m["region"] = m.zone.map(region_of)
        rows.append(m)
    if not rows:
        return
    m = pd.concat(rows)
    m.to_csv(HERE / "TS_17_vs_18.csv", index=False)

    def fmt(sub, by):
        g = sub.groupby(by).agg(v17=("value_17", "median"), v18=("value_18", "median"),
                                n=("zone", "nunique")).round(3)
        g["delta"] = (g.v18 - g.v17).round(3)
        return g

    for year in m.year.unique():
        for var in ["TEMP", "SAL"]:
            sub = m[(m.year == year) & (m.variable == var)]
            if sub.empty:
                continue
            print(f"\n===== {year}  {var}  (median across {sub.zone.nunique()} zones with data) =====")
            for met in METRICS:
                s = sub[sub.metric == met]
                overall = fmt(s.assign(all="overall"), "all")
                per_region = fmt(s, "region")
                print(f"-- {met}: overall 1.7={overall.v17.iloc[0]}  1.8={overall.v18.iloc[0]}  "
                      f"delta={overall.delta.iloc[0]}")
                print(per_region.to_string())
    print("\nwrote TS_17_vs_18.csv")

if __name__ == "__main__":
    main()
