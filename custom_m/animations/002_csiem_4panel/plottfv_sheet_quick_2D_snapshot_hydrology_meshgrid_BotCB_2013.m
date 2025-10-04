clear ; close all;

inDir='W:\csiem\Model\TFV\Results_2013_B009\';

metfile=[inDir,'csiem_v1_B009_20130101_20131231_WQ_met.nc'];
wavefile=[inDir,'csiem_v1_B009_20130101_20131231_WQ_wave.nc'];
WQfile=[inDir,'csiem_v1_B009_20130101_20131231_WQ_WQ.nc'];

dat = tfv_readnetcdf(metfile,'time',1);
timesteps_met = dat.Time;

dat = tfv_readnetcdf(wavefile,'time',1);
timesteps_wave = dat.Time;

dat = tfv_readnetcdf(WQfile,'time',1);
timesteps_WQ = dat.Time;

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

img_dir = '.\meshgrid_2013\';

if ~exist(img_dir,'dir')
    mkdir(img_dir);
end

sim_name = [img_dir,'animation_uncompressed.avi'];

hvid = VideoWriter(sim_name,'Uncompressed AVI');
%set(hvid,'Quality',100);
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

% xlim=[115.6666  115.8];
% ylim=[-32.3000  -31.9];
xlim=[115.6000  115.8];
ylim=[-32.3000  -31.9];

m_proj('miller','lon',xlim,'lat',ylim);
hold on;

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
    
    t0=timesteps_WQ(i);
    ind0=find(abs(timesteps_met-t0)==min(abs(timesteps_met-t0)));
    
    tdat = tfv_readnetcdf(metfile,'timestep',ind0);
    Wx=tdat.W10_x;
    Wy=tdat.W10_y;
    cdata1=sqrt(Wx.^2+Wy.^2);

    Fx = scatteredInterpolant(cell_X,cell_Y,double(Wx));
    zzzx=Fx(xxx,yyy);zzzx(~cell_inds)=NaN;
    xxxu=zzzx(1:intv:end,1:intv:end);
    Fy = scatteredInterpolant(cell_X,cell_Y,double(Wy));
    zzzy=Fy(xxx,yyy);zzzy(~cell_inds)=NaN;
    xxxv=zzzy(1:intv:end,1:intv:end);
                    
    clear tdat;
    
    trange=[0 10];
    
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig0=m_pcolor(xxx,yyy,zzz);shading interp;
                        
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
    
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    colormap('jet');
    %cb = colorbar;
    %cbarrow;
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'Wind Speed (m/s)';
    
    hold on;
    hq0=quiver(xxxx,yyyy,xxxu,xxxv);
    
    colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    title({'Wind','Speeds'},'color','k','fontsize',10);hold on;
     dim = [0.4 0.94 0.3 0.05];
     str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
     annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    subplot(1,4,2);
    
    t0=timesteps_WQ(i);
    ind0=find(abs(timesteps_wave-t0)==min(abs(timesteps_wave-t0)));
    
    tdat = tfv_readnetcdf(wavefile,'timestep',ind0);
    %Wx=tdat.W10_x;
    %Wy=tdat.W10_y;
    cdata1=tdat.WVHT; %sqrt(Wx.^2+Wy.^2);
    
    %d=tdat.D;
    %cdata1(d<clip_depth)=NaN;
    
    clear tdat;
    
    trange=[0 3];
    
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig2=m_pcolor(xxx,yyy,zzz);shading interp;
    set(gca,'box','on');
    
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
    cb.Label.String = 'Wave Height (m)';
    hold on;

    title({'Significant','Wave Height'}','color','k','fontsize',10);hold on;
    
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    subplot(1,4,3);
    
    t0=timesteps_WQ(i);
    % ind0=find(abs(timesteps_wave-t0)==min(abs(timesteps_wave-t0)));
    
    tdat = tfv_readnetcdf(WQfile,'timestep',i);
    %Wx=tdat.W10_x;
    %Wy=tdat.W10_y;
    cdata1=tdat.SAL(surf_cells); %sqrt(Wx.^2+Wy.^2);
    
    d=tdat.D;
    cdata1(d<clip_depth)=NaN;
    
    Fx = scatteredInterpolant(cell_X,cell_Y,double(tdat.V_x(surf_cells)));
    zzzx=Fx(xxx,yyy);zzzx(~cell_inds)=NaN;
    xxxu=zzzx(1:intv:end,1:intv:end);
    Fy = scatteredInterpolant(cell_X,cell_Y,double(tdat.V_y(surf_cells)));
    zzzy=Fy(xxx,yyy);zzzy(~cell_inds)=NaN;
    xxxv=zzzy(1:intv:end,1:intv:end);
    
    clear tdat;
    
    trange=[34 36];
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
    patFig3=m_pcolor(xxx,yyy,zzz);shading interp;
    %patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    set(gca,'box','on');
    
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
    cb.Label.String = 'Salinity (PSU)';
    hold on;
    hq3=quiver(xxxx,yyyy,xxxu,xxxv);
        
   % cbarrow;

    title({'Surface','Salinity'},'color','k','fontsize',10);hold on;
    
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    subplot(1,4,4);
    
    % t0=timesteps_WQ(i);
    % ind0=find(abs(timesteps_wave-t0)==min(abs(timesteps_wave-t0)));
    
    tdat = tfv_readnetcdf(WQfile,'timestep',i);
    %Wx=tdat.W10_x;
    %Wy=tdat.W10_y;
    cdata1=tdat.TEMP(surf_cells); %sqrt(Wx.^2+Wy.^2);
    
    d=tdat.D;
    cdata1(d<clip_depth)=NaN;
    
    clear tdat;
    
    trange=[15 21];
    F = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
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
    
    colormap('jet');
    cb = colorbar('southoutside');
    P1=get(cb,'Position');
    set(cb,'Position',[P1(1) P1(2)-0.05 P1(3) P1(4)]);
    cb.Label.String = 'Temperature (^oC)';
    
    hold on;
        hq4=quiver(xxxx,yyyy,xxxu,xxxv);
  %  cbarrow;

    title({'Surface','Temperature'},'color','k','fontsize',10);hold on;
    
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    img_name =[img_dir,'/hydro_',datestr(double(timesteps_WQ(i)),'yyyymmddHHMM'),'.png'];
    
    saveas(gcf,img_name);
    
    writeVideo(hvid,getframe(hfig));
    
end

close(hvid);