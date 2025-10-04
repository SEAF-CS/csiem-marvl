clear; close all;

model=load('.\restart_08\results2.mat');
ncfile(1).name='W:/csiem/Model/TFV/csiem_model_tfvaed_1.1/outputs/results/tests_PH_map_light2_OASIM_restart_08_nopollution70s_v2_WQ.nc';
disp(ncfile(1).name);

 dat = tfv_readnetcdf(ncfile.name,'time',1);
 timesteps = dat.Time;
 t0=datenum('20220101 00:00','yyyymmdd HH:MM');
tt = find(abs(timesteps-t0)==min(abs(timesteps-t0)));
disp(datestr(timesteps(tt)));

t1=datenum('20230101 00:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps-t1)==min(abs(timesteps-t1)));
disp(datestr(timesteps(tt1)));

allvars = tfv_infonetcdf(ncfile(1).name);
dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);

Surfcells=dat.idx3(dat.idx3 > 0);
depths=dat.cell_Zb;

cellID=[3243 3241 3240];
depths=[1.5 3.6 7.1];
factors=[86400 1/1000 1/1000 1/1000];

%%
hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 20.32*1.2 8.24*1.2]);

vars={'kI','MAC_A','MAC_B','MAC_F'};
titles={'(a) photon captured','(b) above-ground biomass','(c) below-ground biomass','(d) fruit biomass'};
yls={'\mumol photon/m^2/day','mol C/m^2','mol C/m^2','mol C/m^2'};
ylims=[80 30 30 2];
time=model.PAR_time;
datearray=datenum(2022,1:3:13,1);

for i=1:length(vars)
    subplot(2,2,i);

    for j=1:length(cellID)
        tmpdata=model.(vars{i})(cellID(j),:)*factors(i);
        if i==1
            tmpdata=movmean(tmpdata,6);
            tmpdata(1:6)=tmpdata(6:11);
        end


        plot(time,tmpdata);
        hold on;
    end

    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'));
    set(gca,'ylim',[0 ylims(i)]);
    title(titles{i});
    ylabel(yls{i});
end

hl=legend('1.5 m','3.6 m','7.1 m');
set(hl,'Position',[0.94 0.65 0.03 0.1])
outputName='./seagrass-results.jpg';
print(gcf,'-dpng',outputName);




