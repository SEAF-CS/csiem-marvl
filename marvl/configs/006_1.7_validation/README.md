# 006_1.7_validation snapshots

This folder contains MARVL validation snapshots and their run scripts. Folder-based snapshots include a `RUN_MARVL_WQ_*` script that is the one to use for running the snapshot. The runner iterates multiple date windows and writes a separate output folder for each window.

Notes:
- For folder snapshots, use the `RUN_MARVL_WQ_*` script, not the `MARVL_WQ_*` config directly.
- The runner overrides the output directory and the date array for each window.
- Output paths below are relative to the `csiem-marvl` repo root (top-level folder only).

| snapshot name | output (top-level) | timeframes (date windows) | description |
| --- | --- | --- | --- |
| `MARVL_WQ_ChlA_2021_2023.m` | `outputs/001_ValidationSnapshot/Chlorophyll_a` | n/a (single config) | Chlorophyll-a (TCHLA) validation timeseries for 2021–2023. Run this config directly in MATLAB. |
| `MARVL_WQ_TurbidityValidation_2023.m` | `outputs/007_1.7_validation/2023A_turb2` | n/a (single config) | Turbidity validation (Turbidity, TSS, EXTC, etc.) for 2023. Run this config directly in MATLAB. |
| `BOTTOM_T_WWMSP5` | `outputs/001_ValidationSnapshot/BOTTOM_T_WWMSP5` | 2021-11-15 to 2021-12-30; 2022-01-24 to 2022-02-24; 2022-04-17 to 2022-05-01; 2022-06-01 to 2022-08-01 | Bottom temperature timeseries for WWMSP5. Run `BOTTOM_T_WWMSP5/RUN_MARVL_WQ_BOTTOM_T_WWMSP5.m` to generate multiple date-window snapshots. |
| `OXY_WWMSP5` | `outputs/001_ValidationSnapshot/OXY_WWMSP5` | 2021-11-15 to 2021-12-30; 2022-01-24 to 2022-02-24; 2022-04-17 to 2022-05-01; 2022-06-01 to 2022-08-01 | Dissolved oxygen (DO) timeseries for WWMSP5. Run `OXY_WWMSP5/RUN_MARVL_WQ_OXY_WWMSP5.m` to generate multiple date-window snapshots. |
| `PAR_WWMSP2` | `outputs/001_ValidationSnapshot/PAR_WWMSP2` | 2022-11-28 to 2022-12-14; 2023-01-02 to 2023-01-18; 2023-02-16 to 2023-03-04; 2023-03-18 to 2023-04-03; 2023-05-02 to 2023-05-18; 2023-05-18 to 2023-06-03 | PAR (photosynthetically active radiation) validation for WWMSP2. Run `PAR_WWMSP2/RUN_MARVL_WQ_PAR_WWMSP2.m` to generate multiple date-window snapshots. |
| `PAR_WWMSP5` | `outputs/001_ValidationSnapshot/PAR_WWMSP5` | 2021-11-15 to 2021-12-30; 2022-01-24 to 2022-02-24; 2022-04-17 to 2022-05-01; 2022-06-01 to 2022-08-01 | PAR validation for WWMSP5. Run `PAR_WWMSP5/RUN_MARVL_WQ_PAR_WWMSP5.m` to generate multiple date-window snapshots. |
| `T_WWMSP5` | `outputs/001_ValidationSnapshot/T_WWMSP5` | 2021-11-15 to 2021-12-30; 2022-01-24 to 2022-02-24; 2022-04-17 to 2022-05-01; 2022-06-01 to 2022-08-01 | Temperature timeseries for WWMSP5. Run `T_WWMSP5/RUN_MARVL_WQ_T_WWMSP5.m` to generate multiple date-window snapshots. |
