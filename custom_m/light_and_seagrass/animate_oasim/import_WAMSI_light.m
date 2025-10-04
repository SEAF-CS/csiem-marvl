%% import WAMSI light data

clear; close all;

load('W:\csiem-data-hub\data-warehouse\mat\agency\csiem_WAMSI_public.mat');

sites=fieldnames(csiem);

sitename='_KwinanaShelf_Fixed_';
WLname='WL_';

for ss=1:length(sites)
    tmps=sites{ss};
    Index = find(contains(tmps,sitename));
    
    if Index>0
        disp(tmps);
        vars=fieldnames(csiem.(sites{ss}));
        
        tmps2=vars{1};
        Index2 = find(contains(tmps2,WLname));
        
        if Index2>0
            disp(tmps2);
            C = strsplit(tmps2,'_');
            
            WAMSI.(tmps2)=csiem.(sites{ss}).(tmps2);
        end
    end
end

WAMSI.PAR=csiem.WAMSI_WWMSP22_KwinanaShelf_Fixed_3758.Total_Par_day;

save('./WAMSI_light.mat','WAMSI','-mat','-v7.3');
        