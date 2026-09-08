function config=check_TS_configs(config)

% checking the time series plot configuration file

if ~isfield(config,'add_vdata')
    config.add_vdata=0;
end

if ~isfield(config,'isHTML')
    config.isHTML=1;
end

if ~isfield(config,'htmloutput')
    config.htmloutput=config.outputdirectory;
end

if ~isfield(config,'add_error')
    config.add_error=0;
end

if ~isfield(config,'add_human')
    config.add_human=0;
end

if ~isfield(config,'fieldrange_min')
    config.fieldrange_min=200;
end

if ~isfield(config,'validation_minmax')
    config.validation_minmax=0;
end

if ~isfield(config,'isModelRange')
    config.isModelRange=1;
end

if ~isfield(config,'pred_lims')
    config.pred_lims=[0.05,0.25,0.5,0.75,0.95];
end

if ~isfield(config,'Range_ALL')
    config.Range_ALL=0;
end

if ~isfield(config,'isRange_Bottom')
    config.isRange_Bottom=0;
end

if ~isfield(config,'custom_datestamp')
    config.custom_datestamp=0;
end

if ~isfield(config,'add_triangle')
    config.add_triangle=0;
end

if ~isfield(config,'start_plot_ID')
    config.start_plot_ID=1;
end

if ~isfield(config,'end_plot_ID')
    config.end_plot_ID=size(MARVLs.master.varname,1);
end

if ~isfield(config,'validation_raw')
    config.validation_raw=0;
else 
    if config.validation_raw==1
        config.validation_minmax = 0;
    end
end

if ~isfield(config,'end_plot_ID')
    config.end_plot_ID=length(config.varname);
end

if ~isfield(config,'alph')
    config.alph=0.5;
end

if ~isfield(config,'visible')
    config.visible = 'on';
end

if ~isfield(config,'isGridon')
    config.isGridon = 1;
end

if ~isfield(config,'istitled')
    config.istitled = 1;
end

if ~isfield(config,'isylabel')
    config.isylabel = 1;
end

if ~isfield(config,'islegend')
    config.islegend = 1;
end

if ~isfield(config,'isYlim')
    config.isYlim = 0;
end

if ~isfield(config,'surface_offset')
    config.surface_offset = 0;
end

config.isConv = 0;

if ~isfield(config,'plotmodel')
    config.plotmodel=1;
end

if ~isfield(config,'isFieldRange')
    config.isFieldRange=0;
end

if ~isfield(config,'fielddprctile')
    config.fielddprctile=[5 95];
end

if ~isfield(config,'isHTML')
    config.isHTML=0;
end

config.max_depth = 5000;

if ~isfield(config,'depth_range')
    config.depth_range=[0.5 config.max_depth];
end

if ~isfield(config,'plotvalidation')
    config.plotvalidation=0;
end

if ~isfield(config,'add_error')
    config.add_error=0;
end

if ~isfield(config,'dimc')
    config.dimc=[0.9 0.9 0.9];
end

if ~isfield(config,'dailyave')
    config.dailyave=0;
end

if ~isfield(config,'smoothfactor')
    config.smoothfactor=1;
end

if ~isfield(config,'isSaveErr')
    config.isSaveErr=0;
end

if ~isfield(config,'legendlocation')
    config.legendlocation='northeastoutside';
end

if ~isfield(config,'dimensions')
    config.dimensions=[20 10];
end

if config.plotmodel==1 && config.plotvalidation==0
    config.add_error = 0;
end