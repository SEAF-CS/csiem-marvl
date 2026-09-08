function marvl_plot_transect_StackedArea(MARVLs)
%
% 
%clear; close all;
%run('E:\database\AED-MARVl-v0.2\Examples\Cockburn\MARVL.m');
master=MARVLs.master;
config=MARVLs.transectSA;

ncfile=master.ncfile;
% load in and check configurations
%st = dbstack;

config=check_transectSA_config(config);
def=config;

%--------------------------------------------------------------------------
disp('plottfv_transect_StackedArea: START')
disp('')

% load in model geometry (layers, depth etc)
if config.plotmodel==1
    [~, d_data]=pre_load_model_GEOs(ncfile);
end

loadname = config.varname{1,1};       % AED name
loadname_human = config.varname{1,2}; % User-define name

disp(['Plotting ',loadname]);

savedir = [config.outputdirectory,loadname,'/']; % output path
if ~exist(savedir,'dir')
    mkdir(savedir);
    mkdir([savedir,'eps/']);
end

for k = 1:length(config.thevars)
    disp(config.thevars{k});
    td = tfv_readnetcdf(ncfile(1).name,'names',config.thevars(k));
    raw(1).data(k).Val = td.(config.thevars{k})  * config.thevars_conv(k); clear td;
end

% load in shape file
shp = shaperead(config.polygon_file);

% field data
fdata = struct;
isvalidation=master.add_fielddata;

if length(master.ncfile)>1
    isvalidation=0;
end

if isvalidation
%field = load(master.fielddata_matfile);
%fdata = field.(master.fielddata); clear field;
fdata = marvl_load_fielddata(master);
end

for tim = 1:length(def.pdates)
    for k = 1:length(config.thevars)
        rd(1).data.(config.thevars{k}) = raw(1).data(k).Val;
        [data(1),c_units,isConv,ylab] = marvl_getmodelpolylinedata_dist(rd(1).data,ncfile(1).name,shp,{config.thevars{k}},d_data,config,def,tim,1);
        
        pData(:,k) = data(1).pred_lim_ts(3,:);
        clear rd;
    end
    
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
      
    H = area(data(1).dist,pData);hold on
    
    cmap = parula(length(config.thevars));
    for kk = 1:length(config.thevars)
        H(kk).FaceColor = cmap(kk,:);
    end
    
    box_vars = [];
    if config.plotvalidation
        if ~isempty(fielddata)
            boxplot(gca,fielddata,fielddist,'positions',unique(fielddist),'color','k','plotstyle','compact');
            box_vars = findall(gca,'Tag','Box');
        end
    end
    
    if ~isfield(config,'thelabels')
        thelabels = config.thevars;
    else
        thelabels = config.thelabels;
    end
    %     if ~isempty(box_vars)
    %         thelabels = [thelabels,{'Field Data'}];
    %     end
    leg = legend(regexprep(thelabels,'_',' '));
    set(leg,'location',def.rangelegend,'fontsize',master.legendsize);
    %title(leg,[datestr(def.pdates(tim).value(1),'mmm yyyy'),' to ',datestr(def.pdates(tim).value(2),'mmm yyyy')],'fontsize',8)
    
    % legpos = get(leg,'position');
    
    % tailor x axis and label
    %xlim(def.xlim);
    
        if def.xtickManual == 1
                    set(gca,'xlim',def.xlim,'XTick',def.xticks,'XTickLabel',def.xticklabels,'TickDir','out');
                else
                    set(gca,'xlim',def.xlim,'XTick',def.xticks);
                    xlabel(def.xlabel,'fontsize',master.xlabelsize,'FontWeight','bold','color','k','FontName',master.font);
        end

%     if ~isempty(def.xticks)
%         set(gca,'xtick',def.xticks,'xticklabel',def.xticks);
%     end
% 
%     text(0.5,-0.1,def.xlabel,'fontsize',master.xlabelsize,...
%         'color',[0.4 0.4 0.4],'horizontalalignment','center','units','normalized');
%     
    % tailor y axis and label
    if ~isempty(def.cAxis(1).value)
        ylim(def.cAxis(1).value);
    end
    
    if config.add_human
        ylabel(regexprep(loadname_human,'_',' '),'fontsize',master.ylabelsize,...
            'color',[0.4 0.4 0.4],'horizontalalignment','center');
    else
        ylabel(regexprep(loadname,'_',' '),'fontsize',master.ylabelsize,...
            'color',[0.4 0.4 0.4],'horizontalalignment','center');
    end

    % add time label on top left
    if config.isSurf
        text(0.05,1.05,[datestr(def.pdates(tim).value(1),'dd/mm/yyyy'),' to ',datestr(def.pdates(tim).value(end),'dd/mm/yyyy'),': Surface'],'units','normalized',...
            'fontsize',8,'color',[0.4 0.4 0.4]);
    else
        text(0.05,1.05,[datestr(def.pdates(tim).value(1),'dd/mm/yyyy'),' to ',datestr(def.pdates(tim).value(end),'dd/mm/yyyy'),': Bottom'],'units','normalized',...
            'fontsize',8,'color',[0.4 0.4 0.4]);
    end
    
    if ~isempty(box_vars)
        udist = unique(fielddist);
        yl = get(gca,'ylim');
        ryl = yl(2)-yl(1);
        offset = ryl * 0.03;
        
        for i = 1:length(udist)
            if udist(i) < def.xlim(end)
                sss = find(fielddist == udist(i));
                mval = max(fielddata(sss));
                mval = mval + offset;
                text(gca,udist(i),mval,['n=',num2str(length(sss))],'fontsize',5,'horizontalalignment','center');
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
    
    
    % text(0.5,-0.1,def.xlabel,'fontsize',8,'color','k','horizontalalignment','center','units','normalized');
    
    % get current (active) axes property
    %     tt = get(gca,'OuterPosition')
    %     set(gca,'OuterPosition',[tt(1) tt(2) + 0.05 tt(3) (4)])
    
    
    if config.isSurf
        image_name = [datestr(def.pdates(tim).value(1),'yyyy-mm-dd'),'_',datestr(def.pdates(tim).value(end),'yyyy-mm-dd'),'_Surface.png'];
    else
        image_name = [datestr(def.pdates(tim).value(1),'yyyy-mm-dd'),'_',datestr(def.pdates(tim).value(end),'yyyy-mm-dd'),'_Bottom.png'];
    end
    finalname = [savedir,image_name];
    
    print(gcf,finalname,'-opengl','-dpng','-r300');
    print(gcf,regexprep(finalname,'.png','.eps'),'-painters','-depsc2','-r300');
    close;
    
    
end

if config.isHTML
    
    create_html_for_directory_onFly(savedir,loadname,config.htmloutput);
    
end

