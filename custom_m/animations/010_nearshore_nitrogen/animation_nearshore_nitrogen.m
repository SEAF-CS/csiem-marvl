clear ; close all;

inDir='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results_GW_noND\';
inDirHR='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results_HighRes\';

fluxfile='E:\database\Cockburn\nutrient_budgeting\flux\Flux_Cockburn_2013_noDIR.mat';
load(fluxfile);

WQfile=[inDir,'csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_WQ.nc'];
HRfile=WQfile;
%[inDirHR,'csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_HighRes_hires.nc'];
%WQfile=HRfile;

dat = tfv_readnetcdf(WQfile,'time',1);
timesteps_WQ = dat.Time;

dat = tfv_readnetcdf(HRfile,'time',1);
timesteps_HR = dat.Time;

dat = tfv_readnetcdf(WQfile,'timestep',1);
clear funcions;

vertWQ(:,1) = dat.node_X;
vertWQ(:,2) = dat.node_Y;

facesWQ = dat.cell_node';

%--% Fix the triangles
facesWQ(facesWQ(:,4)== 0,4) = facesWQ(facesWQ(:,4)== 0,1);

surf_cellsWQ=dat.idx3(dat.idx3 > 0);
bottom_cellsWQ(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsWQ(length(dat.idx3)) = length(dat.idx3);

dat = tfv_readnetcdf(HRfile,'timestep',1);
clear funcions;

vertHR(:,1) = dat.node_X;
vertHR(:,2) = dat.node_Y;

facesHR = dat.cell_node';

%--% Fix the triangles
facesHR(facesHR(:,4)== 0,4) = facesHR(facesHR(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

clip_depth=0.05;
config.add_quiver = 0;

def.xlim = [0 8.48];% xlim in KM
def.xticks = [0    4.2   8.28]; %[0:5:45];
def.xticklabels = {'West','Central CS','East'};

def.ylim=[-24 2];
config.ylim=[-24 2];
config.max_depth = -24;

%%
% line config
coastline_file='../GIS/Boundary.shp';
shp2=shaperead(coastline_file);
%  cell_inds=inpolygon(xxx,yyy,shp2.X,shp2.Y);

ndfile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\gis_repo\1_domain\nodestrings\2d_ns_Cockburn_Sound_001_nutirent.shp';
shp3=shaperead(ndfile);
line(:,1)=shp3(10).X;
line(:,2)=shp3(10).Y;
%%
first_plot = 1;

img_dir = '.\animation_nearshore_nitrogen\';

if ~exist(img_dir,'dir')
    mkdir(img_dir);
end


sim_name = [img_dir,'animation.avi'];

hvid = VideoWriter(sim_name);
set(hvid,'Quality',100);
set(hvid,'FrameRate',3);
framepar.resolution = [1024,768];

open(hvid);

%%
hfig = figure('visible','on','position',[304         166         1200        675]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 24 13.5])

t01=datenum('20130901 00:00','yyyymmdd HH:MM');
tt = find(abs(timesteps_WQ-t01)==min(abs(timesteps_WQ-t01)));
t1=datenum('20131001 00:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps_WQ-t1)==min(abs(timesteps_WQ-t1)));
plot_interval=1;

xlim=[115.6300  115.7786]; %[115.6000  115.8];
ylim=[-32.3000  -32.1000]; %[-32.3000  -31.9];


cellInt=floor((xlim(2)-xlim(1))*1111111/500);
    XXs=xlim(1):cellInt/1111111:xlim(2);
    YYs=ylim(1):cellInt/1111111:ylim(2);
    [xxxs,yyys]=meshgrid(XXs,YYs);
  
    
    [aa,bb]=m_ll2xy(xxxs,yyys);
    xxxq=aa;yyyq=bb;
                    
    intv=round(size(xxxq,1)/50);
    xxxx=xxxq(1:intv:end,1:intv:end);
    yyyy=yyyq(1:intv:end,1:intv:end);

%coastline_file='../GIS/Boundary.shp';
%shp2=shaperead(coastline_file);
cell_inds=inpolygon(xxxs,yyys,shp2.X,shp2.Y);

m_proj('miller','lon',xlim,'lat',ylim);
hold on;

LONG=vertHR(:,1);LAT=vertHR(:,2);
[X,Y]=m_ll2xy(LONG,LAT);
vert(:,1)=X;vert(:,2)=Y;

pos1=[0.1 0.1 0.3 0.8];
pos2=[0.48 0.55 0.45 0.28];
pos3=[0.48 0.15 0.45 0.28];

for i=tt:plot_interval:tt1
    
    disp(datestr(timesteps_WQ(i)));
    clf;
    
    gca=axes('Position',pos1);
    
    t0=timesteps_WQ(i);
    ind0=find(abs(timesteps_HR-t0)==min(abs(timesteps_HR-t0)));
    
	%names={'WQ_NIT_AMM'; 'D'};
    tdat = tfv_readnetcdf(HRfile,'timestep',ind0);
    cdata1=tdat.WQ_NIT_AMM(surf_cellsHR)*14;
    d=tdat.D;
    cdata1(d<clip_depth)=NaN;
    
   %  clear tdat d;
    
   % x = [xlim(1) xlim(1) xlim(2) xlim(2)];
   % y = [ylim(1) ylim(2) ylim(2) ylim(1)];
   % [X1,Y1]=m_ll2xy(x,y);
   % vert(:,1)=X;vert(:,2)=Y;

    %m_patch(x,y,'red','FaceAlpha',.3);
   % F1 = fill(X1,Y1,[146, 116, 91]./255); %140,81,10
    hold on;

    tdatWQ = tdat; %tfv_readnetcdf(WQfile,'timestep',i);
    cell_X=tdatWQ.cell_X;
    cell_Y=tdatWQ.cell_Y;
    Fx = scatteredInterpolant(cell_X,cell_Y,double(tdatWQ.V_x(bottom_cellsWQ)));
    zzzx=Fx(xxxs,yyys);zzzx(~cell_inds)=NaN;
    xxxu=zzzx(1:intv:end,1:intv:end);
    Fy = scatteredInterpolant(cell_X,cell_Y,double(tdatWQ.V_y(bottom_cellsWQ)));
    zzzy=Fy(xxxs,yyys);zzzy(~cell_inds)=NaN;
    xxxv=zzzy(1:intv:end,1:intv:end);
    
    Fc = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
    zzzc=Fc(xxxs,yyys);zzzc(~cell_inds)=NaN;
    
    %patFig = patch('faces',facesHR,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    patFig=m_pcolor(xxxs,yyys,zzzc);shading interp;
    hold on;
    set(gca,'box','on');
    
   % trange=[0 5];
   % caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    %  axis off;
    %  axis equal;
    
    %  set(gca,'xlim',xlim,'ylim',ylim);
    
    cmap=colormap('jet');
    
    for cc=1 
      cmap(cc,:)=[0.8 0.8 0.8];
    end
    colormap(cmap);
    cb = colorbar;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    m_plot(line(:,1),line(:,2),'Color',[0.1 0.1 0.1],'LineWidth',2);
    hold on;
    %  set(cb,'position',[0.9 0.1 0.01 0.25],...
    %      'units','normalized','ycolor','k');
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    
    
    hq3=quiver(xxxx,yyyy,xxxu,xxxv);
    hold on;
    
    title('NH_4 (\mug/L)','color','k','fontsize',14);hold on;
     dim = [0.4 0.91 0.3 0.05];
     str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
     annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    gca=axes('Position',pos2);

    fluxT=flux.CSNS.mDate;
    plot(fluxT, flux.CSNS.NIT_amm,'k');
	hold on;
	
	t0=timesteps_WQ(i);
    ind0=find(abs(fluxT-t0)==min(abs(fluxT-t0)));
	plot([fluxT(ind0) fluxT(ind0)],[-3000 3000],'r','LineWidth',2);
	set(gca,'xlim',[t01 t1],'XTick',t01:7:t1,'XTickLabel',datestr(t0:7:t1,'dd/mmm'));
	set(gca,'ylim',[-3000 3000]);
     
                
    img_name =[img_dir,'/temp_',datestr(double(timesteps_WQ(i)),'yyyymmddHHMM'),'.png'];
    
    saveas(gcf,img_name);
    
    writeVideo(hvid,getframe(hfig));
    
end

close(hvid);