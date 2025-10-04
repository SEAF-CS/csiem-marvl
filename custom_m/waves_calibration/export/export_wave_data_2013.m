
clear; close all;

inDir='W:\csiem\Model\WAVES\WWM_SWAN_conversion\WWM_SWAN_CONV_Bgrid_all_years\';
infile=[inDir,'WWM_SWAN_CONV_Bgrid_2013.nc'];

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

save('WWM_2013.mat','output','-mat','-v7.3');

%% import AWAC data
clear output;
inDir='E:\AED Dropbox\AED_Cockburn_db\CSIEM\Data\data-swamp\JPPL\AWAC\JPPL_AWAC\';
sites={'a','b','c','d'};
stdvars={'DIR','HS','TPER'};
vars={'WVDIR','WVHT','WVPER'};
clear output;

for ss=1:length(sites)
    infile=[inDir,'S01_',sites{ss},'\Westport_S01_',sites{ss},'.mat'];
    data=load(infile);
    
    if ss==1
        
        output.S01.time=data.DATA.SITE01.TIME_wave;
        output.S01.DIR=data.DATA.SITE01.WVDIR;
        output.S01.HS=data.DATA.SITE01.WVHT;
        output.S01.TPER=data.DATA.SITE01.WVPER;
    else
        l1=length(output.S01.time);
        l2=length(data.DATA.SITE01.TIME_wave);
        
        output.S01.time(l1+1:l1+l2)=data.DATA.SITE01.TIME_wave;
        output.S01.DIR(l1+1:l1+l2)=data.DATA.SITE01.WVDIR;
        output.S01.HS(l1+1:l1+l2)=data.DATA.SITE01.WVHT;
        output.S01.TPER(l1+1:l1+l2)=data.DATA.SITE01.WVPER;
    end
    
end

for ss=1:length(sites)
    infile=[inDir,'S02_',sites{ss},'.\Westport_S02_',sites{ss},'.mat'];
    data=load(infile);
    
    if ss==1
        
        output.S02.time=data.DATA.SITE02.TIME_wave;
        output.S02.DIR=data.DATA.SITE02.WVDIR;
        output.S02.HS=data.DATA.SITE02.WVHT;
        output.S02.TPER=data.DATA.SITE02.WVPER;
    else
        l1=length(output.S02.time);
        l2=length(data.DATA.SITE02.TIME_wave);
        
        output.S02.time(l1+1:l1+l2)=data.DATA.SITE02.TIME_wave;
        output.S02.DIR(l1+1:l1+l2)=data.DATA.SITE02.WVDIR;
        output.S02.HS(l1+1:l1+l2)=data.DATA.SITE02.WVHT;
        output.S02.TPER(l1+1:l1+l2)=data.DATA.SITE02.WVPER;
    end
    
end
save('AWAC_2013.mat','output','-mat','-v7.3');
clear output;

