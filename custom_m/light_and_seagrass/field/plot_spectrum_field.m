clear; close all;

%%
readdata=0;

if readdata
load light_data.mat;

    agencies=fieldnames(output);
    inc=1;
    inc2=1;
    wavelength=[];
    wavelength2=[];

    for aa=1:length(agencies)

        sites=fieldnames(output.(agencies{aa}));

        for ss=1:length(sites)

            if strfind(sites{ss},'KwinanaShelf_Fixed')

            vars=fieldnames(output.(agencies{aa}).(sites{ss}));

            for vv=1:length(vars)
                disp(vars{vv});

                if strfind(vars{vv},'_uW')
                    varname=vars{vv};
                    C=strsplit(varname,'_');
                    wavelength(inc)=str2double(C{2});
                    spectrum.(vars{vv})=output.(agencies{aa}).(sites{ss}).(vars{vv});
                    inc=inc+1;
                end
            end

            elseif strfind(sites{ss},'KwinanaShelf_shade')
                vars=fieldnames(output.(agencies{aa}).(sites{ss}));

            for vv=1:length(vars)
                disp(vars{vv});

                if strfind(vars{vv},'_uW')
                    varname=vars{vv};
                    C=strsplit(varname,'_');
                    wavelength2(inc2)=str2double(C{2});
                    spectrum_shade.(vars{vv})=output.(agencies{aa}).(sites{ss}).(vars{vv});
                    inc2=inc2+1;
                end
            end



            end
        end
    end

    save('light_spetrum_KwinanaShelf_uW.mat','spectrum*','wavelength*','-mat','-v7.3')
else
    load light_spetrum_KwinanaShelf_uW.mat;

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

wls=fieldnames(spectrum);
datearray=datenum(2022,11:25,1);
d2c=datevec(datearray);

monthlymean=zeros(length(datearray), length(wls));
monthlymean12=zeros(length(datearray), length(wls));


for ww=1:length(wls)
    tmp=spectrum.(wls{ww});

    tmpdate=tmp.Date;
    tmpdata=tmp.Data;

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

    bar(monthlymean,'stacked');
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    xlabel('Months');
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths');
    set(gca,'XTick',1:15,'XTickLabel',datestr(datearray,'mmm/yyyy'));

    pngname='KwinanaShelf_Fixed_uW.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');


   clf;

       bar(monthlymean12,'stacked');
    hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    set(hl,'Location','eastoutside')
    xlabel('Months');
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths at 12 pm');
    set(gca,'XTick',1:15,'XTickLabel',datestr(datearray,'mmm/yyyy'));

    pngname='KwinanaShelf_Fixed_uW_12pm.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');

   save('light_summary.mat','monthlymean*','-mat','-v7.3')





