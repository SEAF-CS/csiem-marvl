%clear; close all;

%%
readdata=1;

if readdata
load light_data.mat;

    agencies=fieldnames(output);
    inc=1;
  %  inc2=1;
    wavelength=[];
  %  wavelength2=[];

    for aa=1:length(agencies)

        sites=fieldnames(output.(agencies{aa}));

        for ss=1:length(sites)

            if strfind(sites{ss},'6147036')

            vars=fieldnames(output.(agencies{aa}).(sites{ss}));

            for vv=1:length(vars)
                disp(vars{vv});

                if strfind(vars{vv},'BAND')
                    varname=vars{vv};
                    variable_name=output.(agencies{aa}).(sites{ss}).(varname).Variable_Name;
                    C=strsplit(variable_name,'WL');
                    wavelength(inc)=str2double(C{2}(4:6));
                  %  spectrum.(vars{vv})=output.(agencies{aa}).(sites{ss}).(vars{vv});
                    spectrum.(['WL_',num2str(wavelength(inc)),'uW'])=output.(agencies{aa}).(sites{ss}).(vars{vv});
                    inc=inc+1;
                end
            end

%             elseif strfind(sites{ss},'KwinanaShelf_shade')
%                 vars=fieldnames(output.(agencies{aa}).(sites{ss}));
% 
%             for vv=1:length(vars)
%                 disp(vars{vv});
% 
%                 if strfind(vars{vv},'_uW')
%                     varname=vars{vv};
%                     C=strsplit(varname,'_');
%                     wavelength2(inc2)=str2double(C{2});
%                     spectrum_shade.(vars{vv})=output.(agencies{aa}).(sites{ss}).(vars{vv});
%                     inc2=inc2+1;
%                 end
%             end
% 
% 

            end
        end
    end

    save('light_spetrum_DWER_uW.mat','spectrum*','wavelength*','-mat','-v7.3')
else
    load light_spetrum_DWER_uW.mat;

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
monthlymean=[];
datearray=datenum(2021,9:37,1);
d2c=datevec(datearray);

for ww=1:length(wls)
    tmp=spectrum.(wls{ww});

    tmpdate=tmp.Date;
    tmpdata=tmp.Data;

    vec=datevec(tmpdate);

    for mm=1:length(datearray)

        inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2));


        if ~isempty(inds)
            tmpdata2=tmpdata(inds);
            tmpdata3=tmpdata2(tmpdata2>=0 & tmpdata2<1000);
            monthlymean(mm,ww)=mean(tmpdata3);
        else
            monthlymean(mm,ww)=NaN;
        end
    end

end

    bar(monthlymean,'stacked');
    wl=[410,440,490,510,550,590,635,660,700];
    hl=legend('410 nm','440 nm','490 nm','510 nm','550 nm','590 nm',...
        '635 nm','660 nm','700 nm');
    set(hl,'Location','eastoutside')
    xlabel('Months');
    ylabel('\muW/cm^2/nm');
    title('Light intensity at wavelengths');
    set(gca,'XTick',1:29,'XTickLabel',datestr(datearray,'mmm/yyyy'));

    pngname='DWERmooring_uW.png';
    %  pngname2=strrep(pngname,'_','-');
   print(gcf,'-dpng',pngname,'-r300');


%    %% plotting
%    gcf2=figure(2);
% pos=get(gcf2,'Position');
% xSize = 28;
% ySize = 10;
% newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
% newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
% set(gcf2,'Position',[pos(1) pos(2) newPos3 newPos4]);
% %  set(0,'DefaultAxesFontName',master.font);
% %  set(0,'DefaultAxesFontSize',master.fontsize);
% 
% %--% Paper Size
% set(gcf2, 'PaperPositionMode', 'manual');
% set(gcf2, 'PaperUnits', 'centimeters');
% set(gcf2,'paperposition',[0 0 xSize ySize]);
% clf;
% 
% wls=fieldnames(spectrum_shade);
% monthlymean_shade=[];
% 
% for ww=1:length(wls)
%     tmp=spectrum_shade.(wls{ww});
% 
%     tmpdate=tmp.Date;
%     tmpdata=tmp.Data;
% 
%     vec=datevec(tmpdate);
% 
%     for mm=1:length(datearray)
% 
%         inds=find(vec(:,1)==d2c(mm,1) & vec(:,2)==d2c(mm,2));
%         if ~isempty(inds)
%         monthlymean_shade(mm,ww)=mean(tmpdata(inds));
%         else
%             monthlymean_shade(mm,ww)=NaN;
%         end
%     end
% 
% end
% 
%     bar(monthlymean_shade(1:15,:),'stacked');
%     hl=legend('398 nm','448 nm','470 nm','524 nm','554 nm','590 nm',...
%         '628 nm','656 nm','699 nm');
%     set(hl,'Location','eastoutside')
%     xlabel('Months');
%     ylabel('\muW/cm^2/nm');
%     set(gca,'XTick',1:15,'XTickLabel',datestr(datearray,'mmm/yyyy'));
%     title('Light intensity at wavelengths')
% 
%     pngname='KwinanaShelf_Shade_Fixed_uW.png';
%     %  pngname2=strrep(pngname,'_','-');
%    print(gcf2,'-dpng',pngname,'-r300');
% 





