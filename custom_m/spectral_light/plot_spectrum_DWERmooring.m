clear; close all;

load('E:\light_and_seagrass\field\light_spetrum_KwinanaShelf_uW.mat');

%% load model
modeldata=load('W:\csiem\csiem-marvl-dev\others\CSIEM20_reporting\light\extracted_2023_light.mat');
bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

dlayer=4;

for b=1:length(bands_str)

    varname=upper(['WQ_DIAG_OAS_DIR_BAND',num2str(b)]);
    Ldir(b,:)=modeldata.output.Kwinana.(varname).profile(dlayer,:);

    varname=upper(['WQ_DIAG_OAS_DIF_BAND',num2str(b)]);
    Ldif(b,:)=modeldata.output.Kwinana.(varname).profile(dlayer,:);
end

time=modeldata.output.Kwinana.(varname).date;

for t=1:length(time)
     tmp1=Ldir(:,t);
     tmp2=interp1(bands,tmp1,WL2);
     Ldir_new(:,t)=tmp2;

     tmp1=Ldif(:,t);
     tmp2=interp1(bands,tmp1,WL2);
     Ldif_new(:,t)=tmp2;
end

Ltotal=Ldir_new+Ldif_new;

%% plotting
gcf=figure(1);
pos=get(gcf,'Position');
xSize = 28;
ySize = 22;
newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);
%  set(0,'DefaultAxesFontName',master.font);
%  set(0,'DefaultAxesFontSize',master.fontsize);

%--% Paper Size
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0 0 xSize ySize]);
clf;

wls=fieldnames(spectrum);
monthlymean=[];
datearray=datenum(2022,12:2:19,1);
d2c=datevec(datearray);

for ww=1:length(wls)
    tmp=spectrum.(wls{ww});

    tmpdate=tmp.Date;
    tmpdata=tmp.Data;


subplot(5,2,ww);

plot(tmpdate,tmpdata,'Color',[141,160,203,100]./255);
hold on;

plot(tmpdate,movmean(tmpdata,24),'Color',[252,141,98]./255);

title(['Wavelength at ', num2str(wavelength(ww)),' nm']);
ylim([0 150]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'));
ylabel('\muW/cm^2/nm');

% 
%     vec=datevec(tmpdate);
% 
%     for mm=1:length(datearray)
% 
%         inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2));
% 
% 
%         if ~isempty(inds)
%             tmpdata2=tmpdata(inds);
%             tmpdata3=tmpdata2(tmpdata2>=0 & tmpdata2<1000);
%             monthlymean(mm,ww)=mean(tmpdata3);
%         else
%             monthlymean(mm,ww)=NaN;
%         end
%     end


 %   bar(monthlymean,'stacked');
%     wl=[410,440,490,510,550,590,635,660,700];
%     hl=legend('410 nm','440 nm','490 nm','510 nm','550 nm','590 nm',...
%         '635 nm','660 nm','700 nm');
%     set(hl,'Location','eastoutside')
%     xlabel('Months');
%     ylabel('\muW/cm^2/nm');
%     title('Light intensity at wavelengths');
%     set(gca,'XTick',1:29,'XTickLabel',datestr(datearray,'mmm/yyyy'));


end

hl=legend('raw','daily average');
set(hl,'Position',[0.55 0.12 0.2 0.05])

    pngname='DWERmooring_uW.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');



%% plotting
gcf=figure(2);
pos=get(gcf,'Position');
xSize = 28;
ySize = 22;
newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);
%  set(0,'DefaultAxesFontName',master.font);
%  set(0,'DefaultAxesFontSize',master.fontsize);

%--% Paper Size
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0 0 xSize ySize]);
clf;

for ww=1:length(wavelength)
    
    tmpdate=time;
    tmpdata=Ltotal(ww,:)*100;


subplot(5,2,ww);

plot(tmpdate,tmpdata,'Color',[141,160,203,100]./255);
hold on;

plot(tmpdate,movmean(tmpdata,24),'Color',[252,141,98]./255);

title(['Wavelength at ', num2str(wavelength(ww)),' nm']);
ylim([0 150]);
set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'));
ylabel('\muW/cm^2/nm');

end

hl=legend('raw','daily average');
set(hl,'Position',[0.55 0.12 0.2 0.05])

    pngname='modelled_uW.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');

   %% plotting
gcf=figure(3);
pos=get(gcf,'Position');
xSize = 25;
ySize = 32;
newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);

fh=0.1;
fh2=0.08;

%--% Paper Size
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0 0 xSize ySize]*0.8);
clf;

for ww=1:length(wavelength)
    
 tmp=spectrum.(wls{ww});

    tmpdate=tmp.Date;
    tmpdata=tmp.Data;


axes('Position',[0.1 0.98-ww*fh 0.42 fh2]);

plot(tmpdate,tmpdata,'Color',[141,160,203,100]./255);
hold on;

plot(tmpdate,movmean(tmpdata,24),'Color',[252,141,98]./255);

ylim([0 150]);

if ww==length(wavelength)
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'));
else
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel','');
end
ylabel({[num2str(wavelength(ww)),' nm'],'(\muW/cm^2/nm)'});

if ww==1 
    title('Measured Light Intensity');
end

text(datenum(2022,11,15), 135, [' measured,', num2str(wavelength(ww)),' nm']);


    tmpdate=time;
    tmpdata=Ltotal(ww,:)*100;


axes('Position',[0.56 0.98-ww*fh 0.42 fh2]);

plot(tmpdate,tmpdata,'Color',[141,160,203,100]./255);
hold on;

plot(tmpdate,movmean(tmpdata,24),'Color',[252,141,98]./255);

ylim([0 150]);

if ww==length(wavelength)
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yy'));
else
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel','');
end
%ylabel({[num2str(wavelength(ww)),' nm'],'(\muW/cm^2/nm)'});

if ww==1 
    title('Modelled Light Intensity');
end

text(datenum(2022,11,15), 135, [' modelled, ', num2str(wavelength(ww)),' nm']);

end

hl=legend('raw','daily average','NumColumns',2,'FontSize',9);
set(hl,'Position',[0.45 0.02 0.2 0.02])

    pngname='modelled_uW.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');

   %%

   ind1=find(abs(time-spectrum.(wls{1}).Date(1))==min(abs(time-spectrum.(wls{1}).Date(1))));
   ind2=find(abs(time-spectrum.(wls{1}).Date(end))==min(abs(time-spectrum.(wls{1}).Date(end))));

   inc=1;
   for ii=ind1:ind2
       tmpind=find(abs(spectrum.(wls{1}).Date-time(ii))==min(abs(spectrum.(wls{1}).Date-time(ii))));
       disp(datestr(time(ii)));

       for ww=1:length(wls)
           kwinanaInt(inc,ww)=spectrum.(wls{ww}).Data(tmpind);
       end
       inc=inc+1;
   end
   
%% plotting
gcf=figure(3);
pos=get(gcf,'Position');
xSize = 28;
ySize = 22;
newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);
%--% Paper Size
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0 0 xSize ySize]*0.7);
clf;


for ww=1:length(WL2)
    w=WL2(ww);

if (w >= 380 && w < 440)
    R = -(w - 440.) / (440. - 380.);
    G = 0.0;
    B = 1.0;
elseif (w >= 440 && w < 490)
    R = 0.0;
    G = (w - 440.) / (490. - 440.);
    B = 1.0;
elseif (w >= 490 && w < 510)
    R = 0.0;
    G = 1.0;
    B = -(w - 510.) / (510. - 490.);
elseif (w >= 510 && w < 580)
    R = (w - 510.) / (580. - 510.);
    G = 1.0;
    B = 0.0;
elseif (w >= 580 && w < 645)
    R = 1.0;
    G = -(w - 645.) / (645. - 580.);
    B = 0.0;
elseif (w >= 645 && w <= 780)
    R = 1.0;
    G = 0.0;
    B = 0.0;
else
    R = 0.0;
    G = 0.0;
    B = 0.0;
end

colors(ww,1)=R;
colors(ww,2)=G;
colors(ww,3)=B;

end

ms =8;
clear allmodel alldata;
for ww=1:length(wavelength)
    
scatter(Ltotal(ww,ind1:ind2)*100,kwinanaInt(:,ww),ms,'filled','MarkerFaceColor',colors(ww,:),'MarkerFaceAlpha',.6,'MarkerEdgeAlpha',.6);
hold on;

if ww==1
    allmodel=Ltotal(ww,ind1:ind2)*100;
    alldata=kwinanaInt(:,ww);
else
    allmodel=[allmodel,Ltotal(ww,ind1:ind2)*100];
    alldata=[alldata; kwinanaInt(:,ww)];

end

end

box on;
axis equal;
xlim([0 150]);
ylim([0 150]);

[r,m,b] = regression(allmodel,alldata','one');
hold on;
plot([0 150],[0 150],'k');
hold on;
text(100,135,'r=0.9112');


hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    xlabel('modelled (\muW/cm^2/nm)');
    ylabel('monitored (\muW/cm^2/nm)');


    pngname='modelled_vs_observed.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');





