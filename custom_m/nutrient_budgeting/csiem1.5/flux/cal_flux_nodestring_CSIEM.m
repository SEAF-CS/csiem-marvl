clear; close all;
 
 % update the flux MAT file name to match the sim version
 % and output name
flux=load('./Flux_CSIEM_1p5.mat');
outname='saved_nodestring_flux_data_1p5.mat';

 % define start and end dates
t1=datenum(2023,1,1);
t2=datenum(2024,1,1);

% nodestring boundaries of interested area
nsnames={'CS_north','CS_south'};
nsnames2={'CS_north','CS_south'};
nssigns=[1,-1];

%% calculate daily nodestring data

timens=flux.flux.(nsnames{1}).mDate;

flux_vars={'NIT_amm','NIT_nit','PHS_frp','PHS_frp_ads','OGM_doc',...
    'OGM_poc','OGM_don','OGM_pon','OGM_dop','OGM_pop','PHY_mixed','PHY_pico',...
    'PHY_diatom','PHY_dino'};

flux_vars2={'AMM','NIT','FRP','FRP_ADS',...
    'DOC','POC','DON','PON','DOP','POP','MIXED','PICO',...
    'DIATOM','DINO'};

for nn=1:length(nsnames)
    for ii=1:length(flux_vars)
        data.(nsnames2{nn}).(flux_vars2{ii})=zeros(1,length(t1:t2));
        tmpflux=flux.flux.(nsnames{nn}).(flux_vars{ii});
        
        for tt=t1:t2
            inds=find(timens>=tt & timens <tt+1);
            data.(nsnames2{nn}).(flux_vars2{ii})(tt-t1+1)=mean(tmpflux(inds))*nssigns(nn)*86400;
            
        end
    end
    
    data.(nsnames2{nn}).IN=data.(nsnames2{nn}).NIT+data.(nsnames2{nn}).AMM;
    data.(nsnames2{nn}).ON=data.(nsnames2{nn}).PON+data.(nsnames2{nn}).DON;
    data.(nsnames2{nn}).PPN=(data.(nsnames2{nn}).MIXED+data.(nsnames2{nn}).PICO ...
        +data.(nsnames2{nn}).DIATOM+data.(nsnames2{nn}).DINO)*16/106;
   % data.(nsnames2{nn}).ZOON=(data.(nsnames2{nn}).CLADOCERAN+data.(nsnames2{nn}).COPEPOD)*16/106;
    
    data.(nsnames2{nn}).IP=data.(nsnames2{nn}).FRP+data.(nsnames2{nn}).FRP_ADS;
    data.(nsnames2{nn}).OP=data.(nsnames2{nn}).POP+data.(nsnames2{nn}).DOP;
    data.(nsnames2{nn}).PPP=(data.(nsnames2{nn}).MIXED+data.(nsnames2{nn}).PICO ...
        +data.(nsnames2{nn}).DIATOM+data.(nsnames2{nn}).DINO)*1/106;
%    data.(nsnames2{nn}).ZOOP=(data.(nsnames2{nn}).CLADOCERAN+data.(nsnames2{nn}).COPEPOD)*1/106;
end


save(outname,'data','-mat');

