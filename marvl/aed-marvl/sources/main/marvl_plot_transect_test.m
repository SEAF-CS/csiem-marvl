%function marvl_plot_transect(MARVLs)

%--------------------------------------------------------------------------
disp('plot_transect: START');
% 
clear; close all;
run('E:\database\MARVL\examples\Cockburn_Sound\MARVL.m');
master=MARVLs.master;
config=MARVLs.transect;

ncfile=master.ncfile;
% load in and check configurations
%st = dbstack;

config=check_transect_config(config);
def=config;
%check_transect_config_vars_F;
%--------------------------------------------------------------------------
%disp('plottfv_transect: START')
disp('')

% load in model geometry (layers, depth etc)
if config.plotmodel==1
    [~, d_data]=pre_load_model_GEOs(master.ncfile);
end

% load in shape file
shp = shaperead(config.polygon_file);

% field data
fdata = struct;
isvalidation=master.add_fielddata;

% if length(master.ncfile)>1
%     isvalidation=0;
% end

if isvalidation
field = load(master.fielddata_matfile);
fdata = field.(master.fielddata); clear field;
end

% start plotting, loop through selected variables
for var = config.start_plot_ID:config.end_plot_ID
    
    loadname = master.varname{var,1};       % AED name
    loadname_human = master.varname{var,2}; % User-define name
    savedir = [config.outputdirectory,loadname,'/']; % output path
    if ~exist(savedir,'dir')
        mkdir(savedir);
        mkdir([savedir,'eps/']);
    end
    
    disp(['Plotting ',loadname]);
    % load in raw model data
    if config.plotmodel
        allvars = tfv_infonetcdf(master.ncfile(1).name);
        raw=struct;
        for mod = 1:length(master.ncfile)
            disp(['Loading Model ',num2str(mod)]);
            rawdata=load_AED_vars(master.ncfile,mod,loadname,allvars);
            raw(mod).data=rawdata.data; clear rawdata;
        end
    end
    
    % looping through the dates to plot transects
    for tim = 1:length(config.pdates)
        
        % process model data
        for mod = 1:length(ncfile)
            [data(mod),c_units,isConv,ylab] = marvl_getmodelpolylinedata_dist(raw(mod).data,ncfile(mod).name,shp,{loadname},d_data,config,def,tim,mod);
        end
        
        % process field data
        if config.plotvalidation
            [fielddata,fielddist] = marvl_getfielddata_boxregion_dist(fdata,shp,config,def,loadname,tim);
        end
        
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
        
        % plot median line and percentile bands
        for mod = 1:length(ncfile)
            plot(data(mod).dist,data(mod).pred_lim_ts(3,:),'color',config.ncfile(mod).colour,'linewidth',0.5,'DisplayName',[ncfile(mod).legend,' (Median)']);hold on
            
            num_lims = length(config.pred_lims);
            nn = (num_lims+1)/2;
                
            if config.isRange
                fig = fillyy(data(mod).dist,data(mod).pred_lim_ts(1,:),data(mod).pred_lim_ts(2*nn-1,:),def.dimc,config.ncfile(mod).col_pal_color(1,:));hold on;
                set(fig,'DisplayName',[ncfile(mod).legend,' (Range 5^{th}-95^{th})']);
                set(fig,'FaceAlpha', def.alph);
                uistack(fig,'bottom');
                hold on;
                
                for plim_i=2:(nn-1)
                    fig2 = fillyy(data(mod).dist,data(mod).pred_lim_ts(plim_i,:),data(mod).pred_lim_ts(2*nn-plim_i,:),def.dimc.*0.9.^(plim_i-1),config.ncfile(mod).col_pal_color(plim_i,:));
                   % set(fig2,'HandleVisibility','off');
                    set(fig2,'DisplayName',[ncfile(mod).legend,' (Range 25^{th}-75^{th})']); %Surf
                    set(fig2,'FaceAlpha', def.alph);
                    uistack(fig2,'bottom');
                end
            end
        end
        
        % model legend
        leg = legend('show');
        set(leg,'location',def.rangelegend,'fontsize',master.legendsize);
        
        % add field data
        box_vars = [];
        if config.plotvalidation
            if ~isempty(fielddata)
                h_box=boxplot(fielddata,fielddist,'positions',unique(fielddist),'color','k','plotstyle','compact');
                box_vars = findall(gca,'Tag','Box');
                set(h_box,'DisplayName','Field Data');
            end
        end

        % tailor x axis and label
        %xlim(def.xlim);
        
		if def.xtickManual == 1
                    set(gca,'xlim',def.xlim,'XTick',def.xticks,'XTickLabel',def.xticklabels,'TickDir','out');
                else
                    set(gca,'xlim',def.xlim,'XTick',def.xticks);
                    xlabel(def.xlabel,'fontsize',master.xlabelsize,'FontWeight','bold','color','k','FontName',master.font);

                end
				
        %if ~isempty(def.xticks)
        %    set(gca,'xtick',def.xticks,'xticklabel',def.xticks,'fontsize',6);
        %end
%         if config.add_shapefile_label
%             dist(1,1) = 0;
%             for gdg = 1:length(shp)
%                 sdata(gdg,1) = shp(gdg).X;
%                 sdata(gdg,2) = shp(gdg).Y;
%                 labels(gdg,1) = {shp(gdg).Name};
%             end
%             for hhh = 2:length(shp)
%                 dist(hhh,1) = sqrt(power((sdata(hhh,1) - sdata(hhh-1,1)),2) + power((sdata(hhh,2)- sdata(hhh-1,2)),2)) + dist(hhh-1,1);
%             end
%             dist = dist / 1000;
%             
%             if length(dist) > 15
%                 set(gca,'xtick',dist(1:2:end),'xticklabels',labels(1:2:end),'fontsize',4);
%             else
%                 set(gca,'xtick',dist,'xticklabels',labels,'fontsize',4);
%             end
%             set(gca,'XTickLabelRotation',90)
%         end
        
        % tailor y axis and label        
        if ~isempty(def.cAxis(var).value)
            ylim(def.cAxis(var).value);
        end
        
        if master.add_human
            ylabel([loadname_human,' (',c_units,')'],...
                'fontsize',master.ylabelsize,'color',[0.4 0.4 0.4],'horizontalalignment','center');
        else
            ylabel([ylab,' (',c_units,')'],...
                'fontsize',master.ylabelsize,'color',[0.4 0.4 0.4],'horizontalalignment','center');
        end
  
%         yt = get(gca,'yticklabel');
%         set(gca,'yticklabel',yt,'fontsize',6);
        
               
        % add time label on top left
        if config.isSurf
            text(0.05,1.05,[datestr(def.pdates(tim).value(1),'dd/mm/yyyy'),' to ',datestr(def.pdates(tim).value(end),'dd/mm/yyyy'),': Surface'],'units','normalized',...
                'fontsize',8,'color',[0.4 0.4 0.4]);
        else
            text(0.05,1.05,[datestr(def.pdates(tim).value(1),'dd/mm/yyyy'),' to ',datestr(def.pdates(tim).value(end),'dd/mm/yyyy'),': Bottom'],'units','normalized',...
                'fontsize',8,'color',[0.4 0.4 0.4]);
        end
        
        % optional, add trigger values
        if config.add_trigger_values
            trig = find(strcmpi(trigger_vars,loadname) == 1);
            
            if ~isempty(trig)
                plot([def.xlim(1) def.xlim(end)],[trigger_values(trig) trigger_values(trig)],'--r','DisplayName',trigger_label{trig});
            end
        end
        
        % optional, add markers
        if config.addmarker
            HH=gca; HH.XAxis.TickLength = [0 0];
            load(markerfile);
            
            yl = get(gca,'ylim');
            yl_r = (yl(2) - yl(1)) * 0.01;
            
            yx(1:length(marker.Dist)) = yl(2);
            scatter(marker.Start,yx- yl_r,12,'V','filled','MarkerFaceColor','k','HandleVisibility','off');
        end
        
        % optional, add observation numbers
        if ~isempty(box_vars) && config.add_obs_num
            udist = unique(fielddist);
            yl = get(gca,'ylim');
            ryl = yl(2)-yl(1);
            offset = ryl * 0.03;
            
            for i = 1:length(udist)
                if udist(i) < def.xlim(end)
                    sss = find(fielddist == udist(i));
                    mval = max(fielddata(sss));
                    mval = mval + offset;
                    text(gca,udist(i),mval,['n=',num2str(length(sss))],'fontsize',6,'horizontalalignment','center');
                end
            end
        end
        
        % add field data legend
        if ~isempty(box_vars)
            ah1=axes('position',get(gca,'position'),'visible','off');
            lpos=get(leg,'position');
            newpos=[lpos(1)-0.01,lpos(2)-0.03,lpos(3),0.02];
            hLegend = legend(ah1,box_vars([1]), {'Field Data'},'location',def.boxlegend,'fontsize',6);
        end
        
        box on;

        if config.isSurf
            image_name = [datestr(def.pdates(tim).value(1),'yyyy-mm-dd'),'_',datestr(def.pdates(tim).value(end),'yyyy-mm-dd'),'_Surface.png'];
        else
            image_name = [datestr(def.pdates(tim).value(1),'yyyy-mm-dd'),'_',datestr(def.pdates(tim).value(end),'yyyy-mm-dd'),'_Bottom.png'];
        end
        
        finalname = [savedir,image_name];
        finalnameEPS = [savedir,'eps/',image_name];
      %  print(gcf,finalname,'-opengl','-dpng');
        
        if exist('filetype','var')
            if strcmpi(filetype,'png')
               % print(gcf,'-dpng',regexprep(finalname_p,'.eps','.png'),'-opengl');
                print(gcf,finalname,'-opengl','-dpng');
            else
                %saveas(gcf,regexprep(finalname_p,'.eps','.png'));
              %  finalname_p2 = [savedir,'\eps\',final_sitename];
                finalnameEPS=regexprep(finalnameEPS,'.png','.eps');
                saveas(gcf,finalnameEPS,'epsc');
                exportgraphics(gcf,regexprep(finalname,'.png','.jpg'),'Resolution',300);
            end
        else
            %saveas(gcf,regexprep(finalname_p,'.eps','.png'));
            finalnameEPS=regexprep(finalname,'.png','.eps');
            saveas(gcf,finalnameEPS,'epsc');
            exportgraphics(gcf,regexprep(finalname,'.png','.jpg'),'Resolution',300);
        end
        
        close all force;
      %  clear data;

    end
    
    if config.isHTML
      %  create_html_for_directory_onFly(savedir,loadname,config.htmloutput);
        create_html_for_directory(config.outputdirectory,config.htmloutput);
    end
end

%--------------------------------------------------------------------------
% export HTML file for figures
if config.isHTML
    create_html_for_directory(config.outputdirectory,config.htmloutput);
end

%end