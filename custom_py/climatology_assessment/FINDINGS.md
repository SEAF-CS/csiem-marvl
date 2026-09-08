# CSIEM 1990s ocean assessment — findings & how-to

## JULY 2026 RE-RUN — recovered SMCWS data (766 casts, was 404) + DMV reader fix

The SMCWS archive recovery (see `smcws_data/AUDIT_CHAPTER4_GAPS.md`) added the winter-1991
outer grids (Y1–42, V1–12 shelf transect to 290 m, MA western, MN southern; ~460 casts) and
the summer-1992 V transect (63 casts). The assessment chain was re-run end-to-end
(inventory → compare_to_roms → core → plots). Two data fixes on the way:
**(a)** SDL (`dsv`/`esv`) readers added; **(b)** a **9-column `b`/`d`-suffix DMV variant**
(cols time, sal, dens, depth, temp, …, data ~0x6C0) was being silently mis-parsed by the
8-column reader — ~113 March-92 casts carried garbage bottoms (fake 36 m depths, 15 °C/29.5 psu)
**in the June assessment too**; both climatology readers now have majority-plausibility guards.
Old outputs preserved as `extended_assessment_pre_recovery_backup.csv`.

### Raw (uncorrected) climatology vs obs — now season-resolved (bias = BC − obs)

| Campaign / zone | n | surf T | surf S | bot T | bot S |
|---|---|---|---|---|---|
| **Winter 91** mid-shelf (Y/MA/GI-band) | 166 | **+0.43** | +0.14 | +0.68 | +0.12 |
| **Winter 91** deep shelf (V + offshore Y, >40 m) | 36 | **−0.32** | −0.08 | +0.62 | −0.09 |
| **Winter 91** MN plume zone (< −32.40) | 108 | +0.71 | **+1.21** | +0.62 | +0.43 |
| **Summer 92** mid-shelf | 268 | **+0.56** | **−0.25** | +0.70 | −0.28 |
| **Summer 92** deep shelf | 28 | +0.58 | −0.22 | +0.93 | −0.30 |
| **Autumn 92** (May routine) | 53 | **+1.1** | −0.05 | **+1.4** | −0.07 |
| **Winter 92** (Jul/Sep routine) | 54 | +0.4 | +0.15 | +0.6 | +0.2 |

Reading: the raw climatology is **warm all year on the mid-shelf** (+0.4–0.6 °C), **much too
warm in May** (misses the real autumn cooling rate; also seen in 1994), and **too cold at the
offshore surface in winter** (−0.3 °C — it lacks the warm Leeuwin surface signature the V/Y
deep casts show, ~19.3 °C obs). Salinity: essentially **unbiased in winter** (+0.1), **fresh
in summer** (−0.25). The MN-plume S bias is a coastal-process gap (no Peel–Harvey plume in
ROMS), not an offshore BC error.

### What the model actually receives (bias-corrected arcs) vs the new obs — the correction call

From `seasonal_envelope_NW.png` (now 267 casts at NW) and siblings:

- **Summer (Mar):** coastal arc ~36.4–36.5 psu vs obs 35.85–36.15 → coastal correction is
  **+0.4–0.5 too salty** (the June suspicion, now confirmed with ~10× the data). The model
  (TUFLOW ×'s, 36.3–36.9) faithfully inherits it → its +0.56 summer surface-salt bias.
- **Winter (Aug) — NEW, from the recovered data:** coastal arc ~35.0–35.1 vs obs 35.3–35.6 →
  coastal correction is **−0.3 too fresh in winter**. The 2013–2023 seasonal correction's
  **amplitude is too large in both directions** for the 1990s.
- **Ocean/W arcs (~35.8 summer → 35.45 winter) track the new obs well in both seasons** —
  leave them unchanged.

### Proposed 1990s BC corrections (obs-anchored)

| Arc | Field | Season | Current → proposed |
|---|---|---|---|
| coastal/E | S | summer (Dec–Apr) | 36.4–37.0 → **cap at ~36.0–36.1** (−0.4 to −0.9) |
| coastal/E | S | winter (Jun–Sep) | 35.0–35.5 → **raise to ~35.4–35.5** (+0.3 at the fresh end) |
| ocean/W | S | all | unchanged |
| all | T | Mar | −0.5 °C |
| all | T | May | **−1.1 to −1.5 °C** (autumn cooling too slow in climatology) |
| all | T | Aug (mid-shelf) | −0.4 °C |

i.e. **compress the coastal seasonal salinity swing by roughly half toward the ocean-arc
curve**, and apply a modest seasonal temperature cooling that peaks in May. Winter deep-shelf
surface T is the one place the BC should be *warmer* (Leeuwin), but no OBC arc sits that far
offshore, so it's a domain-boundary representativeness note rather than a correction.

### Model-side notes from the new data

- **Winter 1991 model run is COLD at the NW/W subregions: −1.5 °C (NW, n=54), −0.6 (W)** vs
  obs — much larger than the BC's own winter bias, so partly model-internal (mixing/heat
  flux); worth a dedicated look before attributing to BC.
- Winter model salinity is fine offshore (+0.05 N, −0.08 NW) but **+0.78 in the S subregion**
  — the model lacks the Peel–Harvey winter plume freshening (consistent with the PHE BC
  chapter below).
- Summer 1992 model: +0.30 T, **+0.56 S** (clean-data update of the +0.278 figure below —
  the DMV fix and extra casts raised it).

*(Sections below are the June-2026 assessment, retained for context; per-cast table is now
`extended_assessment.csv` (766 rows); the old version is in the `_pre_recovery_backup` files.)*

---

Synoptic obs-vs-BC-vs-model bias assessment for the CSIEM TUFLOW-FV model, adapting the
SMCWS `climatology/compare_to_roms.py` approach. Surface (top-2 m) and bottom (bottom-2 m)
T & S for 404 SMCWS outer-ring CTD casts (1991–1994), tagged to 5 latitude-band subregions.

## IMPORTANT REFRAMING — the bias-corrected boundary (added after review)

The ROMS climatology is **bias-corrected only inside 6 seaward-arc polygons** (one per OBC
nodestring; from `SEAF-CS/csiem_model_tools/.../climatology/shapefile`, bundled in
`diagnostics/biascorr_polygons/`). The correction was tuned for the **2013–2023** models.

- **Only 12 of 451 casts fall inside the corrected arc** → the obs-vs-BC "BC" column below
  sampled the **uncorrected interior** climatology (~35.76) for ~97% of casts. That is **not**
  what the model receives at its boundary, so the original "model ≫ BC, model internally too
  salty" reading was largely an **artifact of comparing against the wrong (fresh) cells**.
- The **coastal/east polygons carry a seasonal correction**: salty in summer (~36.6–37 psu,
  Jan–Mar) and fresh in winter (~35.0–35.5); the **ocean/west polygons are steady (~35.8–36.0)**.
  See `diagnostics/biascorr_polygons_map.png` and `seasonal_envelope_{N,NW,W,SW,S}.png`.
- The 1990s field surveys are mostly **March (summer)**, when the coastal-corrected BC is at its
  **saltiest**. The model inherits that salty BC → the model's salty March values are **mostly
  inherited from the coastal correction, not internal evaporation** (confirmed by a W–E transect:
  the model is already ~36.6 at its own seaward boundary vs ~35.8 in the uncorrected cells —
  `diagnostics/model_vs_clim_WE_transect.png`).
- **The 1990s obs (~36.0–36.1) sit *below* the coastal-corrected summer BC (~36.6–37)** → the
  **coastal seasonal correction appears to over-salt the 1990s summer boundary**, and that
  propagates into the model. Whether the 2013–2023 coastal correction is appropriate in the
  1990s climatology context is the open question this assessment now poses.

**Plots:** `seasonal_envelope_{sr}.png` show coastal-BC (red) vs ocean-BC (blue) seasonal cycles
+ obs (by year) + TUFLOW-FV per subregion — built by `ocean_assessment_bc_envelope.py`.

## Salt-source investigation — it's the Peel-Harvey inflow BC (latest conclusion)

A surface/bottom salinity **sheet animation** of the 1992 run's first month
(`diagnostics/salt_1992_month1.gif`, frames in `diagnostics/salt_anim_1992/`) traced the model's
western salt build-up to a **dense bottom intrusion entering from the SOUTHERN open boundary**
(salty water at the bed by day 2–5, filling the domain by day 30) — a **boundary input**, not
evaporation, and not the (fresh, uniform) initial condition.

That southern boundary is the **Peel-Harvey inflow BC** (`bc == QC` at 115.629, −32.598;
`includes/bc/5_phe/phe_WIR_inflows_wq.fvc` → `environment_repo/5_phe/CSV/PeelHarvey_Inflow_1970...csv`).
Its salinity is **hypersaline (~37.5, up to ~39.8 psu) in summer** — far above the ocean (~35.7) — so it
injects salt at the south. This explains the **year-on-year pattern** and **supersedes the
"model internally too salty" headline below** (that was confounded by sampling uncorrected ROMS
cells and not seeing the southern inflow):

| Sim | Peel-Harvey BC salinity | Model surface-S bias |
|---|---|---|
| 1991 (Aug, winter) | ~31–33 (fresh) | +0.05 (none) |
| 1992 (Feb–May, summer) | ~37–39 (hypersaline) | +0.56 (salty) |
| 1994 (May, declining) | ~36 | +0.08 (slight) |

**The Peel-Harvey BC is a repeating climatology** (identical cycle every year 1991–2001, no
Dawesville-Cut step) that matches **post-Cut** conditions, applied to the **pre-Cut** 1990s.
In-estuary marine-interface sites #2/#4/#7 (`ph_data.xls`): summer surface **pre-Cut ~35.6 vs
post-Cut ~39** (the Cut opened Apr-1994). The diluted outflow actually reaching the ocean
(MN casts south of −32.45, March 1992) is **~36.0–36.6** — matching the ~36.6 read off the
daily-salinity map — i.e. **~2.5–3 psu fresher than the BC**. Plots:
`diagnostics/inflow_bc_timeseries_1991_2001.png`, `diagnostics/phe_bc_vs_estuary_climatology.png`,
`diagnostics/phe_bc_vs_field_south.png` (built by `g:/tmp/plot_phe_*.py`).

**Corrected Peel-Harvey BC (test input):**
`environment_repo/5_phe/CSV/PeelHarvey_Inflow_SALcorr_1989_1996.csv` — `SAL` replaced by
per-water-year offsets (**−1.5 / −2.0 / −1.5 / 0** for 1990/91 → 1993/94) with **1992 floored to the
45-day-smoothed in-estuary observations**; Flow/TEMP/WQ unchanged; spans 1989–1996. Applied via
`includes/bc/5_phe/phe_WIR_inflows_wq_SALcorr.fvc`.

## Initial-condition update

Original ICs are **spatially uniform** (one domain-wide value per sim): SAL 35.5 / 35.7 / 35.4 and
TEMP 17.5 / 22.0 / 19.5 for the Aug-1991 / Mar-1992 / Nov-1993 starts. They initialise *fresh*, so the
IC is **not** the salt source — but uniform IC is a simplification.

A revised **graded IC** was built for the 1992 sim
(`includes/ic/initial_condition_2D_Mar_B010_Sgrad.csv`): salinity **and** temperature graded
**linearly E→W by longitude** on the cell centroids — held at the eastern values east of lon 115.75,
ramping to the western model limit (115.331):

| | east (≥ 115.75) | west limit (115.331) |
|---|---|---|
| SAL | 36.25 | 35.80 |
| TEMP | 23.2 | 20.9 |

Other fields (WL, U, V, WQ) keep the original constant values. Built by `g:/tmp/make_ic_grad.py`
(cell→lon from the model `cell_X`).

## Revised 1992 sensitivity run — RESULT (ran 22-Feb→3-Apr 1992; rev made it SALTIER)

`model_runs/HD/csiem_B010_19920222_19920531_rev.fvc` (baseline copy + graded IC + corrected
Peel-Harvey BC + output → `1992_marmay_rev/`) ran and was truncated at 3-Apr-1992 (covers the
March survey). Obs-vs-model salt scatter over the **same 1272 March casts** (region-validation,
`dadamo_transect/region_validation_1992_revcompare.{png,csv}`):

| surface S bias (model−obs) | OA | CS | N | NW | W | SW | S | **overall** |
|---|---|---|---|---|---|---|---|---|
| **baseline** | +0.34 | +0.04 | +0.28 | +0.63 | −0.29 | +0.45 | +0.17 | **+0.278** |
| **rev** | +0.61 | +0.44 | +0.41 | +0.72 | −0.24 | +0.53 | +0.28 | **+0.510** |

**The rev INCREASED the salt bias in every region** (overall +0.278 → +0.510 psu surface, +0.272
→ +0.481 bottom). Temperature essentially unchanged. **Why:** the **graded IC was saltier**
(S 35.8→36.25 vs the baseline uniform 35.7), and over a 5-week run that IC dominates the OA/CS
state — it **overshoots** the March obs (~36.0, which want *fresher*, not saltier). The
Peel-Harvey salinity correction (fresher inflow at −32.598, the far southern boundary) **doesn't
reach the OA/CS survey region** in 5 weeks, so it can't offset the IC. **Implication:** to reduce
the 1992 salt bias the IC/BC must move *toward the obs (~36.0), i.e. FRESHER* — the opposite of the
36.25 graded IC — consistent with the 1991 result (model too salty, obs fresher). The 1991 rev
(`..._19910720_19910831_rev.fvc`) already uses a *freshened* graded IC (S 35.4→34.0); 1992 should
be refreshed the same way before re-testing.

## Salinity time-series diagnostic — the salt is OCEAN-BOUNDARY controlled, not the Peel-Harvey inflow

`dadamo_transect/phe_salinity_timeseries_compare.png` (built by `g:/tmp/phe_salinity_timeseries_compare.py`):
1992 surface-S time-series per outer subregion (S/SW/W/NW), overlaying the PHE input SAL (baseline vs
SALcorr), the raw ROMS climatology, and the model (baseline vs rev). Findings:

- The PHE input **was** reduced — window-mean SAL **38.5 → 36.7 psu** (baseline → SALcorr) — yet the
  **model baseline and rev lines are essentially identical** at every open subregion. Freshening the PHE
  inflow did **not** move the open-domain salinity.
- The model sits at **~36.0–36.5**, **above both the obs (~35.5) and the raw ROMS climatology (~35.3)**.
  The extra salt is **boundary/IC/evaporation**, not the estuary: the open domain is governed by the
  OCEAN open boundary (the **coastal bias-corrected ROMS**, salty in summer — see the reframing section
  above), which the model inherits. The PHE inflow is a single southern point source — too small to move
  the domain (only subregion **S**, nearest the inflow, shows transient freshening dips).
- Note even the *corrected* PHE input (36.7) is still **saltier than the obs (35.5) and the ROMS (35.3)**,
  so it was never going to act as a freshening source.

**Implication:** the salt-bias lever is the **ocean boundary forcing** (the 2013–2023 coastal bias-correction
over-salts the 1990s summer BC) and/or evaporation/IC — **not** the Peel-Harvey salinity. The Mandurah-Channel
relocation of the PHE QC (`phe_WIR_inflows_wq_SALcorr.fvc` → 115.7107,-32.5180) is still physically correct
for the pre-Cut period, but it won't materially change the open-domain salt bias for the same reason.

## Headline (independently verified) — SUPERSEDED by the Peel-Harvey finding above; BC column is the UNCORRECTED climatology

**The model is too salty by ~+0.5–0.7 psu at both the surface and the bottom, in every
subregion.** The boundary forcing (BC) is, by contrast, slightly *fresh* vs obs — so the
salt excess is **model-internal** (the model is saltier than its own forcing → points to
excess evaporation / insufficient freshwater / over-mixing, i.e. a candidate for IC/BC
salinity refinement or freshwater-flux review). Temperature is **warm-biased** (BC and
model) everywhere except the South subregion, which is cold/fresh.

Verification: 6 offshore 1992 casts were re-derived from raw files (obs binary + FV
`get_profile`) fully independently — every number matched the pipeline to ≥4 dp, mean
independent surface-S bias **+0.70 psu**. The bias survives all stress tests (remove
outliers → +0.56; ROMS-only → +0.55; clean-filtered n=197 → +0.60, 99% of rows positive).

### Mean bias by subregion (source − obs; + = too warm/salty)

| | BC S | BC T | MODEL S | MODEL T |
|---|---|---|---|---|
| **Surface** N / NW / W / SW / S | −0.14 / −0.17 / −0.26 / −0.19 / −0.47 | +0.47 / +0.55 / +0.62 / +0.59 / −0.53 | **+0.43 / +0.57 / +0.65 / +0.62 / +0.28** | +0.10 / +0.31 / +0.49 / +0.32 / −0.47 |
| **Bottom** N / NW / W / SW / S | −0.15 / −0.20 / −0.35 / −0.25 / −0.51 | +0.78 / +0.72 / +0.76 / +0.75 / −0.35 | **+0.46 / +0.66 / +0.70 / +0.64 / +0.26** | +0.27 / +0.24 / +0.65 / +0.44 / −0.36 |

## Caveats (from the adversarial audit — already applied)

- **Model coverage** (after the 1994 run completed, 1993-11-01 → 1994-05-31): **292/404 casts**
  — 1991 (6), 1992 (271), **1994 (14, now all covered)**, 1993 (1). The headline salt bias is
  unchanged with 1994 included (MODEL surface S bias **+0.52 psu**, n=292). **1993 remains a gap**:
  its casts pre-date the Nov-1993 run start, so only 1 is model-covered (BC is still assessed there).
- **CTD fresh-bottom spikes** (obs_botS < 33 psu, unphysical on the open shelf) are masked
  for bottom stats — this removes a spurious N-subregion bottom spike (was +2.4, now +0.46).
- **6 OA45/OA50 Aug-1991 winter casts** show a real −0.8…−1.4 °C surface cold bias; kept for
  salinity, noted for SST.
- Bottom comparisons sample each source **at the obs cast's own bottom depth** (interp), to
  handle grid-bathymetry mismatch (model 3 m / ROMS 14 m / HYCOM 50 m at the "same" point).

## Outputs

| File | What |
|---|---|
| `extended_assessment.csv` | per-cast obs/BC/MODEL surface+bottom T/S + biases + subregion + doy (404 rows) |
| `subregion_bias_summary.{png,csv}` | mean bias by subregion, BC vs MODEL, surf/bot, T/S |
| `scatter_surf.png`, `scatter_bot.png` | obs-vs-BC and obs-vs-MODEL scatter, T & S, coloured by subregion (the recreate + model overlay) |
| `seasonal_{N,NW,W,SW,S}.png` | **seasonal alignment**: day-of-year ROMS-climatology curve + obs (by year) + TUFLOW-FV, per subregion, surface & bottom |

## How to run

Open **`ocean_assessment_1990s.ipynb`** (imports the two modules, displays all figures).
- `ocean_assessment_core.py` — multi-source extraction (`run()` → `extended_assessment.csv`).
  Reuses `compare_to_roms.py` binary readers via exec-prefix; BC = ROMS-clim (91/92) + HYCOM
  (93/94) from `environment_repo`; MODEL = TUFLOW-FV via `tfv` `get_profile`.
- `ocean_assessment_plots.py` — the three plot types (applies the bottom QC on load).
Set `REEXTRACT = True` in the notebook to rebuild the CSV (~80 s). Subregion cutoffs and
the BC/model file paths are constants near the top of the core module — easy to retune.

## Next steps to consider

- Extend model coverage once the 1994B run completes (re-run `core.run()`; 1993/94 will populate).
- Add density / depth-resolved (not just surface/bottom) bias if you want stratification skill.
- The salt bias is the clearest signal — worth checking model evaporation forcing, river/drain
  freshwater inputs, and the initial salinity field against this +0.5–0.7 psu offset.
