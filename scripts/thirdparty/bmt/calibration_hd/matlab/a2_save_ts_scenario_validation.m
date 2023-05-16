%% extract_prof_CS_calibration_Hydrodynamic
% Save as time series mat file
% Script to extract time series data from Cockburn Sound Hydro calibration
% Written for A11348 Cockburn Sound BGC Model
%
% Uses: fv_get_ids
%       fv_create_profiles
%
% Copyright (C) BMT 2023

all_vars = vars;
CHLconv = 12/50; %this is standard change if required
                      
%% Run through and extract data

%Preallocate structure array
CockburnSound = struct();

for var_i =1:length(all_vars) %loop through variables
    vname = all_vars{var_i};
    disp(['Extracting variable: ' vname])

    %TUFLOW FV and AED2 variable names and conversions
    pvar = a3_plotvars_conv(vname,CHLconv);
    fvnam = pvar.fvnam;
    uconv = pvar.uconv;
        
    %% Extract depth averaged model output at CS sites
   
     for site_i = 1:length(sites)
        sname = sites{site_i};
        
        % Take depth average of surface layer
        if isfield(range_val,'surf')
            ref=range_val.surf_ref; 
                range= range_val.surf;
                    depth_ave_surf=fv_dave_profile(outfil,'variable',fvnam,'ref',{ref},'range',{range},'locations',sites);
                        dpthstr_surf = fields(depth_ave_surf.(sites{1}).(fvnam{1}));
        end
        
            if isfield(range_val,'mid')
                %Take depth average of middle layer
                ref=range_val.mid_ref; 
                    range= range_val.mid;
                        depth_ave_mid=fv_dave_profile(outfil,'variable',fvnam,'ref',{ref},'range',{range},'locations',sites);
                            dpthstr_mid = fields(depth_ave_mid.(sites{1}).(fvnam{1}));
            end        

        if isfield(range_val,'bot')
            %Take depth average of bottom layer
            ref=range_val.bot_ref;
                range= range_val.bot;
                    depth_ave_bot=fv_dave_profile(outfil,'variable',fvnam,'ref',{ref},'range',{range},'locations',sites);
                        dpthstr_bot = fields(depth_ave_bot.(sites{1}).(fvnam{1}));
        end



            if isfield(range_val,'sig')
                %Take depth average of water column
                ref='sigma'; 
                    range= range_val.sig;
                        depth_ave_sig=fv_dave_profile(outfil,'variable',fvnam,'ref',{ref},'range',{range},'locations',sites);
                            dpthstr_sig = fields(depth_ave_sig.(sites{1}).(fvnam{1}));
            end


        %Time
        CockburnSound.(sname).(vname).surface.date =  datenum(1990,1,1)+depth_ave_surf.time/24.0;
        CockburnSound.(sname).(vname).middle.date =  datenum(1990,1,1)+depth_ave_surf.time/24.0;
        CockburnSound.(sname).(vname).bottom.date =  datenum(1990,1,1)+depth_ave_surf.time/24.0;
        CockburnSound.(sname).(vname).sigma.date = datenum(1990,1,1)+depth_ave_surf.time/24.0;
            modres_surf = zeros(size(depth_ave_surf.time));
            modres_mid = zeros(size(depth_ave_surf.time));
            modres_bot = zeros(size(depth_ave_surf.time));
            modres_sig = zeros(size(depth_ave_surf.time));

        for vr=1:length(fvnam)
            if strcmp(vname,'DILN')
                modres_surf = modres_surf + (1./(uconv(vr)*depth_ave_surf.(sname).(fvnam{vr}).(dpthstr_surf{1})'));
                modres_mid = modres_mid + (1./(uconv(vr)*depth_ave_mid.(sname).(fvnam{vr}).(dpthstr_mid{1})'));
                modres_bot = modres_bot + (1./(uconv(vr)*depth_ave_bot.(sname).(fvnam{vr}).(dpthstr_bot{1})'));
                modres_sig = modres_sig + (1./(uconv(vr)*depth_ave_sig.(sname).(fvnam{vr}).(dpthstr_sig{1})'));
            else                
                modres_surf = modres_surf + uconv(vr)*depth_ave_surf.(sname).(fvnam{vr}).(dpthstr_surf{1})';
                modres_mid = modres_mid + uconv(vr)*depth_ave_mid.(sname).(fvnam{vr}).(dpthstr_mid{1})';
                modres_bot = modres_bot + uconv(vr)*depth_ave_bot.(sname).(fvnam{vr}).(dpthstr_bot{1})';
                modres_sig = modres_sig + uconv(vr)*depth_ave_sig.(sname).(fvnam{vr}).(dpthstr_sig{1})';
            end

        end

            CockburnSound.(sites{site_i}).(vname).surface.data = modres_surf;
            CockburnSound.(sites{site_i}).(vname).middle.data = modres_mid;
            CockburnSound.(sites{site_i}).(vname).bottom.data =  modres_bot;
            CockburnSound.(sites{site_i}).(vname).sigma.data =  modres_sig;

    
     end
end

%% Calculate VMAG from V_x and V_y
for site_i = 1:length(sites)
    if isfield(CockburnSound.(sites{site_i}),'V_x') && isfield(CockburnSound.(sites{site_i}),'V_y')
    CockburnSound.(sites{site_i}).VMAG.surface.date = CockburnSound.(sites{site_i}).V_x.surface.date;
    CockburnSound.(sites{site_i}).VMAG.surface.data = hypot(CockburnSound.(sites{site_i}).V_x.surface.data, ...
                                                      CockburnSound.(sites{site_i}).V_y.surface.data);

    CockburnSound.(sites{site_i}).VMAG.middle.date = CockburnSound.(sites{site_i}).V_x.middle.date;
    CockburnSound.(sites{site_i}).VMAG.middle.data = hypot(CockburnSound.(sites{site_i}).V_x.middle.data, ...
                                                     CockburnSound.(sites{site_i}).V_y.middle.data);

    CockburnSound.(sites{site_i}).VMAG.bottom.date = CockburnSound.(sites{site_i}).V_x.bottom.date;
    CockburnSound.(sites{site_i}).VMAG.bottom.data = hypot(CockburnSound.(sites{site_i}).V_x.bottom.data, ...
                                                      CockburnSound.(sites{site_i}).V_y.bottom.data);
    CockburnSound.(sites{site_i}).VMAG.sigma.date = CockburnSound.(sites{site_i}).V_x.sigma.date;
    CockburnSound.(sites{site_i}).VMAG.sigma.data = hypot(CockburnSound.(sites{site_i}).V_x.sigma.data, ...
                                                          CockburnSound.(sites{site_i}).V_y.sigma.data);
    end
end

%% Save time series data

    saveloc=strcat('..\data\matfiles\',ncfnames{1}(1:end-3));
    mkdir(saveloc)
    save([saveloc filesep ncfnames{1}(1:end-3) '_ts.mat'],'CockburnSound');


