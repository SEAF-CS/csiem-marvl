
function run_AEDmarvl(filePath, style)

arguments
    filePath (1, 1) string
    style {mustBeMember(style, ["matlab", "yaml"])} = "matlab"
end

global MARVLs;

addpath(genpath('./'));

if strcmpi(style,'matlab')
    run(filePath);
    master=MARVLs.master;
elseif strcmpi(style,'yaml')
    MARVLs=yaml.loadFile(filePath,"ConvertToArray", true);
    master=MARVLs.master;
else
    msg=['Error: unreconized style of ',style];
    error(msg);
end


for modules=1:length(master.modules)
    module=master.modules{modules};
    if strcmpi(module,'timeseries')
        marvl_plot_timeseries(MARVLs,style);
    elseif strcmpi(module,'transect')
        marvl_plot_transect(MARVLs);
    elseif strcmpi(module,'transect_stackedArea')
        marvl_plot_transect_StackedArea(MARVLs);
    elseif strcmpi(module,'transect_exceedance')
        marvl_plot_transect_exceedance(MARVLs);
    elseif strcmpi(module,'site_profiling')
        marvl_plot_profile(MARVLs);
    elseif strcmpi(module,'sheet')
        marvl_plot_sheet(MARVLs);
    elseif strcmpi(module,'curtain')
        marvl_plot_curtain(MARVLs);
    elseif strcmpi(module,'boxchart')
        marvl_plot_boxchart(MARVLs,style);
    else
        msg=['Error: module of ',module,' is not recognized'];
        error(msg);
    end
end
