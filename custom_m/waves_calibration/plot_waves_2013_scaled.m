clear; close all;

wwm=load('WWM_2013.mat');
awac=load('AWAC_2013.mat');

inDir='W:\csiem\Model\WAVES\WWM_SWAN_conversion\WWM_SWAN_CONV_Bgrid_all_years\';
infile=[inDir,'WWM_SWAN_CONV_Bgrid_2013.nc'];
time=ncread(infile,'time')/24+datenum(1990,1,1);
wwm.output.time=time;

%% plotting

hfig = figure('visible','on','position',[304         166        1271         812]*1.2);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 15]*1.2);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

datearray=datenum(2013,1:3:13,1);

subplot(3,1,1);

plot(wwm.output.time, wwm.output.S01.Hs,'-','Color',color1);
hold on;

plot(wwm.output.time, wwm.output.S01.Hs*0.5,'-','Color','k');
hold on;

scatter(awac.output.S01.time, awac.output.S01.HS,sz,'filled','Color',color2);
hold on;

title('(a) Significant Wave Height');
ylabel('meters'); ylim([0 2]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

ind11=find(abs(wwm.output.time-datearray(1))==min(abs(wwm.output.time-datearray(1))));
ind12=find(abs(wwm.output.time-datearray(end))==min(abs(wwm.output.time-datearray(end))));

ind21=find(abs(awac.output.S01.time-datearray(1))==min(abs(awac.output.S01.time-datearray(1))));
ind22=find(abs(awac.output.S01.time-datearray(end))==min(abs(awac.output.S01.time-datearray(end))));

rd1=interp1(wwm.output.time(ind11:ind12), wwm.output.S01.Hs(ind11:ind12)*0.5,awac.output.S01.time(ind21:ind22));
rd2=awac.output.S01.HS(ind21:ind22);
%rd2(rd2>0.4)=NaN;rd2(rd2<-0.4)=NaN;
%rd22=rd2(~isnan(rd2));
%rd12=rd1(~isnan(rd2));
[r,C]=regression(rd1,rd2,'one');
mae=abs(mean(rd1-rd2));

        str2{1}=['r = ',num2str(r,'%1.4f')];
        str2{2}=['MAE = ',num2str(mae,'%1.4f')];
        text(datenum(2013,11,1),1.7,str2);


subplot(3,1,2);

plot(wwm.output.time, wwm.output.S01.Dir,'-','Color',color1);
hold on;

plot(wwm.output.time, wwm.output.S01.Dir,'-','Color','k');
hold on;

scatter(awac.output.S01.time, awac.output.S01.DIR,sz,'filled','Color',color2);
hold on;
title('(b) Wave Direction');
ylabel('degrees'); ylim([0 360]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);

plot(wwm.output.time, wwm.output.S01.TP,'-','Color',color1);
hold on;

plot(wwm.output.time, wwm.output.S01.TP,'-','Color','k');
hold on;

tmp=awac.output.S01.TPER; tmp(tmp<0)=NaN;
scatter(awac.output.S01.time, awac.output.S01.TPER,sz,'filled','Color',color2);
hold on;

title('(c) Wave Period');
ylabel('seconds'); ylim([0 30]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

hl=legend('WWM','CSIEM','AWAC','Position',[0.4 0.03 0.2 0.03],'NumColumns',5);
set(hl,'Position')

img_name ='wave_calibration_timeseries_2013_S01_scaled.png';

saveas(gcf,img_name);

%% plotting

hfig = figure('visible','on','position',[304         166        1271         812]*1.2);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 15]*1.2);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

datearray=datenum(2013,1:3:13,1);

subplot(3,1,1);

plot(wwm.output.time, wwm.output.S02.Hs,'-','Color',color1);
hold on;

plot(wwm.output.time, wwm.output.S02.Hs*0.5,'-','Color','k');
hold on;

scatter(awac.output.S02.time, awac.output.S02.HS,sz,'filled','Color',color2);
hold on;

title('(a) Significant Wave Height');
ylabel('meters'); ylim([0 2]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));



ind11=find(abs(wwm.output.time-datearray(1))==min(abs(wwm.output.time-datearray(1))));
ind12=find(abs(wwm.output.time-datearray(end))==min(abs(wwm.output.time-datearray(end))));

ind21=find(abs(awac.output.S02.time-datearray(1))==min(abs(awac.output.S02.time-datearray(1))));
ind22=find(abs(awac.output.S02.time-datearray(end))==min(abs(awac.output.S02.time-datearray(end))));

rd1=interp1(wwm.output.time(ind11:ind12), wwm.output.S02.Hs(ind11:ind12)*0.5,awac.output.S02.time(ind21:ind22));
rd2=awac.output.S02.HS(ind21:ind22);
%rd2(rd2>0.4)=NaN;rd2(rd2<-0.4)=NaN;
%rd22=rd2(~isnan(rd2));
%rd12=rd1(~isnan(rd2));
[r,C]=regression(rd1,rd2,'one');
mae=abs(mean(rd1-rd2));

        str2{1}=['r = ',num2str(r,'%1.4f')];
        str2{2}=['MAE = ',num2str(mae,'%1.4f')];
        text(datenum(2013,11,1),1.7,str2);
        

subplot(3,1,2);

plot(wwm.output.time, wwm.output.S02.Dir,'-','Color',color1);
hold on;

plot(wwm.output.time, wwm.output.S02.Dir,'-','Color','k');
hold on;

scatter(awac.output.S02.time, awac.output.S02.DIR,sz,'filled','Color',color2);
hold on;
title('(b) Wave Direction');
ylabel('degrees'); ylim([0 360]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);

plot(wwm.output.time, wwm.output.S02.TP,'-','Color',color1);
hold on;

plot(wwm.output.time, wwm.output.S02.TP,'-','Color','k');
hold on;

tmp=awac.output.S02.TPER; tmp(tmp<0)=NaN;
scatter(awac.output.S02.time, awac.output.S02.TPER,sz,'filled','Color',color2);
hold on;

title('(c) Wave Period');
ylabel('seconds'); ylim([0 30]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

hl=legend('WWM','CSIEM','AWAC','Position',[0.4 0.03 0.2 0.03],'NumColumns',5);
set(hl,'Position')

img_name ='wave_calibration_timeseries_2013_S02_scaled.png';

saveas(gcf,img_name);


% %% plotting
% 
% hfig = figure('visible','on','position',[304         166        1271         612]);
% 
% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperUnits', 'centimeters');
% set(gcf,'paperposition',[0.635 6.35 20.32 12]);
% 
% color1=[50,136,189]/255;
% color2=[252,141,89]/255;
% sz=3;
% 
% datearray=datenum(2013,1:3:13,1);
% 
% subplot(1,2,1);
% 
% wwmint=interp1(wwm.output.time, wwm.output.S01.Hs,awac.output.S01.time);
% 
% scatter(wwmint, awac.output.S01.HS,sz,'filled','Color',color1);
% title('(a) S01 - Wave Heights');
% xlabel('WWM (m)'); ylabel('AWAC (m)'); 
% axis equal; box on;
% xlim([0 2]); ylim([0 2]);
% hold on;
% dlm = fitlm(wwmint, awac.output.S01.HS,'Intercept',false);
% plot([0 2],[0 2]*dlm.Coefficients.Estimate,'r');
% text(1.2,1.2,['y=', num2str(dlm.Coefficients.Estimate,'%4.4f'),'x'],'Color','r');
% 
% subplot(1,2,2);
% wwmint2=interp1(wwm.output.time, wwm.output.S02.Hs,awac.output.S02.time);
% 
% scatter(wwmint2, awac.output.S02.HS,sz,'filled','Color',color1);
% title('(b) S02 - Wave Heights');
% xlabel('WWM (m)'); ylabel('AWAC (m)'); 
% axis equal; box on;
% xlim([0 2]); ylim([0 2]);
% hold on;
% dlm2 = fitlm(wwmint2, awac.output.S02.HS,'Intercept',false);
% plot([0 2],[0 2]*dlm2.Coefficients.Estimate,'r');
% text(1.2,1.2,['y=', num2str(dlm2.Coefficients.Estimate,'%4.4f'),'x'],'Color','r');
% 
% img_name ='wave_calibration_regression_2013.png';
% 
% saveas(gcf,img_name);