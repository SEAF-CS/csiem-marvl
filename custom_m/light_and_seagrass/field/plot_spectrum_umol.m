clear; close all;

%%
readdata=1;

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

                if strfind(vars{vv},'_umol')
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

                if strfind(vars{vv},'_umol')
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

    save('light_spetrum_KwinanaShelf_umol.mat','spectrum*','wavelength*','-mat','-v7.3')
else
    load light_spetrum_KwinanaShelf_umol.mat;

end

%% plotting
gcf=figure(1);
pos=get(gcf,'Position');
xSize = 20;
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
monthlymean=[];

for ww=1:length(wls)
    tmp=spectrum.(wls{ww});

    tmpdate=tmp.Date;
    tmpdata=tmp.Data;

    vec=datevec(tmpdate);

    for mm=1:12

        inds=find(vec(:,2)==mm);

        if ~isempty(inds)
        monthlymean(mm,ww)=mean(tmpdata(inds));
        else
            monthlymean(mm,ww)=NaN;
        end
    end

end

    bar(monthlymean(1:7,:),'stacked');
    legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    xlabel('Months');
    ylabel('\mumol/m^2/s');
    title('Light intensity at wavelengths')

    pngname='KwinanaShelf_Fixed_umol.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');


   %% plotting
   gcf2=figure(2);
pos=get(gcf2,'Position');
xSize = 20;
ySize = 10;
newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4]);
%  set(0,'DefaultAxesFontName',master.font);
%  set(0,'DefaultAxesFontSize',master.fontsize);

%--% Paper Size
set(gcf2, 'PaperPositionMode', 'manual');
set(gcf2, 'PaperUnits', 'centimeters');
set(gcf2,'paperposition',[0 0 xSize ySize]);
clf;

wls=fieldnames(spectrum_shade);
monthlymean=[];

for ww=1:length(wls)
    tmp=spectrum_shade.(wls{ww});

    tmpdate=tmp.Date;
    tmpdata=tmp.Data;

    vec=datevec(tmpdate);

    for mm=1:12

        inds=find(vec(:,2)==mm);

        if ~isempty(inds)
        monthlymean_shade(mm,ww)=mean(tmpdata(inds));
        else
            monthlymean_shade(mm,ww)=NaN;
        end
    end

end

    bar(monthlymean_shade(1:7,:),'stacked');
    legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
        '628 nm','656 nm','699 nm');
    xlabel('Months');
    ylabel('\mumol/m^2/s');
    title('Light intensity at wavelengths')

    pngname='KwinanaShelf_Shade_Fixed_umol.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');






