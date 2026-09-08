 clear; close all;
 run('W:\csiem\csiem-marvl-dev\config\MARVL_WQ.m');
master=MARVLs.master;
config=MARVLs.timeseries;
style='matlab';
% load in and check configurations
config=check_TS_configs(config);

% load in model geometry (layers, depth etc)
if config.plotmodel==1
    [t_data, d_data]=pre_load_model_GEOs_ROMS(master.ncfile);
end

shp = shaperead(config.polygon_file);
for kk = 1:length(shp)
    shp(kk).Name = regexprep(shp(kk).Name,'-','_');
    shp(kk).Name = regexprep(shp(kk).Name,'\.','');
end

% check and define sites for plotting
%[shp, sites]=refine_SHP(shp, config);

if config.plotAllsites == 0
    sites=config.plotsite;
else
    sites=1:length(shp);
end
fdata = struct;
isvalidation=master.add_fielddata;

if isvalidation
   % field = load(master.fielddata_matfile);
   % fdata = field.(master.fielddata); clear field;
    fdata = marvl_load_fielddata(master);
end

%%
loadname='WQ_DIAG_PHY_TCHLA';
sites=1:length(shp);

site=6;

if isvalidation
    sitenames = fieldnames(fdata);

    sss=[];
    inc=1;
    for i = 1:length(sitenames)
       % vars = fieldnames(fdata.(sitenames{i}));
       if isfield(fdata.(sitenames{i}),loadname)
           Vertical_Ref=fdata.(sitenames{i}).(loadname).Deployment;
           X = fdata.(sitenames{i}).(loadname).X;
           Y = fdata.(sitenames{i}).(loadname).Y;
                 
           if strcmpi(Vertical_Ref,'Integrated') 
               if config.includeINT
                 inpol = inpolygon(X,Y,shp(site).X,shp(site).Y);
                 if inpol
                     sss(inc)=i;
                     inc=inc+1;
                 end
               end
           else
               inpol = inpolygon(X,Y,shp(site).X,shp(site).Y);
                 if inpol
                     disp(i);disp(inc)
                     sss(inc)=i;
                     inc=inc+1;
                 end

           end
       end
    end
end