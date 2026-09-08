function marvl_plot_profile(MARVLs)
%**************************************************************************
%
% This is AED-Marvl version 1.0 (SEPT-2022)
%
% AEDmarvl_plot_timeseries is a MATLAB-version tool for visualizing and
%    assessing AED model results. It plots the time series of selected
%    variables at selected locations (defined by site polygon GIS file),
%    and has options to add observational data (when isvalidation==1)
%    and calculate the model performance statistics.
%
% Please note that his software is intended to be used for AED-users,
%    meaning that the configuration (e.g. model names, variable name)
%    should be consistent with AED conventions. For info of AED model
%    please refer to https://aquaticecodynamics.github.io/aed-science/
%
% For more info please have a look at:
%    Huang et al., 2022. AED-MARVL - The AED Model Assessment, Reporting
%    and Visualisation Library, AED Research Group, UWA.
%    http://github ***************
%
%**************************************************************************
%
%  **** SYNTAX:
%  AEDmarvl_plot_timeseries(masterConfig, siteConfig)
%    where: masterConfig is the master (general) configuration file;
%           siteConfig is the site/style specific configuraton file;
%
%  **** SYNTAX EXAMPLES:
%  masterConfig = '../../../Configs/Coorong/Coorong_master_config.m';
%  siteConfig = '../../../Configs/Coorong/Coorong_timeseries_config.m';
%  AEDmarvl_plot_timeseries(masterConfig, siteConfig)

%**************************************************************************
% NOTHING BELOW THIS SHOULD REQUIRE EDITING BY USER!
%**************************************************************************

%--------------------------------------------------------------------------
disp('plot_profile: START');

%clear; close all;
%run('E:\database\MARVL\examples\Cockburn_Sound\MARVL.m');
master=MARVLs.master;
config=MARVLs.profile;
def=config;
ncfile=master.ncfile;

%[config, def]=check_TS_config_vars_F(config, def);

% load in model geometry (layers, depth etc)
% [t_data, d_data]=pre_load_model_GEOs(ncfile);

% check and define sites for plotting
%[shp, sites]=refine_SHP(shp, config);

% place-holder for model skill matrix
%errorMatrix=struct;

% start plotting, loop through selected variables
for var = config.start_plot_ID:config.end_plot_ID
    
    loadname = master.varname{var,1};       % AED name
    loadname_human = master.varname{var,2}; % User-define name
    savedir = [config.outputdirectory,loadname,'/']; % output path
    if ~exist(savedir,'dir')
        mkdir(savedir);
        mkdir([savedir,'eps/']);
    end
    
    % load in raw model data
    if config.plotmodel
        allvars = tfv_infonetcdf(ncfile(1).name);
        raw=struct;
        fielddata=struct;
        for site = 1:length(config.sitenames)
            disp(['Loading ',config.sitenames{site}]);
            rawData=load_AED_vars(ncfile,1,loadname,allvars);
            [rawData.data.(loadname),c_units,isConv]  = tfv_Unit_Conversion(rawData.data.(loadname),loadname);
            raw(site).data = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,config.siteX(site),config.siteY(site),{loadname});
            % raw(site).data=rawdata2; clear rawdata;
            
            if config.plotvalidation
                % load field data
               % fieldt=load(master.fielddata_matfile);
               % field=fieldt.(master.fielddata);
				field = marvl_load_fielddata(master);
                
                sites=fieldnames(field);
                
                if sum(cellfun(@(s) ~isempty(strfind(config.sitenames{site}, s)), sites))>0
                    fielddata(site).data=field.(config.sitenames{site}).(loadname);
                    [fielddata(site).data.Data,c_units,isConv]  = tfv_Unit_Conversion(fielddata(site).data.Data,loadname);
                else
                    msg=['Warning: site ',config.sitenames{site},' is not found in the field dataset'];
                    warning(msg);
                    stop;
                end
            end
            
        end
    end
    % save(['E:\database\AED-MARVl-v0.2\Examples\Swan\',loadname,'.mat'],'raw','-mat','-v7.3');
    % loop though sites, do data processing and plotting
    for site = 1:length(config.sitenames)
        disp(strcat(' >>> var',num2str(var),'=',loadname,'; site=',...
            num2str(site),[': ',regexprep(config.sitenames{site},'_',' ')]))
        
        gcf=figure('visible',master.visible);
        pos=get(gcf,'Position');
        xSize = def.dimensions(1);
        ySize = def.dimensions(2);
        newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
        newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
        set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);
        set(0,'DefaultAxesFontName',master.font);
        set(0,'DefaultAxesFontSize',master.fontsize);
        
        %--% Paper Size
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf,'paperposition',[0 0 xSize ySize]);
        
        if strcmpi(config.plottype,'whole')
            
            if config.plotvalidation
                subplot(2,1,1);
            end
            hfig=pcolor(raw(site).data.date,raw(site).data.depths,raw(site).data.profile);
            shading interp;
            hc=colorbar;
            title(hc,c_units);
            
            % polishing the figure (ticks, labels, titles, legends)
            % Y axis and label
            
            if def.isylabel
                ylabel('Depth (m)','fontsize',6,'FontWeight','bold',...
                    'color',[0.4 0.4 0.4],'horizontalalignment','center');
            end
            
            %   if def.isYlim
            if ~isempty(def.ylim)
                ylim([def.ylim]);
            end
            
            if ~isempty(def.cAxis(var).value)
                caxis([def.cAxis(var).value]);
            end
            
            % X axis and label
            xlim([def.datearray(1) def.datearray(end)]);
            
            set(gca,'Xtick',def.datearray,...
                'XTickLabel',datestr(def.datearray,def.dateformat),...
                'FontSize',master.xlabelsize);
            set(gca,'box','on','LineWidth',1.0,'Layer','top');
            
            % title
            if def.istitled
                if master.add_human
                    title([regexprep(config.sitenames{site},'_',' '),': ',loadname_human, ' (modelled)'],...
                        'FontSize',master.titlesize,...
                        'FontWeight','bold');
                else
                    title([regexprep(config.sitenames{site},'_',' '),': ',loadname, ' (modelled)'],...
                        'FontSize',master.titlesize,...
                        'FontWeight','bold');
                end
            end
            
            if config.plotvalidation
                subplot(2,1,2);
                
                hfig2=pcolor(fielddata(site).data.Date,fielddata(site).data.Depth,fielddata(site).data.Data);
                shading interp;
                hc=colorbar;
                title(hc,c_units);
                
                % polishing the figure (ticks, labels, titles, legends)
                % Y axis and label
                
                if def.isylabel
                    ylabel('Depth (m)','fontsize',6,'FontWeight','bold',...
                        'color',[0.4 0.4 0.4],'horizontalalignment','center');
                end
                
                if ~isempty(def.ylim)
                    ylim([def.ylim]);
                end
                
                if ~isempty(def.cAxis(var).value)
                    caxis([def.cAxis(var).value]);
                end
                
                % X axis and label
                xlim([def.datearray(1) def.datearray(end)]);
                
                set(gca,'Xtick',def.datearray,...
                    'XTickLabel',datestr(def.datearray,def.dateformat),...
                    'FontSize',master.xlabelsize);
                set(gca,'box','on','LineWidth',1.0,'Layer','top');
                
                % title
                if def.istitled
                    if master.add_human
                        title([regexprep(config.sitenames{site},'_',' '),': ',loadname_human, ' (observed)'],...
                            'FontSize',master.titlesize,...
                            'FontWeight','bold');
                    else
                        title([regexprep(config.sitenames{site},'_',' '),': ',loadname, ' (observed)'],...
                            'FontSize',master.titlesize,...
                            'FontWeight','bold');
                    end
                end
                
            end
        
        else
            color1=[69,117,180]./255;
            color2=[215,48,39]./255;
            
            for cc=1:length(config.datearray)
                tc=config.datearray(cc);
                subplot(config.RCnum(1),config.RCnum(2),cc);
                
                indc=find(abs(raw(site).data.date-tc)==min(abs(raw(site).data.date-tc)));
                plot(raw(site).data.profile(:,indc),raw(site).data.depths,...
                    'Color',color1);
                hold on;
                
                if config.plotvalidation
                indm=find(abs(fielddata(site).data.Date-tc)==min(abs(fielddata(site).data.Date-tc)));
                plot(fielddata(site).data.Data(:,indm),fielddata(site).data.Depth,...
                    'Color',color2);
                hold on;
                end
                
                
                if def.isylabel
                    ylabel('Depth (m)','fontsize',6,'FontWeight','bold',...
                        'color',[0.4 0.4 0.4],'horizontalalignment','center');
                end
                
                if ~isempty(def.ylim)
                    ylim([def.ylim]);
                end
                title(datestr(tc,'yyyy-mm-dd HH:MM'));
                set(gca,'box','on','LineWidth',1.0,'Layer','top');
            end
                
            hl=legend('Modelled','Observed');
            set(hl,'Position',[0.4 0.02 0.2 0.02],'NumColumns',2);
            
        end
        
        % export the figure
        
        final_sitename = [config.sitenames{site},'.eps'];
        
        finalname_p = [savedir,final_sitename];
        
        if exist('filetype','var')
            if strcmpi(filetype,'png')
                print(gcf,'-dpng',regexprep(finalname_p,'.eps','.png'),'-r300');
            else
                print(gcf,'-djpg',regexprep(finalname_p,'.eps','.jpg'),'-r300');
            end
        else
            %   saveas(gcf,regexprep(finalname_p,'.eps','.png'));
            print(gcf,'-dpng',regexprep(finalname_p,'.eps','.png'),'-r300');
        end
    end
    
    if config.isHTML
        create_html_for_directory_onFly(savedir,loadname,config.htmloutput);
    end
    
    close all force;
    clear data rawData raw;
end

%--------------------------------------------------------------------------
% export HTML file for figures
if config.isHTML
    create_html_for_directory(config.outputdirectory,config.htmloutput);
end

%end
