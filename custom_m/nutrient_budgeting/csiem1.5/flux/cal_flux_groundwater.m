clear; close all;
 
 % read in groundwater influx

%  gw_folder='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\bc_repo\6_gw\CSV\';
 gw_folder='W:\WAMSI\PRAMS\';

files=dir([gw_folder,'*.csv']);

for f=1:length(files)
    disp([gw_folder,files(f).name]);
    tmp=strsplit(files(f).name,'.');
    shortnames{f}=tmp{1};
    rawdata.(shortnames{f})=tfv_readBCfile_TIME([gw_folder,files(f).name]);
end

% vars={'WQ_NIT_AMM','WQ_NIT_NIT','WQ_PHS_FRP','WQ_PHS_FRP_ADS','WQ_OGM_DON','WQ_OGM_PON','WQ_OGM_DOP','WQ_OGM_POP'};
vars={'AMM','NIT','FRP','FRP_ADS','DON','PON','DOP'};
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

fluxdata.(shortnames{f}).IN=fluxdata.(shortnames{f}).NIT+fluxdata.(shortnames{f}).AMM;
fluxdata.(shortnames{f}).ON=fluxdata.(shortnames{f}).PON+fluxdata.(shortnames{f}).DON;
fluxdata.(shortnames{f}).PPN=fluxdata.(shortnames{f}).Date*0;
% POP set to 0
fluxdata.(shortnames{f}).POP=fluxdata.(shortnames{f}).Date*0;

fluxdata.(shortnames{f}).IP=fluxdata.(shortnames{f}).FRP+fluxdata.(shortnames{f}).FRP_ADS;
fluxdata.(shortnames{f}).OP=fluxdata.(shortnames{f}).POP+fluxdata.(shortnames{f}).DOP;
fluxdata.(shortnames{f}).PPP=fluxdata.(shortnames{f}).Date*0;

fluxdata.(shortnames{f}).TN=fluxdata.(shortnames{f}).NIT ...
    +fluxdata.(shortnames{f}).AMM...
    +fluxdata.(shortnames{f}).PON...
    +fluxdata.(shortnames{f}).DON;

fluxdata.(shortnames{f}).TP=fluxdata.(shortnames{f}).FRP ...
    +fluxdata.(shortnames{f}).FRP_ADS...
    +fluxdata.(shortnames{f}).POP...
    +fluxdata.(shortnames{f}).DOP;


if f==1
    totalFlux.Flow=fluxdata.(shortnames{f}).FLOW;
    totalFlux.IN=fluxdata.(shortnames{f}).IN;
    totalFlux.ON=fluxdata.(shortnames{f}).ON;
    totalFlux.PPN=fluxdata.(shortnames{f}).PPN;
    totalFlux.IP=fluxdata.(shortnames{f}).IP;
    totalFlux.OP=fluxdata.(shortnames{f}).OP;
    totalFlux.PPP=fluxdata.(shortnames{f}).PPP;
    totalFlux.TN=fluxdata.(shortnames{f}).TN;
    totalFlux.TP=fluxdata.(shortnames{f}).TP;

else

    totalFlux.Flow=totalFlux.Flow+fluxdata.(shortnames{f}).FLOW;
    totalFlux.IN=totalFlux.IN+fluxdata.(shortnames{f}).IN;
    totalFlux.ON=totalFlux.ON+fluxdata.(shortnames{f}).ON;
    totalFlux.PPN=totalFlux.PPN+fluxdata.(shortnames{f}).PPN;
    totalFlux.IP=totalFlux.IP+fluxdata.(shortnames{f}).IP;
    totalFlux.OP=totalFlux.OP+fluxdata.(shortnames{f}).OP;
    totalFlux.PPP=totalFlux.PPP+fluxdata.(shortnames{f}).PPP;

    totalFlux.TN=totalFlux.TN+fluxdata.(shortnames{f}).TN;
    totalFlux.TP=totalFlux.TP+fluxdata.(shortnames{f}).TP;

end



end

outname='G:\CSIEM\1.6.0\outputs\sh\2023B\groundwater_influx_daily.mat';
save(outname,'rawdata','fluxdata','totalFlux','-mat');

