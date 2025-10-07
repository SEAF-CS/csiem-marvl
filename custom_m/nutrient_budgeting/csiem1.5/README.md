
 ## Nutrient budgeting instructions
 
 ### step 1: 
  
  export the included nutrient variables and saved in MAT format for next step processing
          in the '`mat_export`' folder, run the
          `export_model_data_for_budget.m`. This process is time consuming
          and slow to run on local computer. It is better to run on `sci-nix`
          matlab and in the folder of
          `\Projects2\csiem\csiem-marvl-dev\others\mat_export_CSIEM_ECO05\`
 
###  step 2: 

  preprocessing the MPB variables for next step by runing the 
          `preprocessing_vars_nitrogen_MPB.m` script
 
###  step 3: 

   preprocesing the nodestring flux data for next step;
          in the `flux` folder, run the `process_flux_files_CSIEM.m` to 
          export the flux csv file into `.mat` file, and the `cal_flux_nodestring_CSIEM.m` script
          to calculate the daily flux rates; then run the `cal_flux_groundwater.m` script to 
          calculate the groundwater inputs. 
 
###  step 5: 

   define the nitrogen variables to be included in the pool and flux plots and then 
          do the nitrogen budgeting and plot by running the `cal_nitrogen_budget_hchb_5panels_2022_final.m`
          script.
 
### step 6: 

   define the phosphorus variables to be included in the pool and flux plots and then 
          do the phosphorus budgeting and plot by running the `cal_phosphorus_budget_hchb_5panels_2022_final.m` 
          script. 