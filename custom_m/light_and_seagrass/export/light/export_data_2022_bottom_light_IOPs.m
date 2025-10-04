clear; close all;
%addpath(genpath('W:\csiem\csiem-marvl\'))

ncfile(1).name='/Projects2/csiem/Model/TFV/csiem_model_tfvaed_1.1/outputs/results/tests_PH_map_light2_OASIM_restart_08_nopollution70s_v2_WQ.nc';
disp(ncfile(1).name);

 dat = tfv_readnetcdf(ncfile.name,'time',1);
 timesteps = dat.Time;
 t0=datenum('20220101 00:00','yyyymmdd HH:MM');
tt = find(abs(timesteps-t0)==min(abs(timesteps-t0)));
disp(datestr(timesteps(tt)));

t1=datenum('20230101 00:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps-t1)==min(abs(timesteps-t1)));
disp(datestr(timesteps(tt1)));

allvars = tfv_infonetcdf(ncfile(1).name);
dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);

Surfcells=dat.idx3(dat.idx3 > 0);


% loadnames={'SAL','WQ_OXY_OXY','WQ_NIT_AMM','WQ_NIT_NIT','WQ_PHS_FRP','WQ_DIAG_OGM_POC_SWI','WQ_DIAG_PHY_PHY_SWI_C'};
% short_names={'SAL','OXY','AMM','NIT','FRP','POCSWI','PHYSWI'};
% long_names={'salinity','oxygen',...
%     'ammonium','nitrate','phosphate','POC settling','PHY setting'};
% units ={'PSU','mmol/m3','mmol/m3','mmol/m3','mmol/m3','mmol/m2/d','mmol/m2/d'};
% 
% sitenames={'Kwinana'};
% siteX=[115.7473];
% siteY=[-32.1977];
% 
% for t=1:length(sitenames)
%     distx=cellx-siteX(t);
%     disty=celly-siteY(t);
%     distt=sqrt(distx.^2+disty.^2);
%     
%     inds=find(distt==min(distt));
%     siteI(t)=inds(1);
%     siteD(t)=dat.D(inds(1));
% end

%%

readdata=1;

if readdata

for ll=1:length(allvars)
    loadname=allvars{ll};

    if any([strfind(loadname,'IOP'), strfind(loadname,'WQ_NCS_SS1'), strfind(loadname,'WQ_OGM_DOC'), ...
	strfind(loadname,'WQ_DIAG_PHY_TCHLA'), strfind(loadname,'WQ_OGM_POC')])
    disp(['loading ',loadname,' ...']);
    tic;

    rawData=ncread(ncfile(1).name, loadname); %load_AED_vars(ncfile,1,loadname,allvars);
    output.(loadname)=rawData(Bottcells,tt:tt1);
    
    toc;
    end
end

save('extracted_bottom_light_2022_restart_08_nopollution70s_v2_IOPs_wholeYear.mat','output','-mat','-v7.3');

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
