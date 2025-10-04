clear; close all;
 
 % read in groundwater influx

%  gw_folder='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\bc_repo\6_gw\CSV\';
 gw_folder='/Projects2/csiem/model/csiem_model_tfvaed_1.6/bc_repo/6_gw/CSV/';

files=dir([gw_folder,'*.csv']);

for f=1:length(files)
    disp([gw_folder,files(f).name]);
    tmp=strsplit(files(f).name,'.');
    shortnames{f}=tmp{1};
    rawdata.(shortnames{f})=tfv_readBCfile_TIME([gw_folder,files(f).name]);
end

vars={'WQ_NIT_AMM','WQ_NIT_NIT','WQ_PHS_FRP','WQ_PHS_FRP_ADS','WQ_OGM_DON','WQ_OGM_PON','WQ_OGM_DOP','WQ_OGM_POP'};

 % define start and end dates
t1=datenum(2023,1,1);
t2=datenum(2024,1,1);

timearray=t1:t2;


%% calculate the daily inflow nutrient load to interested area

for f=1:length(files)

    tmp=rawdata.(shortnames{f});
timens=tmp.Date;
fluxdata.(shortnames{f}).Date=timearray;
fluxdata.(shortnames{f}).FLOW=interp1(timens,tmp.Flow,timearray)*86400;

totalFlux.Date=t1:t2;

for ii=1:length(vars)
    tmpt=tmp.Flow.*tmp.(vars{ii});
    fluxdata.(shortnames{f}).(vars{ii})=interp1(timens,tmpt,timearray)*86400;
end

fluxdata.(shortnames{f}).IN=fluxdata.(shortnames{f}).WQ_NIT_NIT+fluxdata.(shortnames{f}).WQ_NIT_AMM;
fluxdata.(shortnames{f}).ON=fluxdata.(shortnames{f}).WQ_OGM_PON+fluxdata.(shortnames{f}).WQ_OGM_DON;
fluxdata.(shortnames{f}).PPN=fluxdata.(shortnames{f}).Date*0;

fluxdata.(shortnames{f}).IP=fluxdata.(shortnames{f}).WQ_PHS_FRP+fluxdata.(shortnames{f}).WQ_PHS_FRP_ADS;
fluxdata.(shortnames{f}).OP=fluxdata.(shortnames{f}).WQ_OGM_POP+fluxdata.(shortnames{f}).WQ_OGM_DOP;
fluxdata.(shortnames{f}).PPP=fluxdata.(shortnames{f}).Date*0;

if f==1
    totalFlux.Flow=fluxdata.(shortnames{f}).FLOW;
    totalFlux.IN=fluxdata.(shortnames{f}).IN;
    totalFlux.ON=fluxdata.(shortnames{f}).ON;
    totalFlux.PPN=fluxdata.(shortnames{f}).PPN;
    totalFlux.IP=fluxdata.(shortnames{f}).IP;
    totalFlux.OP=fluxdata.(shortnames{f}).OP;
    totalFlux.PPP=fluxdata.(shortnames{f}).PPP;

else

    totalFlux.Flow=totalFlux.Flow+fluxdata.(shortnames{f}).FLOW;
    totalFlux.IN=totalFlux.IN+fluxdata.(shortnames{f}).IN;
    totalFlux.ON=totalFlux.ON+fluxdata.(shortnames{f}).ON;
    totalFlux.PPN=totalFlux.PPN+fluxdata.(shortnames{f}).PPN;
    totalFlux.IP=totalFlux.IP+fluxdata.(shortnames{f}).IP;
    totalFlux.OP=totalFlux.OP+fluxdata.(shortnames{f}).OP;
    totalFlux.PPP=totalFlux.PPP+fluxdata.(shortnames{f}).PPP;

end



end

outname='groundwater_influx_daily.mat';
save(outname,'rawdata','fluxdata','totalFlux','-mat');

