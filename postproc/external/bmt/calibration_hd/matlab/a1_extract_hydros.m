%% extract_prof_CS_calibration_Hydrodynamic
%
% Script to extract profile data from Cockburn Sound Hydro calibration
% Written for A11348 Cockburn Sound BGC Model
%
% Uses: fv_get_ids
%       fv_create_profiles
% Copyright (C) BMT 2023    

%% Clean up
clear;
close all;

%% USER ENTRY
% User to enter details (file dir, file loc) of model results  
ncfnames = {'CSound_HD_2013.nc'}; %.
locs_fname = '..\data\Cockburn_Extraction_XYZ_Scal-Vel_Validation_Coordinates.csv'; %Location of extraction points

%% Set run info
run=struct();
dirDatetime=char(datetime('now','Format','yyyyMdd.HHmmss'));
resdir = '..\..\..\..\2TUFLOWFV\results\hd_calib\';
outdir = resdir;

%% Get site location data
HD_locs = readtable(locs_fname);
sites = cell(height(HD_locs),1);

% Site names
for ii = 1:length(HD_locs.sites)
    sites{ii} = HD_locs.sites{ii};
end


%% Extract model output 
for ncfName_i = 1:length(ncfnames)
    %% Run through and extract data
    
    resfil = ncfnames{ncfName_i};

    cell_ids=fv_get_ids([HD_locs.Lon_DDD,HD_locs.Lat_DDD],[resdir resfil],'cell',true); % get cell IDs
    [~,ic,~] = unique(cell_ids);    
    T=table(sites,cell_ids);
    sites = sites(ic);
    writetable(T,'cellID')
    
    range_val.surf = [0.66 1];
    range_val.surf_ref='sigma';

    range_val.mid = [0.33 0.66];
    range_val.mid_ref='sigma';

    range_val.bot = [0 0.33];
    range_val.bot_ref='sigma';

    range_val.sig = [0 1];
    

        
    % Physical
    outfil = strcat(outdir,dirDatetime,'_',strrep(resfil,'.nc','_profiles.nc')); % save on network, not blaydos
    
    if ~exist(outdir)
        mkdir(outdir);
    end 
    
    disp(['Extracting the file: ' resdir resfil])
    disp(['Saving as: ' outfil])
    vars={'H';'V_x';'V_y';'TEMP';'SAL'};
    % ================================================================================================
    % Save Results
    if ~exist(outfil)
        fv_create_profiles_vars([resdir resfil],outfil,[HD_locs.Lon_DDD(ic),HD_locs.Lat_DDD(ic)],sites,vars); % Other variables to be added on later on
    else
        disp('Profile .nc file already exist. Please move .nc profile if you wish to create again.')
    end
    
    a2_save_ts_scenario_validation 

end




