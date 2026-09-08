# CSIEM 1991 HD calibration — handoff summary

_Concise state of the 1991 August hindcast calibration (TUFLOW-FV + AED), for another agent._
_Written mid-calibration; a temperature-climatology run is in progress._

## 1. What we're doing
Calibrating the **1991 winter (Aug) CSIEM hindcast** against the historical **SMCWS CTD surveys**,
focused on **Owen Anchorage (OA)** and **Cockburn Sound (CS)**. The mid-Aug **storm survey (18 Aug
1991)** is the key comparison. Goal: model surface/bottom **T, S, density** should match the field.

## 2. Key paths
| Thing | Path |
|---|---|
| Run control (edit here) | `S:/Matt_Working/csiem/model_runs/HD/csiem_B010_19910720_19910831_rev.fvc` |
| Model includes (working copy the run reads) | `S:/Matt_Working/csiem/model_components/` (NOT the W: 1.7 master) |
| Model output NC | `S:/Matt_Working/csiem/output_archive/1.7.0/1991_aug_rev/csiem_B010_19910720_19910831_rev.nc` |
| Validation scripts + plot set | `G:/CSIEM/1.8.0/csiem-marvl/custom_py/validation/years/1991/` → `run_all.sh` |
| Validation outputs / diagnostics | `.../years/1991/outputs/` and `.../outputs/diagnostics/` |
| **SMCWS field data** | `Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/` |
| River/BC climatology source (SWANEST) | `G:/CSIEM/1.7.0/csiem-data/data-warehouse/csv/dwer/swanest/` |

TUFLOW-FV NC gotcha: call `fv = ds.tfv` BEFORE reading `ds['Time']` (else time decodes to 1970).
Surface = top-2 m mean (`datum='depth'`), bottom = bottom-2 m mean (`datum='height'`); no RHOW in
HD output → inject EOS-80 (`common/lib/eos80.py`).

## 3. Progress — the calibration arc (each fix verified)
1. **ROOT CAUSE: Fremantle mouth was tidally choked.** Model transmitted only **6% of the tide to
   the Narrows vs 91% real** — B010 mesh had shallow/emergent barrier cells in the Blackwall reach.
   Fix: `Cell Elevation File` override `bathy_swan_mouth.csv` (restored B009 depths, 367 cells) →
   tide now 73% transmission, estuary stratifies (salt wedge), plume forms. **This was the big one.**
2. **Inflow salinity placeholder.** NAR/CAN inflow SAL was a flat **27.16/23.87 psu** placeholder →
   replaced with a **Narrows depth-mean monthly climatology** (SWANEST s6160262). Aug ≈ 18.8 psu.
3. **Graded IC salinity.** Longitude-breakpoint IC: `36.1 → 35.1 → 34.65 → 20 → 13` at lons
   `115.331/115.65/115.75/115.80/115.854` (`includes/ic/make_graded_ic.py`, config `1991`).
4. **Flow scale** (bc scale): NAR ×1.5, CAN ×2.0. **SAL offset** (bc offset): −5 psu.
5. **Horizontal diffusivity** reduced 0.1 → 0.01 (sharpen the plume front).
6. **Inflow temperature placeholder (latest).** NAR/CAN TEMP was a flat **21.6 °C** placeholder (too
   warm → spurious OA heat; OA80 model bottom ~1–1.5 °C warm). Replaced with a **Narrows monthly
   temperature climatology** (Aug ≈ 15.4 °C). **← this run is in progress now.**

Salinity/temperature BC lives in `includes/bc/4_sce/sce_WIR_inflows_wq_19700101_19941231_SALclim.fvc`
+ the `{NAR,CAN}_Inflow_..._SALclim.csv` (now carry both SAL and TEMP climatology).

## 4. Scoreboard (OA surface-salinity bias, model − obs; fresh-cast = obs<34 psu coastal casts)
| iter | region-wide surf-S | OA fresh-cast (coast) | note |
|---|---|---|---|
| ITER2 (flow 1.3, IC east_edge 15) | −0.035 | +1.42 | best coast + neutral region |
| ITER3 (flow 1.5/2.0, steep IC, low κ) | −0.294 | +1.29 | best coast, marine over-fresh |
| ITER4 (saltier shelf IC) | +0.124 | +1.71 | best marine/CS55, coast under-fresh |
| ITER5 (temp climatology) | _running_ | — | targets OA warm bias |

**Fundamental tension:** no single basin-scale config nails BOTH the sharp fresh coast AND the
correct marine/CS55 salinity — freshening the coast over-freshens the interior and vice-versa. The
immediate-coast super-fresh casts (field ~20 psu) are a sub-grid feature this mesh won't fully resolve.

## 5. Steps to go
- **Score the temp-climatology run** (expect OA/OA80/CS55 warm bias to drop ~1–1.5 °C). Diagnostics:
  `S:/tmp/oa80_timeseries.py`, `cs55_timeseries.py`, `transect_NAR_offshore_temp.py`.
- **Converge salinity** to a config between ITER2 and ITER4 (e.g. ITER4 saltier IC but ease the
  115.75 breakpoint from 34.65 toward ~34.4, or trim flow).
- Growing **warm surface-T bias** region-wide (+0.13 → +0.43 across iters) — watch after the temp fix;
  may implicate heat flux / reduced vertical mixing, not just the inflow.
- **1992 and 1994 windows still use the RAW placeholders** (SAL 27.16, TEMP 21.6) — they don't include
  `_SALclim.fvc` yet. Same fix needed there.
- CAN uses the Narrows climatology as a proxy (Canning flow ~2.5% of Swan; second-order).

## 6. SMCWS field data — layout & what the validation consumes (for the data search)
Root: `Q:/SEAF-CS/V1.8/DATA/csiem-data/data-lake/DEP/SMCWS/` — **read its `CLAUDE.md` and per-year
`MANIFEST_*.md` first.** Structure:
- `1991/`, `1992/`, `1993/`, `1994/` — per-year survey data.
  - `1991/survey_log_1991.csv` — indexes every cast: `date,time,jday,station,month,data_type,
    associated,fv_file`. `data_type` ∈ {`FV-only`, `DFV+FV`, ...}. Built by `build_survey_log.py`.
  - `1991/1991-08/profile_data/<station>/dfv<hhmm>.<jday>` — binary **DFV** CTD profiles (S, density,
    depth, T). `1991/1991-08/velocity_data/` — ADCP/velocity. Also `1991-03/` (March casts, predate
    the 20-Jul sim start so not used for 1991 HD scoring).
  - Sub-surveys: `Transect_A/`, `Transect_B/`, `TransectOA/`, `March/`, `ProfileSeries/`, `Halocline/`.
- Cross-cutting: `6-13_OATransects/`, `6-16_CStransects/` (thesis figure transect defs + `.loc` coords),
  `DAdamo/`, `climatology/`, `gis/` (coastline, zones). `reorganise_1991.py`/`_1992.py`, `scan_fv_dfv.py`.
- **Binary readers:** DFV/FV parsed by `read_dfv` (find `b'EPA'` header at 0x18 or 0x14; big-endian
  float32; cols = SAL, density, depth, TEMP). See `run_transectOA.py` / the `_timeseries.py` scripts.

**Validation inventory:** `validation/common/data/region_profiles_inventory.csv` — the curated cast
set the plot set reads (1991 = **686 casts**; regions **CS 420, OA 195, NW 49, SW 16, W 6**). Stations
tagged OA/CS by point-in-polygon (`MLAU_Zones_v3_ll.shp`), else N/NW/W/SW/S lat bands. Key sites:
**CS55** (115.714, −32.188), **OA80** (115.7013, −32.1313), OA-transect stations **OA10–OA45**.

**Likely gaps to search for** (things known-incomplete in prior notes): the **1994** March intensive
(jdays 080/081) was blocked on an FV reader; **1994** May Transects A/B/C model rows pending; some
sub-surveys may have casts on disk not yet in the inventory/survey log. When searching, cross-check
`survey_log_<year>.csv` + `MANIFEST_<year>.md` + `manifest.csv` against the actual files under each
year folder to find casts present-but-unindexed (or expected-but-absent).
