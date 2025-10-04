clear all; close all;

load Flux_CSIEM_1p5.mat;

ncfile = 'W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results/csiem_A001_20221101_20240401_WQ_test_3round_WQv7.nc';
dat = tfv_readnetcdf(ncfile,'timestep',1);

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);
Surfcells=dat.idx3(dat.idx3 > 0);

readdata=0;

if readdata
Vx01=ncread(ncfile,'V_y');
Vx02=Vx01(Surfcells,:);
cellID=2300;
Vx=Vx02(cellID,:);

tdat = tfv_readnetcdf(ncfile,'time',1);
time=tdat.Time;

save('processed_vy_north.mat','Vx','time','-mat','-v7.3');
else
load('processed_vy_north.mat');
end


%%
hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 30.32 20]);
datearray=datenum(2023,1,1:5:21);

yyaxis left;
%plot(flux.CS_shelf.mDate,-flux.CS_shelf.Flow);
%hold on;
plot(flux.CS_north.mDate,-flux.CS_north.Flow);
hold on;
plot(flux.CS_north.mDate,flux.CS_north.Flow*0);
hold on;
ylim([-5000 5000])

yyaxis right;
plot(time,Vx);
ylim([-0.2 0.2])

set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'));

legend('NC-north','zero','Vy');

img_name ='check_nodestring_CSnorth.png';

saveas(gcf,img_name);


