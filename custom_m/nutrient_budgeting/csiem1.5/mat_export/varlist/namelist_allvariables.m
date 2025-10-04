%% list all variable of TFV-AED outputs

clear all; close all;
ncfile = 'W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results/csiem_A001_20221101_20240401_ECO05_WQ.nc';

dat= tfv_readnetcdf(ncfile,'timestep',1);

fields=fieldnames(dat);

fileID = fopen('all_varialbe_names.csv','w');

for f=16:length(fields)

    fprintf(fileID,'%s\n',['''',fields{f},'''',';...']);
%fprintf(fileID,'%6.2f %12.8f\n',A);
end
fclose(fileID);