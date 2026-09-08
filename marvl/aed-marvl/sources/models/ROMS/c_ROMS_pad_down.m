clear all;
close all;
fclose all;

%% - Input
in_path = '/Projects2/WAMSI/Model/ROMS/inputs/nc/';
in_name = 'ROMS_UTC+8_20160101_20160201.nc';

z_max = 3500;

%% - Script
% Get Dimensions
in_file = [in_path in_name];
dims = {'time', 'lon', 'lat', 'depth'};
roms = netcdf_get_var(in_file, 'names', dims);

x = roms.lon;
y = roms.lat;
z = roms.depth;
t = roms.time;

nx = size(x,1);
ny = size(y,1);
nz = size(z,1);
nt = size(t,1);

% Get 2D Index
fprintf('\nGetting 2D Array Mapping\n');

[Y2,X2] = meshgrid(y,x);
roms = netcdf_get_var(in_file, 'names', 'surf_el', 'timestep', 1);

is_nan = isnan(roms.surf_el);
indices_2D = find(is_nan == 1);
nearest_2D = nan(size(indices_2D));

tic; inc = [];
nc = size(indices_2D,1);
for aa = 1:nc
    inc = mytimer(aa, [1, nc], inc);
    
    index = indices_2D(aa);
    xp = X2(index);
    yp = Y2(index);
    dist = ((X2-xp).^2+(Y2-yp).^2).^0.5; 

    dist(is_nan) = inf;
    [~, nearest_2D(aa)] = min(dist(:));      
end

% Get 3D Index
fprintf('\nGetting 3D Array Mapping\n');

[Y3, X3, Z3] = meshgrid(y, x, z);
roms = netcdf_get_var(in_file, 'names', 'water_u', 'timestep', 1);

is_nan = isnan(roms.water_u);
is_nan(Z3>z_max) = false;

indices_3D = find(is_nan == 1);
nearest_3D = nan(size(indices_3D));

tic; inc = [];
nc = size(indices_3D,1);
for aa = 1:nc
    inc = mytimer(aa, [1, nc], inc);
    
    index = indices_3D(aa);
    xp = X3(index);
    yp = Y3(index);
    zp = Z3(index);
    dist = ((X3-xp).^2+(Y3-yp).^2+(Z3-zp).^2).^0.5;
    
    zl = find(z == zp);
    look_up = sum(sum(is_nan(:,:,zl))) == nx*ny;
    
    if ~look_up
        dist(Z3~=zp) = inf;
    end
    
    dist(is_nan) = inf;
    [~, nearest_3D(aa)] = min(dist(:));      
end

% Pad Out roms Dataset
fprintf('\nWriting Filled roms Dataset\n');

vars = {'surf_el', 'water_u', 'water_v', 'salinity', 'water_temp'};
out_file = strrep(in_file, '.nc', '_FILLED.nc')
copyfile(in_file, out_file);

tic; inc = [];
for kk = 1:nt
    inc = mytimer(kk, [1, nt], inc);
    
    roms = netcdf_get_var(in_file, 'names', vars, 'timestep', kk);
    
    for aa = 1:length(vars)
        var = vars{aa};
        if strcmp(var,'surf_el')
            the_nans = indices_2D;
            the_next = nearest_2D;
        else
            the_nans = indices_3D;
            the_next = nearest_3D;
        end   
        
        data = roms.(var);
        data(the_nans) = data(the_next);
        netcdf_put_var(out_file, var, data, kk);
    end
end

