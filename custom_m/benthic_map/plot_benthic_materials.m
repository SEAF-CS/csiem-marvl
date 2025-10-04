clear; close all;

shpfile1='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\model_runs\WQ_ocean_climatology\check\csiem_B009_20221101_20240401_WQ_mesh_check_R.shp';
shpfile2='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\gis_repo\2_benthic\materials\CSOA_Ranae_SGspp_merged_reorder.shp';
coastline_file='E:\light_and_seagrass\model\scenarios/GIS/Boundary.shp';
    
shp1=shaperead(shpfile1);
shp2=shaperead(shpfile2);
shp3=shaperead(coastline_file);

ncfile='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results\csiem_B009_20221101_20240401_WQ_WQ.nc';

dat = tfv_readnetcdf(ncfile,'timestep',1);

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);

Surfcells=dat.idx3(dat.idx3 > 0);

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

subplot(1,2,1);

for i=1:length(Bottcells)
    cdata1(i)=shp1(Bottcells(i)).Mat;
end
    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1');shading flat
    set(gca,'box','on');
   % trange=[0 10];
   % caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    colormap('jet');
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = [nams2{j},' (mmol C/m^3)'];
    %cbarrow;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;

    title('Model Material Types','color','k','fontsize',10);hold on;

    m_grid('box','fancy','tickdir','out');
    hold on;



     img_name ='./Benthic_map.jpg';
 saveas(gcf,img_name);