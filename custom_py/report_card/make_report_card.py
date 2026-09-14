"""Generate CSIEM report-card HTML pages from marvl_stats.csv (no image scraping).

One HTML per variable (temperature.html-style): metric tables with zone rows
grouped by region and one column per simulation year, plus a *_Region
aggregate table. Reads the tidy CSV written by extract_marvl_stats.py.

Metrics shown: MAE, R, BIAS (MARVL 'range' scoremethod semantics: matched
model value = obs when obs falls inside the model percentile envelope, else
the nearest envelope bound — so MAE reads as mean exceedance of the model
range, and can be < |BIAS|).

Usage: python make_report_card.py [--model csiem1.8.0] [--out output/]
"""
import argparse
from pathlib import Path
import numpy as np
import pandas as pd

HERE = Path(__file__).parent

VAR_LABELS = {  # AED name -> (page title, units)
    "TEMP": ("Temperature", "degC"), "SAL": ("Salinity", "psu"),
    "WQ_OXY_OXY": ("Dissolved Oxygen", "mg/L"),
    "WQ_DIAG_TOT_TURBIDITY": ("Turbidity", "NTU"),
    "WQ_DIAG_PHY_TCHLA": ("Chlorophyll-a", "ug/L"),
    "WQ_DIAG_TOT_TSS": ("TSS", "mg/L"), "WQ_DIAG_TOT_TN": ("Total Nitrogen", "mg/L"),
    "WQ_NIT_AMM": ("Ammonium", "mg/L"), "WQ_NIT_NIT": ("Nitrate", "mg/L"),
    "WQ_DIAG_TOT_TP": ("Total Phosphorus", "mg/L"), "WQ_PHS_FRP": ("Phosphate", "mg/L"),
    "H": ("Water Level", "m"), "WQ_DIAG_TOT_PAR": ("PAR", "W/m2"),
    "WQ_DIAG_TOT_EXTC": ("Light Extinction", "1/m"),
}
PRIORITY = ["TEMP", "SAL", "WQ_OXY_OXY", "WQ_DIAG_TOT_TURBIDITY"]

REGIONS = [  # (section title, zone-name predicate)
    ("North (Gage Roads & Fremantle)", lambda z: z.startswith(("GR_", "Freo", "SCE_"))),
    ("Owen Anchorage",                 lambda z: z.startswith("OA")),
    ("Cockburn Sound",                 lambda z: z.startswith("CS_")),
    ("South (Warnbro, Comet Bay & Surrounds)",
     lambda z: z.startswith(("Comet", "SW_", "Warnbro", "Sepia", "Falcon", "Murray", "Kingston"))),
    ("West (Rottnest & offshore)",     lambda z: z.startswith(("RI_", "IO_", "Stragglers", "Carnac",
                                                               "Mewstone", "Horseshoe", "Parmelia"))),
]

CSS = """
body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1{font-size:20px} h2{font-size:16px;margin-top:28px} h3{font-size:13px;color:#555}
table{border-collapse:collapse;margin:8px 0 20px 0;font-size:12px}
th,td{border:1px solid #ccc;padding:3px 10px;text-align:right}
th{background:#f0f0f0} td.zone{text-align:left}
.g{background:#c6efce}.y{background:#ffeb9c}.r{background:#ffc7ce}.na{color:#bbb}
.small{font-size:11px;color:#777}
"""

# traffic-light thresholds per metric: (good<=, ok<=) for MAE-like; R is reversed
def cell_class(metric, v, var):
    if not np.isfinite(v):
        return "na"
    if metric == "R":
        return "g" if v >= 0.8 else ("y" if v >= 0.5 else "r")
    scale = dict(TEMP=(0.5, 1.0), SAL=(0.3, 0.6)).get(var)
    if metric in ("MAE",) and scale:
        return "g" if v <= scale[0] else ("y" if v <= scale[1] else "r")
    if metric == "BIAS" and scale:
        return "g" if abs(v) <= scale[0] else ("y" if abs(v) <= scale[1] else "r")
    return ""


def table_html(sub, zones, sims, metric, var):
    h = ["<table><tr><th>Zone</th>" + "".join(f"<th>{s}</th>" for s in sims) + "</tr>"]
    for z in zones:
        cells = []
        for s in sims:
            v = sub[(sub.zone == z) & (sub.sim == s) & (sub.metric == metric)].value
            v = float(v.iloc[0]) if len(v) else np.nan
            txt = f"{v:.2f}" if np.isfinite(v) else "–"
            cells.append(f'<td class="{cell_class(metric, v, var)}">{txt}</td>')
        h.append(f'<tr><td class="zone">{z}</td>' + "".join(cells) + "</tr>")
    h.append("</table>")
    return "\n".join(h)


def main(model="csiem1.8.0", out="output"):
    df = pd.read_csv(HERE / "marvl_stats.csv")
    df = df[df.model == model]
    outdir = HERE / out
    outdir.mkdir(exist_ok=True)
    sims = sorted(df.sim.unique())
    pages = []
    var_order = PRIORITY + [v for v in sorted(df.variable.unique()) if v not in PRIORITY]
    for var in var_order:
        sub = df[(df.variable == var) & df.value.notna()]
        if sub.empty:
            continue
        title, units = VAR_LABELS.get(var, (var, ""))
        body = [f"<h1>CSIEM Report Card: {title} ({model})</h1>",
                f'<p class="small">Generated from MARVL errorMatrix stats '
                f'(marvl_stats.csv) — no image scraping. Metrics use the MARVL '
                f'"range" scoremethod. Units: {units}.</p>']
        for metric, mtitle in [("MAE", f"Mean Absolute Error ({units})"),
                               ("R", "Correlation Coefficient (R)"),
                               ("BIAS", f"Bias ({units})")]:
            body.append(f"<h2>{mtitle}</h2>")
            agg = sorted(z for z in sub.zone.unique() if z.endswith("_Region"))
            if agg:
                body.append("<h3>Region aggregates</h3>")
                body.append(table_html(sub, agg, sims, metric, var))
            for rtitle, pred in REGIONS:
                zones = sorted(z for z in sub.zone.unique()
                               if pred(z) and not z.endswith("_Region"))
                if zones:
                    body.append(f"<h3>{rtitle}</h3>")
                    body.append(table_html(sub, zones, sims, metric, var))
        fn = title.lower().replace(" ", "_").replace("-", "") + ".html"
        (outdir / fn).write_text(
            f"<html><head><meta charset='utf-8'><title>{title}</title>"
            f"<style>{CSS}</style></head><body>" + "\n".join(body) + "</body></html>",
            encoding="utf-8")
        pages.append((title, fn))
        print("wrote", fn)
    idx = ["<h1>CSIEM 1.8 Report Card</h1><ul>"] + \
          [f'<li><a href="{fn}">{t}</a></li>' for t, fn in pages] + ["</ul>"]
    (outdir / "index.html").write_text(
        f"<html><head><style>{CSS}</style></head><body>" + "\n".join(idx) + "</body></html>",
        encoding="utf-8")
    print(f"wrote index.html ({len(pages)} variables, sims: {', '.join(sims)})")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="csiem1.8.0")
    ap.add_argument("--out", default="output")
    a = ap.parse_args()
    main(a.model, a.out)
