function [mface,mcolor,agencyname] = marvl_sort_agency_information(agency)

% below is a collection of known agencies; for new sites simply add the 
%     new agency names into the 'AgencyNameCollection' list;
AgencyNameCollection={'CSMC','WC','ECCC','ECCC-WQ','ECCC-YSI','EPA','OTHER','DEW SONDE','ECCC-CGM',...
    'ECCC-PAR','DEW WDSA Hydro','UA HCHB','UA Sediment','FU TLM','UA Sonde',...
    'DEW ALS','DEW AWQC',...
    'DEW WDSA Met','DEW WDSA Sonde','SA Water','UA DO Logger',...
    'UA WQ','UA_Sonde','UA Logger','SWC',...
    'SWC-ww','DPIE-mc','DPIE-sc','WNSW','BC','DPIE-bouy','Hornsby'};

% symbol and color database
mface_options= {'ok','dk','sk','pk','hk','^k','>k'};
mcolor_options=[55,126,184;...
    77,175,74;...
    152,78,163;...
    255,127,0;...
    255,255,51;...
    166,86,40;...
    228,26,28;...
    247,129,191]./255;

% check and define agency
fgf = strcmpi(AgencyNameCollection,agency);

if sum(fgf)>0
    inds=find(fgf==1);
    ind=inds(1);

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


