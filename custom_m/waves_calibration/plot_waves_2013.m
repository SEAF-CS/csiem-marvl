clear; close all;

wwm=load('WWM_2013.mat');
awac=load('AWAC_2013.mat');

inDir='W:\csiem\Model\WAVES\WWM_SWAN_conversion\WWM_SWAN_CONV_Bgrid_all_years\';
infile=[inDir,'WWM_SWAN_CONV_Bgrid_2013.nc'];
time=ncread(infile,'time')/24+datenum(1990,1,1);
wwm.output.time=time;

%% plotting

hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 18]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

datearray=datenum(2013,1:3:13,1);

subplot(3,1,1);

plot(wwm.output.time, wwm.output.S01.Hs,'-','Color',color1);
hold on;

scatter(awac.output.S01.time, awac.output.S01.HS,sz,'filled','Color',color2);
hold on;

title('(a) Significant Wave Height');
ylabel('meters'); ylim([0 2]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));


subplot(3,1,2);

plot(wwm.output.time, wwm.output.S01.Dir,'-','Color',color1);
hold on;

scatter(awac.output.S01.time, awac.output.S01.DIR,sz,'filled','Color',color2);
hold on;
title('(b) Wave Direction');
ylabel('degrees'); ylim([0 360]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);

plot(wwm.output.time, wwm.output.S01.TP,'-','Color',color1);
hold on;

tmp=awac.output.S01.TPER; tmp(tmp<0)=NaN;
scatter(awac.output.S01.time, awac.output.S01.TPER,sz,'filled','Color',color2);
hold on;

title('(c) Wave Period');
ylabel('seconds'); ylim([0 30]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

img_name ='wave_calibration_timeseries_2013_S01.png';

saveas(gcf,img_name);

%% plotting

hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 18]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

datearray=datenum(2013,1:3:13,1);

subplot(3,1,1);

plot(wwm.output.time, wwm.output.S02.Hs,'-','Color',color1);
hold on;

scatter(awac.output.S02.time, awac.output.S02.HS,sz,'filled','Color',color2);
hold on;

title('(a) Significant Wave Height');
ylabel('meters'); ylim([0 2]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));


subplot(3,1,2);

plot(wwm.output.time, wwm.output.S02.Dir,'-','Color',color1);
hold on;

scatter(awac.output.S02.time, awac.output.S02.DIR,sz,'filled','Color',color2);
hold on;
title('(b) Wave Direction');
ylabel('degrees'); ylim([0 360]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);

plot(wwm.output.time, wwm.output.S02.TP,'-','Color',color1);
hold on;

tmp=awac.output.S02.TPER; tmp(tmp<0)=NaN;
scatter(awac.output.S02.time, awac.output.S02.TPER,sz,'filled','Color',color2);
hold on;

title('(c) Wave Period');
ylabel('seconds'); ylim([0 30]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

img_name ='wave_calibration_timeseries_2013_S02.png';

saveas(gcf,img_name);


%% plotting

hfig = figure('visible','on','position',[304         166        1271         612]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 12]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

datearray=datenum(2013,1:3:13,1);

subplot(1,2,1);

wwmint=interp1(wwm.output.time, wwm.output.S01.Hs,awac.output.S01.time);

scatter(wwmint, awac.output.S01.HS,sz,'filled','Color',color1);
title('(a) S01 - Wave Heights');
xlabel('WWM (m)'); ylabel('AWAC (m)'); 
axis equal; box on;
xlim([0 2]); ylim([0 2]);
hold on;
dlm = fitlm(wwmint, awac.output.S01.HS,'Intercept',false);
plot([0 2],[0 2]*dlm.Coefficients.Estimate,'r');
text(1.2,1.2,['y=', num2str(dlm.Coefficients.Estimate,'%4.4f'),'x'],'Color','r');

subplot(1,2,2);
wwmint2=interp1(wwm.output.time, wwm.output.S02.Hs,awac.output.S02.time);

scatter(wwmint2, awac.output.S02.HS,sz,'filled','Color',color1);
title('(b) S02 - Wave Heights');
xlabel('WWM (m)'); ylabel('AWAC (m)'); 
axis equal; box on;
xlim([0 2]); ylim([0 2]);
hold on;
dlm2 = fitlm(wwmint2, awac.output.S02.HS,'Intercept',false);
plot([0 2],[0 2]*dlm2.Coefficients.Estimate,'r');
text(1.2,1.2,['y=', num2str(dlm2.Coefficients.Estimate,'%4.4f'),'x'],'Color','r');

img_name ='wave_calibration_regression_2013.png';

saveas(gcf,img_name);