clear; close all;

wwm=load('.\extracted_for_Jeff_AED_2013.mat');
awac=load('.\AWAC_currents_2013.mat');

%% plotting

hfig = figure('visible','on','position',[304         166        1271         612]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 12]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;
% 
 datearray=datenum(2013,1:4,1);
 dstr='Jan_Mar';
% sitenames={'PB','SBA','SBB','PBA','PBB'};
% sites={'PortBeach','SuccessBankA','SuccessBankB','ParmeliaBankA','ParmeliaBankB'};

subplot(2,1,1);

Vx=wwm.output.S01.V_x;
pcolor(Vx.date, Vx.depths, Vx.profile); shading interp;
%plot(wwm.output.(sitenames{ss}).V_x.date, wwm.output.(sitenames{ss}).V_x.bottom,'-','Color',color1);
hold on;
caxis([-0.15 0.15]);
% 
% scatter(awac.output.(sites{ss}).time+16/24, awac.output.(sites{ss}).Ux,sz,'filled','Color',color2);
% hold on;

title('(a) Eastern Currents - Modelled');
ylabel('depth (m)'); ylim([-12 3]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'dd/mmm/yyyy'));
colorbar;

subplot(2,1,2);

VxA=awac.output.S01;

pcolor(VxA.time, VxA.zcell(9:end),VxA.V_x(9:end,:));shading interp;
hold on;

title('(b) Eastern Currents - AWAC');
ylabel('depth (m)'); ylim([-12 3]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'dd/mmm/yyyy'));
caxis([-0.15 0.15]);
colorbar;

%hl=legend('CSIEM','ADV','Position',[0.4 0.03 0.2 0.03],'NumColumns',2);
%set(hl,'Position')

img_name =['currents_profile_',dstr,'_2013_S01_Vx.png'];

saveas(gcf,img_name);


%% plotting

hfig = figure('visible','on','position',[304         166        1271         612]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 12]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;
% 
% datearray=datenum(2013,1,1:10:91);
% sitenames={'PB','SBA','SBB','PBA','PBB'};
% sites={'PortBeach','SuccessBankA','SuccessBankB','ParmeliaBankA','ParmeliaBankB'};

subplot(2,1,1);

Vx=wwm.output.S01.V_y;
pcolor(Vx.date, Vx.depths, Vx.profile); shading interp;
%plot(wwm.output.(sitenames{ss}).V_x.date, wwm.output.(sitenames{ss}).V_x.bottom,'-','Color',color1);
hold on;
caxis([-0.25 0.25]);
% 
% scatter(awac.output.(sites{ss}).time+16/24, awac.output.(sites{ss}).Ux,sz,'filled','Color',color2);
% hold on;

title('(a) Northern Currents - Modelled');
ylabel('depth (m)'); ylim([-12 3]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'dd/mmm/yyyy'));
colorbar;

subplot(2,1,2);

VxA=awac.output.S01;

pcolor(VxA.time, VxA.zcell(9:end),VxA.V_y(9:end,:));shading interp;
hold on;

title('(b) Northern Currents - AWAC');
ylabel('depth (m)'); ylim([-12 3]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'dd/mmm/yyyy'));
caxis([-0.25 0.25]);
colorbar;

%hl=legend('CSIEM','ADV','Position',[0.4 0.03 0.2 0.03],'NumColumns',2);
%set(hl,'Position')

img_name =['currents_profile_',dstr,'_2013_S01_Vy.png'];

saveas(gcf,img_name);