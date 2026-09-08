function [mface,mcolor,agencyname] = sort_agency_information_inc(agencyinc,agency)

mface_options= {'ok','dk','sk','pk','hk','^k','>k'};
mcolor_options=[228,26,28;...
55,126,184;...
77,175,74;...
152,78,163;...
255,127,0;...
255,255,51;...
166,86,40;...
247,129,191]./255;

%agencyinc=7;

opt_f=mod(agencyinc,length(mface_options));
if opt_f==0 
    opt_f=7;
end
opt_c=mod(agencyinc,size(mcolor_options,1));
if opt_c==0 
    opt_c=8;
end

mface=mface_options{opt_f};
mcolor=mcolor_options(opt_c,:);


agencyname = agency;
        
        
       