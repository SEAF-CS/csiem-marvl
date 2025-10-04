clear all;close all;

% define the exported mat files folder
scen='1p5';
% infolder0=['W:\csiem\csiem-marvl-dev\others\mat_export_CSIEM_ECO05\extracted_csiem1p5\CS-Region\'];
infolder0=['/Projects2/csiem/csiem-marvl-dev/custom/nutrient_budgeting/csiem1.5/mat_export/extracted_ECO05/CS-Region/'];


% pre-processed nodestring and groundwater daily flux file
fluxdata=load('./flux/saved_nodestring_flux_data_1p5.mat');
gwfluxdata=load('./flux/groundwater_influx_daily.mat');

% time and output folder
datearray=datenum(2023,1:3:13,1);
t1=datenum(2023,1,1);
t2=datenum(2024,1,1);
datess=datestr(datearray,'yyyymmdd');
%   t1=datenum(2019,1,1);t2=datenum(2020,1,1);
%   datess={'20190101','20190401','20190701','20191001','20200101'};
outputfolder='./Budget_CS_Phosphorus/';

if ~exist(outputfolder,'dir')
    mkdir(outputfolder);
end

infolder=infolder0;
disp(infolder);

% loading phosphorus vars

define_phosphorus_outputs;

readdata=0;

if readdata
    data=[];
    %    preprocessing_vars_nitrogen;

    Dtmp=load([infolder,'D.mat']);
    DD=Dtmp.savedata.D;
    % loop through the 3D and 2D variables to calculate the daily pools and fluxes
    D_lim=0.0401;
    data = cal_3D_pool_DD(data,infolder, NPool_3D,t1,t2,NPool_3D_factors,DD,D_lim);
    data = cal_2D_pool_DD(data,infolder, N_BGC_2D,t1,t2,N_BGC_2D_factors,DD,D_lim);
    data = cal_2D_pool_DD(data,infolder, NPool_2D,t1,t2,NPool_2D_factors,DD,D_lim);
   % data = cal_3D_pool_DD(data,infolder, N_BGC_3D,t1,t2,N_BGC_3D_factors,DD,D_lim);

    save([outputfolder,'data_BC_phosphorus',scen,'_DD.mat'],'data','-mat','-v7.3');

else
    load([outputfolder,'data_BC_phosphorus',scen,'_DD.mat']);
end
%% plotting

figure(1);
def.dimensions = [22.5 27]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

clf;

plh=0.14;hlh=0.05;
plw=0.64;hls=0.82;adj=0.025;
pos1=[0.1 0.84 plw plh];pos11=[hls 0.86+adj 0.10 hlh];
pos2=[0.1 0.65 plw plh];pos21=[hls 0.67+adj 0.10 hlh];
pos3=[0.1 0.46 plw plh];pos31=[hls 0.48+adj 0.10 hlh];
pos4=[0.1 0.27 plw plh];pos41=[hls 0.29+adj 0.10 hlh];
pos5=[0.1 0.08 plw plh];pos51=[hls 0.10+adj 0.10 hlh];

fs=14; fsl=9;
% panel 1: plot daily pools
axes('Position',pos1);

cc=data.(NPool_vars{1});

for ii=2:length(NPool_vars)
    cc=[cc;data.(NPool_vars{ii})];
end

hh = bar(t1:t2,cc',0.9,'stacked');
for jj=1:length(NPool_vars)
    hh(jj).FaceColor = NPool_colors(jj,:)/255;
end

set(gca,'xlim',[t1 t2]); %,'ylim',[0 2.5]);

datesv=datenum(datess,'yyyymmdd');
set(gca,'XTick',datesv,'XTickLabel',datestr(datesv,'mm-yy'));
xlabel('');ylabel({'phosphorus pools','(tonnes)'});
title('(a) phosphorus pools in water','FontWeight','Bold','FontSize',fs);
set(gca,'FontSize',9);
box on;grid on;

hl=legend(NPool_names);
set(hl,'Fontsize',fsl,'Position',pos11,'Interpreter','latex');


% panel 2: plot daily pools in benthic community
axes('Position',pos2);

cc=data.(NPool_benthic_vars{1});

for ii=2:length(NPool_benthic_vars)
    cc=[cc;data.(NPool_benthic_vars{ii})];
end

hh = bar(t1:t2,cc',0.9,'stacked');
for jj=1:length(NPool_benthic_vars)
    hh(jj).FaceColor = NPool_benthic_colors(jj,:)/255;
end

set(gca,'xlim',[t1 t2]); %,'ylim',[0 2.5]);

datesv=datenum(datess,'yyyymmdd');
set(gca,'XTick',datesv,'XTickLabel',datestr(datesv,'mm-yy'));
xlabel('');ylabel({'nitrogen pools','(tonnes)'});
title('(b) phosphorus pools in benthic communities','FontWeight','Bold','FontSize',fs);
set(gca,'FontSize',9);
box on;grid on;

hl=legend(NPool_benthic_names);
set(hl,'Fontsize',fsl,'Position',pos21,'Interpreter','latex');


% panel 3: plot sediment-water exchang fluxes
axes('Position',pos3);

cc=data.(N_BGC_vars{1})*N_BGC_signs(1);

for ii=2:length(N_BGC_vars)
    cc=[cc;data.(N_BGC_vars{ii})*N_BGC_signs(ii)];
end

hh = bar(t1:t2,cc',0.9,'stacked');
for jj=1:length(N_BGC_vars)
    hh(jj).FaceColor = N_BGC_colors(jj,:)/255;
end
% t1=datenum(2008,1,1);t2=datenum(2009,1,1);
set(gca,'xlim',[t1 t2]); %,'ylim',[0 0.3]);

datesv=datenum(datess,'yyyymmdd');
set(gca,'XTick',datesv,'XTickLabel',datestr(datesv,'mm-yy'));
title('(c) phosphorus fluxes at sediment-water interface (+ve: to water; -ve: to sediment)','FontWeight','Bold','FontSize',fs);
xlabel('');ylabel({'phosphorus fluxes','(tonnes/day)'});

set(gca,'FontSize',9);
box on;grid on;

hl=legend(N_BGC_names);
set(hl,'Fontsize',fsl,'Position',pos31,'Interpreter','latex');

% panel 4: boundary fluxes
axes('Position',pos4);

% IP: inorganic P; OP: organix P; PPP: primary producer P;
% Bound1,2,3 are the nodestrings
data.nsnetflux.IP=(fluxdata.data.CS_north.IP + fluxdata.data.CS_south.IP)*31/1e9;
data.nsnetflux.OP=(fluxdata.data.CS_north.OP + fluxdata.data.CS_south.OP)*31/1e9;
data.nsnetflux.PPP=(fluxdata.data.CS_north.PPP + fluxdata.data.CS_south.PPP)*31/1e9;
%data.nsnetflux.ZOOP=(fluxdata.data.CS_north.ZOOP + fluxdata.data.CS_south.ZOOP)*31/1e9;
data.nsnetflux.GW=(gwfluxdata.totalFlux.IP + gwfluxdata.totalFlux.OP)*31/1e9;

cc3=data.nsnetflux.(N_flux_names{1});

for ii=2:length(N_flux_names)
    cc3=[cc3;data.nsnetflux.(N_flux_names{ii})];
end

cc31=cc3;
cc32=cc3;

for mm=1:size(cc3,1)
    for nn=1:size(cc3,2)
        if cc3(mm,nn)>0
            cc31(mm,nn)=0;
        else
            cc32(mm,nn)=0;
        end
    end
end

hh1 = bar(t1:t2,cc31',0.9,'stacked');hold on;
hh2 = bar(t1:t2,cc32',0.9,'stacked');hold on;

for jj=1:length(N_flux_names)
    hh1(jj).FaceColor = N_flux_colors(jj,:)/255;
    hh2(jj).FaceColor = N_flux_colors(jj,:)/255;
end

%t1=datenum(2008,1,1);t2=datenum(2009,1,1);
set(gca,'xlim',[t1 t2]); %,'ylim',[-15 5]);

datesv=datenum(datess,'yyyymmdd');
set(gca,'XTick',datesv,'XTickLabel',datestr(datesv,'mm-yy'));
xlabel('');ylabel({'boundary fluxes','(tonnes/day)'});

title('(d) boundary exchange fluxes (+ve: in; -ve: out)','FontWeight','Bold','FontSize',fs);

set(gca,'FontSize',9);
box on;grid on;

hl=legend(N_flux_names2);
set(hl,'Fontsize',fsl,'Position',pos41,'Interpreter','latex');

% panel 5: changes in water and sediment
% NOTE: this script include the calculation of sediment changes by the sum
% of POP/DOP SWI and FRP DSF, but in reality the sediment changes are much
% more complicated including MPB/MAG/MAC burial, so sediment change is not
% included in the plot
axes('Position',pos5);

% total P in water
for ii=1:length(NPool_vars)
    if ii==1
        Twat=data.(NPool_vars{ii});
    else
        Twat=Twat+data.(NPool_vars{ii});
    end
end


% total boundary flux

% calculate total sediment diffusive exchange, denitrification, and burial
data.FRP_release=data.WQ_DIAG_PHS_FRP_DSF+data.WQ_DIAG_OGM_DOP_SWI+data.WQ_DIAG_OGM_POP_SWI;
%data.FRP_burial=data.WQ_DIAG_MAG_MAG_SWI_P+data.WQ_DIAG_PHY_PHY_SWI_P;
Ttran=data.nsnetflux.IP+data.nsnetflux.OP+data.nsnetflux.PPP;

% calculate daily changes in water and accumulative change in sediment
DeltaWat=zeros(size(Twat));
Sedacc=zeros(size(Twat));
for jj=2:length(Twat)
    DeltaWat(jj)=Twat(jj)-Twat(jj-1);
end

% daily change in sediment, calculated as residual of Total water - total boundary flux - diffusive release
DeltaSed=DeltaWat-Ttran-data.FRP_release; %
for jj=1:length(DeltaWat)
    if jj==1
        Watacc(jj)=DeltaWat(jj);
     %   Sedacc(jj)=DeltaSed(jj);
     %   Sedacc2(jj)=Tsed(jj);
        Tranacc(jj)=Ttran(jj);
        Releaseacc(jj)=data.FRP_release(jj);

    else
        Watacc(jj)=Watacc(jj-1)+DeltaWat(jj);
     %   Sedacc(jj)=Sedacc(jj-1)+DeltaSed(jj);
     %   Sedacc2(jj)=Sedacc2(jj-1)+Tsed(jj);
        Tranacc(jj)=Tranacc(jj-1)+Ttran(jj);
        Releaseacc(jj)=Releaseacc(jj-1)+data.FRP_release(jj);
    end
end

plot(t1:t2,Watacc,'Color',[67,162,202]./255);
hold on;
% plot(t1:t2,-(Sedacc+Releaseacc),'Color',[136,86,167]./255);
%plot(t1:t2,-(Sedacc2),'Color',[136,86,167]./255);
%plot(t1:t2,-Releaseacc,'Color',[136,86,167]./255);
%hold on;

set(gca,'xlim',[t1 t2]); %,'ylim',[-15 5]);

datesv=datenum(datess,'yyyymmdd');
set(gca,'XTick',datesv,'XTickLabel',datestr(datesv,'mm-yy'));
xlabel('');ylabel({'cumulative changes','(tonnes)'});
title('(e) cumulative change in water','FontWeight','Bold','FontSize',fs);
set(gca,'FontSize',9);
box on;grid on;

hl=legend('\deltaWater');
set(hl,'Fontsize',fsl,'Position',pos51);

% outputName=[outputfolder,'nutrient_budget_nitrogen_timeseries.png'];
outputName=[outputfolder,'budget_timeseries_V12.png'];
print(gcf,'-dpng',outputName);


save([outputfolder,'data_BC_phosphorus_DD_postprocessed.mat'],'data','Twat','DeltaWat','Ttran','-mat','-v7.3');
