# Wind-panel composite

Stacks any 3-D frame series over a wind-speed timeseries panel whose red marker sweeps in sync, so
wind events line up with the modelled response (storm → mixing → cascade diagnosis).

## Wind source
BARRA: `W:\WAMSI\1.7\csiem_model_tfvaed_1.7\model_components\environment_repo\1_weather\BARRA\BARRA_PH_UTC+8_19910101_19911231.nc`
Vars `uwnd10m`, `vwnd10m` (10 m, hourly, gridded 91×70). Also mslp, air_temp_2m, precip_rate, relhum,
shortwave/longwave — easy to add more panels.

## Pipeline
```
python scripts/extract_wind.py      # nearest grid pt to CS (lat -32.154, lon 115.747) -> data/wind_cs_1991.csv
SRC=images/drape_low python scripts/composite_wind.py   # -> images/composite/f_###.png
#   then assemble to MP4 at ~6 fps
```
`composite_wind.py`: frame time = `1991-07-20 + 4h*i` (matches the 4-hourly model output); plots wind
speed for the whole window with a vertical red marker + current speed/dir readout at frame i. To use a
different field/series, swap the CSV column and the frame-time origin.

Note: 1991 peak wind 20.4 m/s on Aug 1; multiple events — useful for correlating against the cascade.
A wind-rose variant (accumulating to current time) was considered but the timeseries reads storm timing
more directly.
