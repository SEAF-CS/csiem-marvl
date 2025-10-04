%% import AWAC data
clear output;
inDir='E:\AED Dropbox\AED_Cockburn_db\CSIEM\Data\data-swamp\JPPL\AWAC\JPPL_AWAC\';
sites={'a','b','c','d'};
stdvars={'DIR','HS','TPER'};
vars={'WVDIR','WVHT','WVPER'};
clear output;

for ss=1:length(sites)
    infile=[inDir,'S01_',sites{ss},'\Westport_S01_',sites{ss},'.mat'];
    data=load(infile);
    
    if ss==1
        
        output.S01.time=data.DATA.SITE01.TIME_hydro;
        output.S01.V_x=data.DATA.SITE01.V_x;
        output.S01.V_y=data.DATA.SITE01.V_y;
        zcell=data.DATA.SITE01.zcell;
        output.S01.zcell=zcell;
       % output.S01.TPER=data.DATA.SITE01.WVPER;
    else
        l1=length(output.S01.time);
        l2=length(data.DATA.SITE01.TIME_hydro);

        
        output.S01.time(l1+1:l1+l2)=data.DATA.SITE01.TIME_hydro;

        tmpx=data.DATA.SITE01.V_x;
        tmpy=data.DATA.SITE01.V_y;
        newzcell=data.DATA.SITE01.zcell;
        clear newVx newVy;

        for j=1:size(tmpx,2)
            newVx(:,j)=interp1(newzcell,tmpx(:,j),zcell);
            newVy(:,j)=interp1(newzcell,tmpy(:,j),zcell);
        end
        output.S01.V_x(:,l1+1:l1+l2)=newVx;
        output.S01.V_y(:,l1+1:l1+l2)=newVy;
     %   output.S01.TPER(l1+1:l1+l2)=data.DATA.SITE01.WVPER;
    end
    
end

for ss=1:length(sites)
    infile=[inDir,'S02_',sites{ss},'.\Westport_S02_',sites{ss},'.mat'];
    data=load(infile);
    
    if ss==1
        
        output.S02.time=data.DATA.SITE02.TIME_hydro;
        output.S02.V_x=data.DATA.SITE02.V_x;
        output.S02.V_y=data.DATA.SITE02.V_y;
       % output.S02.TPER=data.DATA.SITE02.WVPER;
       zcell=data.DATA.SITE02.zcell;
       output.S02.zcell=zcell;
    else
        l1=length(output.S02.time);
        l2=length(data.DATA.SITE02.TIME_hydro);

        tmpx=data.DATA.SITE02.V_x;
        tmpy=data.DATA.SITE02.V_y;
        newzcell=data.DATA.SITE02.zcell;
        clear newVx newVy;

        for j=1:size(tmpx,2)
            newVx(:,j)=interp1(newzcell,tmpx(:,j),zcell);
            newVy(:,j)=interp1(newzcell,tmpy(:,j),zcell);
        end
        
        output.S02.time(l1+1:l1+l2)=data.DATA.SITE02.TIME_hydro;
        output.S02.V_x(:,l1+1:l1+l2)=newVx;
        output.S02.V_y(:,l1+1:l1+l2)=newVy;
       % output.S02.TPER(l1+1:l1+l2)=data.DATA.SITE02.WVPER;
    end
    
end
save('AWAC_currents_2013.mat','output','-mat','-v7.3');
clear output;
