% Script to take data from roms and convert it into coordinates to use in
% TUFLOW FV
%
% Save each daily ncfile as a matlab file.
% Written for A11348  Cockburn SOund model
%
% Uses:
%     
%
% Created by: Kabir Suara <kabir.suara@bmtglobal.com>
% Created on: XXXXXX
% updated by Kabir Suara
%  16 - Septmeber -2022
    % Transform from sigma to z cordinate
    % Interpolate into a structure 3 dimensional grid to use in TUFLOW FV
    % Save into fixed z grid and 
    %
    % 
    % Uses b_combine_ROMS.m to convert each daily matfiles into a single ncfile 

%clear 
%clc
clear; close all;
tic

addpath(genpath('toolbox'));

%% User input for a
resdir = 'W:/WAMSI/Model/ROMS/2016/';
fname = 'cwa_XXXX_03__his.nc';
grid_file = 'grid.nc';

%zlim = [0 5000];
tstart  = datenum(2016,01,01); % starting time of download
tfinish  = datenum(2016,02,01); % end time of download
times = tstart:tfinish;
var2extract  = {'zeta','salt','temp'};
nn = 1; % Horizontal grid coarsening factor.  1 recommended to preserve ROMS resolution
% Higher nn value to reduce processing speed at the expense of resoulion in
% set the initial conditions. nn = 2 is still a good trade-off. Values less
% than 1 will perform the same as 1 and take extremely longer time to
% process
%% User input to b_combine_ROMS.m
% -- INPUT
 %addpath(genpath('L:\Z_Matlab\wbm\'));
 tag = 'ROMS'; % Name for files, best to include timezone
 creator = 'KabirSuara'; % For file metadata
jobno = '11348'; % For file metadata
 timezone = 8; % Hours to add to GMT
 timezone_Name = 'UTC+8';
 inpat = 'W:/WAMSI/Model/ROMS/inputs/';
 outinpat = [inpat 'nc/'];
 if ~exist(inpat); mkdir(inpat); end
 if ~exist(outinpat); mkdir(outinpat); end
%% Extract grid information
disp(' grid info ...')
gridfil = [resdir grid_file]; 
% % grid_var = {'h','s_rho','hc','Cs_r'};
% % 
% % for i = 1:length(grid_var)
% %     grid.(grid_var{i}) = ncread(gridfil, grid_var{i});
% % end
grid.s_rho= ncread(gridfil, 's_rho');
grid.h= ncread(gridfil, 'h');
grid.sigma = -1*grid.s_rho;
grid.lat = ncread(gridfil,'lat_rho');
grid.lon = ncread(gridfil,'lon_rho');
% grid.lat_u = ncread(gridfil,'lat_u');
% grid.lon_u = ncread(gridfil,'lon_u');
% grid.lat_v = ncread(gridfil,'lat_v');
% grid.lon_v = ncread(gridfil,'lon_v');

% tfvfil = 'E:\database\AED-MARVl-v0.3\Examples\Cockburn\Data\Cockburn_kw_001_ALL_clipped.nc';
% cellX=ncread(tfvfil,'cell_X');
% cellY=ncread(tfvfil,'cell_Y');
xs=380;xf=480;ys=40;yf=150;

lon2int=grid.lon(xs:nn:xf,ys:nn:yf);
lat2int=grid.lat(xs:nn:xf,ys:nn:yf);

[newxx,newyy]=ll2utm(lat2int,lon2int);


for time_i  = 1 :length(times)
    resfil = [resdir strrep(fname, 'XXXX',datestr(times(time_i),'yyyymmdd'))];
    disp(resfil);
    timet = ncread(resfil,'ocean_time')./(24*3600) +  datenum(2000,1,1);
    
    tmpS=ncread(resfil,'salt');
    tmpT=ncread(resfil,'temp');
    tmpZ=ncread(resfil,'zeta');
    
    lengt=length(timet);
    
    if time_i==1
        salinity.Surf=squeeze(tmpS(xs:nn:xf,ys:nn:yf,end,:));
        temperature.Surf=squeeze(tmpT(xs:nn:xf,ys:nn:yf,end,:));
        salinity.Bot=squeeze(tmpS(xs:nn:xf,ys:nn:yf,1,:));
        temperature.Bot=squeeze(tmpT(xs:nn:xf,ys:nn:yf,1,:));
        zeta=tmpZ(xs:nn:xf,ys:nn:yf,:);
        time=timet;
    else
        lengs=size(salinity.Surf,3);
     %   salinity(:,:,lengs+1:lengs+lengt)=squeeze(tmpS(1:nn:end,1:nn:end,:,:));
     %   temperature(:,:,:,lengs+1:lengs+lengt)=tmpT(1:nn:end,1:nn:end,:,:);
        salinity.Surf(:,:,lengs+1:lengs+lengt)=squeeze(tmpS(xs:nn:xf,ys:nn:yf,end,:));
        temperature.Surf(:,:,lengs+1:lengs+lengt)=squeeze(tmpT(xs:nn:xf,ys:nn:yf,end,:));
        salinity.Bot(:,:,lengs+1:lengs+lengt)=squeeze(tmpS(xs:nn:xf,ys:nn:yf,1,:));
        temperature.Bot(:,:,lengs+1:lengs+lengt)=squeeze(tmpT(xs:nn:xf,ys:nn:yf,1,:));
        
        zeta(:,:,lengs+1:lengs+lengt)=tmpZ(xs:nn:xf,ys:nn:yf,:);
        time(lengs+1:lengs+lengt)=timet;
    end
    
end

% %%
% vars={};
% 
% for time_j  = 1 :length(time)
%     %resfil = [resdir strrep(fname, 'XXXX',datestr(times(time_i),'yyyymmdd'))];
%     disp(['interping ',datestr(time(time_j),'yyyy mm dd HH')]);
%     
%     d2int=squeeze(salinity.Surf(:,:,time_j));
%     F = scatteredInterpolant(newxx(:),newyy(:),d2int(:)); % Negeative to turn to depth
%     F.ExtrapolationMethod = 'none';
%     saltTFV.Surf(:,time_j) = F(cellX,cellY);
%     
%     d2int=squeeze(salinity.Bot(:,:,time_j));
%     F = scatteredInterpolant(newxx(:),newyy(:),d2int(:)); % Negeative to turn to depth
%     F.ExtrapolationMethod = 'none';
%     saltTFV.Bot(:,time_j) = F(cellX,cellY);
%     
%     d2int=squeeze(temperature.Surf(:,:,time_j));
%     F = scatteredInterpolant(newxx(:),newyy(:),d2int(:)); % Negeative to turn to depth
%     F.ExtrapolationMethod = 'none';
%     tempTFV.Surf(:,time_j) = F(cellX,cellY);
%     
%     d2int=squeeze(temperature.Bot(:,:,time_j));
%     F = scatteredInterpolant(newxx(:),newyy(:),d2int(:)); % Negeative to turn to depth
%     F.ExtrapolationMethod = 'none';
%     tempTFV.Bot(:,time_j) = F(cellX,cellY);
%     
%     d2int=squeeze(zeta(:,:,time_j));
%     F = scatteredInterpolant(newxx(:),newyy(:),d2int(:)); % Negeative to turn to depth
%     F.ExtrapolationMethod = 'none';
%     zetaTFV(:,time_j) = F(cellX,cellY);
%     
% end

save('outdata.mat','zeta*','sal*','temp*','time','lat2int','lon2int','newxx','newyy','-mat');

%% put vars
newfil = 'ROMS_combined2.nc';
if exist(newfil,'file')
    delete(newfil);
end

dims.x_rho = size(lon2int,1); % 1st dimension
dims.y_rho = size(lon2int,2); % 2nd dimension
%dims.tfvCell = length(cellX); % 2nd dimension
%dims.depth = length(S.z); % 3rd dimension
dims.time = length(time); %'UNLIMITED'; % 4th dimension

vars.time.nctype       = 'NC_DOUBLE';
vars.time.dimensions   = 'time';
vars.time.long_name    = 'Valid Time';
vars.time.units        = 'hours since 1990-01-01 00:00:00';
vars.time.time_origin  = '1990-01-01 00:00:00';
vars.time.calendar     = 'gregorian';
vars.time.axis         = 'T';
vars.time.reference    = timezone_Name;
vars.time.CoordinateAxisType = 'Time';

vars.lon.nctype        = 'NC_FLOAT';
vars.lon.dimensions    = {'x_rho','y_rho'};
vars.lon.long_name     = 'Longitude';
vars.lon.standard_name = 'longitude';
vars.lon.units         = 'degrees_east';
vars.lon.modulo        = '360 degrees';
vars.lon.axis          = 'X';
vars.lon.NAVO_code     = 2;
vars.lon.projection    = 'LL_WGS84';
vars.lon.CoordinateAxisType = 'Lon';

vars.lat.nctype        = 'NC_FLOAT';
vars.lat.dimensions    = {'x_rho','y_rho'};
vars.lat.long_name     = 'Latitude';
vars.lat.standard_name = 'latitude';
vars.lat.units         = 'degrees_north';
vars.lat.axis          = 'Y';
vars.lat.NAVO_code     = 1;
vars.lat.projection    = 'LL_WGS84';
vars.lat.CoordinateAxisType = 'Lat';

vars.lonUTM.nctype        = 'NC_FLOAT';
vars.lonUTM.dimensions    = {'x_rho','y_rho'};
vars.lonUTM.long_name     = 'Longitude UTM';
vars.lonUTM.standard_name = 'longitude UTM';
vars.lonUTM.units         = 'meters_east';
%vars.lon.modulo        = 'meters';
vars.lonUTM.axis          = 'X';
% vars.lon.NAVO_code     = 2;
% vars.lon.projection    = 'LL_WGS84';
vars.lonUTM.CoordinateAxisType = 'Lon';

vars.latUTM.nctype        = 'NC_FLOAT';
vars.latUTM.dimensions    = {'x_rho','y_rho'};
vars.latUTM.long_name     = 'Latitude UTM';
vars.latUTM.standard_name = 'latitude UTM';
vars.latUTM.units         = 'meters_north';
vars.latUTM.axis          = 'Y';
% vars.lat.NAVO_code     = 1;
% vars.lat.projection    = 'LL_WGS84';
vars.latUTM.CoordinateAxisType = 'Lat';

vars.depth.nctype        = 'NC_FLOAT';
vars.depth.dimensions    = {'x_rho','y_rho'};
vars.depth.long_name     = 'Grid Depth';
vars.depth.standard_name = 'grid depth';
vars.depth.units         = 'meters';
vars.depth.axis          = 'Z';
% vars.depth.NAVO_code     = 1;
% vars.depth.projection    = 'LL_WGS84';
% vars.depth.CoordinateAxisType = 'Lat';

vars.TEMPsurf.nctype         = 'NC_FLOAT';
vars.TEMPsurf.dimensions     = {'x_rho','y_rho','time'};
vars.TEMPsurf.CoordinateAxes = 'time lat lon';
vars.TEMPsurf.long_name      = 'Surface Water Temperature';
vars.TEMPsurf.standard_name  = 'surf_sea_water_temperature';
vars.TEMPsurf.units          = 'degC';
vars.TEMPsurf.missing_value  = -30000;
vars.TEMPsurf.scale_factor   = 1;
vars.TEMPsurf.add_offset     = 0;
vars.TEMPsurf.NAVO_code      = 15;
vars.TEMPsurf.comment        = 'in-situ temperature';
vars.TEMPsurf.coordinates    = 'time lat lon';

vars.SALsurf.nctype         = 'NC_FLOAT';
vars.SALsurf.dimensions     = {'x_rho','y_rho','time'};
vars.SALsurf.FillValue      = -30000;
vars.SALsurf.CoordinateAxes = 'time lat lon ';
vars.SALsurf.long_name      = 'Surface Salinity';
vars.SALsurf.standard_name  = 'surface_sea_water_salinity';
vars.SALsurf.units          = 'psu';
vars.SALsurf.missing_value  = -30000;
vars.SALsurf.scale_factor   = 1;
vars.SALsurf.add_offset     = 0;
vars.SALsurf.NAVO_code      = 16;
vars.SALsurf.coordinates    = 'time lat lon';


vars.TEMPbot.nctype         = 'NC_FLOAT';
vars.TEMPbot.dimensions     = {'x_rho','y_rho','time'};
vars.TEMPbot.CoordinateAxes = 'time lat lon';
vars.TEMPbot.long_name      = 'bottom Water Temperature';
vars.TEMPbot.standard_name  = 'bottom_sea_water_temperature';
vars.TEMPbot.units          = 'degC';
vars.TEMPbot.missing_value  = -30000;
vars.TEMPbot.scale_factor   = 1;
vars.TEMPbot.add_offset     = 0;
vars.TEMPbot.NAVO_code      = 15;
vars.TEMPbot.comment        = 'in-situ temperature';
vars.TEMPbot.coordinates    = 'time lat lon';

vars.SALbot.nctype         = 'NC_FLOAT';
vars.SALbot.dimensions     = {'x_rho','y_rho','time'};
vars.SALbot.FillValue      = -30000;
vars.SALbot.CoordinateAxes = 'time lat lon ';
vars.SALbot.long_name      = 'bottom Salinity';
vars.SALbot.standard_name  = 'bottom_sea_water_salinity';
vars.SALbot.units          = 'psu';
vars.SALbot.missing_value  = -30000;
vars.SALbot.scale_factor   = 1;
vars.SALbot.add_offset     = 0;
vars.SALbot.NAVO_code      = 16;
vars.SALbot.coordinates    = 'time lat lon';

vars.zeta.nctype         = 'NC_FLOAT';
vars.zeta.dimensions     = {'x_rho','y_rho','time'};
vars.zeta.FillValue      = -30000;
vars.zeta.CoordinateAxes = 'time lat lon ';
vars.zeta.long_name      = 'free surface';
vars.zeta.standard_name  = 'free_surface';
vars.zeta.units          = 'meter';
vars.zeta.missing_value  = -30000;
vars.zeta.scale_factor   = 1;
vars.zeta.add_offset     = 0;
% vars.zeta.NAVO_code      = 16;
vars.zeta.coordinates    = 'time lat lon';

atts = struct();

netcdf_define(newfil, dims, vars, atts);

netcdf_put_var(newfil, 'time', (time-datenum(1990,1,1))*24);
netcdf_put_var(newfil, 'lon', lon2int);
netcdf_put_var(newfil, 'lat', lat2int);
netcdf_put_var(newfil, 'lonUTM', newxx);
netcdf_put_var(newfil, 'latUTM', newyy);
netcdf_put_var(newfil, 'depth', grid.h(xs:nn:xf,ys:nn:yf,:));
netcdf_put_var(newfil, 'TEMPsurf', temperature.Surf);
netcdf_put_var(newfil, 'SALsurf', salinity.Surf);
netcdf_put_var(newfil, 'TEMPbot', temperature.Bot);
netcdf_put_var(newfil, 'SALbot', salinity.Bot);
netcdf_put_var(newfil, 'zeta', zeta);
%netcdf_put_var(newfil, 'depth', S.z);
                   

% %%
% H = zeros(length(x),length(y),length(timet));
% salt = zeros(length(x),length(y),length(zf),length(timet));
% temp = zeros(length(x),length(y),length(zf),length(timet));
% u = zeros(length(x),length(y),length(zf),length(timet));
% v = zeros(length(x),length(y),length(zf),length(timet));
% 
% for subt_i = 1:length(timet)
%     zt  = repmat(zeros(size(mod.grid.h)),1,1,length(grid.s_rho));
%     tmz = mod.zeta(:,:,subt_i); % Extract water leve at given time
%     tmzz = tmz  + mod.grid.h; % add bathymetry in m 
%     
%     for lev_i = 1:length(grid.s_rho) 
%         zt(:,:,lev_i) = tmz + (tmzz)*grid.s_rho(lev_i);
%     end
%     zin = -1*zt;
%     zin_u = -1*zt(1:size(mod.grid.lon_u,1),1:size(mod.grid.lon_u,2),:);  % Negeative to turn to depth
%     zin_v = -1*zt(1:size(mod.grid.lon_v,1),1:size(mod.grid.lon_v,2),:);  % Negeative to turn to depth
%     % Interpolate Salt
%     saltin = mod.salt(:,:,:,subt_i);   
%     ind = find(~isnan(saltin(:)));
%     Fsalt = scatteredInterpolant(mod.grid.lon(ind),mod.grid.lat(ind),zin(ind),saltin(ind)); % Negeative to turn to depth
%     Fsalt.ExtrapolationMethod = 'none';
%     salt(:,:,:,subt_i) = Fsalt(xx,yy,zz);
% 
%         % Interpolate Temperature
%     tempin = mod.temp(:,:,:,subt_i);   
%     ind = find(~isnan(tempin(:))); % Negeative to turn to depth
%     Ftemp = scatteredInterpolant(mod.grid.lon(ind),mod.grid.lat(ind),zin(ind),tempin(ind)); % Negeative to turn to depth
%     Ftemp.ExtrapolationMethod = 'none';
%     temp(:,:,:,subt_i) = Ftemp(xx,yy,zz);
% 
%      % Interpolate velocities
%     uin = mod.u(:,:,:,subt_i);   
%     ind = find(~isnan(uin(:)));
%     Fu = scatteredInterpolant(mod.grid.lon_u(ind),mod.grid.lat_u(ind),zin_u(ind),uin(ind)); % Negeative to turn to depth
%     Fu.ExtrapolationMethod = 'none';
%     u(:,:,:,subt_i) = Fu(xx,yy,zz);
% 
%     vin = mod.v(:,:,:,subt_i);   
%     ind = find(~isnan(vin(:)));
%     Fv = scatteredInterpolant(mod.grid.lon_v(ind),mod.grid.lat_v(ind),zin_v(ind),vin(ind)); % Negeative to turn to depth
%     Fv.ExtrapolationMethod = 'none';
%     v(:,:,:,subt_i) = Fv(xx,yy,zz);
% 
%   
%     ind = find(~isnan(tmz(:)));
%     xin = mod.grid.lon(:,:,1);
%     yin = mod.grid.lat(:,:,1);
%     FH = scatteredInterpolant(xin(ind),yin(ind),tmz(ind)); % Negeative to turn to depth
%     FH.ExtrapolationMethod = 'none';
%     H(:,:,subt_i) = FH(xw,yw);
% 
%       
% end
%  %% Pad down horizontally turning interpolated value deeper than actual bathy to nan (avoiding artifact of exptrapolation)
% for ii = 1:size(xw,1)
%     for jj = 1:size(xw,2)
%         salt(ii,jj,zlast_ind(ii,jj):end,:) = nan;
%         u(ii,jj,zlast_ind(ii,jj):end,:) = nan;
%         v(ii,jj,zlast_ind(ii,jj):end,:) = nan;
%         temp(ii,jj,zlast_ind(ii,jj):end,:) = nan;
% 
%     end
% end
% %% Write data into strcuture
%     S.ssh=H;
%     S.u=u;                                  
%     S.v=v;
%     S.temperature=temp;
%     S.salinity=salt;  
%     S.z = zf';
%     S.x = x';
%     S.y = y';
%     S.t = timet + (timezone/24); % Add timezone correction
%     filename = [inpat 'ROMS_' datestr(times(time_i),'yyyymmdd') '.mat'];
%     save(filename,'S','-mat');
%     disp(['saved for timestep ' datestr(times(time_i),'yyyy-mm-dd') ])
% 
% %% Combine into netCDF file
% disp('Interpolation and conversion to gridded format completed, all matfile saved')
% 
% disp('Combining matfiles into a single .nc file')
% % tstart  = datenum(2013,01,01); % starting time of download
% b_combine_ROMS
% 
