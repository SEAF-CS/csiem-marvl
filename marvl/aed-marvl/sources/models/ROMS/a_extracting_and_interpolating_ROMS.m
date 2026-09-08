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
%zfile = 'M:\UWA\A11348_Cockburn_Sound_BCG_Model\2Exectn\2Modelling\2TUFLOWFV\model\geo\z_layer\SEP_zlayer_0p25.csv';

xlim = [108.5  116.2];
ylim = [-34.3  -22.5];
zf = [0 2:0.5:5 6:2:14 15:5:50 60:10:90 100:20:180 200:50:400 500:500:2000];
%zlim = [0 5000];
tstart  = datenum(2016,01,01); % starting time of download
tfinish  = datenum(2016,01,10); % end time of download
times = tstart:tfinish;
var2extract  = {'zeta', 'u', 'v', 'salt','temp'};
nn = 2; % Horizontal grid coarsening factor.  1 recommended to preserve ROMS resolution
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
grid.lat_u = ncread(gridfil,'lat_u');
grid.lon_u = ncread(gridfil,'lon_u');
grid.lat_v = ncread(gridfil,'lat_v');
grid.lon_v = ncread(gridfil,'lon_v');
%% Trim down domain size before processing
disp(' grid trim ...')
polyx = [min(xlim) min(xlim) max(xlim) max(xlim) min(xlim)];
polyy  = [min(ylim) max(ylim) max(ylim) min(ylim) min(ylim)];

[inpoly, ~] = inpolygon(grid.lon, grid.lat,polyx,polyy);
[row.rho,col.rho] = find(inpoly >0); % Rho bounds
mod.grid.lon = grid.lon(min(row.rho):max(row.rho),min(col.rho):max(col.rho));
mod.grid.lat = grid.lat(min(row.rho):max(row.rho),min(col.rho):max(col.rho));
mod.grid.h = grid.h(min(row.rho):max(row.rho),min(col.rho):max(col.rho));
mod.grid.lon = repmat(mod.grid.lon,1,1,length(grid.sigma));
mod.grid.lat = repmat(mod.grid.lat,1,1,length(grid.sigma));


[inpoly, ~] = inpolygon(grid.lon_u, grid.lat_u,polyx,polyy);
[row.u,col.u] = find(inpoly >0); % u bounds
mod.grid.lon_u = grid.lon_u(min(row.u):max(row.u),min(col.u):max(col.u));
mod.grid.lat_u = grid.lat_u(min(row.u):max(row.u),min(col.u):max(col.u));
mod.grid.lon_u = repmat(mod.grid.lon_u,1,1,length(grid.sigma));
mod.grid.lat_u = repmat(mod.grid.lat_u,1,1,length(grid.sigma));


[inpoly, ~] = inpolygon(grid.lon_v, grid.lat_v,polyx,polyy);
[row.v,col.v] = find(inpoly >0); % v bounds
mod.grid.lon_v = grid.lon_v(min(row.v):max(row.v),min(col.v):max(col.v));
mod.grid.lat_v = grid.lat_v(min(row.v):max(row.v),min(col.v):max(col.v));
mod.grid.lon_v = repmat(mod.grid.lon_v,1,1,length(grid.sigma));
mod.grid.lat_v = repmat(mod.grid.lat_v,1,1,length(grid.sigma));

%% Create three dimesional structured and fixed z grid
%
disp(' grid stru ...')
x = linspace(min(xlim),max(xlim),floor(size(mod.grid.h,1)/nn)); % out x coordinate
y = linspace(min(ylim),max(ylim),floor(size(mod.grid.h,2)/nn)); % out y coordinate

[xx,yy,zz] = ndgrid(x,y,zf); % 3D Structured grid 
[xw,yw] = ndgrid(x,y); % 2D grid structure for water level

% get bathymetry of the x,y reular grid
 xin = mod.grid.lon(:,:,1);
 yin = mod.grid.lat(:,:,1);
 zlast_ind = zeros(length(x),length(y));
Fbathy = scatteredInterpolant(xin(:),yin(:),mod.grid.h(:)); % Negeative to turn to depth
bathy = Fbathy(xw,yw);
for ii = 1:size(bathy,1)
    for jj = 1:size(bathy,2)
        [~,ind] = min(abs(zf-bathy(ii,jj)));
        zlast_ind(ii,jj) = ind;
    end
end
%%

for time_i  = 1 :length(times)
    resfil = [resdir strrep(fname, 'XXXX',datestr(times(time_i),'yyyymmdd'))];
    disp(resfil);
   timet = ncread(resfil,'ocean_time')./(24*3600) +  datenum(2000,1,1);
 for i = 1:length(var2extract)
     tmp = ncread(resfil, var2extract{i});
     if strcmp(var2extract{i},'zeta')
         mod.(var2extract{i}) = tmp(min(row.rho):max(row.rho),min(col.rho):max(col.rho),:);
     elseif ismember(var2extract{i},{'salt','temp'})
         mod.(var2extract{i}) = tmp(min(row.rho):max(row.rho),min(col.rho):max(col.rho),:,:);
     else
         mod.(var2extract{i}) = tmp(min(row.(var2extract{i})):max(row.(var2extract{i})),min(col.(var2extract{i})):max(col.(var2extract{i})),:,:);
     end
 end
H = zeros(length(x),length(y),length(timet));
salt = zeros(length(x),length(y),length(zf),length(timet));
temp = zeros(length(x),length(y),length(zf),length(timet));
u = zeros(length(x),length(y),length(zf),length(timet));
v = zeros(length(x),length(y),length(zf),length(timet));

for subt_i = 1:length(timet)
    zt  = repmat(zeros(size(mod.grid.h)),1,1,length(grid.s_rho));
    tmz = mod.zeta(:,:,subt_i); % Extract water leve at given time
    tmzz = tmz  + mod.grid.h; % add bathymetry in m 
    
    for lev_i = 1:length(grid.s_rho) 
        zt(:,:,lev_i) = tmz + (tmzz)*grid.s_rho(lev_i);
    end
    zin = -1*zt;
    zin_u = -1*zt(1:size(mod.grid.lon_u,1),1:size(mod.grid.lon_u,2),:);  % Negeative to turn to depth
    zin_v = -1*zt(1:size(mod.grid.lon_v,1),1:size(mod.grid.lon_v,2),:);  % Negeative to turn to depth
    % Interpolate Salt
    saltin = mod.salt(:,:,:,subt_i);   
    ind = find(~isnan(saltin(:)));
    Fsalt = scatteredInterpolant(mod.grid.lon(ind),mod.grid.lat(ind),zin(ind),saltin(ind)); % Negeative to turn to depth
    Fsalt.ExtrapolationMethod = 'none';
    salt(:,:,:,subt_i) = Fsalt(xx,yy,zz);

        % Interpolate Temperature
    tempin = mod.temp(:,:,:,subt_i);   
    ind = find(~isnan(tempin(:))); % Negeative to turn to depth
    Ftemp = scatteredInterpolant(mod.grid.lon(ind),mod.grid.lat(ind),zin(ind),tempin(ind)); % Negeative to turn to depth
    Ftemp.ExtrapolationMethod = 'none';
    temp(:,:,:,subt_i) = Ftemp(xx,yy,zz);

     % Interpolate velocities
    uin = mod.u(:,:,:,subt_i);   
    ind = find(~isnan(uin(:)));
    Fu = scatteredInterpolant(mod.grid.lon_u(ind),mod.grid.lat_u(ind),zin_u(ind),uin(ind)); % Negeative to turn to depth
    Fu.ExtrapolationMethod = 'none';
    u(:,:,:,subt_i) = Fu(xx,yy,zz);

    vin = mod.v(:,:,:,subt_i);   
    ind = find(~isnan(vin(:)));
    Fv = scatteredInterpolant(mod.grid.lon_v(ind),mod.grid.lat_v(ind),zin_v(ind),vin(ind)); % Negeative to turn to depth
    Fv.ExtrapolationMethod = 'none';
    v(:,:,:,subt_i) = Fv(xx,yy,zz);

  
    ind = find(~isnan(tmz(:)));
    xin = mod.grid.lon(:,:,1);
    yin = mod.grid.lat(:,:,1);
    FH = scatteredInterpolant(xin(ind),yin(ind),tmz(ind)); % Negeative to turn to depth
    FH.ExtrapolationMethod = 'none';
    H(:,:,subt_i) = FH(xw,yw);

      
end
 %% Pad down horizontally turning interpolated value deeper than actual bathy to nan (avoiding artifact of exptrapolation)
for ii = 1:size(xw,1)
    for jj = 1:size(xw,2)
        salt(ii,jj,zlast_ind(ii,jj):end,:) = nan;
        u(ii,jj,zlast_ind(ii,jj):end,:) = nan;
        v(ii,jj,zlast_ind(ii,jj):end,:) = nan;
        temp(ii,jj,zlast_ind(ii,jj):end,:) = nan;

    end
end
%% Write data into strcuture
    S.ssh=H;
    S.u=u;                                  
    S.v=v;
    S.temperature=temp;
    S.salinity=salt;  
    S.z = zf';
    S.x = x';
    S.y = y';
    S.t = timet + (timezone/24); % Add timezone correction
    filename = [inpat 'ROMS_' datestr(times(time_i),'yyyymmdd') '.mat'];
    save(filename,'S','-mat');
    disp(['saved for timestep ' datestr(times(time_i),'yyyy-mm-dd') ])
end
toc
%% Combine into netCDF file
disp('Interpolation and conversion to gridded format completed, all matfile saved')

disp('Combining matfiles into a single .nc file')
% tstart  = datenum(2013,01,01); % starting time of download
b_combine_ROMS

