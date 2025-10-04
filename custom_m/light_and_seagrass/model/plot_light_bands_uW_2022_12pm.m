%%
clear; close all;

load extracted_2022_newBIN20240916_SALCH4.mat;

bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

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
monthlymean=[];
datearray=datenum(2022,1:12,1);
d2c=datevec(datearray);


for ww=1:length(WL2)
   % tmp=spectrum.(wls{ww});

    tmpdate=time;
    tmpdata=Ltotal(ww,:);

    vec=datevec(tmpdate);

    for mm=1:length(datearray)

        inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2) & vec(:,4)==12);

        if ~isempty(inds)
            monthlymean(mm,ww)=mean(tmpdata(inds));
        else
            monthlymean(mm,ww)=NaN;
        end
    end

end


%% plotting
gcf=figure(1);
pos=get(gcf,'Position');
xSize = 28;
ySize = 10;
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

%monthlymean(1,:)=monthlymean(1,:)*1.8;
    bar(monthlymean*100,'stacked');
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    %xlabel('Months');
	set(gca,'XTick',1:12,'XTickLabel',datestr(datearray,'mmm/yyyy'));
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths - modelled')

    pngname='model_KwinanaShelf_Fixed_uW_2022_5m_12pm_newBIN20240916_SALCH4.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');





