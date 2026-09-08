clear; close all;
 
 % update the flux MAT file name to match the sim version
 % and output name
flux=load('./Flux_Erie_12KIP.mat');
outname='saved_catchment_data_12KIP.mat';

 % define start and end dates
t1=datenum(2013,5,8);
t2=datenum(2013,9,30);

% nodestring boundaries of interested area
nsnames={'Bound1','Bound2','Bound3'};
nsnames2={'Bound1','Bound2','Bound3'};
nssigns=[1,1,1];


%% calculate the daily inflow nutrient load to interested area
Gra='/Projects2/Erie/erie_tfv_aed_2013_ver012_rev0/erie_tfv_aed_2013_ver012_rev0/BCs/Inflows/2002-14_flwi_Gra_ON-WQ_v02.csv';
disp(Gra);
tmp=tfv_readBCfile_TIME(Gra);
timens=tmp.Date;
data.Gra.FLOW=zeros(1,length(t1:t2));

% BC variabales and scale, Matt may change the BC scales in each test sim, so need to check out the sim FVC file to update the BC scales
BCvars  ={'Q','SAL','TEMP','T1','SS1','AGE','OXY','SIL','AMM','NIT','FRP','FRP_ADS',...
    'DOC','POC','DON','PON','DOP','POP','CY','CYr','CYin','CYip','CH','CHin','CHip',...
    'CR','CRin','CRip','ED','EDin','EDip','LD','LDin','LDip','CGM','CGMip','BIVF'};
BCscale =[1,1,1,1,1,1,1,1,1,1,0.6,0.6,1,1,1,1,0.6,0.6,1,1,1,0.6,1,1,0.6,1,1,0.6,1,1,0.6,1,1,0.6,1,0.6,1];

for ii=1:length(BCvars)
    
    data.Gra.(BCvars{ii})=zeros(1,length(t1:t2));
    
    tmpt=tmp.Q.*tmp.(BCvars{ii});
    for tt=t1:t2
        inds=find(timens>=tt & timens <tt+1);
        data.Gra.FLOW(tt-t1+1)=mean(tmp.Q(inds))*86400;
        data.Gra.(BCvars{ii})(tt-t1+1)=mean(tmpt(inds))*86400*BCscale(ii);
    end
    
    
end

data.Gra.IN=data.Gra.NIT+data.Gra.AMM;
data.Gra.ON=data.Gra.PON+data.Gra.DON;
data.Gra.PPN=data.Gra.CYin+data.Gra.CHin ...
    +data.Gra.CRin+data.Gra.EDin+data.Gra.LDin;

data.Gra.IP=data.Gra.FRP+data.Gra.FRP_ADS;
data.Gra.OP=data.Gra.POP+data.Gra.DOP;
data.Gra.PPP=data.Gra.CYip+data.Gra.CHip ...
    +data.Gra.CRip+data.Gra.EDip+data.Gra.LDip;

%% load nodestring data

timens=flux.flux.(nsnames{1}).mDate;

flux_vars={'SIL_rsi','NIT_amm','NIT_nit','PHS_frp','PHS_frp_ads','OGM_doc',...
    'OGM_poc','OGM_don','OGM_pon','OGM_dop','OGM_pop','PHY_cyano','PHY_cyano_rho',...
    'PHY_cyano_IN','PHY_cyano_IP','PHY_chlor','PHY_chlor_IN','PHY_chlor_IP',...
    'PHY_crypt','PHY_crypt_IN','PHY_crypt_IP','PHY_ediat','PHY_ediat_IN',...
    'PHY_ediat_IP','PHY_ldiat','PHY_ldiat_IN','PHY_ldiat_IP','MAG_cgm','MAG_cgm_IP','BIV_filtfrac'};

flux_vars2={'SIL','AMM','NIT','FRP','FRP_ADS',...
    'DOC','POC','DON','PON','DOP','POP','CY','CYr','CYin','CYip','CH','CHin','CHip',...
    'CR','CRin','CRip','ED','EDin','EDip','LD','LDin','LDip','CGM','CGMip','BIVF'};

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
    data.(nsnames2{nn}).PPN=data.(nsnames2{nn}).CYin+data.(nsnames2{nn}).CHin ...
        +data.(nsnames2{nn}).CRin+data.(nsnames2{nn}).EDin+data.(nsnames2{nn}).LDin;
    
    data.(nsnames2{nn}).IP=data.(nsnames2{nn}).FRP+data.(nsnames2{nn}).FRP_ADS;
    data.(nsnames2{nn}).OP=data.(nsnames2{nn}).POP+data.(nsnames2{nn}).DOP;
    data.(nsnames2{nn}).PPP=data.(nsnames2{nn}).CYip+data.(nsnames2{nn}).CHip ...
        +data.(nsnames2{nn}).CRip+data.(nsnames2{nn}).EDip+data.(nsnames2{nn}).LDip;
    
end


save(outname,'data','-mat');

