"""Version-comparison report card: is model B better than model A, zone by zone?

Reads marvl_stats.csv (from extract_marvl_stats.py) and renders HTML where each
cell is the CHANGE between two model versions, coloured by *improvement*:

    green  = improved   (error down / correlation up, beyond tolerance)
    yellow = unchanged  (within tolerance)
    red    = degraded
Cell text: "a -> b" so the underlying values stay visible. Roll-ups per region
and an overview page (variables x sims: % zones improved, median deltas) give
the one-glance verdict without opening a single figure.

Improvement orientation: MAE/RMS/NMAE/NRMS lower=better; R/MEF higher=better;
BIAS judged on |BIAS|. Zones enter only if both versions have n_matched >= NMIN.

Sim pairing maps each year to the sim run under each version (2013 pairs the
old A-mesh reference against the new B-mesh run — the mesh change is part of
the version upgrade).

Usage: python make_comparison_card.py [--a csiem1.7.0] [--b csiem1.8.0]
"""
import argparse
from pathlib import Path
import numpy as np
import pandas as pd

HERE = Path(__file__).parent
PAIRS = {"2013": ("2013A", "2013B"), "2021": ("2021B", "2021B"),
         "2015": ("2015A", "2015B"), "2022": ("2022B", "2022B")}
METRICS = ["MAE", "RMS", "R", "BIAS"]
LOWER_BETTER = {"MAE", "RMS", "NMAE", "NRMS"}
NMIN = 10
# tolerance for "unchanged": max(rel% of baseline, absolute floor)
TOL_REL = 0.05
TOL_ABS = {"R": 0.02, "BIAS": 0.02, "MAE": 0.02, "RMS": 0.02}

VAR_LABELS = {"TEMP": "Temperature", "SAL": "Salinity", "WQ_OXY_OXY": "Dissolved Oxygen",
              "WQ_DIAG_TOT_TURBIDITY": "Turbidity", "WQ_DIAG_PHY_TCHLA": "Chlorophyll-a"}
REGION = [("North (Gage Rds/Freo)", ("GR_", "Freo", "SCE_")), ("Owen Anchorage", ("OA",)),
          ("Cockburn Sound", ("CS_",)),
          ("South", ("Comet", "SW_", "Warnbro", "Sepia", "Falcon", "Murray", "Kingston")),
          ("West/offshore", ("RI_", "IO_", "Stragglers", "Carnac", "Mewstone", "Horseshoe", "Parmelia"))]

CSS = """body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1{font-size:19px}h2{font-size:15px;margin-top:24px}h3{font-size:13px;color:#555}
table{border-collapse:collapse;margin:6px 0 18px 0;font-size:11.5px}
th,td{border:1px solid #ccc;padding:3px 8px;text-align:center}
th{background:#f0f0f0}td.zone{text-align:left}
.g{background:#c6efce}.y{background:#ffffcc}.r{background:#ffc7ce}.na{color:#bbb}
.small{font-size:11px;color:#777}.big{font-size:14px;font-weight:bold}"""


def verdict(metric, a, b):
    if not (np.isfinite(a) and np.isfinite(b)):
        return "na", np.nan
    xa, xb = (abs(a), abs(b)) if metric == "BIAS" else (a, b)
    delta = xb - xa
    if metric in LOWER_BETTER or metric == "BIAS":
        improved = delta < 0
    else:
        improved = delta > 0
    tol = max(TOL_REL * abs(xa), TOL_ABS.get(metric, 0.02))
    if abs(delta) <= tol:
        return "y", delta
    return ("g" if improved else "r"), delta


def main(model_a, model_b):
    df = pd.read_csv(HERE / "marvl_stats.csv")
    ok = df[df.value.notna() & (df.n_matched >= NMIN)]
    out = HERE / f"compare_{model_a}_vs_{model_b}"
    out.mkdir(exist_ok=True)
    summary_rows, pages = [], []
    variables = [v for v in ["TEMP", "SAL", "WQ_OXY_OXY", "WQ_DIAG_TOT_TURBIDITY"]
                 if v in ok.variable.unique()] + \
                sorted(set(ok.variable.unique()) - {"TEMP", "SAL", "WQ_OXY_OXY", "WQ_DIAG_TOT_TURBIDITY"})
    for var in variables:
        body = [f"<h1>{VAR_LABELS.get(var, var)}: {model_a} → {model_b}</h1>",
                '<p class="small">cell = baseline → candidate; green improved, '
                'yellow unchanged (within tolerance), red degraded. BIAS judged on |BIAS|.</p>']
        wrote_any = False
        for year, (sa, sb) in PAIRS.items():
            A = ok[(ok.model == model_a) & (ok.sim == sa) & (ok.variable == var)]
            B = ok[(ok.model == model_b) & (ok.sim == sb) & (ok.variable == var)]
            if A.empty or B.empty:
                continue
            m = A.merge(B, on=["zone", "metric"], suffixes=("_a", "_b"))
            if m.empty:
                continue
            wrote_any = True
            body.append(f"<h2>{year} ({sa} vs {sb})</h2>")
            for met in METRICS:
                s = m[m.metric == met].set_index("zone")
                if s.empty:
                    continue
                res = {z: verdict(met, s.value_a[z], s.value_b[z]) for z in s.index}
                cls = pd.Series({z: r[0] for z, r in res.items()})
                dlt = pd.Series({z: r[1] for z, r in res.items()})
                n = dict(g=(cls == "g").sum(), y=(cls == "y").sum(), r=(cls == "r").sum())
                summary_rows.append(dict(variable=var, year=year, metric=met,
                                         improved=n["g"], unchanged=n["y"], degraded=n["r"],
                                         median_delta=float(np.nanmedian(dlt))))
                body.append(f"<h3>{met} — improved {n['g']} / unchanged {n['y']} / degraded {n['r']} "
                            f"(median Δ {np.nanmedian(dlt):+.3f})</h3>")
                body.append("<table><tr><th>Region</th><th>Zone</th><th>" +
                            f"{model_a}</th><th>{model_b}</th><th>Δ</th></tr>")
                for rname, pref in REGION:
                    for z in sorted(z for z in s.index if z.startswith(pref)):
                        c, d = res[z]
                        body.append(f'<tr><td class="zone small">{rname}</td><td class="zone">{z}</td>'
                                    f'<td>{s.value_a[z]:.2f}</td><td>{s.value_b[z]:.2f}</td>'
                                    f'<td class="{c}">{d:+.2f}</td></tr>')
                body.append("</table>")
        if wrote_any:
            fn = var.lower() + ".html"
            (out / fn).write_text("<html><head><meta charset='utf-8'><style>" + CSS +
                                  "</style></head><body>" + "\n".join(body) + "</body></html>",
                                  encoding="utf-8")
            pages.append((VAR_LABELS.get(var, var), fn))
            print("wrote", fn)

    # overview: one row per variable x year x metric with the win/loss verdict
    sm = pd.DataFrame(summary_rows)
    if sm.empty:
        print("nothing to compare yet"); return
    sm.to_csv(out / "summary.csv", index=False)
    body = [f"<h1>Model comparison overview: {model_a} → {model_b}</h1>",
            '<p class="small">Per variable/year/metric: zones improved / unchanged / degraded '
            f'(zones need n≥{NMIN} matched obs in both versions).</p>',
            "<table><tr><th>Variable</th><th>Year</th><th>Metric</th><th>Improved</th>"
            "<th>Unchanged</th><th>Degraded</th><th>Median Δ</th><th>Verdict</th></tr>"]
    for _, r in sm.iterrows():
        v = "g" if r.improved > r.degraded else ("r" if r.degraded > r.improved else "y")
        word = {"g": "BETTER", "y": "neutral", "r": "WORSE"}[v]
        body.append(f"<tr><td>{VAR_LABELS.get(r.variable, r.variable)}</td><td>{r.year}</td>"
                    f"<td>{r.metric}</td><td>{r.improved}</td><td>{r.unchanged}</td>"
                    f"<td>{r.degraded}</td><td>{r.median_delta:+.3f}</td>"
                    f'<td class="{v} big">{word}</td></tr>')
    body.append("</table><h2>Variable pages</h2><ul>")
    body += [f'<li><a href="{fn}">{t}</a></li>' for t, fn in pages] + ["</ul>"]
    (out / "index.html").write_text("<html><head><meta charset='utf-8'><style>" + CSS +
                                    "</style></head><body>" + "\n".join(body) + "</body></html>",
                                    encoding="utf-8")
    print("wrote index.html + summary.csv")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", default="csiem1.7.0")
    ap.add_argument("--b", default="csiem1.8.0")
    x = ap.parse_args()
    main(x.a, x.b)
