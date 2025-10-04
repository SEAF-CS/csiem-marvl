%%
ncfile(1).name='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\tests_OBC_2023_waves_scale_wave.nc';

allvars = tfv_infonetcdf(ncfile(1).name);
dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
    Bottcells(length(dat.idx3)) = length(dat.idx3);

    Surfcells=dat.idx3(dat.idx3 > 0);

loadnames={'WVHT','WVPER','WVDIR'};
short_names={'WH','WP','DIR'};
long_names={'Significant Wave Height','Peak Wave Period', 'Wave Direction'};
units ={'m','s','degrees'};

%%
sitenames={'PB','SBA','SBB','PBA','PBB','S01','S02'};
siteXutm=[381417.02, 379268.75, 380032.24, 378568.03, 379279.01];
siteYutm=[6455449.94, 6449572.59, 6448864.65, 6445541.44, 6444071.61];

[~, ~, grid_zone] = ll2utm (115.6976, -32.1463);

for ss=1:length(siteXutm)
    [siteX(ss), siteY(ss)] = utm2ll (siteXutm(ss), siteYutm(ss), grid_zone);
end

% Site	Easting	Northing
% Port Beach	381417.02	6455449.94
% Success Bank A	379268.75	6449572.59
% Success Bank B	380032.24	6448864.65
% Parmelia Bank A	378568.03	6445541.44
% Parmelia Bank B	379279.01	6444071.61

siteX(6:7)  =[115.762710, 115.730832];
siteY(6:7)  =[-32.200942, -32.180925];

% sitesheet='./GPS_sites_only.xlsx';
% 
% [num,txt,raw]=xlsread(sitesheet,'B2:C10');
% sitenames={'KS1','KS2','KS3','KS4','KS5','R6','OA7','OA8','Collection'};
for t=1:length(sitenames)
  %  tmp=txt{t};
  %  C=strsplit(tmp,',');
  %  siteX(t)=num(t,2); %str2double(C{2});
  %  siteY(t)=num(t,1);
    
    distx=cellx-siteX(t);
    disty=celly-siteY(t);
    distt=sqrt(distx.^2+disty.^2);
    
    inds=find(distt==min(distt));
    siteI(t)=inds(1);
    siteD(t)=dat.D(inds(1));
end

%%
for ll=1:length(loadnames)
    loadname=loadnames{ll};
    disp(['loading ',loadname,' ...']);
    tic;

    rawData=load_AED_vars(ncfile,1,loadname,allvars);
    
    for site=1:length(sitenames)
        disp(sitenames{site});
         %    tmp = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,siteX(site),siteY(site),{loadname});
             output.(sitenames{site}).(loadname).Date=rawData.data.ResTime;
             output.(sitenames{site}).(loadname).Data=rawData.data.(loadname)(siteI(site),:);
    end
    
    toc;
end

save('TFV_waves_scale_2023.mat','output','-mat','-v7.3');