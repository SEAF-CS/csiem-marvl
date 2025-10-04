%%
clear; close all;

scenario='restart_newtest';
load(['extracted_2022_',scenario,'v2.mat']);
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
     tmp2=interp1(bands,tmp1,WL2);
     Ldir_new(:,t)=tmp2;

     tmp1=Ldif(:,t);
     tmp2=interp1(bands,tmp1,WL2);
     Ldif_new(:,t)=tmp2;
end

%%

Ltotal=Ldir_new+Ldif_new;

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

pos1=[0.06 0.6 0.6 0.3];
pos2=[0.06 0.1 0.6 0.3];
pos3=[0.72 0.3 0.25 0.4];

axes('Position',pos1)
%monthlymean(1,:)=monthlymean(1,:)*1.8;
    hb1=bar(monthlymean*100,'stacked');

    for j=1:9
        hb1(j).FaceColor=colors(j,:);
    end
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    %xlabel('Months');
	set(gca,'XTick',1:12,'XTickLabel',datestr(datearray,'mmm/yyyy'),'ylim',[0 200]);
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths - modelled')

axes('Position',pos2)
    datearray2=datenum(2022,11:25,1);
%monthlymean(1,:)=monthlymean(1,:)*1.8;
    hb2=bar(field.monthlymean,'stacked');
    for j=1:9
        hb2(j).FaceColor=colors(j,:);
    end
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    %xlabel('Months');
	set(gca,'XTick',1:14,'XTickLabel',datestr(datearray2,'mmm/yyyy'),'ylim',[0 200]);
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths - field')

    
axes('Position',pos3)
data1=monthlymean(1:7,:);
data2=field.monthlymean(3:9,:);

for j=1:9
    scatter(data1(:,j)*100,data2(:,j),25,'MarkerEdgeColor',colors(j,:),'MarkerFaceColor',colors(j,:));
    hold on;
end

xlabel('model');
ylabel('field');
box on; axis equal;
plot([0 50],[0 50],'k');
set(gca,'xlim',[0 50],'ylim',[0 50]);

% hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
%         '628 nm','656 nm','699 nm');
%     set(hl,'Location','northeast')

pngname=[outdir,'model_KwinanaShelf_Fixed_uW_2022_5m_',scenario,'.png'];
print(gcf,'-dpng',pngname,'-r300');

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

pos1=[0.06 0.6 0.6 0.3];
pos2=[0.06 0.1 0.6 0.3];
pos3=[0.72 0.3 0.25 0.4];

axes('Position',pos1)
%monthlymean(1,:)=monthlymean(1,:)*1.8;
    hb1=bar(monthlymean12*100,'stacked');
    for j=1:9
        hb1(j).FaceColor=colors(j,:);
    end
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    %xlabel('Months');
	set(gca,'XTick',1:12,'XTickLabel',datestr(datearray,'mmm/yyyy'),'ylim',[0 600]);
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths - modelled')

axes('Position',pos2)
    datearray2=datenum(2022,11:25,1);
%monthlymean(1,:)=monthlymean(1,:)*1.8;
    hb2=bar(field.monthlymean12,'stacked');
    for j=1:9
        hb2(j).FaceColor=colors(j,:);
    end
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    %xlabel('Months');
	set(gca,'XTick',1:14,'XTickLabel',datestr(datearray2,'mmm/yyyy'),'ylim',[0 600]);
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths - field')

    
axes('Position',pos3)
data1=monthlymean12(1:7,:);
data2=field.monthlymean12(3:9,:);

for j=1:9
    scatter(data1(:,j)*100,data2(:,j),25,'MarkerEdgeColor',colors(j,:),'MarkerFaceColor',colors(j,:));
    hold on;
end

xlabel('model');
ylabel('field');
box on; axis equal;
set(gca,'xlim',[0 150],'ylim',[0 150]);
plot([0 150],[0 150],'k');

% hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
%         '628 nm','656 nm','699 nm');
%     set(hl,'Location','northeast')

pngname=[outdir, 'model_KwinanaShelf_Fixed_uW_2022_5m_',scenario,'_12pm.png'];
print(gcf,'-dpng',pngname,'-r300');



