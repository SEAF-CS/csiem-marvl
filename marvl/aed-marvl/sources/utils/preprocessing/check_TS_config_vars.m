
% checking the time series plot configuration file

if exist('add_vdata','var') == 0
    add_vdata = 0;
end

if exist('isHTML','var') == 0
    isHTML = 1;
end
if ~exist('htmloutput','var')
    htmloutput = outputdirectory;
end

if ~exist('add_error','var')
    add_error = 0;
end

if ~exist('add_human','var')
    add_human = 0;
end

if ~exist('fieldrange_min','var')
    fieldrange_min = 200;
end

if exist('validation_minmax','var') == 0
    validation_minmax = 0;
end

if exist('isRange','var') == 0
    isRange = 1;
end
if exist('Range_ALL','var') == 0
    Range_ALL = 0;
end
if exist('isRange_Bottom','var') == 0
    isRange_Bottom = 0;
end
if ~exist('custom_datestamp','var')
    custom_datestamp = 0;
end
if ~exist('add_triangle','var')
    add_triangle = 0;
end
if ~exist('add_coorong','var')
    add_coorong = 0;
end

if ~exist('start_plot_ID','var')
    start_plot_ID = 1;
end

if ~exist('end_plot_ID','var')
    end_plot_ID = length(varname);
end

if ~exist('validation_raw','var')
    validation_raw = 0;
    
end

if validation_raw
    validation_minmax = 0;
end

if ~exist('alph','var')
    alph = 0.5;
end

if ~isfield(def,'visible')
    def.visible = 'on';
end

%if ~exist('fielddata_matfile','var')
%    fielddata_matfile = ['matfiles/',fielddata,'.mat'];
%end

if ~exist('surface_offset','var')
    surface_offset = 0;
end

isConv = 0;

if ~exist('plotmodel','var')
    plotmodel = 1;
end
if plotmodel
    allvars = tfv_infonetcdf(ncfile(1).name);
end

if ~exist('sites','var')
    sites = [1:1:1:length(shp)];
end
disp('SHP sites:')
disp(sites)

if ~exist('isFieldRange','var')
    isFieldRange = 0;
end

max_depth = 5000;
if ~exist('depth_range','var')
    depth_range = [0.5 max_depth];
end

if exist('plotsite','var')
    shp_t = shp;
    clear shp;
    inc = 1;
    disp('Removing plotting sites');
    for bhb = 1:length(shp_t)
        
        if ismember(shp_t(bhb).Plot_Order,plotsite)
            
            shp(inc) = shp_t(bhb);
            inc = inc + 1;
        end
    end
end

if ~plotmodel || plotvalidation
    add_error = 0;
end