"""Weather-forcing bias check: is the 2021 water-temperature warm offset a
WRF air-temperature bias rather than model physics?

Compares 2 m air temperature and 10 m wind speed from each met product against
BOM station observations (warehouse var00153 / var00130), full-year windows,
at the nearest product gridpoint, hourly-matched:

    2013: BARRA-SUB (the forcing actually used)  +  BARRA-C2 (counterfactual)
    2021: WRF d02  (the forcing actually used)   +  BARRA-C2 (counterfactual)

Stations: Garden Island HSF (in the Sound), Rottnest Island, Swanbourne,
Jandakot. Outputs per station/product: bias, RMSE, r + monthly bias table ->
met_bias_summary.csv + console report.

Context: csiem.seaf.org.au/weather-waves.html found WRF +1.76 degC vs
BARRA-C2 +0.57 degC air-temp bias at Rottnest for a Jan-2022 fortnight; this
extends that to full years at Sound-adjacent stations.

NB (Matt 2026-09-12): BARRA-C2 is NOT BARRA-PH — PH is the higher-resolution
1.5 km Perth product (used for the 1990s runs; no modern-window PH file on
the store). C2 here is only the cross-year counterfactual; grid spacing per
product is recorded in the summary so coastal representativeness can be
weighed (coarser grids smear the land-sea contrast at shoreline stations).
"""
import numpy as np
import pandas as pd
import netCDF4
from pathlib import Path

HERE = Path(__file__).parent
ENV = r'G:/CSIEM/V1.7/MODEL/csiem_model_tfvaed_1.7/model_components/environment_repo/1_weather'
W = r'G:/CSIEM/V1.7/DATA/csiem-data/data-warehouse/parquet/variable/csiem_var{:05d}_public.parquet'

PRODUCTS = {
    2013: [("BARRA-SUB (forcing)", f"{ENV}/BARRA/BARRA_SUB_20121001_20140105_UTC+8.0.nc"),
           ("BARRA-C2", f"{ENV}/BARRAC2/BARRA2_ATMOS_C2_20121101_20140331_GMTpl8.nc")],
    2021: [("WRF (forcing)", f"{ENV}/WRF/WRF4tfv_perth-1500_UTC+8_20201101-20211231.nc"),
           ("BARRA-C2", f"{ENV}/BARRAC2/BARRA2_ATMOS_C2_20201101_20220331_GMTpl8.nc")],
}
STATIONS = ["GARDEN ISLAND HSF", "ROTTNEST ISLAND", "SWANBOURNE", "JANDAKOT AERO"]

AIRT_NAMES = ["air_temp_2m", "T2", "temp_scrn", "tas", "AIR_TEMP"]
WSPD_NAMES = ["WINDSPD10"]
UV_NAMES = [("uwnd10m", "vwnd10m"), ("U10", "V10"), ("uas", "vas"), ("u10", "v10")]


def load_obs(vid, year):
    d = pd.read_parquet(W.format(vid))
    d = d[d["Agency"].astype(str).str.startswith("BOM")]
    d["Date"] = pd.to_datetime(d["Date"])
    d = d[d.Date.dt.year == year]
    d["Data"] = pd.to_numeric(d["Data"], errors="coerce")
    d["Lat"] = pd.to_numeric(d["Lat"], errors="coerce")
    d["Long"] = pd.to_numeric(d["Long"], errors="coerce")
    d["hour"] = d.Date.dt.floor("h")
    return d


class Product:
    def __init__(self, path):
        self.nc = netCDF4.Dataset(path)
        v = self.nc.variables
        self.lat = np.asarray(v["latitude"][:]); self.lon = np.asarray(v["longitude"][:])
        tname = "local_time" if "local_time" in v else "time"
        tv = v[tname]
        units = getattr(tv, "units", "hours since 1990-01-01")
        m = pd.Timestamp(units.split("since")[1].strip().split()[0])
        unit = units.split()[0].rstrip("s")
        self.time = m + pd.to_timedelta(np.asarray(tv[:], dtype=float), unit=unit[0])
        self.hour = pd.DatetimeIndex(self.time).round("h")
        self.airt = next((n for n in AIRT_NAMES if n in v), None)
        self.wspd = next((n for n in WSPD_NAMES if n in v), None)
        self.uv = next((p for p in UV_NAMES if p[0] in v and p[1] in v), None)

    def grid_dx(self):
        a = self.lat if self.lat.ndim == 1 else self.lat[:, 0]
        return float(np.median(np.abs(np.diff(a)))) * 111.0  # ~km

    def nearest(self, lat, lon):
        if self.lat.ndim == 2:
            d2 = (self.lat - lat) ** 2 + (self.lon - lon) ** 2
            j, i = np.unravel_index(np.argmin(d2), d2.shape)
            return (j, i)
        return (int(np.argmin(np.abs(self.lat - lat))), int(np.argmin(np.abs(self.lon - lon))))

    def series(self, kind, lat, lon):
        j, i = self.nearest(lat, lon)
        if kind == "airT" and self.airt:
            x = np.asarray(self.nc[self.airt][:, j, i], dtype=float)
            if np.nanmedian(x) > 150:  # Kelvin
                x = x - 273.15
        elif kind == "wind":
            if self.wspd:
                x = np.asarray(self.nc[self.wspd][:, j, i], dtype=float)
            elif self.uv:
                u = np.asarray(self.nc[self.uv[0]][:, j, i], dtype=float)
                vv = np.asarray(self.nc[self.uv[1]][:, j, i], dtype=float)
                x = np.hypot(u, vv)
            else:
                return None
        else:
            return None
        return pd.Series(x, index=self.hour).groupby(level=0).mean()


def main():
    rows = []
    for year, prods in PRODUCTS.items():
        obs = {"airT": load_obs(153, year), "wind": load_obs(130, year)}
        for pname, path in prods:
            P = Product(path)
            for st in STATIONS:
                for kind in ("airT", "wind"):
                    o = obs[kind][obs[kind].Site_Description == st]
                    if o.empty:
                        continue
                    lat, lon = o.Lat.median(), o.Long.median()
                    oh = o.groupby("hour").Data.mean()
                    ms = P.series(kind, lat, lon)
                    if ms is None:
                        continue
                    both = pd.concat([oh, ms], axis=1, keys=["obs", "mod"]).dropna()
                    if len(both) < 100:
                        continue
                    d = both["mod"] - both["obs"]
                    rows.append(dict(year=year, product=pname, dx_km=round(P.grid_dx(), 2),
                                     station=st, var=kind,
                                     n=len(both), bias=d.mean(), rmse=np.sqrt((d**2).mean()),
                                     r=both["obs"].corr(both["mod"]),
                                     **{f"m{m:02d}": g.mean() for m, g in d.groupby(d.index.month)}))
                    print(f"{year} {pname:20s} {st:18s} {kind:5s} n={len(both):5d} "
                          f"bias {d.mean():+.2f}  rmse {np.sqrt((d**2).mean()):.2f}  "
                          f"r {both['obs'].corr(both['mod']):.3f}")
    df = pd.DataFrame(rows).round(3)
    df.to_csv(HERE / "met_bias_summary.csv", index=False)
    print("\nwrote", HERE / "met_bias_summary.csv")


if __name__ == "__main__":
    main()
