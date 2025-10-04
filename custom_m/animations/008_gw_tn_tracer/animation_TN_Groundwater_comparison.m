clear ; close all;

inDir='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\';

%metfile=[inDir,'csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_met.nc'];
%wavefile=[inDir,'csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_wave.nc'];
WQfile=[inDir,'results_GW_noND\csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_WQ.nc'];
WQfile2=[inDir,'results_noGW_ND\csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_noGW_WQ.nc'];

dat = tfv_readnetcdf(WQfile,'time',1);
timesteps_WQ = dat.Time;

dat2 = tfv_readnetcdf(WQfile2,'time',1);
timesteps_WQ2 = dat2.Time;

load cmap.mat;
%%

dat = tfv_readnetcdf(WQfile,'timestep',1);
clear funcions

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cells=dat.idx3(dat.idx3 > 0);
bottom_cells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cells(length(dat.idx3)) = length(dat.idx3);
clip_depth=0.05;

first_plot = 1;

img_dir = '.\animation_TN_GW\';

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

t0=datenum('20130701 00:00','yyyymmdd HH:MM');
tt = find(abs(timesteps_WQ-t0)==min(abs(timesteps_WQ-t0)));
t1=datenum('20130715 00:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps_WQ-t1)==min(abs(timesteps_WQ-t1)));
plot_interval=1;

xlim=[115.6000  115.8];
ylim=[-32.3000  -31.9];

cellInt=floor((xlim(2)-xlim(1))*1111111/500);
    XX=xlim(1):cellInt/1111111:xlim(2);
    YY=ylim(1):cellInt/1111111:ylim(2);
    [xxx,yyy]=meshgrid(XX,YY);
    cell_X=dat.cell_X;
    cell_Y=dat.cell_Y;
    
    [aa,bb]=m_ll2xy(xxx,yyy);
    xxxq=aa;yyyq=bb;
                    
    intv=round(size(xxxq,1)/50);
    xxxx=xxxq(1:intv:end,1:intv:end);
    yyyy=yyyq(1:intv:end,1:intv:end);
                    
    
    coastline_file='../GIS/Boundary.shp';
    shp2=shaperead(coastline_file);
    cell_inds=inpolygon(xxx,yyy,shp2.X,shp2.Y);

m_proj('miller','lon',xlim,'lat',ylim);
hold on;

LONG=vert(:,1);LAT=vert(:,2);
[X,Y]=m_ll2xy(LONG,LAT);
vert(:,1)=X;vert(:,2)=Y;

%         LONG=vert2(:,1);LAT=vert2(:,2);
%     [X,Y]=m_ll2xy(LONG,LAT);
%     vert2(:,1)=X;vert2(:,2)=Y;

for i=tt:plot_interval:tt1
    
    disp(datestr(timesteps_WQ(i)));
    clf;
    
   % if first_plot
    subplot(1,4,1);
    
   % t0=timesteps_WQ(i);
   % ind0=find(abs(timesteps_met-t0)==min(abs(timesteps_met-t0)));
    
    tdat = tfv_readnetcdf(WQfile,'timestep',i);
   % Wx=tdat.W10_x;
   % Wy=tdat.W10_y;
    cdata1=tdat.WQ_DIAG_TOT_TN(bottom_cells)*14; %sqrt(Wx.^2+Wy.^2);
    d=tdat.D;
    cdata1(d<clip_depth)=NaN;
    clear tdat;
    
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig0=m_pcolor(xxx,yyy,zzz);shading interp;
                        
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
    trange=[0 600];
    
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    %colormap('jet');
    colormap(cmap);
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'TN (\mugN/L)';
    %cbarrow;
    
    hold on;
   % hq0=quiver(xxxx,yyyy,xxxu,xxxv);
   % hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title('TN - with GW','color','k','fontsize',10);hold on;
     dim = [0.4 0.91 0.3 0.05];
     str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
     annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    subplot(1,4,2);
    
    t0=timesteps_WQ(i);
    ind0=find(abs(timesteps_WQ2-t0)==min(abs(timesteps_WQ2-t0)));
    
    tdat = tfv_readnetcdf(WQfile2,'timestep',ind0);
    %Wx=tdat.W10_x;
    %Wy=tdat.W10_y;
    cdata2=tdat.WQ_DIAG_TOT_TN(bottom_cells)*14; %sqrt(Wx.^2+Wy.^2);
    
    d=tdat.D;
    cdata2(d<clip_depth)=NaN;
    
    clear tdat;
    
    
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata2));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig2=m_pcolor(xxx,yyy,zzz);shading interp;
    set(gca,'box','on');
    trange=[0 600];
    
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
   % cmap=colormap('jet');
   % cmap(1,:)=[0.8 0.8 0.8];
    colormap(cmap);
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'TN (\mugN/L)';
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    %cbarrow;
    hold on;

    title('TN - no GW','color','k','fontsize',10);hold on;
    
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    subplot(1,4,3);
    
    %t0=timesteps_WQ(i);
    % ind0=find(abs(timesteps_wave-t0)==min(abs(timesteps_wave-t0)));
    
    %tdat = tfv_readnetcdf(WQfile,'timestep',i);
    %Wx=tdat.W10_x;
    %Wy=tdat.W10_y;
    cdata3=cdata1-cdata2; %tdat.SAL(surf_cells); %sqrt(Wx.^2+Wy.^2);
    
   % d=tdat.D;
    cdata3(d<clip_depth)=NaN;%cdata3(cdata3<0.1)=NaN;
        
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata3));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig3=m_pcolor(xxx,yyy,zzz);shading interp;
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
   
    trange=[0 200];
    
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
   % colormap('jet');
   colormap(cmap);
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'TN difference (\mugN/L)';

    hold on;
    
  %  hq3=quiver(xxxx,yyyy,xxxu,xxxv);
  %      hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
   % cbarrow;

    title('\DeltaTN (GW - no GW)','color','k','fontsize',10);hold on;
    
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    subplot(1,4,4);
    
    % t0=timesteps_WQ(i);
    % ind0=find(abs(timesteps_wave-t0)==min(abs(timesteps_wave-t0)));
    
    tdat = tfv_readnetcdf(WQfile,'timestep',i);
    %Wx=tdat.W10_x;
    %Wy=tdat.W10_y;
    cdata4=tdat.WQ_TRC_TR2(bottom_cells)*100; %sqrt(Wx.^2+Wy.^2);
    
    d=tdat.D;
    cdata4(d<clip_depth)=NaN;
   % cdata4(cdata4<0.0001)=NaN;
    clear tdat;
    
    trange=[0 0.5];
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata4));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig4=m_pcolor(xxx,yyy,zzz);shading interp;
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
   % colormap('jet');
   colormap(cmap);
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'GW tracer (%)';
    
    
    hold on;
  %  hq4=quiver(xxxx,yyyy,xxxu,xxxv);
  %  cbarrow;
hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    title('GW Tracer','color','k','fontsize',10);hold on;
    
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    img_name =[img_dir,'/hydro_',datestr(double(timesteps_WQ(i)),'yyyymmddHHMM'),'.png'];
    
    saveas(gcf,img_name);
    
    writeVideo(hvid,getframe(hfig));
    
end

close(hvid);