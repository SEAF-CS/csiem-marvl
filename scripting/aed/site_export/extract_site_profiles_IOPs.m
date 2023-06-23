clear; close all;
%addpath(genpath('W:\csiem\csiem-marvl\'))

ncfile(1).name='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results_GW_noND\csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_WQ.nc';
allvars = tfv_infonetcdf(ncfile(1).name);

IOPsheet='IOP_variables.xlsx';
[~,short_names,~]=xlsread(IOPsheet,'C4:C11');
[~,long_names,~]=xlsread(IOPsheet,'D4:D11');
[~,units,~]=xlsread(IOPsheet,'E4:E11');

for n=1:length(short_names)
    loadnames{n}=['WQ_',upper(short_names{n})];
end
% 
% loadnames={'WQ_OGM_POC','WQ_DIAG_OGM_CDOM','WQ_DIAG_PHY_TPHY','WQ_DIAG_TOT_TOC',...
%     'WQ_DIAG_TOT_TSS','WQ_DIAG_TOT_TURBIDITY','WQ_DIAG_TOT_LIGHT',...
%     'WQ_DIAG_TOT_PAR','WQ_DIAG_TOT_UV','WQ_DIAG_TOT_EXTC'};
% short_names={'POC','CDOM','TPHY','TOC','TSS','TURB','LIGHT','PAR','UV','EXTC'};
% long_names={'particulate organic particles', 'Colored dissolved organic matter','total phytoplankton biomass','total organic carbon',...
%     'total suspended solids','turbidity','light','Photosynthetically active radiation',...
%     'UV','extinction coefficient'};
% units ={'mmol C/m3','mmol C/m3', 'mmol C/m3','mmol C/m3',...
%     'mg/L','NTU','W/m2','W/m2','W/m2','/m'};

sitenames={'center','nearshore'};
siteX=[115.7265 115.7697];
siteY=[-32.1927 -32.1811];

readdata=0;

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

save('extracted_light_IOPs.mat','output','-mat','-v7.3');

else
    load extracted_light_IOPs.mat;
end

%% Export to NetCDF
layers=[24 17];

for site=1:length(sitenames)
    
    outfile = ['IOP_site_profile_CS_',sitenames{site},'.nc'];

ncid=netcdf.create(outfile,'NC_NOCLOBBER');
%lon_dimID = netcdf.defDim(ncid,'Nx',156);
depth_dimID = netcdf.defDim(ncid,'Depth',layers(site));
time_dimID = netcdf.defDim(ncid,'time',...
    netcdf.getConstant('NC_UNLIMITED'));

    varidTIME = netcdf.defVar(ncid,'time','NC_DOUBLE',time_dimID);
    netcdf.putAtt(ncid,varidTIME,'units','time in days since 01/01/2013 00:00:00');
    netcdf.putAtt(ncid,varidTIME,'longname','time');
    netcdf.putAtt(ncid,varidTIME,'reference_time','01/01/2013 00:00:00');
    netcdf.putAtt(ncid,varidTIME,'tz','UTC+08');
    
        varidD = netcdf.defVar(ncid,'depth','NC_DOUBLE',depth_dimID);
    netcdf.putAtt(ncid,varidTIME,'units','m');
    netcdf.putAtt(ncid,varidTIME,'longname','depth');

    
    
for ll=1:length(loadnames)
    varidTIME = netcdf.defVar(ncid,short_names{ll},'NC_DOUBLE',[depth_dimID, time_dimID]);
    netcdf.putAtt(ncid,varidTIME,'units',units{ll});
    netcdf.putAtt(ncid,varidTIME,'longname',long_names{ll});
    netcdf.putAtt(ncid,varidTIME,'AED_name',loadnames{ll});

end

netcdf.close(ncid);


ncwrite(outfile,'time',output.(sitenames{site}).(loadnames{1}).date-datenum(2013,1,1));
ncwrite(outfile,'depth',output.(sitenames{site}).(loadnames{1}).depths);

for ll=1:length(loadnames) 
    ncwrite(outfile,short_names{ll},output.(sitenames{site}).(loadnames{ll}).profile);
end

end
%     
% newtime=(output.time-datenum(1990,1,1))*24+8; %UTC+08
% ncwrite(outfile,'time',newtime);
% ncwrite(outfile,'Hsig',output.Hsig);
% ncwrite(outfile,'Dir',output.Dir);
% ncwrite(outfile,'TPsmoo',output.TPsmoo);
% %ncwrite(outfile,'Ubot',output.Ubot);