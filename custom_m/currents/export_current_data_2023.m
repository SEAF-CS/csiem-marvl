
clear; close all;

inDir='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\bc_repo\3_waves\WWM\';
infile=[inDir,'WWM_Bgrid_UTC+0_20221101_20240331.nc'];

Xp=ncread(infile,'Xp');
Yp=ncread(infile,'Yp');

sitenames={'PB','SBA','SBB','PBA','PBB','S01','S02'};
siteXutm=[381417.02, 379268.75, 380032.24, 378568.03, 379279.01];
siteYutm=[6455449.94, 6449572.59, 6448864.65, 6445541.44, 6444071.61];

[~, ~, grid_zone] = ll2utm (115.6976, -32.1463);

for ss=1:length(siteXutm)
    [siteX(ss), siteY(ss)] = utm2ll (siteXutm(ss), siteYutm(ss), grid_zone);
end

siteX(6:7)  =[115.762710, 115.730832];
siteY(6:7)  =[-32.200942, -32.180925];

%% export WWM regional grids

for ss=1:length(sitenames)
    disp(['importing ',sitenames{ss}, '...']);

X0=siteX(ss);
Y0=siteY(ss);

X1=Xp-X0;
Y1=Yp-Y0;

Td=sqrt(X1.^2+Y1.^2);
tmp1=min(Td,[],2);
ind1=find(tmp1==min(tmp1));

tmp2=min(Td,[],1);
ind2=find(tmp2==min(tmp2));

time=ncread(infile,'time')/24+datenum(1990,1,1);
output.time=time;

tmp=ncread(infile,'Hsig',[ind1,ind2,1],[1 1 Inf]);
output.(sitenames{ss}).Hs=squeeze(tmp(1,1,:));

tmp=ncread(infile,'Dir',[ind1,ind2,1],[1 1 Inf]);
output.(sitenames{ss}).Dir=squeeze(tmp(1,1,:));

tmp=ncread(infile,'TPsmoo',[ind1,ind2,1],[1 1 Inf]);
output.(sitenames{ss}).TP=squeeze(tmp(1,1,:));

end

save('WWM_2023.mat','output','-mat','-v7.3');

%% import AWAC data
clear output;
inDir='E:\AED Dropbox\AED_Cockburn_db\CSIEM\Data\data-swamp\Jeff\';
sites={'PortBeach','SuccessBankA','SuccessBankB','ParmeliaBankA','ParmeliaBankB'};
stdvars={'DIR','HS','TPER'};
vars={'WVDIR','WVHT','WVPER'};

for ss=1:length(sites)
    infile=[inDir,sites{ss},'_output.csv'];
    disp(infile);
    data=readtable(infile);


        output.(sites{ss}).time=datenum(data.Time);
        output.(sites{ss}).DIRpeak=data.PeakDirection_deg_;
        output.(sites{ss}).DIRmean=data.MeanDirection_deg_;
        output.(sites{ss}).HS=data.SigWaveHeight_m_;
        output.(sites{ss}).TPERpeak=data.PeakPeriod_s_;
        output.(sites{ss}).TPERmean=data.MeanPeriod_s_;
        output.(sites{ss}).Ux=data.EastMeanCurrentMagnitude_m_s_;
        output.(sites{ss}).Uy=data.NorthMeanCurrentMagnitude_m_s_;
        output.(sites{ss}).D=data.Depth_m_;
end

save('ADV_2023.mat','output','-mat','-v7.3');
clear output;

