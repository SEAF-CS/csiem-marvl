clear; close all;

Sori=load('E:\light_and_seagrass\model\seagrass\restart_08_nopollution70s_v2\results2.mat');
Sdredge=load('E:\light_and_seagrass\model\seagrass\restart_08_pollution70s\results2.mat');


ncfile='W:/csiem/Model/TFV/csiem_model_tfvaed_1.1/outputs/results/tests_PH_map_light2_OASIM_restart_08_WQ.nc';

dat = tfv_readnetcdf(ncfile,'time',1);
timesteps = dat.Time;
t0=datenum(2023,1,1);
tt0=find(abs(timesteps-t0)==min(abs(timesteps-t0)));

dat = tfv_readnetcdf(ncfile,'timestep',1);
vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

coastline_file='./GIS/Boundary.shp';
    shp2=shaperead(coastline_file);
%    cell_inds=inpolygon(xxx,yyy,shp2.X,shp2.Y);

%%

hfig = figure('visible','on','position',[304         166         1200        675]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 24 13.5]);


xlim=[115.6000  115.8];
ylim=[-32.3000  -31.9];

m_proj('miller','lon',xlim,'lat',ylim);
hold on;
LONG=vert(:,1);LAT=vert(:,2);
[X,Y]=m_ll2xy(LONG,LAT);
vert(:,1)=X;vert(:,2)=Y;

subplot(1,4,1);

    cdata1=Sori.MAC_A(:,1)/1000;
  %  d=tdat.D;
  %  cdata1(d<clip_depth)=NaN;

    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
    trange=[0 25];
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    colormap('jet');
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'MAC_A (mol C/m^2)';
    %cbarrow;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title('Initial biomass','color','k','fontsize',10);hold on;
   %  dim = [0.4 0.91 0.3 0.05];
   %  str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
   %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;

    subplot(1,4,2);

    cdata11=Sori.MAC_A(:,tt0)/1000;
  %  d=tdat.D;
  %  cdata1(d<clip_depth)=NaN;

    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata11);shading flat
    set(gca,'box','on');
   % trange=[0 25000];
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    colormap('jet');
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'MAC_A (mol C/m^2)';
    %cbarrow;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title('Final biomass (1960s)','color','k','fontsize',10);hold on;
   %  dim = [0.4 0.91 0.3 0.05];
   %  str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
   %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;

    subplot(1,4,3);

    cdata12=Sdredge.MAC_A(:,tt0)/1000;
  %  d=tdat.D;
  %  cdata1(d<clip_depth)=NaN;

    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata12);shading flat
    set(gca,'box','on');
   % trange=[0 25000];
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    colormap('jet');
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'MAC_A (mol C/m^2)';
    %cbarrow;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title('Final biomass (1970s)','color','k','fontsize',10);hold on;
   %  dim = [0.4 0.91 0.3 0.05];
   %  str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
   %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;

   ax4= subplot(1,4,4);

    cdata13=cdata12-cdata11;
  %  d=tdat.D;
  %  cdata1(d<clip_depth)=NaN;

    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata13);shading flat
    set(gca,'box','on');
    trange=[-5 0];
    caxis(trange);
    colormap(ax4,summer);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
   % colormap('jet');
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = '\DeltaMAC_A (mol C/m^2)';
    %cbarrow;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title('Biomass change','color','k','fontsize',10);hold on;
   %  dim = [0.4 0.91 0.3 0.05];
   %  str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
   %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;

     img_name =['./compare_pollution_scenarios_seagrass_biomass_',...
         datestr(timesteps(tt0),'yyyymmdd'),'.jpg'];
 saveas(gcf,img_name);