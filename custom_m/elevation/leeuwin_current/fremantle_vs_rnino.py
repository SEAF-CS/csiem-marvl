#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""

Create three-panel Fremantle vs R-Niño3.4 figure with:
- R-nino3.4 (from BOM website)
- Annual Freo data with annual anomaly trendline and slope 
- MJJ (peak LC period) anomalies detrended (by annual slope) and centered around zero
- Shaded regions above +4 cm (red) and below -4 cm (blue)
- Red labels for high MJJ years, blue labels for low MJJ years

Inputs (same folder):
  - h175.csv               # columns: year, month, day, hour, rsl_mm (hourly). Remove rows with rsl_mm <= -10
  - rnino34-monthly.txt    # columns: datecode (yyyymmddYYYYMM), value (monthly R-Niño3.4)

Outputs:
  - fremantle_three_panel_shaded_labeled.png (400 dpi)
  - fremantle_three_panel_shaded_labeled.pdf
  - fremantle_three_panel_shaded_labeled.svg
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ---------- Load Fremantle sea-level (hourly) ----------
cols = ["year", "month", "day", "hour", "rsl_mm"]
df = pd.read_csv("h175.csv", names=cols, skiprows=1)
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

# ---------- Load R-Niño3.4 (monthly), compute annual means ----------
r34 = pd.read_csv("rnino34-monthly.txt", header=None, names=["datecode", "value"])
r34["year"] = r34["datecode"].astype(str).str[:4].astype(int)
r34_annual = r34.groupby("year")["value"].mean().reset_index()

# ---------- Merge datasets ----------
merged = pd.DataFrame({
    "Year": annual_mean.index.values,
    "annual_anom_cm": (annual_mean["anomaly_mm"] / 10).values,
    "mjj_anom_cm": (mjj_yearly["anomaly_mm"] / 10).values,
}).merge(r34_annual, left_on="Year", right_on="year", how="left")

# ---------- Annual trend (for panel b) ----------
x = merged["Year"].astype(float).values
y = merged["annual_anom_cm"].astype(float).values
slope, intercept = np.polyfit(x, y, 1)  # cm/yr
trendline = slope * x + intercept

# Detrend & center the MJJ anomalies (for panel c)
ref_year = merged["Year"].min()
mjj_detr = merged["mjj_anom_cm"] - slope * (merged["Year"] - ref_year)
mjj_detr_center = mjj_detr - mjj_detr.mean()

# Thresholds
thresh = 4.0  # cm
mjj_high = merged.loc[mjj_detr_center > thresh, ["Year"]].copy()
mjj_low  = merged.loc[mjj_detr_center < -thresh, ["Year"]].copy()

# ---------- Plot ----------
fig, axs = plt.subplots(3, 1, figsize=(10, 9), sharex=True)

# (a) R-Niño3.4 (inverted axis, La Niña up)
axs[0].plot(merged["Year"], merged["value"], color="purple", marker="o", linewidth=1.8)
axs[0].axhline(0, color="gray", linewidth=1.0)
axs[0].invert_yaxis()
axs[0].set_ylabel("R-Niño3.4 (annual mean)")

# (b) Annual sea level anomaly + trend
axs[1].plot(merged["Year"], merged["annual_anom_cm"], marker="o", linewidth=1.8)
axs[1].plot(merged["Year"], trendline, color="lightgrey", linewidth=2.0)
axs[1].axhline(thresh, color="red", linestyle="--", linewidth=1.2)
axs[1].axhline(-thresh, color="blue", linestyle="--", linewidth=1.2)
axs[1].set_ylabel("Annual sea level anomaly (cm)")
axs[1].text(merged["Year"].min() + 1, trendline.min() + 0.5,
            f"Slope = {slope:.3f} cm/yr", color="dimgray", fontsize=9)

# (c) MJJ anomaly (detrended & centered) with shaded regions
x_years = merged["Year"].astype(float).values
axs[2].plot(merged["Year"], mjj_detr_center, marker="o", linewidth=1.8)
axs[2].axhline(thresh, color="red", linestyle="--", linewidth=1.2)
axs[2].axhline(-thresh, color="blue", linestyle="--", linewidth=1.2)
axs[2].axhline(0, color="gray", linewidth=1.0, linestyle=":")
# Shade above/below thresholds exactly to axis limits
ymin, ymax = axs[2].get_ylim()
axs[2].fill_between(x_years, np.full_like(x_years, thresh), np.full_like(x_years, ymax), color="red", alpha=0.12)
axs[2].fill_between(x_years, np.full_like(x_years, ymin), np.full_like(x_years, -thresh), color="blue", alpha=0.12)
axs[2].set_ylabel("MJJ de-trended anomaly (cm)")
axs[2].set_xlabel("Year")

# Label abnormal MJJ years (red for high, blue for low)
for yr in mjj_high["Year"].values:
    yv = mjj_detr_center[merged["Year"] == yr].values[0]
    axs[2].text(yr, yv + 0.3, f"{int(yr)}", ha="center", fontsize=8, color="red")
for yr in mjj_low["Year"].values:
    yv = mjj_detr_center[merged["Year"] == yr].values[0]
    axs[2].text(yr, yv - 0.6, f"{int(yr)}", ha="center", fontsize=8, color="blue")

# Add bold sub-panel labels in top-right
labels = ["(a)", "(b)", "(c)"]
for ax, label in zip(axs, labels):
    ax.text(0.98, 0.93, label, transform=ax.transAxes, fontsize=12, fontweight="bold", ha="right", va="top")

# Grid and export
for ax in axs:
    ax.grid(True, linestyle=":", linewidth=0.7)

plt.tight_layout()
plt.savefig("fremantle_three_panel_shaded_labeled.png", dpi=400, bbox_inches="tight")
plt.savefig("fremantle_three_panel_shaded_labeled.pdf", bbox_inches="tight")
plt.savefig("fremantle_three_panel_shaded_labeled.svg", bbox_inches="tight")
print("Saved figure to PNG, PDF, and SVG.")
