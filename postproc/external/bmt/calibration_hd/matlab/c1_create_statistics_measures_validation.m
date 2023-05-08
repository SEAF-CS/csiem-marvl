%% Script to conduct statistical measures on hydro model
%
% Script to conduct statistical measures on hydro model
% These measures are used to compare simulated results with observed data and to evaluate the accuracy of the model
% BIAS,RMSE,MAE, COR_Coef are some of the key tests
% Written for A11348 Cockburn Sound BGC Model
% 
% Copyright (C) BMT 2023    


close all 
clear  
clc

%% User definitions
run_version_name ='CSound_000_A7_20130101_20130601';
% run_version = [run_version_name '_tsFormat_Validation']; 
fname_list=dir(['..\data\matfiles\CSound_Calibration\ADCP Data\*.mat']);
fname_list=fname_list(~ismember({fname_list.name},{'.','..'}));

output_FilePath='..\data\matfiles\';

if ~exist(output_FilePath)
    mkdir(output_FilePath);
    disp('New directory created...')
end

Cell_IDS = readtable('cellID.txt');
[v, w] = unique( Cell_IDS.cell_ids, 'stable' );
duplicate_indices = setdiff( 1:numel(Cell_IDS.cell_ids), w );


for fname_i = 1 : length(fname_list)


    clear OBS
    fname = fname_list(fname_i).name;

    fileTest=find(strcmp(Cell_IDS.sites,(fname(1:end-4))));
    fileTest2=ismember(Cell_IDS.cell_ids,Cell_IDS.cell_ids(fileTest));
    fileTest3=find(fileTest2 > 0,1);
    fname=Cell_IDS.sites(fileTest3);
    fname=[fname{1} '.mat'];

    obs_data_name = ['..\data\matfiles\CSound_Calibration\ADCP Data\' fname];
    mod_data_name = ['..\data\matfiles\CSound_Calibration\' run_version_name '_ts.mat'];

    run_name = [run_version_name '_ts'];
    
    model_data_dir = ['..\data\matfiles\' run_version_name '\'];
    out_dir = [model_data_dir 'Stats_measures'];
    
    plot_purpose = 'Validation';



    % load data
    load(obs_data_name);
    load(mod_data_name);

    if contains(fname,'a.mat')
        t_rng=[datetime({'01-Jan-2013';}) DATA.PeriodEnd];
    else
        t_rng={DATA.PeriodStart DATA.PeriodEnd};
    end    

    time_start = datenum(t_rng(1));
    time_end = datenum (t_rng(end));



        if contains(fname,'S01')
            site='SITE01';
        elseif contains(fname,'S02')
            site='SITE02';
        end
    OBS=DATA;

        levels = {'surface';'middle';'bottom';'sigma';};

    
         
         for level_i  = 1:length(levels)

            varn=fields(OBS.(levels{level_i}));

            for varn_i = 1 : length(varn)

                [Meas_Data, ind] = rmoutliers(OBS.(levels{level_i}).(varn{varn_i})); % remove outliers from the data
                
                if ismember (varn,'H')
                    Meas_Data = Meas_Data - mean(Meas_Data,'omitnan');
                end

                tmeas =   OBS.TIME_hydro(~ind); % extract index of time for non-outliers
                Meas_Data=Meas_Data';
    
                if isempty(Meas_Data) < eps
                st = find((tmeas  -time_start)>eps); 
                    if isempty(st)> eps; st = 1; 
                
                    else
                            st = st(1); 
                    end
                
                ed = find((tmeas  - time_end)>eps);
    
                    if isempty(ed) >eps; ed  = length(tmeas); 
                    
                    else
                        ed  = ed(1)-1; 
                    end
                tmeas = tmeas(st:ed);
                Meas_Data = Meas_Data(st:ed);
                    if isempty(Meas_Data) < eps
        
                   
                        
                        if ismember(varn{varn_i},'VDIR')
                            [Mod_Res, ~] = cart2compass(CockburnSound.(fname(1:end-4)).V_x.(levels{level_i}).data,CockburnSound.(fname(1:end-4)).V_y.(levels{level_i}).data);
                            tmodel =  CockburnSound.(fname(1:end-4)).V_x.(levels{level_i}).date;
                        elseif ismember (varn{varn_i},'H')
                            tmodel =  CockburnSound.(fname(1:end-4)).(varn{varn_i}).(levels{level_i}).date;
                             Mod_Res = CockburnSound.(fname(1:end-4)).(varn{varn_i}).(levels{level_i}).data - mean(CockburnSound.(fname(1:end-4)).(varn{varn_i}).(levels{level_i}).data,'omitnan');
                        else
                            tmodel =  CockburnSound.(fname(1:end-4)).V_x.(levels{level_i}).date;
                            Mod_Res = CockburnSound.(fname(1:end-4)).(varn{varn_i}).(levels{level_i}).data;
                        end

                        iind=find(tmeas>=(tmodel(1)) & tmeas<=(tmodel(end))); % selects one day before and aafter the model to make sure the interp doesn't start and end to NAN

                        if iind ~= 0
                            PLOT_SWitch = 0;
                            [Willmott,Brier,BIAS,RMSE,COR_Coef, MAE] = Willmott_BR_SKILL_v2(tmeas,Meas_Data,tmodel,Mod_Res,PLOT_SWitch);
                
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).BIAS = BIAS;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).RMSE = RMSE;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).MAE = MAE;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).COR_Coef = COR_Coef;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).Brier = Brier;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).Willmott = Willmott;
                        else
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).BIAS = 0;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).RMSE = 0;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).MAE = 0;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).COR_Coef = 0;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).Brier = 0;
                            stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_i}).Willmott = 0;
                        end
                    
                    end
                end

            end

         
             % ============================================
             % SAVE ALL VARN RESULTS DATA in .xlsx
            clear interCalc tabs
            interCalc.BIAS = [];
            interCalc.RMSE = [];
            interCalc.MAE = [];
            interCalc.COR_Coef = [];
            interCalc.Brier = [];
            interCalc.Willmott= [];
                        % loop results into 
            for varn_ii =  1 : length(varn) 

                interCalc.BIAS(varn_ii,:) =stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_ii}).BIAS;
                interCalc.RMSE(varn_ii,:) =  stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_ii}).RMSE;
                interCalc.MAE(varn_ii,:) = stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_ii}).MAE;
                interCalc.COR_Coef(varn_ii,:) =  stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_ii}).COR_Coef;
                interCalc.Brier(varn_ii,:) = stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_ii}).Brier;
                interCalc.Willmott(varn_ii,:) =stats.(fname(1:end-4)).(levels{level_i}).(varn{varn_ii}).Willmott;

            end

            tabs = table();
            tabs.Loc=repmat(fname(1:end-4),[length(varn),1]);
            tabs.Levels=repmat(levels{level_i},[length(varn),1]);
            tabs.Var=char(varn);
            tabs.IOA_Willmott=interCalc.Willmott;
            tabs.BIAS =interCalc.BIAS;
            tabs.RMSE =interCalc.RMSE;
            tabs.MAE =interCalc.MAE;
            tabs.COR_Coef =interCalc.COR_Coef;
            tabs.Brier =interCalc.Brier;

            sheetName=(fname(1:end-4));
            writetable(tabs,[output_FilePath strrep(run_name,'_ts',filesep) 'Stats_measures\' fname(10:12) '_' plot_purpose 'test_all_var_report' '_stat.xlsx'],'sheet',sheetName);     

            % =================================================

    
    %% save all data in .mat
    
    if ~exist(out_dir,'dir')
        mkdir(out_dir); 
    end

    out_file_name = [out_dir '\' run_name '_' plot_purpose '_stat.mat'];
    save(out_file_name,'stats');

         end

end   

    








