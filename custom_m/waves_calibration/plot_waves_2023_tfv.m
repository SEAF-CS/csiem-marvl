clear; close all;

wwm=load('WWM_2023.mat');
awac=load('ADV_2023.mat');
tfv=load('TFV_waves_2023.mat');
tfvscale=load('TFV_waves_scale_2023.mat');

%% plotting

hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 18]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

datearray=datenum(2023,1:3:16,1);
%datearray=datenum(2023,7,1:31,1,1,1);
sitenames={'PB','SBA','SBB','PBA','PBB'};
sites={'PortBeach','SuccessBankA','SuccessBankB','ParmeliaBankA','ParmeliaBankB'};

for ss=1:length(sitenames)
    clf;

subplot(3,1,1);

plot(wwm.output.time, wwm.output.(sitenames{ss}).Hs,'-','Color',color1);
hold on;

plot(tfv.output.(sitenames{ss}).WVHT.Date/24+datenum(1990,1,1), tfv.output.(sitenames{ss}).WVHT.Data,'-','Color','m');
hold on;

plot(tfvscale.output.(sitenames{ss}).WVHT.Date/24+datenum(1990,1,1), tfvscale.output.(sitenames{ss}).WVHT.Data,'-','Color','k');
hold on;

scatter(awac.output.(sites{ss}).time, awac.output.(sites{ss}).HS,sz,'filled','Color',color2);
hold on;grid on;

title('(a) Significant Wave Height');
ylabel('meters'); ylim([0 3]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));


subplot(3,1,2);

plot(wwm.output.time, wwm.output.(sitenames{ss}).Dir,'-','Color',color1);
hold on;

plot(tfv.output.(sitenames{ss}).WVDIR.Date/24+datenum(1990,1,1), tfv.output.(sitenames{ss}).WVDIR.Data,'-','Color','m');
hold on;

plot(tfvscale.output.(sitenames{ss}).WVDIR.Date/24+datenum(1990,1,1), tfvscale.output.(sitenames{ss}).WVDIR.Data,'-','Color','k');
hold on;

scatter(awac.output.(sites{ss}).time, awac.output.(sites{ss}).DIRmean,sz,'filled','Color',color2);
hold on;
title('(b) Wave Direction');
ylabel('degrees'); ylim([0 360]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);

plot(wwm.output.time, wwm.output.(sitenames{ss}).TP,'-','Color',color1);
hold on;

plot(tfv.output.(sitenames{ss}).WVPER.Date/24+datenum(1990,1,1), tfv.output.(sitenames{ss}).WVPER.Data,'-','Color','m');
hold on;

plot(tfvscale.output.(sitenames{ss}).WVPER.Date/24+datenum(1990,1,1), tfvscale.output.(sitenames{ss}).WVPER.Data,'-','Color','k');
hold on;

%tmp=awac.output.S01.TPER; tmp(tmp<0)=NaN;
scatter(awac.output.(sites{ss}).time, awac.output.(sites{ss}).TPERpeak,sz,'filled','Color',color2);
hold on;

title('(c) Wave Period');
ylabel('seconds'); ylim([0 30]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

hl=legend('WWM','TFV','TFV scaled','ADV','Position',[0.3 0.03 0.2 0.03],'NumColumns',5);
set(hl,'Position')

img_name =['wave_tfv_calibration_timeseries_2023_',sitenames{ss},'.png'];

saveas(gcf,img_name);

end

