clear; close all;
%addpath(genpath('W:\csiem\csiem-marvl\aed-marvl\'))

ncfile(1).name='W:\csiem\Model\TFV\Results_2013_B009\csiem_v1_B009_20130101_20131231_WQ_WQ.nc';

allvars = tfv_infonetcdf(ncfile(1).name);
dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
    Bottcells(length(dat.idx3)) = length(dat.idx3);

    Surfcells=dat.idx3(dat.idx3 > 0);

loadnames={'WQ_DIAG_NCS_D_TAUB','V_x','V_y','W','SAL','TEMP'};
short_names={'TAUB','Vx','Vy','W','SAL','TEMP'};
long_names={'TAUB','Vx','Vy','W','SAL','TEMP'};
units ={'N/m2','m/s','m/s','m/s','PSU','degrees'};

%%
%sitenames={'CS1','CS4','CS6'};
%siteX=[115.6976, 115.7500, 115.7392];
%siteY=[-32.1463, -32.2044, -32.0960];

sitenames={'PB','SBA','SBB','PBA','PBB','S01','S02'};
siteXutm=[381417.02, 379268.75, 380032.24, 378568.03, 379279.01];
siteYutm=[6455449.94, 6449572.59, 6448864.65, 6445541.44, 6444071.61];

[~, ~, grid_zone] = ll2utm (115.6976, -32.1463);

for ss=1:length(siteXutm)
    [siteX(ss), siteY(ss)] = utm2ll (siteXutm(ss), siteYutm(ss), grid_zone);
end

siteX(6:7)  =[115.762710, 115.730832];
siteY(6:7)  =[-32.200942, -32.180925];

% Site	Easting	Northing
% Port Beach	381417.02	6455449.94
% Success Bank A	379268.75	6449572.59
% Success Bank B	380032.24	6448864.65
% Parmelia Bank A	378568.03	6445541.44
% Parmelia Bank B	379279.01	6444071.61


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

readdata=1;

if readdata

for ll=1:length(loadnames)
    loadname=loadnames{ll};
    disp(['loading ',loadname,' ...']);
    tic;

    rawData=load_AED_vars(ncfile,1,loadname,allvars);
    
    for site=1:length(sitenames)
        disp(sitenames{site});
             tmp = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,siteX(site),siteY(site),{loadname});
             output.(sitenames{site}).(loadname)=tmp;
    end
    
    toc;
end

    loadname='D';
    disp(['loading ',loadname,' ...']);
    tic;

    rawData=load_AED_vars(ncfile,1,loadname,allvars);
    
    for site=1:length(sitenames)
        disp(sitenames{site});
         %    tmp = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,siteX(site),siteY(site),{loadname});
             output.(sitenames{site}).(loadname).Date=rawData.data.ResTime;
             output.(sitenames{site}).(loadname).Data=rawData.data.D(siteI(site),:);
    end
    
    toc;


save('extracted_for_Jeff_AED_2013.mat','output','-mat','-v7.3');

else
    load extracted_for_Jeff_AED_2013.mat;
end

% %% Export to NetCDF
% %layers=[24 17];
% 
% for site=1:length(sitenames)
%     
%     outfile = ['CS_bottom_property_',sitenames{site},'.nc'];
% 
% ncid=netcdf.create(outfile,'NC_NOCLOBBER');
% %lon_dimID = netcdf.defDim(ncid,'Nx',156);
% %depth_dimID = netcdf.defDim(ncid,'Ny',layers(site));
% time_dimID = netcdf.defDim(ncid,'time',...
%     netcdf.getConstant('NC_UNLIMITED'));
% 
%     varidTIME = netcdf.defVar(ncid,'time','NC_DOUBLE',time_dimID);
%     netcdf.putAtt(ncid,varidTIME,'units','time in days since 01/01/2022 00:00:00');
%     netcdf.putAtt(ncid,varidTIME,'longname','time');
%     netcdf.putAtt(ncid,varidTIME,'reference_time','01/01/2022 00:00:00');
%     netcdf.putAtt(ncid,varidTIME,'tz','UTC+08');
% %     
% %     varidD = netcdf.defVar(ncid,'depth','NC_DOUBLE',depth_dimID);
% %     netcdf.putAtt(ncid,varidTIME,'units','m');
% %     netcdf.putAtt(ncid,varidTIME,'longname','depth');
% 
%     
%     
% for ll=1:length(loadnames)
%     varidTIME = netcdf.defVar(ncid,short_names{ll},'NC_DOUBLE',time_dimID);
%     netcdf.putAtt(ncid,varidTIME,'units',units{ll});
%     netcdf.putAtt(ncid,varidTIME,'longname',long_names{ll});
%     netcdf.putAtt(ncid,varidTIME,'AED_name',loadnames{ll});
% 
% end
% 
% netcdf.close(ncid);
% 
% 
% ncwrite(outfile,'time',output.(sitenames{site}).(loadnames{1}).date-datenum(2022,1,1));
% %ncwrite(outfile,'depth',output.(sitenames{site}).(loadnames{1}).depths);
% 
% for ll=1:length(loadnames) 
%     ncwrite(outfile,short_names{ll},output.(sitenames{site}).(loadnames{ll}).bottom);
% end
% 
% end
