
function marvl_plot_boxchart(MARVLs,style)

disp('plot_boxchart: START');
% 
% clear; close all;
% run('E:\database\MARVL\examples\Cockburn_Sound\MARVL.m');
% style='matlab';
 
master=MARVLs.master;
config=MARVLs.boxchartConf;

dat=tfv_readnetcdf(master.ncfile(1).name,'timestep',1);
cellX=dat.cell_X;
cellY=dat.cell_Y;

surfinds = dat.idx3(dat.idx3 > 0);
bottom_cells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cells(length(dat.idx3)) = length(dat.idx3);

dat2=tfv_readnetcdf(master.ncfile(1).name,'time',1);
timestep=double(dat2.Time);
modtime=floor(timestep);


% define field data file

%field = load(master.fielddata_matfile);
%fdata = field.(master.fielddata); clear field;

fdata = marvl_load_fielddata(master);
shp=shaperead(config.polygon_file);

%% general plotting features

gcf=figure('visible',master.visible);
pos=get(gcf,'Position');
xSize = config.dimensions(1);
ySize = config.dimensions(2);
newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);
set(0,'DefaultAxesFontName',master.font);
set(0,'DefaultAxesFontSize',master.fontsize);

%--% Paper Size
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0 0 xSize ySize]);

pos1=[0.08 0.15 0.6 0.8];
pos2=[0.75 0.16 0.2 0.8];

color1=[43,140,190]./255;

% go through variables for preprocessing
for var = config.start_plot_ID:config.end_plot_ID
    
    loadname = master.varname{var,1};       % AED name
    loadname_human = master.varname{var,2}; % User-define name
    
    if strcmpi(style,'matlab')
        savedir = [config.outputdirectory,loadname,'/']; % output path
    elseif strcmpi(style,'yaml')
        savedir = [config.outputdirectory{1},loadname,'/']; % output path
    end
    
    if ~exist(savedir,'dir')
        mkdir(savedir);
     %   mkdir([savedir,'eps/']);
    end

    data=ncread(master.ncfile(1).name,loadname);
    
    datasurf=data(surfinds,:);
    databot=data(bottom_cells,:);

    % find out the field data sites and coordinates
    allsites=fieldnames(fdata);
    newsites={};
    xx=[];
    yy=[];
    cellID=[];
    
    inc=1;
    for ss=1:length(allsites)
        tmpsite=fdata.(allsites{ss});
        
        if isfield(tmpsite,loadname)
            newsites{inc}=allsites{ss};
            xx(inc)=tmpsite.(loadname).X;
            yy(inc)=tmpsite.(loadname).Y;
            
            distx=cellX-xx(inc);
            disty=cellY-yy(inc);
            distt=sqrt(distx.^2+disty.^2);
            indtmp=find(distt==min(distt));
            cellID(inc)=indtmp(1);
            inc=inc+1;
        end
    end

    
    %%
    incT=1;
    for pp=1:length(shp)
        IDs=inpolygon(xx,yy,shp(pp).X,shp(pp).Y);       % field data sites within polygon
        IDsM=inpolygon(cellX,cellY,shp(pp).X,shp(pp).Y);% model cells within polygon
        
        % go through all sites within polygon for field data
        for ii=1:length(IDs)
            if IDs(ii)==1
                disp(newsites{ii});
                tmpdate=fdata.(newsites{ii}).(loadname).Date;
                tmpind=find(tmpdate>config.datearray(1) & tmpdate<config.datearray(2));
                
                if (~isempty(tmpind))
                    tmpdata=fdata.(newsites{ii}).(loadname).Data(tmpind);
                    
                    % store field data in format of 'source','polygon name'
                    % and 'data'
                    for tt=1:length(tmpdata)
                        plotdata.Source{incT}='observed';
                        plotdata.Site{incT}=upper(shp(pp).Name);
                        plotdata.Data(incT)=tmpdata(tt);
                        incT=incT+1;
                    end
                    
                    % find model data at same dates of observation and save
                    % the mean data of all cells 
                    newdate=floor(tmpdate(tmpind));
                    uninewdate=unique(newdate);
                    
                    for uu=1:length(uninewdate)
                        timeind=find(modtime==uninewdate(uu));
                        if ~isempty(timeind)
                            disp(datestr(timestep(timeind(1)))); 
                          % merge surface and bottom data
                          tmpmodSurf=datasurf(IDsM,timeind(1));
                          tmpmodBot=databot(IDsM,timeind(1));
                          tmpmod=[tmpmodSurf;tmpmodBot];
                          
                          % sub-sample the model output to reduce size
                          tmpmod2=tmpmod(1:5:end);

                            % save the model output in same format
                            for tt=1:length(tmpmod2)
                                plotdata.Source{incT}='modelled';
                                plotdata.Site{incT}=upper(shp(pp).Name);
                                plotdata.Data(incT)=tmpmod2(tt);
                                incT=incT+1;
                            end
                        end
                    end
                end
            end
        end
        
        
    end
    
 %   save([outdir,'saved_data_',vars{vv},'.mat'],'plotdata','-mat','-v7.3');
 
    clf;
  %  disp(['plotting ',loadname,'...']);
  %  load([outdir,'saved_data_',vars{vv},'.mat']);
    
    % catelog the polygon zones
    namesites=categorical(plotdata.Site,config.cattt);
    
    % factor to convert model unit to mg/L
    %fac=config.facs(vv);
    [plotdata.Data,c_units,isConv,ylab]  = tfv_Unit_Conversion(plotdata.Data,loadname);
    % calculate the median values of each polygon zones
    inc=1;
    for jj=1:length(config.cattt)
        s0=config.cattt(jj);
        s1=cellstr(s0);
        S2F=s1{1};
        tmpdata=find(contains(plotdata.Site,S2F) & contains(plotdata.Source,'observed'));
    
        if ~isempty(tmpdata)
            tmpdataD= plotdata.Data(tmpdata);
            tmpdataN=tmpdataD(~isnan(tmpdataD));
            m1(jj)=median(tmpdataN);
        else
            m1(jj)=nan;
        end
        
        tmpdata2=find(contains(plotdata.Site,S2F) & contains(plotdata.Source,'modelled'));
        
        if ~isempty(tmpdata2)
            tmpdataD2 = plotdata.Data(tmpdata2);
            tmpdataN2=tmpdataD2(~isnan(tmpdataD2));
            m2(jj)=median(tmpdataN2);
        else
            m2(jj)=nan;
        end
    end
    
    axes('position',pos1);

    boxchart(namesites,plotdata.Data,'GroupByColor',plotdata.Source,'MarkerStyle','none')
    
    %set(gca,'xlim',[0 46],'ylim',[0 0.15],'XTick',[]);
    
    ylabel([loadname_human,' (',c_units,')']);
    hold on;
    aa=get(gca,'XTick');
%     plot([aa(7) aa(7)],[0 ylimits(vv)],'k:');
%     
%     hold on;
%     plot([aa(32) aa(32)],[0 ylimits(vv)],'k:');
%     hold on;
%     text(aa(35),ylimits(vv)*0.9,'Eastern Basin');
%     hold on;
%     text(aa(16),ylimits(vv)*0.9,'Central Basin');
%     hold on;
%     text(aa(1),ylimits(vv)*0.9,'Western Basin');
    box on;
    if ~isempty(config.cAxis(var).value)
        set(gca,'ylim',config.cAxis(var).value);
    end
    
    hl=legend('modelled','observed','Location',config.legendLoc);
    %title('(a) modelled vs. observed TP: box chart');
    
    axes('position',pos2);
    
    % IDs for WB, CB, and EB zones
%     indss=[1 7 32];
%     indsf=[6 31 45];
%     
    colors=[127,201,127;...
        190,174,212;...
        253,192,134]./255;
%     
%     for kk=1:length(indss)
%        ms=m1(indss(kk):indsf(kk));
%        ms2=m2(indss(kk):indsf(kk));
        indm=find(~isnan(m1) & m1>0);
        
        if ~isempty(indm)
            
            scatter(m1(indm),m2(indm),'MarkerEdgeColor',colors(1,:),...
                'LineWidth',1.0);
            hold on;
        end
 %   end
    if ~isempty(config.cAxis(var).value)
        set(gca,'xlim',config.cAxis(var).value,'ylim',config.cAxis(var).value);
    end
    
    plot(config.cAxis(var).value,config.cAxis(var).value,'k:');
    hold on;

      hl=legend('data','1:1 ratio','Location','southeast');

    ind1=find(~isnan(m1) & m1>0);
    
    R = corrcoef(m1(ind1),m2(ind1));hold on;
    rf=R(1,2);
    txtlon=(config.cAxis(var).value(2)-config.cAxis(var).value(1))*0.15+config.cAxis(var).value(1);
    txtlat=(config.cAxis(var).value(2)-config.cAxis(var).value(1))*0.85+config.cAxis(var).value(1);
    
    text(txtlon,txtlat,['R=',num2str(rf,'%1.4f')]);
  %  set(gca,'xlim',[0 config.axisLim2(var)],'XTick',0:config.axisInt2(var):config.axisLim2(var),...
  %      'ylim',[0 config.axisLim2(var)],'YTick',0:config.axisInt2:config.axisLim2(var));
    box on;
    xlabel(['observed median ',loadname_human,' (',c_units,')']);
    ylabel(['modelled median ',loadname_human,' (',c_units,')']);
    %title('(b) modelled vs. observed TP: median');
    
    %hl=legend('observed','simulated');
    
    img_name =[savedir,'boxchart_',loadname,'.png'];
    saveas(gcf,img_name);
end
