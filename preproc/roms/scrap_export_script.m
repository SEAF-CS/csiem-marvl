clear all; close all;

addpath(genpath('../../TUFLOWFV/tuflowfv/'));

resdir = 'Y:/WAMSI/Model/ROMS/2013/';
grid_file = 'grid.nc';
gridfil = [resdir grid_file]; 

grid = tfv_readnetcdf(gridfil);
grid.sigma = -1*grid.s_rho;

grid.lat = grid.lat_rho;
grid.lon = grid.lon_rho;

timet = ncread([resdir 'cwa_20130101_03__his.nc'],'ocean_time')./(24*3600) +  datenum(2000,1,1);
data = tfv_readnetcdf([resdir 'cwa_20130101_03__his.nc']);

for subt_i = 1:length(timet)
    
    zt  = repmat(zeros(size(grid.h)),1,1,length(grid.s_rho));
    tmz = data.zeta(:,:,subt_i); % Extract water leve at given time
    tmzz = tmz  + grid.h; % add bathymetry in m 
    
    for lev_i = 1:length(grid.s_rho) 
        zt(:,:,lev_i) = tmz + (tmzz)*grid.s_rho(lev_i);
    end
    
    
    zin = -1*zt;
    
    
end



% 
% grid.s_rho= ncread(gridfil, 's_rho');
% grid.h= ncread(gridfil, 'h');
% grid.sigma = -1*grid.s_rho;
% grid.lat = ncread(gridfil,'lat_rho');
% grid.lon = ncread(gridfil,'lon_rho');
% grid.lat_u = ncread(gridfil,'lat_u');
% grid.lon_u = ncread(gridfil,'lon_u');
% grid.lat_v = ncread(gridfil,'lat_v');
% grid.lon_v = ncread(gridfil,'lon_v');