clear all; close all;

shpfile = '../../../gis/Zones/MLAU_Zones_v2_ll_C.shp';

shp = shaperead(shpfile);

[snum,sstr] = xlsread('Zone_Names.xlsx','A2:E1000');

for i = 1:length(shp)
    
    % if i == 39
    %     shp(i).Unit_Name = 'South Basin East';
    % end

    sss = find(strcmpi(sstr(:,1),shp(i).Unit_Name)==1);

    if length(sss) > 1
        stop;
    end

    if ~isempty(sss)
        shp(i).Name = sstr{sss,2};
        shp(i).BP_Region = sstr{sss,4};
        shp(i).Plot_Order = snum(sss,1);
        shp(i).BP_Order = snum(sss,3);
    else
        stop;
    end
end

shapewrite(shp,'../../../gis/Zones/MLAU_Zones_v3_ll.shp');