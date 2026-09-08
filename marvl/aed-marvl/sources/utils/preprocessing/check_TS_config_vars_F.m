function [config, def]=check_TS_config_vars_F(config, def)

% checking the time series plot configuration file
% allconfig=fieldnames(config);

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

if ~isfield(config,'isRange')
    config.isRange=1;
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
    config.end_plot_ID=length(config.varname);
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

if ~isfield(def,'alph')
    def.alph=0.5;
end

if ~isfield(def,'visible')
    def.visible = 'on';
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

config.max_depth = 5000;

if ~isfield(config,'depth_range')
    config.depth_range=[0.5 config.max_depth];
end

if ~isfield(config,'plotvalidation')
    config.plotvalidation=0;
end

if ~isfield(config,'isSaveErr')
    config.isSaveErr=0;
end

if config.plotmodel==1 && config.plotvalidation==0
    config.add_error = 0;
end