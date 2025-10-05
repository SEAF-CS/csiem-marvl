#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fremantle sea-level vs R-Niño3.4 correlation for identifying anomolous years in CS

Inputs (same folder):
  - h175.csv               # columns: year, month, day, hour, rsl_mm (hourly). Remove rows with rsl_mm <= -10
  - rnino34-monthly.txt    # columns: datecode (yyyymmddYYYYMM), value (monthly R-Niño3.4)

Outputs:
  - three_panel_plot_data.csv
  - three_panel_plot.png
  - correlation_plot.png
  - correlation_summary.csv
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import pearsonr, linregress

# ---------- Load Fremantle sea-level (hourly) ----------
cols = ["year", "month", "day", "hour", "rsl_mm"]
df = pd.read_csv("../h175.csv", names=cols, skiprows=1)
df = df[df["rsl_mm"] > -10]  # remove bad values
df["datetime"] = pd.to_datetime(dict(year=df.year, month=df.month, day=df.day, hour=df.hour), errors="coerce")
df = df.dropna(subset=["datetime"])

# Monthly means
monthly = df.resample("M", on="datetime")["rsl_mm"].mean().to_frame()
monthly["year"] = monthly.index.year
monthly["month"] = monthly.index.month

# MJJ climatology and anomaly
mjj = monthly[monthly["month"].isin([5, 6, 7])]
mjj_clim_mean = mjj["rsl_mm"].mean()
mjj_yearly = mjj.groupby("year")["rsl_mm"].mean().to_frame()
mjj_yearly["anomaly_mm"] = mjj_yearly["rsl_mm"] - mjj_clim_mean

# Annual mean anomaly
annual_mean = monthly.groupby("year")["rsl_mm"].mean().to_frame()
annual_clim = annual_mean["rsl_mm"].mean()
annual_mean["anomaly_mm"] = annual_mean["rsl_mm"] - annual_clim

# ---------- Load R-Niño3.4 and get annual means ----------
r34 = pd.read_csv("rnino34-monthly.txt", header=None, names=["datecode", "value"])
r34["year"] = r34["datecode"].astype(str).str[:4].astype(int)
r34_annual = r34.groupby("year")["value"].mean().reset_index()

# ---------- Merge datasets ----------
merged = pd.DataFrame({
    "Year": annual_mean.index.values,
    "annual_anom_cm": (annual_mean["anomaly_mm"] / 10).values,
    "mjj_anom_cm": (mjj_yearly["anomaly_mm"] / 10).values,
}).merge(r34_annual, left_on="Year", right_on="year", how="left")

# ---------- Annual trend (for three-panel + detrending) ----------
x = merged["Year"].astype(float).values
y = merged["annual_anom_cm"].astype(float).values
slope, intercept = np.polyfit(x, y, 1)  # cm/yr
trendline = slope * x + intercept

# Detrend & center the MJJ anomalies
ref_year = merged["Year"].min()
mjj_detrended = merged["mjj_anom_cm"] - slope * (merged["Year"] - ref_year)
mjj_detrended_centered = mjj_detrended - mjj_detrended.mean()

# Save combined data used in plots
out = pd.DataFrame({
    "Year": merged["Year"],
    "rnino34_annual": merged["value"],
    "annual_anom_cm": merged["annual_anom_cm"],
    "annual_trend_cm": trendline,
    "mjj_anom_cm_detrended_centered": mjj_detrended_centered,
})
out.to_csv("three_panel_plot_data.csv", index=False)

# ---------- Two-panel correlation plot ----------
valid = out.dropna(subset=["rnino34_annual", "mjj_anom_cm_detrended_centered"])

# Correlations (no lag)
r_annual, p_annual = pearsonr(out["rnino34_annual"].dropna(), out["annual_anom_cm"].dropna())
r_mjj, p_mjj = pearsonr(valid["rnino34_annual"], valid["mjj_anom_cm_detrended_centered"])

# Regression for lines
sa, ia, _, _, _ = linregress(out["rnino34_annual"].dropna(), out["annual_anom_cm"].dropna())
sb, ib, _, _, _ = linregress(valid["rnino34_annual"], valid["mjj_anom_cm_detrended_centered"])

xa = np.linspace(out["rnino34_annual"].min(), out["rnino34_annual"].max(), 100)
xb = np.linspace(valid["rnino34_annual"].min(), valid["rnino34_annual"].max(), 100)

fig, axs = plt.subplots(1, 2, figsize=(11, 5))

# (a) Annual anomaly
axs[0].scatter(out["rnino34_annual"], out["annual_anom_cm"], alpha=0.85)
axs[0].plot(xa, sa * xa + ia, linewidth=1.8)
axs[0].set_xlabel("R-Niño3.4 (annual mean)")
axs[0].set_ylabel("Annual sea level anomaly (cm)")
axs[0].set_title(f"(a) Annual anomaly\nr = {r_annual:.2f}, p = {p_annual:.3g}")
axs[0].grid(True, linestyle=":", linewidth=0.7)

# (b) MJJ de-trended anomaly
axs[1].scatter(valid["rnino34_annual"], valid["mjj_anom_cm_detrended_centered"], alpha=0.85)
axs[1].plot(xb, sb * xb + ib, linewidth=1.8)
axs[1].set_xlabel("R-Niño3.4 (annual mean)")
axs[1].set_ylabel("MJJ de-trended anomaly (cm)")
axs[1].set_title(f"(b) MJJ de-trended anomaly\nr = {r_mjj:.2f}, p = {p_mjj:.3g}")
axs[1].grid(True, linestyle=":", linewidth=0.7)

plt.tight_layout()
plt.savefig("correlation_plot.png", dpi=200)
plt.show()

# ---------- Save correlation summary ----------
corr_summary = pd.DataFrame({
    "series": ["Annual anomaly (cm)", "MJJ de-trended anomaly (cm)"],
    "r": [r_annual, r_mjj],
    "p_value": [p_annual, p_mjj],
    "n_years": [out["annual_anom_cm"].dropna().shape[0], valid.shape[0]],
    "annual_trend_slope_cm_per_year": [slope, slope],
})
corr_summary.to_csv("correlation_summary.csv", index=False)

print("Saved: three_panel_plot_data.csv, correlation_plot.png, correlation_summary.csv")
print(f"Annual trend slope: {slope:.3f} cm/yr")
