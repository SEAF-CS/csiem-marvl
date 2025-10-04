clear; close all;

ESA=load('W:\csiem\csiem-marvl-dev\data\agency\csiem_ESA_bysite_public.mat');

data=ESA.csiem.ESA_GC_Polygon_3;
data2=ESA.csiem.ESA_GC_Point_11;
vars={'Diato','GREEN','Dino','PROKAR','HAPTO','PROCHLO','MICRO','NANO', 'PICO','WQ_DIAG_PHY_TCHLA'};
varnames={'Diatom','Green Algae','Dinoflagellates','Haptophytes','Prochlorococcus',...
    'Prokaryotes','Microplankton','Nanoplankton','Picoplankton','Total Chlorophyll-a'};

vars2={'WQ_PHY_DIATOM','WQ_PHY_MIXED','WQ_PHY_DINO','WQ_PHY_PICO'};


%%
ncfile(1).name='W:/csiem/Model/TFV/csiem_model_tfvaed_2.0/outputs/results/csiem_A001_20221101_20240401_WQ_WQ.nc';

allvars = tfv_infonetcdf(ncfile(1).name);

loadnames={'WQ_PHY_PICO','WQ_PHY_DIATOM','WQ_PHY_DINO','WQ_PHY_MIXED'};
sitenames={'IMOS','nearshore'};

dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);
Surfcells=dat.idx3(dat.idx3 > 0);

readdata=0;

if readdata


siteX=[data.Diato.Lon data2.Diato.Lon];
siteY=[data.Diato.Lat data2.Diato.Lat];

for t=1:length(sitenames)
    distx=cellx-siteX(t);
    disty=celly-siteY(t);
    distt=sqrt(distx.^2+disty.^2);
    
    inds=find(distt==min(distt));
    siteI(t)=inds(1);
    siteD(t)=dat.D(inds(1));
end


for ll=1:length(loadnames)
    loadname=loadnames{ll};
    tic;
    
  %  if ll>=9
  %  rawData=load_AED_vars(ncfile,2,loadname,allvars);
  %  else
        rawData=load_AED_vars(ncfile,1,loadname,allvars);
  %  end

  if size(rawData.data.(loadname),1)==length(dat.idx2)
      disp(['loading 3D ',loadname,' ...']);
    
    for site=1:length(sitenames)
        disp(sitenames{site});
             tmp = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,siteX(site),siteY(site),{loadname});
             output.(sitenames{site}).(loadname)=tmp;clear tmp;
    end
  else
      disp(['loading 2D ',loadname,' ...']);
    for site=1:length(sitenames)
        disp(sitenames{site});
        tmp = rawData.data.(loadname)(siteI(site),:);
          %   tmp = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,siteX(site),siteY(site),{loadname});
             output.(sitenames{site}).(loadname)=tmp;clear tmp;
    end
  end
    
    toc;
end


    outfile='extracted_PHYTO_2023.mat';
    save(outfile,'output','-mat','-v7.3');

else

    load('extracted_PHYTO_2023.mat');
end

%%

data.GREEN.Data=data.GREEN.Data+data.HAPTO.Data;
data.PROKAR.Data=data.PROKAR.Data+data.PROCHLO.Data;

data2.GREEN.Data=data2.GREEN.Data+data2.HAPTO.Data;
data2.PROKAR.Data=data2.PROKAR.Data+data2.PROCHLO.Data;
% 
% for v=1:4
%     if v==1
%         data.total=data.(vars{v}).Data;
%         data2.total=data2.(vars{v}).Data;
%     else
%         data.total=data.total+data.(vars{v}).Data;
%         data2.total=data2.total+data2.(vars{v}).Data;
%     end
% end
% 
% for v=1:4
%     rawdata=data.(vars{v}).Data./data.total;
%     timearray=data.(vars{v}).Date;
%     compos.(vars{v}) = create_monthly_climatology(timearray, rawdata);
% 
%     rawdata=data2.(vars{v}).Data./data2.total;
%     timearray=data2.(vars{v}).Date;
%     compos2.(vars{v})=create_monthly_climatology(timearray, rawdata);
% end
% 
% IMOS=load('..\..\datasets\processed_IMOS_udates_allvars.mat');
% DWER=load('..\..\datasets\processed_DWER_udates_allvars.mat');
% 
% rawdata=IMOS.dataout.WQ_DIAG_PHY_TCHLA.Data;
% timearray=IMOS.dataout.WQ_DIAG_PHY_TCHLA.Date;
% IMOSTCHLA=create_monthly_climatology(timearray, rawdata);
% 
% rawdata=DWER.dataout.WQ_DIAG_PHY_TCHLA.Data;
% timearray=DWER.dataout.WQ_DIAG_PHY_TCHLA.Date;
% DWERTCHLA=create_monthly_climatology(timearray, rawdata);
% 
% for v=1:4
%     final.(vars{v}) = IMOSTCHLA.data.*compos.(vars{v}).data;
%     final2.(vars{v}) = DWERTCHLA.data.*compos2.(vars{v}).data;
% end

%% Phytoplankton product information
% expressed as Chlorophyll a concentration in sea water
% (mg m-3), includes the following variables: DIATO
% (Diatoms), DINO (Dinophytes or Dinoflagellates), CRYPTO
% (Cryptophytes), GREEN (Green algae & Prochlorophytes)
% and PROKAR (Prokaryotes); MICRO (Micro-
% phytoplankton), NANO (Nano-phytoplankton) and PICO
% (Pico-phytoplankton) also known as “Phytoplankton Size
% Classes” (PSCs). MICRO consist of DIATO and DINO, NANO
% of CRYPTO and half of the GREEN group and PICO includes
% half GREEN and PROKAR. Note: the development of the
% algorithms applied for the PFT retrieval in this product is
% based on a different methodology than that used for the
% PFT estimate provided in other products (GLO and ATL).
% For more details see the relevant documentation

%% read data

hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 30.32 20]);
datearray=datenum(2023,1:3:13,1);
fac=[26 50 40 40];

%yyaxis left;
for v=1:4
    tmp=data.(vars{v}).Data;
    plotdata(v,:)=tmp;

    tmp2=data2.(vars{v}).Data;
    plotdata2(v,:)=tmp2;

    tmp3=output.IMOS.(vars2{v}).surface;
    plotdata3(v,:)=tmp3*12/fac(v);

    tmp4=output.nearshore.(vars2{v}).surface;
    plotdata4(v,:)=tmp4*12/fac(v);

end

colors=[228,26,28;...
55,126,184;...
77,175,74;...
152,78,163;...
255,127,0;...
255,255,51;...
166,86,40;...
247,129,191;...
153,153,153]./255;

wl=0.8;wd=0.36;ulim=5;

pos1=[0.1 0.58 wl wd];
pos2=[0.1 0.08 wl wd];
% pos3=[0.1 0.38 wl wd];
% pos4=[0.5 0.38 wl wd];
% pos5=[0.1 0.08 wl wd];
% pos6=[0.5 0.08 wl wd];
% pos7=[0.85 0.72 0.12 0.12];
% pos8=[0.85 0.43 0.12 0.06];
% pos9=[0.85 0.18 0.12 0.03];

%axes('Position',pos1);

subplot(2,2,1);

ha=area(data.(vars{v}).Date,plotdata','LineStyle','none');
colororder(colors)
hold on;


set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'yyyy'));
ylabel('Biomass (\mug CHLA/L)');
set(gca,'ylim',[0 2],'YTick',0:0.5:2,'YTickLabel',{'0.0','0.5','1.0','1.5','2.0'});
title('(a) ESA phytoplankton composition - IMOS offshore')
hl=legend('DIATOM','MIXED','DINO','PICO');

subplot(2,2,2);

ha=area(output.IMOS.(vars2{v}).date,plotdata3','LineStyle','none');
colororder(colors)
hold on;

set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'yyyy'));
ylabel('Biomass (\mug CHLA/L)');
set(gca,'ylim',[0 2],'YTick',0:0.5:2,'YTickLabel',{'0.0','0.5','1.0','1.5','2.0'});
title('(b) Modelled phytoplankton composition - IMOS offshore')
hl=legend('DIATOM','MIXED','DINO','PICO');

subplot(2,2,3);

ha=area(data2.(vars{v}).Date,plotdata2','LineStyle','none');
colororder(colors)
hold on;

set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'yyyy'));
ylabel('Biomass (\mug CHLA/L)');
set(gca,'ylim',[0 5],'YTick',0:1:5,'YTickLabel',{'0.0','0.5','1.0','1.5','2.0'});
title('(b) ESA phytoplankton composition - DWER nearshore')

hl=legend('DIATOM','MIXED','DINO','PICO');
%set(hl,'Position',pos9);

subplot(2,2,4);

ha=area(output.nearshore.(vars2{v}).date,plotdata4','LineStyle','none');
colororder(colors)
hold on;

set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'yyyy'));
ylabel('Biomass (\mug CHLA/L)');
set(gca,'ylim',[0 5],'YTick',0:1:5,'YTickLabel',{'0.0','0.5','1.0','1.5','2.0'});
title('(d) Modelled phytoplankton composition - DWER nearshore')
hl=legend('DIATOM','MIXED','DINO','PICO');

img_name ='Phytoplankton_composition_timeseries_2023.png';

saveas(gcf,img_name);
