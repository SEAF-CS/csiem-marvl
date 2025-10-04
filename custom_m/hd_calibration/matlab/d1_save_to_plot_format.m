%% extract_prof_CS_calibration_Hydrodynamic
%
% Script to save raw data into plotting format
% Written for A11348 Cockburn Sound BGC Model
%
% Copyright (C) BMT 2023

scens= {'000_A7_20130101_20130601'};

resdir = '..\data\matfiles\CSound_Calibration\';
whatTypeRun='Validation';
load([resdir strrep('CSound_XXXX_ts.mat','XXXX',scens{1})])
ab = fields(CockburnSound);


for sce_i = 1:length(scens)
    load([resdir strrep('CSound_XXXX_ts.mat','XXXX',scens{sce_i})])
   for i  = 1:length(ab)
        abf = fields(CockburnSound.(ab{i}));
        AB.surface(sce_i).(ab{i}).time = CockburnSound.(ab{i}).(abf{1}).surface.date;
        AB.middle(sce_i).(ab{i}).time = CockburnSound.(ab{i}).(abf{1}).middle.date;
        AB.bottom(sce_i).(ab{i}).time = CockburnSound.(ab{i}).(abf{1}).bottom.date ;
        AB.sigma(sce_i).(ab{i}).time =  CockburnSound.(ab{i}).(abf{1}).sigma.date;

        for j = 1:length(abf)
            AB.surface(sce_i).(ab{i}).(abf{j}) = CockburnSound.(ab{i}).(abf{j}).surface.data;
            AB.middle(sce_i).(ab{i}).(abf{j}) = CockburnSound.(ab{i}).(abf{j}).middle.data;
            AB.bottom(sce_i).(ab{i}).(abf{j}) = CockburnSound.(ab{i}).(abf{j}).bottom.data;
            AB.sigma(sce_i).(ab{i}).(abf{j}) = CockburnSound.(ab{i}).(abf{j}).sigma.data;

        end
    end
end
save([resdir 'CSound_' char(scens) '_tsFormat_' whatTypeRun '.mat'],'AB')