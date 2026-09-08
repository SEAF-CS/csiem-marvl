# Minstrel channel — RETUNE before running

These scripts are **verbatim copies of `areas/success_channel/scripts/`** and still carry the Success
channel's parameters. Retune them for the minstrel channel, working through the pipeline in order. Paths
already point at `../../common/data/` (shared) and `outputs/`/`data/` (this area) — no path edits needed.

Run from this area folder: `cd areas/minstrel_channel` then `python scripts/<x>.py`.

## Parameters to change (all currently = Success-channel values)
| Where | Param | Success-channel value | Minstrel channel |
|---|---|---|---|
| `channel_dem.py`, `build_mesh_depthmap.py`, `transect_compare.py`, `cross_sections.py`, `identify_channel_cells.py`, `make_cell_csv.py` | AOI `lons`/`lats` (or `lo`/`la`) box | lon 115.62–115.78, lat −32.05–−32.20 | **TBD** |
| `transect_compare.py`, `cross_sections.py`, `identify_channel_cells.py`, `make_cell_csv.py` | thalweg trace band `SC0,SC1` / `RR0,RR1` | cols 0.40–0.70, rows 0.05–0.78 | **TBD** |
| same | endpoint nudges `NW`,`SE` | 1140 / 1050 | **TBD** |
| `transect_compare.py` | map `XLIM`,`YLIM` | (374500,380500)/(6441000,6452800) | **TBD** |
| `identify_channel_cells.py`, `make_cell_csv.py` | corridor `CH`, `KEEP_KM` | 75 m, (1.0,9.0) | **TBD** |
| `make_cell_csv.py` | manual tweaks (`_adj`, `_last`, `_emound` cell IDs) | Success-channel-specific — **remove/replace** | **TBD** |

## Recommended order
1. `channel_dem.py` — set the AOI, eyeball the crop, confirm the channel is in frame.
2. `transect_compare.py` — tune trace band + `NW`/`SE` until the thalweg sits on the channel
   (print `MEANDEM`; deeper mean = better). Lock the endpoints.
3. `cross_sections.py` — sanity-check the model-vs-DEM steps across the channel.
4. `identify_channel_cells.py` — set `CH`/`KEEP_KM`, read off the corridor element IDs.
5. `make_cell_csv.py` — **delete the Success-channel `_adj`/`_last`/`_emound` lines**, then add
   minstrel-channel tweaks only after inspecting `cell_override_check.png`.

Delete this file once the minstrel channel is done and the params are baked in.
