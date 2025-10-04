clear; close all;

% set up library path
%addpath(genpath('.\aed-marvl\'))

% model output file and read in mesh
ncfile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\csiem_v1_A001_20211101_20221231_WQ_lowRes_MACT1_check_WQ.nc';

dat = tfv_readnetcdf(ncfile,'time',1);
timesteps = dat.Time;

dat = tfv_readnetcdf(ncfile,'timestep',1);
clear funcions

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

%%

vars2animate='WQ_NIT_AMM';
data=ncread(ncfile,vars2animate);
%set plotting data range
d_range=[0 1];
%colormap winter
img_dir = ['.\animation_',vars2animate,'_noDischarge\'];

if ~exist(img_dir,'dir')
    mkdir(img_dir);
end

sim_name = [img_dir,'animation.avi'];

hvid = VideoWriter(sim_name);
set(hvid,'Quality',100);
set(hvid,'FrameRate',2);
framepar.resolution = [1024,768];

open(hvid);


% set which time slot to start and finish
t0=datenum('20220101 00:00','yyyymmdd HH:MM');
tt = find(abs(timesteps-t0)==min(abs(timesteps-t0)));
t1=datenum('20220201 00:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps-t1)==min(abs(timesteps-t1)));

% set animation time step
plot_interval=1;

%%
tdat = tfv_readnetcdf(ncfile,'timestep',tt);


hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 15.24]);


for i=tt:plot_interval:tt1
    
    disp(datestr(timesteps(i)));

    clf;
   % cdata = data(:,i);
    cdata = data(surf_cellsHR,i);
   %nd cdata = tdat.D;
    cdata(tdat.D<0.05)=NaN;
    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata);shading flat
    set(gca,'box','on');

    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    %   x_lim = get(gca,'xlim');
    %  y_lim = get(gca,'ylim');

    %clim(d_range);

    cb = colorbar;

    colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    
   % dim = [0.2 0.2 0.3 0.1];
    str = datestr(double(timesteps(i)),'yyyy/mm/dd HH:MM');
  %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none');
    title([regexprep(vars2animate,'_',' '),' - ', str],'color','k','fontsize',10);hold on;
    axis off;
    axis equal;
  % set(gca,'xlim',[115.663 115.7458],'ylim',[-32.1552 -32.037]);% 115.663 -32.1552 115.7458 -32.0374
  %  set(gca,'xlim',[115.6049 115.7771],'ylim',[-32.3051 -31.9793]);% 115.6049 -32.3051 115.7771 -31.9793

    img_name =[img_dir,'/snapshot_',datestr(double(timesteps(i)),'yyyymmddHHMM'),'.png'];
    
    saveas(gcf,img_name);
    
    writeVideo(hvid,getframe(hfig));
end

close(hvid);