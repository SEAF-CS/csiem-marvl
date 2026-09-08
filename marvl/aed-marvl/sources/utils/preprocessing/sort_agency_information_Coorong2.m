function [mface,mcolor,agencyname] = sort_agency_information_Coorong2(agency)

AgencyNameCollection={'DEW WDSA Hydro','UA HCHB','UA Sediment','FU TLM',...
    'DEW ALS','DEW AWQC',...
    'DEW WDSA Met','DEW WDSA Sonde','SA Water','UA DO Logger',...
    'UA WQ','UA_Sonde','UA Logger','ECCC','DEW SONDE','ECCC-CGM',...
    'ECCC-PAR','ECCC-WQ','ECCC-YSI','EPA','OTHER','SWC',...
    'SWC-ww','DPIE-mc','DPIE-sc','WNSW','BC','DPIE-bouy','Hornsby'};

mface_options= {'ok','dk','sk','pk','hk','^k','>k'};
mcolor_options=[55,126,184;...
    77,175,74;...
    152,78,163;...
    255,127,0;...
    255,255,51;...
    166,86,40;...
    228,26,28;...
    247,129,191]./255;

%agency='SA Water';
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
    mface = 'ok';
    mcolor = [255/255 61/255 9/255];
    
end

agencyname = agency;


