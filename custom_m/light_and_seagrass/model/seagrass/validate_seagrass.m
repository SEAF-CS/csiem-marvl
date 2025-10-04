clear; close all;

modelresult=load('.\restart_08\results2.mat');
fielddatafile='.\seagrass_data1.csv';
T=readtable(fielddatafile);
fdepth=T.depth;
fdata=T.biomass;

% 
%fielddatafile='..\..\field\seagrass biomass (version 1).xlsb.xlsx';
% [status,sheets,xlFormat] = xlsfinfo(fielddatafile);
% 
% fdepth=xlsread(fielddatafile,sheets{4},'E12:E37');
% fbiomass=xlsread(fielddatafile,sheets{4},'F12:F37');

ncfile.name='W:/csiem/Model/TFV/csiem_model_tfvaed_1.1/outputs/results/tests_PH_map_light2_OASIM_restart_08_WQ.nc';

dat = tfv_readnetcdf(ncfile.name,'time',1);
timesteps = dat.Time;

dat = tfv_readnetcdf(ncfile.name,'timestep',1);
clear funcions

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

shp=shaperead('W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\gis_repo\2_benthic\materials\CSOA_Ranae_SGspp_merged_reorder.shp');
cellx=dat.cell_X;
celly=dat.cell_Y;
zb=dat.cell_Zb;

inds=inpolygon(cellx,celly,shp(17).X,shp(17).Y);
inds2=find(inds>0);
Zb2=zb(inds);

d2p=1:2:9;

for d=1:length(d2p)
    d0=-d2p(d);

    newind=find(abs(Zb2-d0)==min(abs(Zb2-d0)));
    cell2p(d)=inds2(newind(1));
    depth2p(d)=zb(cell2p(d));
end

%% 
model=load('.\restart_08\results2.mat');
time=model.PAR_time;
t0=datenum(2022,3,1);
ts=find(abs(time-t0)==min(abs(time-t0)));
t1=datenum(2022,5,1);
tf=find(abs(time-t1)==min(abs(time-t1)));

depth_str={'0-2m','2-4m','4-6m','6-8m','8-10m'};
incT=1;

for c=1:length(cell2p)
    modeldata(c,:)=model.MAC_A(cell2p(c),1:6:end);
    tmp=model.MAC_A(cell2p(c),1:6:end);

    for j=1:length(tmp)
        plotdata.Source{incT}='modelled';
        plotdata.Site{incT}=depth_str{c};
        plotdata.Data(incT)=tmp(j)/1000;
        incT=incT+1;
    end
       
end

dints=0:2:10;

for dd=1:length(dints)-1
    tmpinds=find(fdepth>dints(dd) & fdepth<=dints(dd+1));
    for k=1:length(tmpinds)
        plotdata.Source{incT}='observed';
        plotdata.Site{incT}=depth_str{dd};
        plotdata.Data(incT)=10^(fdata(tmpinds(k)))*0.3/12*1000/1000;
        incT=incT+1;
    end
end

%%
hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 8.24]);

config.cattt=["0-2m","2-4m","4-6m","6-8m","8-10m"];
%config.cattt=["Tauwitchere","Long-Point","Parnka-Point","Stoney-Well","Jacks-Point","Snipe-Point"];
namesites=categorical(plotdata.Site,config.cattt);
hb= boxchart(namesites,plotdata.Data,'GroupByColor',plotdata.Source,'MarkerStyle','none');
hb(1).BoxWidth=0.5;
hb(2).BoxWidth=0.5;

set(gca,'ylim',[0 3e1]);
% set(gca,'XTickLabel',sitenames);
 ylabel({'Above-ground Biomass','(mol C/m^2)'});
 xlabel('Depth Range (m)');
 box on;
 hl=legend('modelled','observed','Location','Northeast');
 set(gca,'FontSize',12);
 
 img_name ='./boxchart_biomass_AB.jpg';
 saveas(gcf,img_name);
