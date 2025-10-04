clear; close all;

ncfile='W:/csiem/Model/TFV/csiem_model_tfvaed_2.0/outputs/results/csiem_A001_20221101_20240401_WQ_WQ.nc';

dat = tfv_readnetcdf(ncfile,'time',1);
timesteps = dat.Time;

dat = tfv_readnetcdf(ncfile,'timestep',1);
vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

coastline_file='E:\light_and_seagrass\model\scenarios/GIS/Boundary.shp';
    shp2=shaperead(coastline_file);
%    cell_inds=inpolygon(xxx,yyy,shp2.X,shp2.Y);
tmp=ncread(ncfile,'WQ_DIAG_MAC_MAC_AG');
output=tmp(bottom_cellsHR,:);

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

datestrings={'20230101','20230401','20230701','20231001','20240101'};
titles={'(a) Biomass: Jan-Mar', '(b) Biomass: Apr-Jun','(c) Biomass: Jul-Sep','(d) Biomass: Oct-Dec'};

for j=1:4
subplot(1,4,j);

    t0=datenum(datestrings{j},'yyyymmdd');
    tt0=find(abs(timesteps-t0)==min(abs(timesteps-t0)));
    t1=datenum(datestrings{j+1},'yyyymmdd');
    tt1=find(abs(timesteps-t1)==min(abs(timesteps-t1)));
    cdata1=mean(output(:,tt0:tt1),2)/1000;
  %  d=tdat.D;
  %  cdata1(d<clip_depth)=NaN;

    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
    trange=[0 12];
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

    %ls=[115.7169 -32.1425];  %[115.7085 -32.1537];  
    %le=[115.6965 -32.0591];
% 
%     ls=[115.7085 115.6966];
%     le=[-32.1537 -32.0486];
% 
%     m_plot([ls(1) le(1)],[ls(2) le(2)],'Color','r','LineWidth',2);
%     hold on;
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title(titles{j},'color','k','fontsize',10);hold on;
   %  dim = [0.4 0.91 0.3 0.05];
   %  str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
   %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;
end
     img_name ='./seagrass_biomass_series.jpg';
 saveas(gcf,img_name);