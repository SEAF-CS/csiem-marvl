function [mface,mcolor,agencyname] = marvl_sort_agency_information_simpleColor(agency,layer)

% below is a collection of known agencies; for new sites simply add the 
%     new agency names into the 'AgencyNameCollection' list;
AgencyNameCollection={'DWER-CSMOORING','WWMSP5.1-WQ','WWMSP5.1-AWAC','CSMC-WQ','DWER-CANEST','DWER-CSMWQ','DWER-SWANCATCH',...
    'DWER-SWANEST','IMOS-ANMN-CTD','WC-BMT''DWER','WAMSI','CSMC','IMOS','WC','ECCC',...
    'ECCC-WQ','ECCC-YSI','EPA','OTHER','DEW SONDE','ECCC-CGM',...
    'ECCC-PAR','DEW WDSA Hydro','UA HCHB','UA Sediment','FU TLM','UA Sonde',...
    'DEW ALS','DEW AWQC',...
    'DEW WDSA Met','DEW WDSA Sonde','SA Water','UA DO Logger',...
    'UA WQ','UA_Sonde','UA Logger','SWC',...
    'SWC-ww','DPIE-mc','DPIE-sc','WNSW','BC','DPIE-bouy','Hornsby'};

% symbol and color database
mface_options= {'ok','dk','^k','>k','sk','pk','hk'};
mcolor_options=[166,206,227;...
31,120,180;...
178,223,138;...
51,160,44;...
253,191,111;...
255,127,0;...
202,178,214;...
106,61,154]./255;

% check and define agency
fgf = strcmpi(AgencyNameCollection,agency);

if sum(fgf)>0
    inds=find(fgf==1);
    ind=inds(1);
	
	if strcmpi(layer,'bottom') == 1
    ind=ind+1;
end 

    opt_f=mod(ind,length(mface_options));
    if opt_f==0
        opt_f=7;
    end
    opt_c=mod(ind,size(mcolor_options,1));
    if opt_c==0
        opt_c=8;
    end
    
    mface=mface_options{opt_f};
    mcolor=mcolor_options(opt_c,:);
    
else
    mface = '>k';
    mcolor = [255/255 61/255 9/255];
    
end

agencyname = agency;


