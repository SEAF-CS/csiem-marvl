clear; close all;

ROMSfile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\bc_repo\1_ocean\ROMS\ROMS_UTC+8_20130101_20140101.nc';
FremTide='Z:\Busch\Studysites\Swan\Simulations\Swan_Full_Domain_new_grid_2015_v3\BCs\Tide\Fremantle_Inflow.csv';

csiemFile='W:\csiem\Model\TFV\Results_2013_B009_HD\csiem_v1_B009_20130101_20131231_HD.nc';


lat0=-32.065556;
lon0=115.748056;

%%

readdata=0;

if readdata
lats=ncread(ROMSfile,'lat');
lons=ncread(ROMSfile,'lon');

indLat=find(abs(lats-lat0)==min(abs(lats-lat0)));
indLon=find(abs(lons-lon0)==min(abs(lons-lon0)));

ele=ncread(ROMSfile,'surf_el');
Frem=tfv_readBCfile(FremTide);

ele0=squeeze(ele(indLon,indLat,:));
RomsTime=ncread(ROMSfile,'time')/24+datenum(1990,1,1);

FremTime=Frem.Date;
FremTide=Frem.wl;

dat=tfv_readnetcdf(csiemFile,'time',1);
csiemTime=dat.Time;

dat=tfv_readnetcdf(csiemFile,'timestep',1);
diffx=dat.cell_X-lon0;
diffy=dat.cell_Y-lat0;

difft=sqrt(diffx.^2+diffy.^2);
indtmp=find(difft==min(difft));
tmpele=ncread(csiemFile,'H');
csiemTide=tmpele(indtmp,:);

save('extracted.mat','ele0','RomsTime','FremTime','FremTide','csiemTime','csiemTide','-mat','-v7.3');

else
    load extracted.mat;
    
end

%% 

  
        hfig = figure('visible','on','position',[304         166        1271         812]);
        
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf,'paperposition',[0.635 6.35 25.32 15.24]);
        
        plot(RomsTime,ele0);
        hold on;
        plot(FremTime,FremTide,'r');
        hold on;
        plot(csiemTime,csiemTide,'k');
        hold on;
        
        datearray=datenum(2013,1:3:13,1);
        
        set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'))
        
        legend('ROMS','Fremantle','CSIEM');
        ylabel('m');
        
        t1=datearray(1);
        t2=datearray(end);
        ind11=find(abs(RomsTime-t1)==min(abs(RomsTime-t1)));
        ind12=find(abs(RomsTime-t2)==min(abs(RomsTime-t2)));
        
        ind21=find(abs(FremTime-t1)==min(abs(FremTime-t1)));
        ind22=find(abs(FremTime-t2)==min(abs(FremTime-t2)));
        
        ind31=find(abs(csiemTime-t1)==min(abs(csiemTime-t1)));
        ind32=find(abs(csiemTime-t2)==min(abs(csiemTime-t2)));
        
        str{1}=['mean ROMS = ',num2str(mean(ele0(ind11:ind12)),'%1.2f')];
        str{2}=['mean Fre Tide = ',num2str(mean(FremTide(ind21:ind22)),'%1.2f')];
        str{3}=['mean csiem Tide = ',num2str(mean(csiemTide(ind31:ind32)),'%1.2f')];
        
        annotation('textbox',[0.4 0.25 0.2 0.03],'String',str,'FitBoxToText','on');
        
        img_name ='ROMS_vs_Fremantle.png';
        
        saveas(gcf,img_name);
        

        %% 

  
        hfig = figure('visible','on','position',[304         166        1271         812]);
        
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf,'paperposition',[0.635 6.35 25.32 10.24]);
        
        color1=[50,136,189]/255;
color2=[252,141,89]/255;
sz=3;

        axes('Position',[0.08 0.1 0.5 0.8]);
        plot(RomsTime,ele0-0.34,'Color',color1);
        hold on;
        plot(csiemTime,csiemTide+0.07,'Color',color2);
        hold on;
        %plot(csiemTime,csiemTide,'k');
        %hold on;
        
        datearray=datenum(2013,1:3:13,1);
        
        set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'))
        
        legend('CSIEM','Fremantle');
        ylabel('m AHD');
        title('(a) timeseris of tidal elevations')

        axes('Position',[0.66 0.12 0.32 0.78]);

        rt1=csiemTime(ind31:ind32);
        rd1=csiemTide(ind31:ind32)+0.07;
        rd2=interp1(FremTime,FremTide-0.77,rt1);

        scatter(rd1,rd2,sz,'filled','Color',color2);
        box on;
        axis equal;
        set(gca,'xlim',[-1 1],'ylim',[-1 1]);
        hold on;
        plot([-1 1],[-1 1],'r');

        [r,C]=regression(rd1,rd2','one');
        mae=(mean(rd1'-rd2))/mean(rd2);

        str2{1}=['r = ',num2str(r,'%1.4f')];
        str2{2}=['MAE = ',num2str(mae,'%1.4f')];
        text(-0.8,0.8,str2);


        xlabel('CSIEM elevations (m AHD)');
        ylabel('Fremantle elevations (m AHD)');
        set(gca,'XTick',[-1:0.5:1],'YTick',[-1:0.5:1]);
       % annotation('textbox',[0.8 0.85 0.1 0.03],'String',str2,'FitBoxToText','on');
        title('(b) regression of tidal elevations')
%         
%         t1=datearray(1);
%         t2=datearray(end);
%         ind11=find(abs(RomsTime-t1)==min(abs(RomsTime-t1)));
%         ind12=find(abs(RomsTime-t2)==min(abs(RomsTime-t2)));
%         
%         ind21=find(abs(FremTime-t1)==min(abs(FremTime-t1)));
%         ind22=find(abs(FremTime-t2)==min(abs(FremTime-t2)));
%         
%         ind31=find(abs(csiemTime-t1)==min(abs(csiemTime-t1)));
%         ind32=find(abs(csiemTime-t2)==min(abs(csiemTime-t2)));
%         
%         str{1}=['mean ROMS = ',num2str(mean(ele0(ind11:ind12)),'%1.2f')];
%         str{2}=['mean Fre Tide = ',num2str(mean(FremTide(ind21:ind22)),'%1.2f')];
%         str{3}=['mean csiem Tide = ',num2str(mean(csiemTide(ind31:ind32)),'%1.2f')];
%         
%         annotation('textbox',[0.4 0.25 0.2 0.03],'String',str,'FitBoxToText','on');
%         
        img_name ='ROMS_vs_Fremantle_final.png';
        
        saveas(gcf,img_name);