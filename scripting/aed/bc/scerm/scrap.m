clear all; close all;

addpath(genpath('C:\Users\00065525\Github\aed_matlab_modeltools\TUFLOWFV\tuflowfv'));

data = tfv_readBCfile('BCs/Tide/NAR_Inflow_Depth.csv');
load ../../../../data/cockburn.mat;

ncfile = 'D:\Cloud\AED Dropbox\AED_Cockburn_db\Brendan\2022_sims\SCERM\NAR_Tide_20210315_20230331.nc';

nctime = ncread(ncfile,'time');
ncH = ncread(ncfile,'H');

mdate = datenum(1990,01,01,00,00,00) + (nctime/24);
mH = ncH(4,:)';


nc2 = 'Y:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results_2022_shifted\csiem_100_A_20220101_20221231_WQ_009_waves_noGW_WWM.nc';

nc2date = ncread(nc2,'ResTime');
mdate2 = datenum(1990,01,01,00,00,00) + (nc2date/24);
nc2H = ncread(nc2,'H');
mH2 = nc2H(11887,:);


plot(mdate,mH);hold on;
plot(data.Date,data.WL);


plot(mdate2,mH2);

plot(cockburn.DOT_FFFBH01.H.Date,cockburn.DOT_FFFBH01.H.Data);
plot(cockburn.DOT_FFFBH01.H.Date,cockburn.DOT_FFFBH01.H.Data - 0.756);

fdata = cockburn.DOT_FFFBH01.H.Data;
fdata(fdata < -50) = NaN;

load('C:\Users\00065525\Github\SCERM\matlab\WIR_Catchment\swan.mat');


plot(swan.s616004.Level.Date,swan.s616004.Level.Data);

legend({'SCERM';'Shifted NAR';'CSIEM';'Freo DOT';'Shifted Freo';'MSB'});

%xlim([datenum(2022,01,01) datenum(2023,01,01)]);

