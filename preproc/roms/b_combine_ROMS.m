%clear;close all;fclose all;




% -- .nc processing. Use if prior script was get_HYCOM.m
% ext_in = '.nc';
% fils = dir([inpat tag '_*_*' ext_in]);

% -- .mat processing. Use if prior script was download_HYCOM_GLBy.m
ext_in = '.mat';
fils = dir([inpat tag '_*' ext_in]);

if strcmp(ext_in, '.nc')
for aa = 1 : length(fils)
    fil = [inpat fils(aa).name];
    
    nci = netcdf.open(fil,'NOWRITE');
    tmptime = netcdf.getVar(nci, netcdf.inqVarID(nci,'time'),'double')./24 + datenum(2000,1,1);
    netcdf.close(nci);
    
    if aa>1
        keep = [keep; tmptime(:)>time(end)];
        time = [time;tmptime(:)];
        mod = [mod;repmat(aa,length(tmptime),1)];
        index = [index;(1:length(tmptime))'-1];
    else
        keep = true(length(tmptime),1);
        time = tmptime(:);
        mod = repmat(aa,length(tmptime),1);
        index = (1:length(tmptime))'-1;
    end
end
    


% Create new file here:
schem = ncinfo([inpat fils(1).name]); % Get Basic Schema from First File

% Make Time unlimited Dimension
timdim = find(strcmpi({schem.Dimensions(:).Name},'time'));
schem.Dimensions(timdim).Length = inf;
schem.Dimensions(timdim).Unlimited = true;
if timezone>0
    tz_str = sprintf('UTC+%2.1f',timezone);
elseif timezone<0
    tz_str = sprintf('UTC+%2.1f',timezone);
elseif timezone==0
    tz_str = sprintf('UTC');
else
    error('Bonkers')
end
schem.Attributes = struct('Name',{'Source','CreationDate','Creator','JobNo.','Timezone'},'Value',{'Hycom GOFS 3.1 Archive Data on GLBv0.08 grid',datestr(now,'yyyymmdd.HHMMSS'),creator,jobno,tz_str});

nvars = length(schem.Variables);
for aa = 1 : nvars
    
    sz = schem.Variables(aa).Size;
    if length(sz)>1
        schem.Variables(aa).ChunkSize = [sz(1:end-1),1];
        schem.Variables(aa).DeflateLevel = 9;
    end
    if strcmpi(schem.Variables(aa).Name,'time')
        schem.Variables(aa).Attributes = struct('Name',{'long_name','units','time_origin','calendar','axis','_CoordinateAxisType'},'Value',{'Valid Time','hours since 1990-01-01 00:00:00','1990-01-01 00:00:00','gregorian','T','Time'});
    end
end
schem.Variables = rmfield(schem.Variables,'Size');


newfil = [outinpat sprintf('%s_%s_%s_%s.nc',tag,timezone_Name,datestr(time(1)+timezone./24,'yyyymmdd'),datestr(time(end)+timezone./24,'yyyymmdd'))];
if exist(newfil,'file')
    delete(newfil);
end
ncwriteschema(newfil, schem);

% -- 
nci = netcdf.open(newfil,'WRITE');
xid = netcdf.inqVarID(nci, 'lon');
yid = netcdf.inqVarID(nci, 'lat');
zid = netcdf.inqVarID(nci, 'depth');
tid = netcdf.inqVarID(nci, 'time');
wtid = netcdf.inqVarID(nci, 'water_temp');
said = netcdf.inqVarID(nci, 'salinity');
seid = netcdf.inqVarID(nci, 'surf_el');
wuid = netcdf.inqVarID(nci, 'water_u');
wvid = netcdf.inqVarID(nci, 'water_v');

% -- Initial Data
ncitmp = netcdf.open([inpat fils(1).name],'NOWRITE');
lon = netcdf.getVar(ncitmp,netcdf.inqVarID(ncitmp,'lon'));
nx = length(lon);
netcdf.putVar(nci,xid,lon);

lat = netcdf.getVar(ncitmp,netcdf.inqVarID(ncitmp,'lat'));
ny = length(lat);
netcdf.putVar(nci,yid,lat);

depth = netcdf.getVar(ncitmp,netcdf.inqVarID(ncitmp,'depth'));
nz = length(depth);
netcdf.putVar(nci,zid,depth);

curid = 1;

tic;
inc = [];
k=-1;
% Loop through
for aa = 1 : length(time)
    if mod(aa)~=curid
        netcdf.close(ncitmp);
        
        curid = mod(aa);
        fil = [inpat fils(curid).name];
        ncitmp = netcdf.open(fil,'NOWRITE');
    end
    
    if keep(aa)
        k=k+1;
        % Keep track of time
        inc = mytimer(aa,[1 length(time)],inc);
        
        % Write Time
        netcdf.putVar(nci,tid,k,1,convtime(time(aa)));
        
        % Get and write surf_el
        tmp2 = netcdf.getVar(ncitmp, netcdf.inqVarID(ncitmp, 'surf_el'), [0,0,index(aa)], [nx,ny,1]);
        netcdf.putVar(nci,seid,[0,0,k], [nx,ny,1], tmp2);
        
        % Get and write water_temp
        tmp3 = netcdf.getVar(ncitmp, netcdf.inqVarID(ncitmp, 'water_temp'), [0,0,0,index(aa)], [nx,ny,nz,1]);
        netcdf.putVar(nci,wtid,[0,0,0,k], [nx,ny,nz,1], tmp3);
        
        % Get and write salinity
        tmp3 = netcdf.getVar(ncitmp, netcdf.inqVarID(ncitmp, 'salinity'), [0,0,0,index(aa)], [nx,ny,nz,1]);
        netcdf.putVar(nci,said,[0,0,0,k], [nx,ny,nz,1], tmp3);
        
        % Get and write water_u
        tmp3 = netcdf.getVar(ncitmp, netcdf.inqVarID(ncitmp, 'water_u'), [0,0,0,index(aa)], [nx,ny,nz,1]);
        netcdf.putVar(nci,wuid,[0,0,0,k], [nx,ny,nz,1], tmp3);
        
        % Get and write water_v
        tmp3 = netcdf.getVar(ncitmp, netcdf.inqVarID(ncitmp, 'water_v'), [0,0,0,index(aa)], [nx,ny,nz,1]);
        netcdf.putVar(nci,wvid,[0,0,0,k], [nx,ny,nz,1], tmp3);
        
    end
end
netcdf.close(ncitmp);
netcdf.close(nci);






%% .mat HYCOM processing
elseif strcmp(ext_in, '.mat')

% Set params    
hnams = sprintf('%s_%s_%s_%s',tag,timezone_Name,datestr(tstart,'yyyymmdd'),datestr(tfinish,'yyyymmdd'));
newfil = [outinpat hnams '.nc'];
if exist(newfil,'file')
    delete(newfil);
end

% Retrieve relevant files
for ii = 1:length(fils)
    fname = fils(ii).name;
    date_str = strsplit(fname,'_');
    dats(ii,1) = datenum(date_str{end}(1:end-4),'yyyymmdd');
end

XX = find(dats >= tstart & dats <= tfinish);

% - Create netCDF4 Output File
varnames={'u'; 'v'};
    
load([inpat fils(XX(1,1)).name]);
%S = D;
dims.lon = length(S.x); % 1st dimension
dims.lat = length(S.y); % 2nd dimension
dims.depth = length(S.z); % 3rd dimension
dims.time = 'UNLIMITED'; % 4th dimension

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
vars.lon.dimensions    = 'lon';
vars.lon.long_name     = 'Longitude';
vars.lon.standard_name = 'longitude';
vars.lon.units         = 'degrees_east';
vars.lon.modulo        = '360 degrees';
vars.lon.axis          = 'X';
vars.lon.NAVO_code     = 2;
vars.lon.projection    = 'LL_WGS84';
vars.lon.CoordinateAxisType = 'Lon';

vars.lat.nctype        = 'NC_FLOAT';
vars.lat.dimensions    = 'lat';
vars.lat.long_name     = 'Latitude';
vars.lat.standard_name = 'latitude';
vars.lat.units         = 'degrees_north';
vars.lat.axis          = 'Y';
vars.lat.NAVO_code     = 1;
vars.lat.projection    = 'LL_WGS84';
vars.lat.CoordinateAxisType = 'Lat';

vars.depth.nctype        ='NC_FLOAT';
vars.depth.dimensions    ='depth';
vars.depth.long_name     ='Depth';
vars.depth.standard_name ='depth';
vars.depth.units         ='m';
vars.depth.positive      ='down';
vars.depth.axis          ='Z';
vars.depth.NAVO_code     = 5;
vars.depth.CoordinateAxisType    = 'Height';
vars.depth.CoordinateZisPositive = 'down';

vars.water_u.nctype         = 'NC_FLOAT';
vars.water_u.dimensions     = {'lon','lat','depth','time'};
vars.water_u.FillValue      = -30000;
vars.water_u.CoordinateAxes = 'time depth lat lon ';
vars.water_u.long_name      = 'Eastward Water Velocity';
vars.water_u.standard_name  = 'eastward_sea_water_velocity';
vars.water_u.units          = 'm/s';
vars.water_u.missing_value  = -30000;
vars.water_u.scale_factor   = 0.001;
vars.water_u.add_offset     = 0;
vars.water_u.NAVO_code      = 17;
vars.water_u.coordinates    = 'time depth lat lon ';

vars.water_v.nctype         = 'NC_FLOAT';
vars.water_v.dimensions     = {'lon','lat','depth','time'};
vars.water_v.FillValue      = -30000;
vars.water_v.CoordinateAxes = 'time depth lat lon ';
vars.water_v.long_name      = 'Northward Water Velocity';
vars.water_v.standard_name  = 'northward_sea_water_velocity';
vars.water_v.units          = 'm/s';
vars.water_v.missing_value  = -30000;
vars.water_v.scale_factor   = 0.001;
vars.water_v.add_offset     = 0;
vars.water_v.NAVO_code      = 18;
vars.water_v.coordinates    = 'time depth lat lon ';

vars.surf_el.nctype = 'NC_FLOAT';
vars.surf_el.dimensions = {'lon','lat','time'};
vars.surf_el.FillValue = -30000;
vars.surf_el.CoordinateAxes = 'time lat lon ';
vars.surf_el.long_name = 'Water Surface Elevation';
vars.surf_el.standard_name = 'sea_surface_elevation';
vars.surf_el.units = 'm';
vars.surf_el.missing_value = -30000;
vars.surf_el.scale_factor = 0.001;
vars.surf_el.add_offset = 0;
vars.surf_el.NAVO_code = 32;
vars.surf_el.coordinates = 'time lat lon ';

vars.water_temp.nctype         = 'NC_FLOAT';
vars.water_temp.dimensions     = {'lon','lat','depth','time'};
vars.water_temp.CoordinateAxes = 'time depth lat lon ';
vars.water_temp.long_name      = 'Water Temperature';
vars.water_temp.standard_name  = 'sea_water_temperature';
vars.water_temp.units          = 'degC';
vars.water_temp.missing_value  = -30000;
vars.water_temp.scale_factor   = 0.001;
vars.water_temp.add_offset     = 20;
vars.water_temp.NAVO_code      = 15;
vars.water_temp.comment        = 'in-situ temperature';
vars.water_temp.coordinates    = 'time depth lat lon ';

vars.salinity.nctype         = 'NC_FLOAT';
vars.salinity.dimensions     = {'lon','lat','depth','time'};
vars.salinity.FillValue      = -30000;
vars.salinity.CoordinateAxes = 'time depth lat lon ';
vars.salinity.long_name      = 'Salinity';
vars.salinity.standard_name  = 'sea_water_salinity';
vars.salinity.units          = 'psu';
vars.salinity.missing_value  = -30000;
vars.salinity.scale_factor   = 0.001;
vars.salinity.add_offset     = 20;
vars.salinity.NAVO_code      = 16;
vars.salinity.coordinates    = 'time depth lat lon ';
                   
atts = struct();

netcdf_define(newfil, dims, vars, atts);

netcdf_put_var(newfil, 'lon', S.x);
netcdf_put_var(newfil, 'lat', S.y);
netcdf_put_var(newfil, 'depth', S.z);
    
%% - Put in the Vars
nf = numel(XX);
time = [];
bad_time = [];

ctr1 = 1; ctr2 = 1; tic; inc = [];
for aa = 1:nf
    inc = mytimer(aa, [1, nf], inc);
    load([inpat fils(XX(aa,1)).name]);
    %S = D; % aew quick fix
    %S.t = dats(aa);
    % Index to clean overlap
    if aa == 1
        I = [1:numel(S.t)];
    else
        I = find(S.t > time(end));
    end
         
    time = [time; S.t(I)];
    
    for bb = 1:length(I)
        ii = I(bb);

        try
            dat = squeeze(S.ssh(:, :, ii));
            netcdf_put_var(newfil, 'surf_el', dat, ctr1);

            dat = squeeze(S.temperature(:, :, :, ii));
            netcdf_put_var(newfil, 'water_temp', dat, ctr1);
            
            dat = squeeze(S.salinity(:, :, :, ii));
            netcdf_put_var(newfil, 'salinity', dat, ctr1);
            
            dat = squeeze(S.u(:, :, :, ii));
            netcdf_put_var(newfil, 'water_u', dat, ctr1);
            
            dat = squeeze(S.v(:, :, :, ii));
            netcdf_put_var(newfil, 'water_v', dat, ctr1);
            
            time_stamp = convtime(S.t(ii));
            netcdf_put_var(newfil, 'time', time_stamp, ctr1);            
            
            ctr1 = ctr1 + 1;
        catch
            bad_time(ctr2) = S.t(ii);
            
            ctr2 = ctr2+1;
        end
    end
end

for aa = 1:ctr2-1
    fprintf([datestr(bad_time(aa)) '\n']); 
end


 
    
end

disp('Done :)')

c_ROMS_pad_down



