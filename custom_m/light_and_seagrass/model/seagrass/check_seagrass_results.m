%% This is a Matlab script for the seagrass dynamic model, only consider
%  the light limitation, e.g. no temperature, salinity, and sediment
%  nutrient limitation is included.
%
%  configurations: in Seagrass_model_config.m;
%  forcing data: surface PAR data at Cockburn Sound centre, exported
%                CSIEM model, then bottom PAR is calculated based on
%                pre-set water depth and extinction coefficient

clear; close all;

% load in configuration file
%run('.\Seagrass_model_config.m');

% load in light data
scenario='restart_08_nopollution_v2';
% fileDir='W:\csiem\Model\TFV\export\';
% load([fileDir,'extracted_bottom_totalight_2022_',scenario,'.mat']);
load('W:\csiem\Model\TFV\export\seagrass\restart_08_nopollution70s_v2\results2.mat');

outdir=['.\',scenario,'\'];
if ~exist(outdir,'dir')
    mkdir(outdir);
end

% load in model information
ncfile(1).name='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\tests_PH_map_light2_OASIM_WQ.nc';
tdat= tfv_readnetcdf(ncfile(1).name,'time',1);
PAR_time = tdat.Time;

allvars = tfv_infonetcdf(ncfile(1).name);
dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);

Surfcells=dat.idx3(dat.idx3 > 0);


%% ploting and checking

figure(1);
def.dimensions = [30 20]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

%dat = tfv_readnetcdf(ncfile,'timestep',1);

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;
faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

vars={'MAC_A','MAC_B','MAC_F','npp','resp','mort_A','mort_B','A_eff','f1','f2','f_tran','f_tran_fruit'};
clim1=[3e4     3e4     2e2    5e2    3e-6   1e2     2e1       1       1    1    1e1      1];
titles={'MAC_A','MAC_B','MAC_F','NPP','Resp','mort_A','mort_B','A_{eff}','f1','f2','f_{tran-BG}','f_{tran-fruit}'};
yls={'mmol C/m^2','mmol C/m^2','mmol C/m^2','mmol C/m^2/d','mmol C/m^2/d','mmol C/m^2/d','mmol C/m^2/d','-','-','-','mmol C/m^2/d','mmol C/m^2/d'};

for dd=1:100:length(PAR_time)

for vv=1:3 %length(vars)
    clf;
eval(['data1 = ',vars{vv},';']);

%colormap('parula');
patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',data1(:,dd));shading flat;
axis equal;
set(gca,'box','on');
hold on;

hl=colorbar;

str = [': ', datestr(double(PAR_time(dd)),'yyyy/mm/dd HH:MM')];
title([vars{vv}, ' at ', str]);
clim([0 clim1(vv)]);

img_name =[outdir,vars{vv},'_',datestr(double(PAR_time(dd)),'yyyymmddHHMM'),'.png'];
saveas(gcf,img_name);

end
end

%%

figure(2);
def.dimensions = [30 20]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

datearray=datenum(2022,1:4:13,1);
cell1 = 3240;
for vv=1:3 %length(vars)
    subplot(3,4,vv);
    eval(['data1 = ',vars{vv},';']);
    data2=data1(cell1,:);

    plot(PAR_time,data2);
    
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mm/yy'));

    set(gca,'FontName','Times New Roman');
    title(titles{vv});
    ylabel(yls{vv});
end

outputName=[outdir,'./site_output_cell1_restart.jpg'];
print(gcf,'-dpng',outputName);

%%

figure(2);
def.dimensions = [30 20]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

datearray=datenum(2022,1:4:13,1);
cell1 = 3243;
for vv=1:3 %length(vars)
    subplot(3,4,vv);
    eval(['data1 = ',vars{vv},';']);
    data2=data1(cell1,:);

    plot(PAR_time,data2);
    
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mm/yy'));

    set(gca,'FontName','Times New Roman');
    title(titles{vv});
    ylabel(yls{vv});
end

outputName=[outdir,'./site_output_cell2_restart.jpg'];
print(gcf,'-dpng',outputName);

