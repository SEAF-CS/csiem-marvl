clear; close all;

wwm=load('E:\CS_export\export_for_Jeff\extracted_for_Jeff_AED_2023.mat');
awac=load('..\waves\calibration\ADV_2023.mat');

%% plotting

hfig = figure('visible','on','position',[304         166        1271         612]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32 15]);

color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;
fs=12;

datearray=datenum(2023,1:3:16,1);
sitenames={'PB','SBA','SBB','PBA','PBB'};
sites={'PortBeach','SuccessBankA','SuccessBankB','ParmeliaBankA','ParmeliaBankB'};
sitesLong={'Port Beach','Success Bank A','Success Bank B','Parmelia Bank A','Parmelia Bank B'};

for ss=1:length(sitenames)
    clf;

subplot(2,1,1);

plot(wwm.output.(sitenames{ss}).V_x.date, wwm.output.(sitenames{ss}).V_x.bottom,'-','Color',color1);
hold on;

scatter(awac.output.(sites{ss}).time+16/24, awac.output.(sites{ss}).Ux,sz,'filled','Color',color2);
hold on;

title(['(a) Eastern Currents - ',sitesLong{ss}],'FontSize',fs);
ylabel('m/s'); ylim([-0.3 0.3]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));
set(gca,'FontSize',fs);

rd1=interp1(wwm.output.(sitenames{ss}).V_x.date, wwm.output.(sitenames{ss}).V_x.bottom,awac.output.(sites{ss}).time+16/24);
rd2=awac.output.(sites{ss}).Ux;
rd2(rd2>0.4)=NaN;rd2(rd2<-0.4)=NaN;
rd22=rd2(~isnan(rd2));
rd12=rd1(~isnan(rd2));
[r,C]=regression(rd12,rd22,'one');
        mae=abs(mean(rd12-rd22));

        str2{1}=['r = ',num2str(r,'%1.4f')];
        str2{2}=['MAE = ',num2str(mae,'%1.4f')];
        text(datenum(2024,1,1),0.2,str2);


subplot(2,1,2);

plot(wwm.output.(sitenames{ss}).V_y.date, wwm.output.(sitenames{ss}).V_y.bottom,'-','Color',color1);
hold on;

scatter(awac.output.(sites{ss}).time+16/24, awac.output.(sites{ss}).Uy,sz,'filled','Color',color2);
hold on;
title(['(b) Northern Currents - ',sitesLong{ss}],'FontSize',fs);
ylabel('m/s'); ylim([-0.5 0.5]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

rd1=interp1(wwm.output.(sitenames{ss}).V_y.date, wwm.output.(sitenames{ss}).V_y.bottom,awac.output.(sites{ss}).time+16/24);
rd2=awac.output.(sites{ss}).Uy;
rd2(rd2>0.4)=NaN;rd2(rd2<-0.4)=NaN;
rd22=rd2(~isnan(rd2));
rd12=rd1(~isnan(rd2));
[r,C]=regression(rd12,rd22,'one');
        mae=abs(mean(rd12-rd22));

        str2{1}=['r = ',num2str(r,'%1.4f')];
        str2{2}=['MAE = ',num2str(mae,'%1.4f')];
        text(datenum(2024,1,1),-0.3,str2);
set(gca,'FontSize',fs);

hl=legend('CSIEM','ADV','Position',[0.4 0.02 0.2 0.03],'NumColumns',2);
set(hl,'FontSize',fs);

img_name =['performance_currents_calibration_timeseries_2023_',sitenames{ss},'.png'];

saveas(gcf,img_name);

end

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
% for ss=1:length(sitenames)
% 
% subplot(2,3,ss);
% % 
% % plot(wwm.output.time, wwm.output.(sitenames{ss}).Hs,'-','Color',color1);
% % hold on;
% % 
% % scatter(awac.output.(sites{ss}).time, awac.output.(sites{ss}).HS,sz,'filled','Color',color2);
% % hold on;
% 
% wwmint=interp1(wwm.output.(sitenames{ss}).V_x.date, wwm.output.(sitenames{ss}).V_x.bottom,awac.output.(sites{ss}).time+16/24);
% 
% scatter(wwmint, awac.output.(sites{ss}).Ux,sz,'filled','Color',color1);
% title(sites{ss});
% xlabel('CSIEM V_x (m/s)'); ylabel('ADV V_x (m/s)'); 
% axis equal; box on;
% xlim([-0.2 0.2]); ylim([-0.2 0.2]);
% hold on;
% dlm = fitlm(wwmint, awac.output.(sites{ss}).Ux,'Intercept',false);
% plot([-0.2 0.2],[-0.2 0.2]*dlm.Coefficients.Estimate,'r');
% text(1.5,2.2,['y=', num2str(dlm.Coefficients.Estimate,'%4.4f'),'x'],'Color','r');
% 
% end
% img_name ='Eastern_Current_calibration_regression_2023.png';
% 
% saveas(gcf,img_name);

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
% for ss=1:length(sitenames)
% 
% subplot(2,3,ss);
% % 
% % plot(wwm.output.time, wwm.output.(sitenames{ss}).Hs,'-','Color',color1);
% % hold on;
% % 
% % scatter(awac.output.(sites{ss}).time, awac.output.(sites{ss}).HS,sz,'filled','Color',color2);
% % hold on;
% 
% wwmint=interp1(wwm.output.(sitenames{ss}).V_y.date, wwm.output.(sitenames{ss}).V_y.bottom,awac.output.(sites{ss}).time+16/24);
% 
% scatter(wwmint, awac.output.(sites{ss}).Uy,sz,'filled','Color',color1);
% title(sites{ss});
% xlabel('CSIEM V_y (m/s)'); ylabel('ADV V_y (m/s)'); 
% axis equal; box on;
% xlim([-0.3 0.3]); ylim([-0.3 0.3]);
% hold on;
% dlm = fitlm(wwmint, awac.output.(sites{ss}).Uy,'Intercept',false);
% plot([-0.3 0.3],[-0.3 0.3]*dlm.Coefficients.Estimate,'r');
% text(0.1,0.2,['y=', num2str(dlm.Coefficients.Estimate,'%4.4f'),'x'],'Color','r');
% 
% end
% img_name ='Northern_Current_calibration_regression_2023.png';
% 
% saveas(gcf,img_name);