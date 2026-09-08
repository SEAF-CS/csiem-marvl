
%% Nutrient budgeting instruction
%
% step 1: export the included nutrient variables and saved in MAT format for next step processing
%         in the 'mat_export' folder, run the export_budget_data_from_region_3d_Erie_AED.m
%
% step 2: preprocessing the MPB and MAG variables for next step by runing the 
%         "preprocessing_vars_nitrogen_MPB.m' script
%
% step 3: preprocesing the nodestring flux data for next step;
%         in the 'flux' folder, run the 'process_flux_files_Erie.m' script
%
% step 4: prepare the daily catchment inflow and nodestring flux by running
%         the 'cal_flux_balance_Erie.m' script in the 'flux' folder
%
% step 5: Do the nitrogen budgeting and plot by running the 'cal_nitrogen_budget_hchb_5panels_2022_final.m'
%         script.
%
% step 6: Do the phosphorus budgeting and plot by running the 'cal_phosphorus_budget_hchb_5panels_2022_final.m'
%         script.