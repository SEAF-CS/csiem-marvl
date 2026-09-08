# CSIEM hindcast validation — model vs SMCWS field

Year-separated validation of the CSIEM TUFLOW-FV(+AED) hindcast against the historical
**SMCWS CTD surveys** (1991, 1992; 1994 pending). Reorganised from the old flat
`../dadamo_transect/` into a **folder-per-year** layout with a shared engine.

## Layout
```
common/
  lib/   region_validation_core.py (paired obs↔model extraction engine) · point_overrides.py
         [Phase 2: readers.py, eos80.py, cross_section.py, krige.py to be factored here]
  data/  region_profiles_inventory.csv · model_sample_locations.csv · transect_A*.shp
  docs/  VALIDATION.md (refinement loop + scoreboard) · README_model_field_comparisons.md (plot mechanics + gotchas)
years/<year>/
  scripts/   the components for that year (params inline; shared engine via common/lib)
  outputs/   results — flat named files + transectA/ and maps/ subdirs
```

## The validation set (10 components) — per-year availability
| # | Component | script | 1991 | 1992 | 1994 |
|---|---|---|---|---|---|
| 1 | region_validation | `region_validation.py` (base+rev extraction + bias bars) | ✅ | ✅ | ⏳ |
| 2 | scatter / scatter_lon | `scatter.py <tag>` · `scatter_lon.py <tag>` | ✅ | ✅ | ⏳ |
| 3a | hovmöller | `hovmoller.py` | ✅ | — | — |
| 3b | ProfileSeries | `profile_series.py` | ✅ | TODO | TODO |
| 4 | TransectA | `run_transectA.py` | ✅ | ✅ | (nb stub) |
| 5 | TransectB | `run_transectB.py` | ✅ | – | – |
| 6 | TransectOA | `run_transectOA.py` | ✅ | – | – |
| 7 | maps – campaign | `run_maps.py campaigns` (1991) / `run_maps.py` (1992 daily) | ✅ | ✅ | – |
| 8 | maps – panels | `run_maps.py panels` (1991) | ✅ | – | – |
| 8b | maps – OA (zoom) | `run_maps_OA.py` (Owen Anchorage zoom, TransectOA window 18-Aug ±2 h) | ✅ | – | – |
| 9 | Halocline | `halocline.py` (model vs field halocline height above seabed, 20-Aug; σt-midpoint detector + RBF) | ✅ | – | – |

✅ = built & **run-clean** (Phase 1 components also reproduce the pre-reorg numbers); TODO = not yet built / not yet wired for that year.

This 10-component set is **Tier 1 — scoring** (*does the model match the field, cast-by-cast?*), run
every scoring pass via `run_all.sh`.

## Tier 2 — refinement diagnostics (per-year, ad-hoc)
Process/mechanism diagnostics that explain *why* a run is off and *which lever* to move — run during
refinement, not every pass. For 1991: `years/1991/scripts/diagnostics/` (`run_diagnostics.sh`, see its
`README.md`). Four groups: **A** E–W along-thalweg transect NAR→mouth→offshore (S & T); **B** point
time-series at CS55 & OA80 (surf/bot T·S·ρ + forcing panel); **C** IC verification maps (S & T);
**D** grid/tidal-connectivity checks (tidal transmission, mouth bathy, mesh-vs-B009). Promoted from
`S:/tmp` 2026-07. Refinement loop + scoreboard live in `common/docs/VALIDATION.md` and
`years/1991/CALIBRATION_HANDOFF.md`.

## Modern era (2021 / 2022 / 2023) — Transect A only
The SMCWS-era components above need the 1991/1992 survey structure. For the recent hindcasts
the only comparable product is **TransectA**, rebuilt against routine monitoring
(**DWER-CSMWQ** + **WAMSI-WWMSP3-CTD**) instead of a purpose-designed survey. Engine:
`common/lib/transectA_modern.py` (sections) and `transectA_modern_maps.py` (per-window station
maps); `years/<year>/scripts/{run_transectA,map_panels}_<year>.py` are one-line wrappers that
set `TRANSECT_SIM`.

| sim | NC | window searched | rounds | field programs |
|---|---|---|---|---|
| 2021B | `2021B-20260131010652/…20201101_20211231_WQ.nc` | 2021 | 12 | DWER only |
| 2022B | `2022B-20260131015416/…20211101_20221231_WQ.nc` | 2022 | 8 (curated) | DWER + WWMSP3 |
| 2023B | `2023B-20251124150126/…20221101_20240401_WQ.nc` | 2023-01 → 2024-03 | 17 | DWER + WWMSP3 |

Key points, all deliberate:
- **One pooled field cache** (`S:/tmp/tA/cs_2021_2024_ST.parquet`, 2020-11 → 2024-04) supplies the
  station positions, so the spine, the 16-station set and every chainage are **identical in all
  three years** and the sections can be read side by side. Occupancy is per-sim.
- Casts are off-line, so each is projected onto the spine and carries its residual offset in the
  station label. Three projection modes: latitude-foot (default), nearest-point (`PERP_SITES`),
  and due-south (`MERID_SITES`).
- **Rounds are found by clustering sampling days** (gap > 6 days starts a new round), not
  hardcoded. 2022 keeps a curated eight-window subset via `WINDOW_OVERRIDES` so its published
  figures stay reproducible — delete that entry for full coverage.
- **Programs alternate**, so most rounds have only 8 of the 16 stations: DWER covers Cockburn +
  Warnbro (nothing north of −4 km), WWMSP3 covers Owen Anchorage + a sparse south (a gap between
  −7 and +5 km). Only rounds where both sample in the same week give all 16. **2021 has no
  WWMSP3 at all**, so every 2021 section stops at −4 km.
- Bed comes from the model mesh (`cell_Zb`), not the 5 m EIA DEM, which stops short of Warnbro.

## Run convention
Per component:  `cd years/<year>/scripts && python <component>.py [args]`
(each script resolves `common/lib` via `__file__` and writes to `../outputs/`).
Whole year in dependency order:  `bash years/<year>/run_all.sh`.

Run order: [1] region_validation **first** (writes the `_rev.csv` the scatter plots consume),
then [2] scatter/lon, [3a] hovmöller, [3b] profile_series, [4/5/6] transectA/B/OA, [7/8] maps,
[8b] maps – OA (standalone Owen-Anchorage zoom; `run_maps_OA.py`, no upstream dependency).

## Model NCs (per year, base + rev) — edit in the per-year `region_validation.py` / runner `MODEL_NC`
- 1991: `1991_aug/…nc` (base) · `1991_aug_rev/…_rev.nc` (rev = graded-fresh IC + Mandurah PHE + poly-6 OBC + SDOOL + **O2Me bathy overrides**)
- 1992: `1992_marmay/…nc` · `1992_marmay_rev/…_rev.nc`
- 1994: `1994B/…nc` (model still advancing; A/B/C stub notebook in `years/1994/scripts/`)

## Status
- **Phase 1 (reorg existing, no behaviour change): DONE & verified.** Pre-reorg numbers reproduce.
- **Phase 2 (extend): DONE for 1991** — ProfileSeries [3b], TransectB [5], TransectOA [6], **maps – OA**
  [8b], and **Halocline [9]** (model-vs-field, σt-midpoint detector; wired into `run_all.sh`) all built &
  run-clean. Remaining: ProfileSeries for 1992/1994.
- **Phase 3 (refinement): active** — the IC/BC/param calibration loop (`common/docs/VALIDATION.md`,
  `years/1991/CALIBRATION_HANDOFF.md`) with the **Tier-2 diagnostics** (`years/1991/scripts/diagnostics/`).
- The old flat `../dadamo_transect/` (pre-reorg source) can now be archived (Halocline has landed).

### Latest full run — 1991 rev, 2026-06-22 (`bash years/1991/run_all.sh`; steps 1→8b all exit 0)
Run against the **regenerated** rev NC `1991_aug_rev/csiem_B010_19910720_19910831_rev.nc` (mtime 2026-06-21).
Headline bias (model − obs), baseline → rev:
- **surf-S +1.117 → +0.230 psu**  ·  bot-S +0.720 → −0.042  ·  surf-T −0.134 → +0.208  (n=654)
- ⚠️ rev surf-S is now **+0.230** (was +0.079 on the earlier rev NC) — the regenerated rev field runs
  ~0.15 psu saltier; still a large improvement on baseline (+1.117).
- maps [7] 6 campaign maps · [8] 57/60 panels (3 skipped, <5 profiles) · [8b] 3 OA-zoom maps (27 casts in 06:11–14:13 window).
- 1992 (not re-run this session): surf-S +0.278 → −0.019.

See `common/docs/VALIDATION.md` for the IC/BC refinement loop and `…/README_model_field_comparisons.md`
for plotting mechanics + model gotchas (ResTime→Time, exact-timestamp get_profile, inject RHOW, surf/bot sheets).
