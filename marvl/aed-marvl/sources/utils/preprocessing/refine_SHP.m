function [shp, sites]=refine_SHP(shp, config)

if config.plotAllsites == 0
    shp_t = shp;
    clear shp;
    inc = 1;
    disp('Removing plotting sites');
    for bhb = 1:length(shp_t)
        
        if ismember(bhb,config.plotsite)
          %  ismember(shp_t(bhb).Plot_Order,config.plotsite)
            shp(inc) = shp_t(bhb);
            inc = inc + 1;
        end
    end
end

if ~exist('sites','var')
    sites = 1:length(shp);
end
%disp('SHP sites:')
%disp(config.plotsite);

end