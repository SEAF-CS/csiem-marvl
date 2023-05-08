%% CS_SCERM_bc_conv
%
% Script to convert from SCERM to Cockburn Sound BGC model for river
% boundary conditions
% Written for A11348 Cockburn Sound BGC Model
%
% Uses:
%       
%     
% Created by:  <Kabir.Suara@bmtglobal.com>
% Created on: 18 October 2022
%
% Based on: Original
%
% Modified
%   1) 
%

%% Clean up
clear
close all
%clear path

%% Set path to functions
addpath(genpath('..\..\..\3Functions\'));

% -- INPUT

%pat = '../'; % FVMODEL Output directory
%% USER Input to be edit

starttime = '15/03/2013 00:00:00'; % Start time
endtime = '01/04/2014 00:00:00'; % End time 
outdir = '..\..\..\..\2Modelling\2TUFLOWFV\bc_dbase\swan_river\';
outf='XXXX_Tide_YYYY.nc';
fil = '..\..\..\..\..\1Data\1Rcvd\from_UWA\SCERM\SCERM44_2013_2014_ALL.nc'; % TUFLOW FV model to extract from
ref_time = datetime('2001-01-01'); % Input model refernce time
time_unit = 'hours'; % Input model output units
zlevels = [0 1 2 3 5 7 10 15 20 25 30 35 40 45 50 60 75 100];

fil_title = 'Curtain Data, XXXX';

geopat= '..\..\..\..\..\1Data\1Rcvd\from_UWA\SCERM\' ;
geofil='SCERM44_2013_2014_geo.nc';
%% USER Input not necessary to be edited except if the nodestrings of change
bnds.NAR = [115.847942512466 -31.9624502539208
        115.848006290813 -31.962573229394
        115.848035280972 -31.9626765286642
        115.84806427113 -31.9627650708033
        115.848070069161 -31.9628929648535
        115.848058473098 -31.9631536714043
        115.848058473098 -31.9632717269573
        115.84806427113 -31.9633848633866
        115.848052675066 -31.9635570272507
        115.848058473098 -31.9638915161208
        115.848081665224 -31.964358814708
        115.848070069161 -31.9645162200124];

bnds.CAN = [ 115.851688040888 -32.0104621062478
        115.851989538532 -32.0104326075517
        115.852360612555 -32.0104227746509
        115.852847647211 -32.0103834430371
        115.853178135013 -32.0103588607699
        115.853398460214 -32.0103244455848
        115.853543411004 -32.0101572859303
        115.853734746048 -32.0098573810802
        115.853897090933 -32.0096263061821
        115.854111618103 -32.0093509821388
        115.854233376766 -32.0091838207089
        115.854430509841 -32.0089330779926
        115.854465298031 -32.008790498495
        115.854523278347 -32.0086184194957
        115.854592854726 -32.0085102553879];

%% Extraction operation
ab = fields(bnds);

for bd_i  = 1:length(ab)
    bdname = ab{bd_i};

    [Lon,Lat]  = ll2utm(bnds.(bdname)(:,1),bnds.(bdname)(:,2));
%     Lon = bnds.(bdname)(:,1); % Add the longitudes of the nodestrings here
%     Lat = bnds.(bdname)(:,2); % Add the alttitudes of the nodestrign here
%     
    outfil = [outdir strrep(outf,'XXXX',bdname)];
    pline= {[Lon Lat]};

% ------------------------------


% -- SETUP files
resfil=[fil];
Geofil= [geopat geofil];
[ids,coords] = fv_get_curtain_ids(pline{1},Geofil);
chainage=get_chain(coords(:,1),coords(:,2));
nids = length(ids);
chainage=chainage(1:nids);

if isunix
    resfil = convert_windows_dir_to_unix(resfil);
end 


% -- Get IDS
nci = netcdf.open(resfil);
hid = netcdf.inqVarID(nci, 'H');
vxid= netcdf.inqVarID(nci, 'V_x');
vyid= netcdf.inqVarID(nci, 'V_y');
sid = netcdf.inqVarID(nci, 'SAL');
tid = netcdf.inqVarID(nci, 'TEMP');
lid = netcdf.inqVarID(nci, 'layerface_Z');

[~,nc2] = netcdf.inqDim(nci, netcdf.inqDimID(nci, 'NumCells2D'));
[~,nc3] = netcdf.inqDim(nci, netcdf.inqDimID(nci, 'NumCells3D'));
[~,nt ] = netcdf.inqDim(nci, netcdf.inqDimID(nci, 'Time'));
[~,nfz] = netcdf.inqDim(nci, netcdf.inqDimID(nci, 'NumLayerFaces3D'));

% -- Get Variables
idx3 = double(netcdf.getVar(nci, netcdf.inqVarID(nci, 'idx3')));
NL_all = double(netcdf.getVar(nci, netcdf.inqVarID(nci, 'NL')));
if strcmp(time_unit,'hours')
    time = datenum(ref_time + hours(netcdf.getVar(nci, netcdf.inqVarID(nci, 'ResTime'))));
elseif strcmp(time_unit,'days')
    time = datenum(ref_time + days(netcdf.getVar(nci, netcdf.inqVarID(nci, 'ResTime'))));
else
    time = convtime(netcdf.getVar(nci, netcdf.inqVarID(nci, 'ResTime')));
end


is = find(time>datenum(starttime,'dd/mm/yyyy HH:MM:SS'),1,'first');
ie = find(time<datenum(endtime,'dd/mm/yyyy HH:MM:SS'),1,'last');
nz = length(zlevels);

outfil = strrep(outfil,'YYYY',[datestr(time(is),'yyyymmdd') '_' datestr(time(ie),'yyyymmdd')]);
% -- Get indices

top = idx3(ids);
nl = NL_all(ids);
bot = top+nl-1;
nlmax = max(nl);

fxtop = top   + ids-1;
fxbot = fxtop + nl;

cellarray = zeros(nlmax, nids);
tmpindex = zeros(nz, nids);
facearray = zeros(nlmax+1, nids);

for aa = 1 : nids
    cellarray(1:nl(aa),aa) = top(aa):bot(aa);
    cellarray(nl(aa):end,aa) = bot(aa);
    
    facearray(1:nl(aa)+1,aa) = fxtop(aa):fxbot(aa);
    facearray((nl(aa)+1):end,aa) = fxbot(aa);
end
% ------------------------------------------------------------






% -- SETUP OUPUT NETCDF
dims.time = [];
dims.x = nids;
dims.depth = nz;

vars.time.nctype = 'NC_DOUBLE';
vars.time.dimensions = 'time';
vars.time.units = 'hours since 1990-01-01 00:00:00';
vars.time.longname = 'Time';
vars.time.axis = 'T';
vars.time.calendar = 'gregorian';

vars.chainage.nctype = 'NC_DOUBLE';
vars.chainage.dimensions = 'x';
vars.chainage.units = 'm';
vars.chainage.longname = 'chainage around nodestring';

vars.depth.nctype = 'NC_DOUBLE';
vars.depth.dimensions = 'depth';
vars.depth.units = 'meters';
vars.depth.positive = 'down';
vars.depth.axis = 'Z';
vars.depth.longname = 'Depth';

variables = {'H','V_x','V_y','SAL','TEMP'};
dimensions = {{'x','time'};{'x','depth','time'};{'x','depth','time'};{'x','depth','time'};{'x','depth','time'}};
units = {'m','m/s','m/s','PSU','degrees celcius'};
longname = {'Sea Surface Height';'X-component of Current Velocity';
    'Y-component of Current Velocity';'Salinity';'Temperature'};


for i = 1 : length(variables)
    name = variables{i};
    vars.(name).nctype = 'NC_FLOAT';
    vars.(name).dimensions = dimensions{i};
    vars.(name).units = units{i};
    vars.(name).longname = longname{i};
    vars.(name).add_offset = 0;
end

atts.title = strrep(fil_title,'XXXX',bdname);
atts.origin = 'BMT';
atts.history = ['compiled ' datestr(now,'dd-mmm-yyyy')];

netcdf_define(outfil,dims,vars,atts);
% -----------------------------------------------------------------------



% -- Open output and get IDS
nci_out = netcdf.open(outfil,'WRITE');

tmout = netcdf.inqVarID(nci_out, 'time');
chout = netcdf.inqVarID(nci_out, 'chainage');
dpout = netcdf.inqVarID(nci_out, 'depth');
hout = netcdf.inqVarID(nci_out, 'H');
vxout= netcdf.inqVarID(nci_out, 'V_x');
vyout= netcdf.inqVarID(nci_out, 'V_y');
sout = netcdf.inqVarID(nci_out, 'SAL');
tout = netcdf.inqVarID(nci_out, 'TEMP');



% Write initial variables
netcdf.putVar(nci_out, chout, chainage);
netcdf.putVar(nci_out, dpout, zlevels);


% Do Time loop for reading then writing
inc = [];
tic
for tt = is : ie
    
    % -- Read In
    H    = netcdf.getVar(nci, hid, [0 tt-1], [nc2,1]);
    Vx   = netcdf.getVar(nci, vxid,[0 tt-1], [nc3,1]);
    Vy   = netcdf.getVar(nci, vyid,[0 tt-1], [nc3,1]);
    SAL  = netcdf.getVar(nci, sid, [0 tt-1], [nc3,1]);
    TEMP = netcdf.getVar(nci, tid, [0 tt-1], [nc3,1]);
    
    zf = double(netcdf.getVar(nci, lid, [0 tt-1], [nfz,1]));
    depths = cumsum([zeros(1,nids);-diff(zf(facearray))]);
    D = zf(fxtop) - zf(fxbot);
    
    % Get Index
    for aa = 1 : nz
        [~,ii] = min(abs(depths-zlevels(aa)));
        tmpindex(aa,:) = cellarray(ii+[0:(nids-1)].*nlmax);
    end
    ilog = bsxfun(@gt, zlevels, D);
    
    % -- Write Out
    netcdf.putVar(nci_out, tmout, [tt-is], [1], convtime(time(tt)));
    netcdf.putVar(nci_out, hout, [0,tt-is], [nids,1], H(ids));
    
    dat = Vx(tmpindex)';
    dat(ilog) = NaN;
    netcdf.putVar(nci_out, vxout, [0,0,tt-is], [nids,nz,1], dat);
    
    dat = Vy(tmpindex)';
    dat(ilog) = NaN;
    netcdf.putVar(nci_out, vyout, [0,0,tt-is], [nids,nz,1], dat);
    
    dat = SAL(tmpindex)';
    dat(ilog) = NaN;
    netcdf.putVar(nci_out, sout, [0,0,tt-is], [nids,nz,1], dat);
    
    dat = TEMP(tmpindex)';
    dat(ilog) = NaN;
    netcdf.putVar(nci_out, tout, [0,0,tt-is], [nids,nz,1], dat);
    
    
    inc = mytimer(tt,[is,ie], inc);
end

% Tidy Up
netcdf.close(nci_out);
netcdf.close(nci);

disp('Done :)')
end
