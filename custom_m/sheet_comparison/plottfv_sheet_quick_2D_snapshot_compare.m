clear; close all;

% set up library path
%addpath(genpath('../../aed-marvl/'))

% model output file and read in mesh
%ncfile='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results\csiem_A001_20221101_20240401_ECO05_WQv1.nc';
%ncfile2='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results\csiem_A001_20221101_20240401_WQ_test_3round_WQv7.nc';
%ncfile2='/Projects2/csiem/model/csiem_model_tfvaed_1.6/outputs/results/csiem_A001_20221101_20240401_WQ_WQ.nc';

ncfile2='/Projects2/csiem/model/_archive_20250715/TFV/csiem_model_tfvaed_1.5_clean/outputs/results/final/AGrid/csiem_A001_20221101_20240401_WQ_WQ.nc';
ncfile='/Projects2/csiem/model/csiem_model_tfvaed_2.0/output_archive/results/csiem_A001_20221101_20240401_ECO_bivfb_WQ.nc';

scenario_name='csiem2.0';

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
% 
% vars2plot={'WQ_DIAG_VEG_LAI','WQ_DIAG_VEG_IG','WQ_DIAG_VEG_UG',...
%     'WQ_DIAG_VEG_RG','WQ_DIAG_VEG_RAINLOSS',...
%     'WQ_DIAG_VEG_SALTBUSH_COVER','WQ_DIAG_VEG_MANGROVE_COVER'};


% set which time slot to plot
t0=datenum('20230202 14:00','yyyymmdd HH:MM');
%t0=datenum('20221102 04:00','yyyymmdd HH:MM');
tt = find(abs(timesteps-t0)==min(abs(timesteps-t0)));

outdir = [scenario_name, '-',datestr(double(timesteps(tt)),'yyyymmddHHMMSS')];
mkdir(outdir);
%%
tdat = tfv_readnetcdf(ncfile,'timestep',tt);
tdat2 = tfv_readnetcdf(ncfile2,'timestep',tt);

vars=fieldnames(tdat);

hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 15.24])

for ii=21:length(vars)

     clf;

    subplot(1,2,1);
    cdata = tdat.(vars{ii})(bottom_cellsHR);
    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata);shading flat
    set(gca,'box','on');

    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');

    %   x_lim = get(gca,'xlim');
    %  y_lim = get(gca,'ylim');

    if strfind(vars{ii},'DEPTH')
      caxis([0 0.01]);

    end
    cb = colorbar;

    colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    
   % dim = [0.2 0.2 0.3 0.1];
    str = datestr(double(timesteps(tt)),'yyyy/mm/dd HH:MM');
  %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none');
    title([scenario_name, ' - ',regexprep(vars{ii},'_',' '),' - ', str],'color','k','fontsize',10);hold on;
    axis off;
    axis equal;

    if isfield(tdat2,vars{ii})

    subplot(1,2,2);
    cdata = tdat2.(vars{ii})(bottom_cellsHR);
    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata);shading flat
    set(gca,'box','on');

    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');

    %   x_lim = get(gca,'xlim');
    %  y_lim = get(gca,'ylim');

    if strfind(vars{ii},'DEPTH')
      caxis([0 0.01]);

    end
    cb = colorbar;

    colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    
   % dim = [0.2 0.2 0.3 0.1];
    str = datestr(double(timesteps(tt)),'yyyy/mm/dd HH:MM');
  %  annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none');
    title(['v7 - ',regexprep(vars{ii},'_',' '),' - ', str],'color','k','fontsize',10);hold on;
    axis off;
    axis equal;

    end

    img_name =[outdir,'/',vars{ii},'.png'];

    saveas(gcf,img_name);


end
