clear; close all;

load light_data.mat;

%%
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

datearray=datenum(2020,1:6:49,1);


agencies=fieldnames(output);

for i=1:length(agencies)
    agency=agencies{i};
    
    outdir=['.\plots\',agency,'\'];
    if ~exist(outdir,'dir')
        mkdir(outdir);
    end

    sites=fieldnames(output.(agency));

    for ss=1:length(sites)

        vars=fieldnames(output.(agency).(sites{ss}));
        for vv=1:length(vars)

            timesteps=output.(agency).(sites{ss}).(vars{vv}).Date;
            data=output.(agency).(sites{ss}).(vars{vv}).Data;
            depth=output.(agency).(sites{ss}).(vars{vv}).Depth;

            clf;

            yyaxis left;
            plot(timesteps,data,'*k');

            if strfind(sites{ss},'6147036')
                ylim([0 1000]);
            end

            yyaxis right;
            plot(timesteps,depth,'r');

            set(gca,'xlim',[datearray(1) datearray(end)],'Xtick',...
                datearray,'XTickLabel',datestr(datearray,'mm/yyyy'));

            title(strrep([sites{ss},':',num2str(mean(depth(~isnan(depth))),'%2.2f')],'_','-'));
            ylabel(strrep(vars{vv},'_','-'));


        end

        pngname=[outdir,sites{ss},'-',vars{vv},'.png'];
        pngname2=strrep(pngname,'_','-');
        print(gcf,'-dpng',pngname2,'-r300');

    end

end


