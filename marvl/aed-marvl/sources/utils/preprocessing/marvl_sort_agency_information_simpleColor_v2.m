function [mface,mcolor,msize,agencyname] = marvl_sort_agency_information_simpleColor(agency,layer)

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


if strcmpi(agency,'CSMC-WQ') == 1
   mface = 'sk';
   msize = 3; 
  if strcmpi(layer,'surface') == 1
      mcolor = [166,206,227]./255;
  else
	  mcolor = [31,120,180]./255;
  end
elseif strcmpi(agency,'DWER-CSMOORING') == 1
   mface = 'dk';
   msize = 1;
  if strcmpi(layer,'surface') == 1
      mcolor = [178,223,138]./255;
  else
	  mcolor = [51,160,44]./255;
  end
elseif strcmpi(agency,'IMOS-ANMN-CTD') == 1
   mface = '^k';
   msize = 3;
  if strcmpi(layer,'surface') == 1
      mcolor = [251,154,153]./255;
  else
	  mcolor = [227,26,28]./255;
  end
elseif strcmpi(agency,'WWMSP5.1-WQ') == 1
   mface = 'ok';
   msize = 1;
  if strcmpi(layer,'surface') == 1
      mcolor = [217,217,217]./255;
  else
	  mcolor = [190,186,218]./255;
  end
elseif strcmpi(agency,'WWMSP5.1-AWAC') == 1
   mface = '^k';
   msize = 1;
  if strcmpi(layer,'surface') == 1
      mcolor = [204,235,197]./255;
  else
	  mcolor = [141,211,199]./255;
  end
elseif strcmpi(agency,'DWER-CSMWQ') == 1
   mface = '>k';
   msize =2;
  if strcmpi(layer,'surface') == 1
      mcolor = [202,178,214]./255;
  else
	  mcolor = [106,61,154]./255;
  end
else
   mface = 'pk';
   msize = 2;
  if strcmpi(layer,'surface') == 1
      mcolor = [255,255,153]./255;
  else
	  mcolor = [177,89,40]./255;
  end
end

agencyname = agency;


