clear; close all;

load('extracted_pollution_scens_totallynopollution_v3_2022.mat');

cdata=WQ_ori.iop_mean-WQ_dredge.iop_mean;


%%
hfig = figure('visible','on','position',[304         166        1271         812]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 25.32 12.24]);

vars={'WQ_NCS_SS1','WQ_OGM_DOC','WQ_DIAG_PHY_TCHLA','WQ_OGM_POC'};
color1=[31,120,180]./255;
color2=[255,127,0]./255;

bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];

IDs=[4 3 1 2];
lims=[3.0 24 5 16];
yls={'SS','DOC','TCHLA','POC'};
units={'mg/L','\muM','\mug/L','\muM'};

for v=1:length(vars)
    axes('Position',[0.05 0.95-v*0.2 0.2 0.15]);
    tmp1=WQ_ori.(vars{v});
    tmp2=WQ_dredge.(vars{v});
    barmean(1)=mean(tmp1(:));
    barmean(2)=mean(tmp2(:));
    barstd(1)=std(tmp1(:));
    barstd(2)=std(tmp2(:));

    hb=bar(1, barmean(1),'FaceColor','flat'); hold on;
    hb2=bar(2, barmean(2),'FaceColor','flat'); hold on;
    er=errorbar(1:2,barmean,barstd);
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  
    hold on;
     hb1.CData(1,:)=color1;
    hb2.CData(1,:)=color2;
    hold on;
    ylim([0 lims(v)]);
    if v==1
        title('Concentrations');
    end
    if v==4
       % hl=legend('basecase','dredging');
       % set(hl,'position',[0.1 0.05 0.2 0.03],'NumColumns',2)
        set(gca,'XTick',1:2,'XTickLabel',{'basecase','WWTP'});
    else
        set(gca,'XTick',1:2,'XTickLabel',{'',''});
    end

    ylabel([yls{v},' (',units{v},')']);
    

    axes('Position',[0.3 0.95-v*0.2 0.6 0.15]);

    plot(bands,WQ_ori.iop_mean(IDs(v),:),'-o','Color',color1);
    hold on;
    plot(bands,WQ_dredge.iop_mean(IDs(v),:),'-o','Color',color2);
    hold on;

    er=errorbar(bands,WQ_ori.iop_mean(IDs(v),:),WQ_ori.iop_std(IDs(v),:));
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  

    hold on;
    er=errorbar(bands,WQ_dredge.iop_mean(IDs(v),:),WQ_dredge.iop_std(IDs(v),:));
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  

    set(gca,'xlim',[300 800]);

    if v==1
        title('Absorbance (m^{-1})');
        hl=legend('basecase','WWTP');
    end

    if v==4
        xlabel('wave lengths (nm)');
    end

end

 img_name ='./compare_pollution_scenarios_totallynopollution_v3_2022.jpg';
 saveas(gcf,img_name);

