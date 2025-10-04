%%
clear; close all;

scenario='newBIN20240916_SALCH4';
load(['extracted_2022_',scenario,'.mat']);
%load('extracted_for_Dan.mat');
field=load('../field/light_summary.mat');

outdir=['.\',scenario,'\'];
if ~exist(outdir,'dir')
    mkdir(outdir);
end

bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

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

%%
for b=1:length(bands_str)

    varname=upper(['WQ_DIAG_OAS_DIR_BAND',num2str(b)]);
    Ldir(b,:)=output.Kwinana.(varname).profile(9,:);

    varname=upper(['WQ_DIAG_OAS_DIF_BAND',num2str(b)]);
    Ldif(b,:)=output.Kwinana.(varname).profile(9,:);
end

time=output.Kwinana.(varname).date;

for t=1:length(time)
     tmp1=Ldir(:,t);
     tmp2=interp1(bands+50,tmp1,WL2);
     Ldir_new(:,t)=tmp2;

     tmp1=Ldif(:,t);
     tmp2=interp1(bands+50,tmp1,WL2);
     Ldif_new(:,t)=tmp2;
end

%%

Ltotal=Ldir_new+Ldif_new;
Ltotal_ori=Ldir+Ldif;

datearray=datenum(2022,1:12,1);
d2c=datevec(datearray);
monthlymean=zeros(length(datearray),length(WL2));
monthlymean12=zeros(length(datearray),length(WL2));

for ww=1:length(WL2)
   % tmp=spectrum.(wls{ww});

    tmpdate=time;
    tmpdata=Ltotal(ww,:);

    vec=datevec(tmpdate);

    for mm=1:length(datearray)

        inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2));

        if ~isempty(inds)
            monthlymean(mm,ww)=mean(tmpdata(inds));
        else
            monthlymean(mm,ww)=NaN;
        end

        inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2) & vec(:,4)==12);

        if ~isempty(inds)
            monthlymean12(mm,ww)=mean(tmpdata(inds));
        else
            monthlymean12(mm,ww)=NaN;
        end
    end

end

for bb=1:length(bands)
   % tmp=spectrum.(wls{ww});

    tmpdate=time;
    tmpdata=Ltotal_ori(bb,:);

    vec=datevec(tmpdate);

    for mm=1:length(datearray)

        inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2));

        if ~isempty(inds)
            monthlymean_ori(mm,bb)=mean(tmpdata(inds));
        else
            monthlymean_ori(mm,bb)=NaN;
        end

    end

end

%% field data

f2=load('..\field\light_spetrum_KwinanaShelf_uW.mat');

d2=datenum(2022,1:7,15,12,0,0);

for ww=1:length(WL2)
    tmpT=f2.spectrum.(['WL_',num2str(WL2(ww)),'_uW']).Date;
    tmpD=f2.spectrum.(['WL_',num2str(WL2(ww)),'_uW']).Date;
end




%% plotting
gcf=figure(1);
pos=get(gcf,'Position');
xSize = 28;
ySize = 15;
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

pos1=[0.06 0.6 0.5 0.3];
pos2=[0.06 0.1 0.5 0.3];
pos3=[0.62 0.6 0.3 0.3];
pos4=[0.62 0.1 0.3 0.3];

axes('Position',pos2)
%monthlymean(1,:)=monthlymean(1,:)*1.8;
    hb1=bar(monthlymean*100,'stacked');

    for j=1:9
        hb1(j).FaceColor=colors(j,:);
    end
   % hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
   %     '628 nm','656 nm','699 nm');
   % set(hl,'Location','north','FontSize',6);
    %xlabel('Months');
	set(gca,'XTick',1:12,'XTickLabel',datestr(datearray,'mmm/yyyy'),'xlim',[0 13],'ylim',[0 200]);
    ylabel('\muW/cm^2/nm');
    title('monthly-average light intensity: modelled 2022')

axes('Position',pos1)
    datearray2=datenum(2022,11:25,1);
%monthlymean(1,:)=monthlymean(1,:)*1.8;
    hb2=bar(field.monthlymean(3:13,:),'stacked');
    for j=1:9
        hb2(j).FaceColor=colors(j,:);
    end
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','east','FontSize',6);
    %xlabel('Months');
	set(gca,'XTick',1:12,'XTickLabel',datestr(datearray,'mmm/yyyy'),'xlim',[0 13],'ylim',[0 200]);
    ylabel('\muW/cm^2/nm');
    title('monthly-average light intensity: observed 2023')

    
axes('Position',pos4);

d2=datenum(2022,1:7,15,12,0,0);

for j=1:7 %length(d2)
   % t2p=find(abs(time-d2(j))==min(abs(time-d2(j))));
    plot(bands+50,monthlymean_ori(j,:)*100);
    hold on;
% 
%     fig = fillyy(data(mod).date,data_to_plot(1,:),data_to_plot(2*nn-1,:),...
%             config.dimc,config.ncfile(mod).col_pal_color_bot(1,:));
% 
% 
%     scatter(data1(:,j)*100,data2(:,j),25,'MarkerEdgeColor',colors(j,:),'MarkerFaceColor',colors(j,:));

end
set(gca,'xlim',[300 1000],'ylim',[0 40]);
xlabel('wave length (nm)');
ylabel('\muW/cm^2/nm');
box on; 
%title

% hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
%         '628 nm','656 nm','699 nm');
%     set(hl,'Location','northeast')

axes('Position',pos3);

for j=1:7 

    plot(WL2,field.monthlymean(j+2,:));
    hold on;
    
% 
%     fig = fillyy(data(mod).date,data_to_plot(1,:),data_to_plot(2*nn-1,:),...
%             config.dimc,config.ncfile(mod).col_pal_color_bot(1,:));
% 
% 
%     scatter(data1(:,j)*100,data2(:,j),25,'MarkerEdgeColor',colors(j,:),'MarkerFaceColor',colors(j,:));

end

set(gca,'xlim',[300 1000],'ylim',[0 40]);
xlabel('wave length (nm)');
ylabel('\muW/cm^2/nm');
box on; 

hl=legend('January','February','March','April','May','June',...
        'July');
    set(hl,'Location','east')

pngname=[outdir,'model_KwinanaShelf_Fixed_uW_2022_5m_',scenario,'_new_correction.png'];
print(gcf,'-dpng',pngname,'-r300');





