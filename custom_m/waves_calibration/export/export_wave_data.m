
clear; close all;

sites={'AWAC1','AWAC2','Cath1','Cath2','DC','Stirling','Parmelia','Rottnest','S01','S02'};
agencies={'CCL','CCL','CoC','CoC','FPA','FPA','FPA','DoT','JPPL','JPPL'};
depths=[-14.6,-7.4,-6.5,-8.5,-13.0,-13.8,-9.0,-73.0,-10,-18];
lons  =[115.704160,  115.679512, 115.728092, 115.745646, 115.686667, 115.744336, 115.701664, 115.407778, 115.762710, 115.730832];
lats  =[-32.079398,  -32.095191, -32.078775, -32.090541, -31.977779, -32.203214, -32.130005, -32.094167, -32.200942, -32.180925];
InGridA =[1 1 1 1 1 1 1 1 1 1];
InGridB =[1 1 1 1 1 1 1 0 1 1];
InGridC =[0 0 0 0 0 1 0 0 1 1];
inWWMGRE=[1 1 1 1 1 1 1 1 1 1];
inWWMLOC=[1 1 1 1 1 1 1 0 1 1];
inExpGdA=[1 1 1 1 1 1 1 1 1 1];
inExpGdB=[1 1 1 1 1 1 1 0 1 1];
inExpGdC=[0 0 0 0 0 1 0 0 1 1];

%% export SWAN grids

infiles={'W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\bc_repo\3_waves\SWAN\A_HIND_2013_combined_base.nc';...
    'W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\bc_repo\3_waves\SWAN\B_HIND_2013_combined_base.nc';...
    'W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\bc_repo\3_waves\SWAN\C_HIND_2013_combined_base.nc'};

exports={'SWAN_Grid_A_sites.mat';...
    'SWAN_Grid_B_sites.mat';...
    'SWAN_Grid_C_sites.mat'};


for ii=1:length(infiles)
    infile=infiles{ii};
    
    switch ii
        case 1
            InGrid=InGridA;
        case 2
            InGrid=InGridB;
        case 3
            InGrid=InGridC;
    end
    
    disp(infile);
    disp(InGrid);
    
    Xp=ncread(infile,'Xp'); %Xpp=Xp(:,1);
    Yp=ncread(infile,'Yp');
    
    stdvars={'DIR','HS','TPER'};
    vars={'Dir','Hsig','TPsmoo'};
    
    for ss=1:length(sites)
        
        if InGrid(ss)==1
            slon=lons(ss);
            slat=lats(ss);
            
            diffx=Xp-slon;
            diffy=Yp-slat;
            difft=diffx.^2+diffy.^2;
            
            aa=min(difft);
            indy(ss)=find(abs(aa-min(aa))==min(abs(aa-min(aa))));
            
            bb=min(difft');
            indx(ss)=find(abs(bb-min(bb))==min(abs(bb-min(bb))));
            
            disp(sites{ss});
            disp(Xp(indx(ss),indy(ss)));
            disp(Yp(indx(ss),indy(ss)));
            
        else
            indy(ss)=NaN;
            indx(ss)=NaN;
            disp([sites{ss},' is not in domain']);
            
        end
    end
    
    
    for vv=1:length(stdvars)
        disp(stdvars{vv});
        % tmp=ncread(infile,vars{vv},[indx indy 1],[1 1 Inf]);
        tmp=ncread(infile,vars{vv});
        
        for ss=1:length(sites)
            if InGrid(ss)==1
                output.(sites{ss}).(stdvars{vv})=squeeze(tmp(indx(ss),indy(ss),:));
                if vv==1
                    output.(sites{ss}).time=ncread(infile,'time')/24+datenum(1990,1,1);
                end
            end
            
        end
        clear tmp;
    end
    
    save(exports{ii},'output','-mat','-v7.3');
    clear output;
end

%% export WWM regional grids

inDir='D:\WWM_REG\2013\';
files=dir([inDir,'*.nc']);

wwmFile='D:\WWM_REG\grid.nc';  %[inDir,files(1).name];
lonWWM=ncread(wwmFile,'lon');
latWWM=ncread(wwmFile,'lat');

exports='WWM_REG_sites.mat';

InGrid=inWWMGRE;

disp(wwmFile);
disp(InGrid);

stdvars={'DIR','HS','TPER'};
vars={'DM','HS','TPP'};

for ss=1:length(sites)
    
    if InGrid(ss)==1
        slon=lons(ss);
        slat=lats(ss);
        
        diffx=lonWWM-slon;
        diffy=latWWM-slat;
        difft=diffx.^2+diffy.^2;
        
        inds(ss)=find(abs(difft-min(difft))==min(abs(difft-min(difft))));
        
        disp(sites{ss});
        disp(lonWWM(inds(ss)));
        disp(latWWM(inds(ss)));
        
    else
        indy(ss)=NaN;
        indx(ss)=NaN;
        disp([sites{ss},' is not in domain']);
        
    end
end

for ff=1:length(files)-1
    infile=[inDir,files(ff).name];
    disp(infile);
    oceantime=datenum(1858,11,17)+ncread(infile,'ocean_time')/86400;
    
    if ff>1
        l1=length(output.(sites{ss}).time);
        l2=length(oceantime);
    end
    
    for vv=1:length(stdvars)
        disp(stdvars{vv});
        % tmp=ncread(infile,vars{vv},[indx indy 1],[1 1 Inf]);
        tmp=ncread(infile,vars{vv});
        
        if ff==1
            for ss=1:length(sites)
                if InGrid(ss)==1
                    output.(sites{ss}).(stdvars{vv})=tmp(inds(ss),:);
                    if vv==1
                        output.(sites{ss}).time=oceantime;
                    end
                end
                
            end
        else
            
            for ss=1:length(sites)
                if InGrid(ss)==1
                    output.(sites{ss}).(stdvars{vv})(l1+1:l1+l2)=tmp(inds(ss),:);
                    if vv==1
                        output.(sites{ss}).time(l1+1:l1+l2)=oceantime;
                    end
                end
                
            end
        end
        clear tmp;
    end
    
end

save(exports,'output','-mat','-v7.3');
clear output;

%% export WWM regional grids

inDir='D:\WWM\2013\';
files=dir([inDir,'*.nc']);

wwmFile=[inDir,files(1).name];
lonWWM=ncread(wwmFile,'lon');
latWWM=ncread(wwmFile,'lat');

exports='WWM_CS_sites.mat';

InGrid=inWWMLOC;

disp(wwmFile);
disp(InGrid);

stdvars={'DIR','HS','TPER'};
vars={'DM','HS','TPP'};

for ss=1:length(sites)
    
    if InGrid(ss)==1
        slon=lons(ss);
        slat=lats(ss);
        
        diffx=lonWWM-slon;
        diffy=latWWM-slat;
        difft=diffx.^2+diffy.^2;
        
        inds(ss)=find(abs(difft-min(difft))==min(abs(difft-min(difft))));
        
        disp(sites{ss});
        disp(lonWWM(inds(ss)));
        disp(latWWM(inds(ss)));
        
    else
        indy(ss)=NaN;
        indx(ss)=NaN;
        disp([sites{ss},' is not in domain']);
        
    end
end

for ff=1:length(files)
    infile=[inDir,files(ff).name];
    disp(infile);
    oceantime=datenum(1858,11,17)+ncread(infile,'ocean_time')/86400;
    
    if ff>1
        l1=length(output.(sites{10}).time);
        l2=length(oceantime);
    end
    
    for vv=1:length(stdvars)
        disp(stdvars{vv});
        % tmp=ncread(infile,vars{vv},[indx indy 1],[1 1 Inf]);
        tmp=ncread(infile,vars{vv});
        
        if ff==1
            for ss=1:length(sites)
                if InGrid(ss)==1
                    output.(sites{ss}).(stdvars{vv})=tmp(inds(ss),:);
                    if vv==1
                        output.(sites{ss}).time=oceantime;
                    end
                end
                
            end
        else
            for ss=1:length(sites)
                if InGrid(ss)==1
                    
                    output.(sites{ss}).(stdvars{vv})(l1+1:l1+l2)=tmp(inds(ss),:);
                    if vv==1
                        output.(sites{ss}).time(l1+1:l1+l2)=oceantime;
                    end
                end
                
            end
        end
        clear tmp;
    end
    
end

save(exports,'output','-mat','-v7.3');
clear output;

%% export SWAN grids

infiles={'./WWM_SWAN_CONV_Agrid.nc';...
    './WWM_SWAN_CONV_Bgrid.nc';...
    './WWM_SWAN_CONV_Cgrid.nc'};

exports={'INTERP_Grid_A_sites.mat';...
    'INTERP_Grid_B_sites.mat';...
    'INTERP_Grid_C_sites.mat'};


for ii=1:length(infiles)
    infile=infiles{ii};
    
    switch ii
        case 1
            InGrid=inExpGdA;
        case 2
            InGrid=inExpGdB;
        case 3
            InGrid=inExpGdC;
    end
    
    disp(infile);
    disp(InGrid);
    
    Xp=ncread(infile,'Xp'); %Xpp=Xp(:,1);
    Yp=ncread(infile,'Yp');
    
    stdvars={'DIR','HS','TPER'};
    vars={'Dir','Hsig','TPsmoo'};
    
    for ss=1:length(sites)
        
        if InGrid(ss)==1
            slon=lons(ss);
            slat=lats(ss);
            
            diffx=Xp-slon;
            diffy=Yp-slat;
            difft=diffx.^2+diffy.^2;
            
            aa=min(difft);
            indy(ss)=find(abs(aa-min(aa))==min(abs(aa-min(aa))));
            
            bb=min(difft');
            indx(ss)=find(abs(bb-min(bb))==min(abs(bb-min(bb))));
            
            disp(sites{ss});
            disp(Xp(indx(ss),indy(ss)));
            disp(Yp(indx(ss),indy(ss)));
            
        else
            indy(ss)=NaN;
            indx(ss)=NaN;
            disp([sites{ss},' is not in domain']);
            
        end
    end
    
    
    for vv=1:length(stdvars)
        disp(stdvars{vv});
        % tmp=ncread(infile,vars{vv},[indx indy 1],[1 1 Inf]);
        tmp=ncread(infile,vars{vv});
        
        for ss=1:length(sites)
            if InGrid(ss)==1
                output.(sites{ss}).(stdvars{vv})=squeeze(tmp(indx(ss),indy(ss),:));
                if vv==1
                    output.(sites{ss}).time=ncread(infile,'time')/24+datenum(1990,1,1);
                end
            end
            
        end
        clear tmp;
    end
    
    save(exports{ii},'output','-mat','-v7.3');
    clear output;
end

%% import AWAC data

inDir='C:\Users\00064235\AED Dropbox\AED_Cockburn_db\CSIEM\Data\data-swamp\JPPL\AWAC\JPPL_AWAC\';
sites={'a','b','c','d'};
stdvars={'DIR','HS','TPER'};
vars={'WVDIR','WVHT','WVPER'};

for ss=1:length(sites)
    infile=[inDir,'S01_',sites{ss},'\Westport_S01_',sites{ss},'.mat'];
    data=load(infile);
    
    if ss==1
        
        output.S01.time=data.DATA.SITE01.TIME_wave;
        output.S01.DIR=data.DATA.SITE01.WVDIR;
        output.S01.HS=data.DATA.SITE01.WVHT;
        output.S01.TPER=data.DATA.SITE01.WVPER;
    else
        l1=length(output.S01.time);
        l2=length(data.DATA.SITE01.TIME_wave);
        
        output.S01.time(l1+1:l1+l2)=data.DATA.SITE01.TIME_wave;
        output.S01.DIR(l1+1:l1+l2)=data.DATA.SITE01.WVDIR;
        output.S01.HS(l1+1:l1+l2)=data.DATA.SITE01.WVHT;
        output.S01.TPER(l1+1:l1+l2)=data.DATA.SITE01.WVPER;
    end
    
end

for ss=1:length(sites)
    infile=['.\Westport_S02_',sites{ss},'.mat'];
    data=load(infile);
    
    if ss==1
        
        output.S02.time=data.DATA.SITE02.TIME_wave;
        output.S02.DIR=data.DATA.SITE02.WVDIR;
        output.S02.HS=data.DATA.SITE02.WVHT;
        output.S02.TPER=data.DATA.SITE02.WVPER;
    else
        l1=length(output.S02.time);
        l2=length(data.DATA.SITE02.TIME_wave);
        
        output.S02.time(l1+1:l1+l2)=data.DATA.SITE02.TIME_wave;
        output.S02.DIR(l1+1:l1+l2)=data.DATA.SITE02.WVDIR;
        output.S02.HS(l1+1:l1+l2)=data.DATA.SITE02.WVHT;
        output.S02.TPER(l1+1:l1+l2)=data.DATA.SITE02.WVPER;
    end
    
end
save('AWAC_sites.mat','output','-mat','-v7.3');
clear output;

%% export TUFLOW

%inDir='D:\WWM_REG\2013\';
%files=dir([inDir,'*.nc']);

tfvFile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results\csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_noGW_WWM_wave.nc';
%'W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results\csiem_100_A_20130101_20130601_WQ_009_waves_wave.nc';
lonTFV=ncread(tfvFile,'cell_X');
latTFV=ncread(tfvFile,'cell_Y');
oceantime=datenum(1990,1,1)+ncread(tfvFile,'ResTime')/24;

exports='TFV_WWM_sites.mat';

InGrid=inExpGdA;

disp(tfvFile);
disp(InGrid);

stdvars={'DIR','HS','TPER'};
vars={'WVDIR','WVHT','WVPER'};

for ss=1:length(sites)
    
    if InGrid(ss)==1
        slon=lons(ss);
        slat=lats(ss);
        
        diffx=lonTFV-slon;
        diffy=latTFV-slat;
        difft=diffx.^2+diffy.^2;
        
        inds(ss)=find(abs(difft-min(difft))==min(abs(difft-min(difft))));
        
        disp(sites{ss});
        disp(lonTFV(inds(ss)));
        disp(latTFV(inds(ss)));
        
    else
        indy(ss)=NaN;
        indx(ss)=NaN;
        disp([sites{ss},' is not in domain']);
        
    end
end

for vv=1:length(stdvars)
    disp(stdvars{vv});
    % tmp=ncread(infile,vars{vv},[indx indy 1],[1 1 Inf]);
    tmp=ncread(tfvFile,vars{vv});
    
    
    for ss=1:length(sites)
        if InGrid(ss)==1
            output.(sites{ss}).(stdvars{vv})=tmp(inds(ss),:);
            if vv==1
                output.(sites{ss}).time=oceantime;
            end
        end
        
    end
    clear tmp;
end


save(exports,'output','-mat','-v7.3');
clear output;