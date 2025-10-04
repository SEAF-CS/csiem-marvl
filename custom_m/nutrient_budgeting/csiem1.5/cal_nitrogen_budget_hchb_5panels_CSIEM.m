clear;close all;

% define the exported mat files folder
scen='1p5';
% infolder0=['W:\csiem\csiem-marvl-dev\others\mat_export_CSIEM_ECO05\extracted_csiem1p5\CS-Region\'];
infolder0=['/Projects2/csiem/csiem-marvl-dev/custom/nutrient_budgeting/csiem1.5/mat_export/extracted_ECO05/CS-Region/'];
% pre-processed nodestring and groundwater daily flux file
fluxdata=load('./flux/saved_nodestring_flux_data_1p5.mat');
gwfluxdata=load('./flux/groundwater_influx_daily.mat');

% time and output folder
% datearray=datenum(2023,1:3:13,1);
% t1=datenum(2023,1,1);
% t2=datenum(2024,1,1);
datearray=datenum(2021,1:3:13,1);
t1=datenum(2021,1,1);
t2=datenum(2022,1,1);
datess=datestr(datearray,'yyyymmdd');

outputfolder='./Budget_CS_Nitrogen/';

if ~exist(outputfolder,'dir')
    mkdir(outputfolder);
end

infolder=infolder0;
disp(infolder);

%% loading nitrogen vars
define_nitrogen_outputs;

readdata=0;

if readdata
    data=[];

    Dtmp=load([infolder,'D.mat']);
    DD=Dtmp.savedata.D;
    % loop through the 3D and 2D variables to calculate the daily pools and fluxes
    D_lim=0.0501;
    data = cal_3D_pool_DD(data,infolder, NPool_3D,t1,t2,NPool_3D_factors,DD,D_lim);
    data = cal_2D_pool_DD(data,infolder, N_BGC_2D,t1,t2,N_BGC_2D_factors,DD,D_lim);
    data = cal_2D_pool_DD(data,infolder, NPool_2D,t1,t2,NPool_2D_factors,DD,D_lim);
    %data = cal_3D_pool_DD(data,infolder, N_BGC_3D,t1,t2,N_BGC_3D_factors,DD,D_lim);

    save([outputfolder,'data_BC_nitrogen',scen,'_DD.mat'],'data','-mat','-v7.3');

else
    load([outputfolder,'data_BC_nitrogen',scen,'_DD.mat']);
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

% panel 1: plot daily pools in water column
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
xlabel('');ylabel({'nitrogen pools','(tonnes)'});
title('(a) nitrogen pools in water','FontWeight','Bold','FontSize',fs);
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
title('(b) nitrogen pools in benthic communities','FontWeight','Bold','FontSize',fs);
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
title('(c) nitrogen fluxes at sediment-water interface (+ve: to water; -ve: to sediment)','FontWeight','Bold','FontSize',fs);
xlabel('');ylabel({'nitrogen fluxes','(tonnes/day)'});

set(gca,'FontSize',9);
box on;grid on;

hl=legend(N_BGC_names);
set(hl,'Fontsize',fsl,'Position',pos31,'Interpreter','latex');

% panel 4: boundary fluxes
axes('Position',pos4);

% IN: inorganic N; ON: organix N; PPN: primary producer N;
% Bound1,2,3 are the nodestrings
data.nsnetflux.IN=(fluxdata.data.CS_north.IN + fluxdata.data.CS_south.IN)*14/1e9;
data.nsnetflux.ON=(fluxdata.data.CS_north.ON + fluxdata.data.CS_south.ON)*14/1e9;
data.nsnetflux.PPN=(fluxdata.data.CS_north.PPN + fluxdata.data.CS_south.PPN)*14/1e9;
%data.nsnetflux.ZOON=(fluxdata.data.CS_north.ZOON + fluxdata.data.CS_south.ZOON)*14/1e9;
data.nsnetflux.GW=(gwfluxdata.totalFlux.IN + gwfluxdata.totalFlux.ON)*14/1e9;


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
axes('Position',pos5);

% total N in water
for ii=1:length(NPool_vars)
    if ii==1
        Twat=data.(NPool_vars{ii});
    else
        Twat=Twat+data.(NPool_vars{ii});
    end
end

% total boundary flux
Ttran=data.nsnetflux.IN+data.nsnetflux.ON+data.nsnetflux.PPN ...
    +data.nsnetflux.GW;

% calculate daily changes in water and accumulative change in sediment
DeltaWat=zeros(size(Twat));
Sedacc=zeros(size(Twat));
for jj=2:length(Twat)
    DeltaWat(jj)=Twat(jj)-Twat(jj-1);
end

% panel 5: changes in water and sediment
% NOTE: this script include the calculation of sediment changes by the sum
% of PON/DON SWI and NIT/AMM DSF, but in reality the sediment changes are much
% more complicated including MPB/MAG/MAC burial, so sediment change is not
% included in the plot
data.NIT_release=data.WQ_DIAG_NIT_AMM_DSF+data.WQ_DIAG_NIT_NIT_DSF...
     +data.WQ_DIAG_OGM_DON_SWI+data.WQ_DIAG_OGM_PON_SWI;
% 
DeltaSed=DeltaWat+Ttran-data.NIT_release; %
% 
% cumulative changes with time
for jj=1:length(DeltaWat)
    if jj==1
        Watacc(jj)=DeltaWat(jj);
        % Sedacc(jj)=DeltaSed(jj);
        %   Sedacc2(jj)=Tsed(jj);
        % Tranacc(jj)=Ttran(jj);
        Releaseacc(jj)=data.NIT_release(jj);

    else
        Watacc(jj)=Watacc(jj-1)+DeltaWat(jj);
        % Sedacc(jj)=Sedacc(jj-1)+DeltaSed(jj);
        %   Sedacc2(jj)=Sedacc2(jj-1)+Tsed(jj);
        % Tranacc(jj)=Tranacc(jj-1)+Ttran(jj);
        Releaseacc(jj)=Releaseacc(jj-1)+data.NIT_release(jj);
    end
end

plot(t1:t2,Watacc,'Color',[67,162,202]./255);
hold on;
%plot(t1:t2,-(Sedacc+Releaseacc),'Color',[136,86,167]./255);
%plot(t1:t2,-Releaseacc,'Color',[136,86,167]./255);
%hold on;

set(gca,'xlim',[t1 t2]); 

datesv=datenum(datess,'yyyymmdd');
set(gca,'XTick',datesv,'XTickLabel',datestr(datesv,'mm-yy'));
xlabel('');ylabel({'cumulative changes','(tonnes)'});
title('(e) cumulative change in water','FontWeight','Bold','FontSize',fs);
set(gca,'FontSize',9);
box on;grid on;

hl=legend('\deltawater');
set(hl,'Fontsize',fsl,'Position',pos51);

outputName=[outputfolder,'nitrogen_budget_timeseries_V4.png'];
print(gcf,'-dpng',outputName);


save([outputfolder,'data_BC_nitrogen_DD_postprocessed.mat'],'data','Twat','DeltaWat','DeltaSed','Ttran','-mat','-v7.3');
