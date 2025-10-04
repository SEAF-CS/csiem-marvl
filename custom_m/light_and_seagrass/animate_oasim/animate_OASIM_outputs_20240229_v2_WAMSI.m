clear; close all;
% 
outDir='.\Plots-20240918\';
if ~exist(outDir,'dir')
    mkdir(outDir);
end

def.datearray=datenum(2022,1,1):1:datenum(2022,1,5);

ncfile.name='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\tests_PH_map_light2_OASIM_restart_08_newBIN20240916_WQ.nc';


dat = tfv_readnetcdf(ncfile.name,'time',1);
timesteps = dat.Time;

dat = tfv_readnetcdf(ncfile.name,'timestep',1);
clear funcions

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

XX0=115.7225;YY0=-32.1824;
config.siteX=XX0;config.siteY=YY0;

xdist=dat.cell_X-XX0;ydist=dat.cell_Y-YY0;
tdist=sqrt(xdist.^2+ydist.^2);
cellind=find(abs(tdist)==min(abs(tdist)));

groups={'A','B','DIR','DIF','DIR_SF','DIF_SF'};
allvars = tfv_infonetcdf(ncfile(1).name);


%%

readdata=1;

if readdata
    %load('./export_light_data_profiles_all_20240226.mat');
    for vv=[239 251 256:length(allvars)]
        varname=allvars{vv};
        disp(varname);
        loadname=varname;
        rawData=load_AED_vars(ncfile,1,loadname,allvars);
        [rawData.data.(loadname),c_units,isConv]  = tfv_Unit_Conversion(rawData.data.(loadname),loadname);
        dataALL.(allvars{vv}) = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,config.siteX,config.siteY,{loadname});
        
    end
    
    save([outDir,'/export_light_data_profiles_all_20240916.mat'],'dataALL','-mat','-v7.3');
else
    
    load([outDir,'/export_light_data_profiles_all_20240916.mat']);
end

% %%
% 
profile_vars={'OAS_PAR','PHY_PAR','OAS_KD','OAS_KD_BAND3','TOT_EXTC'};
lineS_vars={'OAS_PAR','OAS_swr','OAS_secchi'};
lineB_vars={'OAS_par_sf','OAS_par_sf_w','OAS_swr_sf','OAS_swr_sf_w','OAS_swr_dif_sf','OAS_secchi'};

par_vars={'OAS_PAR','OAS_par_sf','OAS_par_sf_w'};
OAS_vars={'OAS_swr','OAS_swr_sf','OAS_swr_sf_w','OAS_swr_dif_sf'};



%%



sim_name = [outDir,'animation_new.avi'];

hvid = VideoWriter(sim_name,'Uncompressed AVI');
%set(hvid,'Quality',100);
set(hvid,'FrameRate',3);
framepar.resolution = [1024,768];
fs=8;
lambda_out = [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
lambda_range = [280 1100];
angle=90;

nlambda_w = 33;

a_w = [6.112000e-01, 7.620000e-02, 4.610000e-02, 1.820000e-02, 6.300000e-03, 5.100000e-03, 8.300000e-03, 1.190000e-02, 2.150000e-02, 4.070000e-02,...
      5.500000e-02, 8.490000e-02, 1.995000e-01, 2.850000e-01, 3.512000e-01, 4.559000e-01, 6.433000e-01, 1.444900e+00, 2.390000e+00, 3.738200e+00,...
      2.748050e+01, 1.934700e+01, 6.718000e+01, 9.499760e+01, 3.631256e+02, 1.118607e+03, 9.448757e+02, 5.195995e+02, 6.467179e+02, 3.768561e+03,...
      2.628083e+03, 4.376230e+05, 1.338404e+06];
  
b_w = [5.670000e-02, 1.870000e-02, 1.350000e-02, 1.000000e-02, 7.600000e-03, 5.800000e-03, 4.500000e-03, 3.600000e-03, 2.900000e-03, 2.300000e-03,...
      1.900000e-03, 1.600000e-03, 1.400000e-03, 1.200000e-03, 9.000000e-04, 7.000000e-04, 7.000000e-04, 6.000000e-04, 4.000000e-04, 2.000000e-04,...
      0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000e+00,...
      0.000000e+00, 0.000000e+00, 0.000000e+00];
lambda_w = [2.500000e+02, 3.250000e+02, 3.500000e+02, 3.750000e+02, 4.000000e+02, 4.250000e+02, 4.500000e+02, 4.750000e+02, 5.000000e+02, 5.250000e+02,...
      5.500000e+02, 5.750000e+02, 6.000000e+02, 6.250000e+02, 6.500000e+02, 6.750000e+02, 7.000000e+02, 7.250000e+02, 7.750000e+02, 8.500000e+02,...
      9.500000e+02, 1.050000e+03, 1.150000e+03, 1.250000e+03, 1.350000e+03, 1.450000e+03, 1.550000e+03, 1.650000e+03, 1.750000e+03, 1.900000e+03,...
      2.200000e+03, 2.900000e+03, 3.700000e+03];


open(hvid);

hfig = figure('visible','on','position',[304         166         1200        675]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 36 20.25]);

timesteps=dataALL.WQ_DIAG_OAS_A_BAND1.date;

load('WAMSI_light.mat');

newt=timesteps+datenum(2023,1,1)-datenum(2022,1,1);
WL2=[398 448 470 524 554 590 628 656 699];

for ww=1:length(WL2)
    tmpdata=WAMSI.(['WL_',num2str(WL2(ww)),'_uW']);
    WamsiData(:,ww)=interp1(tmpdata.Date,tmpdata.Data,newt)/100;
end

tmpPAR=WAMSI.PAR.Data;
tmpPAR2=tmpPAR*618.749/556874.1/4.6;
tmpPAR3=interp1(WAMSI.PAR.Date,tmpPAR2,newt);

t0=datenum('20220101 12:00','yyyymmdd HH:MM');
tt = find(abs(timesteps-t0)==min(abs(timesteps-t0)));
t1=datenum('20220106 12:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps-t1)==min(abs(timesteps-t1)));
plot_interval=1;

for i=tt+3:plot_interval:tt1
    
    disp(datestr(timesteps(i)));
    clf;
    
    subplot(3,2,1);
    
    for bb=1:16
        varname=upper(['WQ_DIAG_OAS_DIR_SF_BAND',num2str(bb)]);
        tmp=dataALL.(varname);
        plotdata4(1,bb)=tmp.bottom(i);
    end
    
    for bb=1:16
        varname=upper(['WQ_DIAG_OAS_DIF_SF_BAND',num2str(bb)]);
        tmp=dataALL.(varname);
        plotdata4(2,bb)=tmp.bottom(i);
    end
    
    plotdata4(:,1)=0;
    ha=area(lambda_out,plotdata4'); hold on;
    ha(1).FaceColor=[255,255,51]./255;
    ha(2).FaceColor=[255,127,0]./255;
    
    hl=legend('direct','diffuse');
    set(hl,'Location','northeast','FontSize',fs);
 %   xlabel('wave length')
    ylabel('E_{\lambda} (W/m^2/nm)')
    
    set(gca,'xlim',lambda_range,'XTick',lambda_out,'XTickLabel',{'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'});
    xtickangle(angle);
    set(gca,'ylim',[0 2]);
    title('(a) Incoming irradiance','FontSize',fs+4);
    
    subplot(3,2,3);
    
    for bb=1:16
        varname=upper(['WQ_DIAG_OAS_DIR_BAND',num2str(bb)]);
        tmp=dataALL.(varname);
        plotdata5(1,bb)=tmp.profile(3,i);
        plotdata5_02m(1,bb)=tmp.profile(2,i);
        plotdata5_5m(1,bb)=tmp.profile(9,i);
    end
    
    for bb=1:16
        varname=upper(['WQ_DIAG_OAS_DIF_BAND',num2str(bb)]);
        tmp=dataALL.(varname);
        plotdata5(2,bb)=tmp.profile(3,i);
        plotdata5_02m(2,bb)=tmp.profile(2,i);
        plotdata5_5m(2,bb)=tmp.profile(9,i);
    end
    
    
    ha=area(lambda_out,-plotdata5'); hold on;
    ha(1).FaceColor=[255,255,51]./255;
    ha(2).FaceColor=[255,127,0]./255;
    
    plot(lambda_out,-sum(plotdata5_02m,1),'--','Color',[55,126,184]./255);
    hold on;
    plot(lambda_out,-sum(plotdata5_5m,1),'--','Color',[37,37,37]./255);
    hold on;
    
    plot(WL2,-WamsiData(i,:),':','Color',[153,0,0]./255);
    hold on;
    
    dvec=datevec(timesteps(i));
    
%     hh=dvec(4);
%     
%     if hh>=6 && hh<=19
%     pdata1=-sum(plotdata5,1);[M1,I1] = min(pdata1);
%     pdata2=-sum(plotdata5_02m,1);[M2,I2] = min(pdata2);
%     pdata3=-sum(plotdata5_5m,1);[M3,I3] = min(pdata3);
%     
%     plot(lambda_out(I1),pdata1(I1),'o','LineWidth',2,...
%     'MarkerSize',10,...
%     'MarkerEdgeColor','k',...
%     'MarkerFaceColor',[255,127,0]./255); hold on;
% 
%     plot(lambda_out(I2),pdata2(I2),'o','LineWidth',2,...
%     'MarkerSize',10,...
%     'MarkerEdgeColor','k',...
%     'MarkerFaceColor',[55,126,184]./255); hold on;
%     
%     plot(lambda_out(I3),pdata3(I3),'o','LineWidth',2,...
%     'MarkerSize',10,...
%     'MarkerEdgeColor','k',...
%     'MarkerFaceColor',[37,37,37]./255); hold on;
%     end
%     
    
    hl=legend('direct @1m','diffuse @1m','dir+dif @0.2m','dir+dif @5m','WAMSI @5m');
    set(hl,'Location','southeast','FontSize',fs);
  %  xlabel('wave length')
    ylabel('E_{\lambda} (W/m^2/nm)')
    %legend({'IOP1','IOP2','IOP3','IOP4'});
    set(gca,'xlim',lambda_range,'XTick',lambda_out,'XTickLabel',{'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'});
    xtickangle(angle);
    set(gca,'ylim',[-2 0]);
    title('(b) Irradiance under water','FontSize',fs+4);
    
    subplot(3,2,5);
    
    for iop=1:4
        for bb=1:16
            varname=upper(['WQ_DIAG_OAS_A_IOP',num2str(iop),'_BAND',num2str(bb)]);
            tmp=dataALL.(varname);
            plotdata(iop,bb)=tmp.surface(i);
        end
    end
    
   % plotdata(3,:)=plotdata(3,:)/10;
    plotdataR(1,:)=plotdata(1,:);
    plotdataR(2,:)=plotdata(4,:);
    plotdataR(3,:)=plotdata(2,:);
    plotdataR(4,:)=plotdata(3,:);
    
    newcolors = [27,158,119;...
             55,126,184]./255;
         
    colororder(newcolors);
    yyaxis left;
    ha=area(lambda_out,plotdataR');
    
    ha(1).FaceColor=[27,120,55]./255;
    ha(2).FaceColor=[246,232,195]./255;
    ha(3).FaceColor=[135,135,135]./255;
    ha(4).FaceColor=[140,81,10]./255;    
    
    
    xlabel('wave length (nm)')
    ylabel('IOP absorbance (/m)')
    %legend({'IOP1','IOP2','IOP3','IOP4'});
    set(gca,'xlim',lambda_range,'XTick',lambda_out,'XTickLabel',{'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'});
    xtickangle(angle);
    set(gca,'ylim',[0 0.5]);
    
    yyaxis right;
    yticks=[0.001 0.01 0.1 1 10 100];
    plot(lambda_w,log10(a_w),'--');
    hold on;
    set(gca,'xlim',lambda_range,'XTick',lambda_out,'XTickLabel',{'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'});
    xtickangle(angle);
    set(gca,'ylim',[-3 2],'YTick',log10(yticks),'YTickLabel',{'0.001','0.01','0.1','1','10','100'});
    ylabel('Water absorbance (/m, log10)')
    
    hl=legend({'PHY-tchla','NCS-ss1','OGM-poc','OGM-doc','water'});
    set(hl,'FontSize',fs,'Location','southeast');
    title('(c) IOP absorbance @surface','FontSize',fs+4);
    
    subplot(3,2,2);
varname=upper('WQ_DIAG_OAS_swr_dif_sf');
tmp=dataALL.(varname);
% plot(tmp.date,tmp.bottom); hold on;
plotdata2(2,:)=tmp.bottom;

varname=upper('WQ_DIAG_OAS_swr_sf');
tmp0=dataALL.(varname);
%   plot(tmp.date,tmp0.bottom-tmp.bottom); hold on;
plotdata2(1,:)=tmp0.bottom-tmp.bottom;

varname=upper('WQ_DIAG_OAS_swr_sf_w');
tmp2=dataALL.(varname);
%  plot(tmp.date,tmp0.bottom-tmp2.bottom); hold on;
plotdata3(1,:)=-(tmp0.bottom-tmp2.bottom);

ha1=area(tmp.date(1:1:end),plotdata2(:,1:1:end)'); hold on;
ha1(1).FaceColor=[255,255,51]./255;
ha1(2).FaceColor=[255,127,0]./255;
    
ha2=area(tmp.date(1:1:end),plotdata3(:,1:1:end)'); hold on;
ha2(1).FaceColor=[55,126,184]./255;

titlename='(d) Incoming shortwave radiation';
title(titlename,'FontSize',fs+4);
%ylabel('Depth (m)','fontsize',6,'FontWeight','bold',...
%                'color',[0.4 0.4 0.4],'horizontalalignment','center');
xlim([def.datearray(1) def.datearray(end)]);
ylim([-200 1200]);
ylabel('SW Radiation (W/m^2)');

set(gca,'Xtick',def.datearray,...
    'XTickLabel',datestr(def.datearray,'dd/mm/yyyy'));
%  set(gca,'box','on','LineWidth',1.0,'Layer','top');

hold on;
plot([timesteps(i) timesteps(i)],[-200 1200],'--','Color','r','LineWidth',2);
hold on;

hl=legend('direct','diffuse','reflected');
set(hl,'Location','northwest','FontSize',fs);


subplot(3,2,4);
varname=upper(['WQ_DIAG_',profile_vars{1}]);
tmp=dataALL.(varname);

varname2=upper('WQ_DIAG_OAS_PAR_SF_W');
tmp2=dataALL.(varname2);

tmp.profile(1,:)=tmp2.bottom;

pcolor(tmp.date,tmp.depths,tmp.profile);
shading interp;
hc=colorbar;set(hc,'Position',[0.62 0.45 0.01 0.10]);
hold on;
text(datenum(2022,1,1,12,0,0),-5,'W/m^2');
hold on;
titlename='(e) PAR Profile';
title(strrep(titlename,'_','-'),'FontSize',fs+4);
ylabel('Depth (m)');
% ylabel('Depth (m)','fontsize',6,'FontWeight','bold',...
%     'color',[0.4 0.4 0.4],'horizontalalignment','center');
xlim([def.datearray(1) def.datearray(end)]);ylim([-19 0]);
caxis([0 500]);
set(gca,'Xtick',def.datearray,...
    'XTickLabel',datestr(def.datearray,'dd/mm/yyyy'));

hold on;
plot([timesteps(i) timesteps(i)],[-19 0],'--','Color','r','LineWidth',2);
hold on;

subplot(3,2,6);
newcolors = [253,174,97;...
             166,86,40]./255;
         
    colororder('default')
    
yyaxis left;
varname=upper('WQ_DIAG_OAS_par');
tmp=dataALL.(varname);
plot(tmp.date,tmp.profile(9,:)); hold on;
plot(tmp.date,tmpPAR3); hold on;

ylabel('PAR @5m (W/m^2)');
ylim([0 200]);

yyaxis right;
varname=upper('WQ_DIAG_OAS_secchi');
tmp=dataALL.(varname);
plot(tmp.date(3:end),tmp.bottom(3:end)); hold on;
ylim([8 10]);
plot([timesteps(i) timesteps(i)],[8 10],'--','Color','r','LineWidth',2);
hold on;

ylabel('Secchi depth (m)');
xlabel('date');
title('(f) PAR @5m vs. Secchi','FontSize',fs+4);

hl=legend('OAS-par','WAMSI','OAS-secchi');
set(hl,'Location','northwest','FontSize',fs);
%   titlename='SWR variables';
%   title(strrep(titlename,'_','-'));
%ylabel('Depth (m)','fontsize',6,'FontWeight','bold',...
%                'color',[0.4 0.4 0.4],'horizontalalignment','center');
xlim([def.datearray(1) def.datearray(end)]);

set(gca,'Xtick',def.datearray,...
    'XTickLabel',datestr(def.datearray,'dd/mm/yyyy'));

dim = [0.44 0.975 0.3 0.02];
str = {['Time at: ', datestr(timesteps(i),'dd/mm/yyyy HH:MM')]};
annotation('textbox',dim,'String',str,'FitBoxToText','on');
    
    pngname=[outDir,'animation_',datestr(double(timesteps(i)),'yyyymmddHHMM'),'.png'];
    saveas(gcf,pngname);
    
    writeVideo(hvid,getframe(hfig));
    
    
end

close(hvid);
