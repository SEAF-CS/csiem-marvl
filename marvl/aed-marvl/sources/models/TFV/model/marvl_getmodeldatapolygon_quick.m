function [data,c_units,isConv] = marvl_getmodeldatapolygon_quick(rawData,shp,varname,d_data,config,use_matfiles)

X=d_data.all_cellsX;
Y=d_data.all_cellsY;
sX=shp.X;
sY=shp.Y;
D=d_data.D;
%layerface=d_data.layerface;
rawGeo=d_data.rawGeo;
tdate=d_data.tdate;
depth_range=config.depth_range;
surface_offset=config.surface_offset;
pred_lims = config.pred_lims; %[0.05,0.25,0.5,0.75,0.95];

inpol = inpolygon(X,Y,sX,sY);
sss = find(inpol == 1);
if use_matfiles
    [rawData.(varname{1}).outdata.surface,c_units,isConv]  = tfv_Unit_Conversion(rawData.(varname{1}).outdata.surface,varname{1});
    [rawData.(varname{1}).outdata.bottom,c_units,isConv]  = tfv_Unit_Conversion(rawData.(varname{1}).outdata.bottom,varname{1});
else
    [rawData.(varname{1}),c_units,isConv]  = tfv_Unit_Conversion(rawData.(varname{1}),varname{1});
end
disp(['Processing ',varname{1}, ' with unit as ', c_units,'...']);

if length(sss) > 1
    
    num_lims = length(pred_lims);
    nn = (num_lims+1)/2;
    
    [iX,iY] = size(rawData.(varname{1}));
    cell_depths(1:iX,1:iY) = NaN;
    
    if length(rawData.(varname{1})) > length(D)
        if surface_offset ~= 0 % There is an offset
            
            disp('Using surface offset');
            cell_depths = calc_cell_depths(cell_depths,layerface,NL);
        end
    end
    for iii = 1:length(sss)
        pt_id(iii) = sss(iii);
        Cell_3D_IDs = find(rawGeo.idx2==pt_id(iii));
        
        if surface_offset ~= 0 % There is an offset
            the_depths = cell_depths(Cell_3D_IDs,1);
            theval = the_depths(1) + surface_offset;
            [~,ind] = min(abs(the_depths - theval));
            surfIndex(iii) = Cell_3D_IDs(ind);
        else
            surfIndex(iii) = min(Cell_3D_IDs);
        end
        botIndex(iii) = max(Cell_3D_IDs);
    end
    
    vars2D={'H','D','cell_A','cell_Zb','WVHT','WVPER','WVDIR','WVSTR_x',...
        'WVSTR_y','LW_RAD','PRECIP','REL_HUM','SW_RAD','W10_x','W10_y'};
    if ~use_matfiles
        %if strcmp(varname{1},'H') == 0 & strcmp(varname{1},'D') == 0 & strcmp(varname{1},'cell_A') == 0 & strcmp(varname{1},'cell_Zb') == 0 & strcmp(varname{1},'WVHT') == 0 & strcmp(varname{1},'W10_x') == 0 & strcmp(varname{1},'W10_y') == 0
        if sum(strcmp(vars2D,varname{1}))>0
            data.surface = rawData.(varname{1})(pt_id,:);
            data.bottom = rawData.(varname{1})(pt_id,:);
        else
            data.surface = rawData.(varname{1})(surfIndex,:);
            data.bottom = rawData.(varname{1})(botIndex,:);
        end
    else
        
        data.surface = rawData.(varname{1}).outdata.surface(pt_id,:);
        data.bottom = rawData.(varname{1}).outdata.bottom(pt_id,:);
    end
    
    point_D = D(pt_id,:);
    
    ddd = find(point_D <= depth_range(1) | point_D >= depth_range(2));
    
    data.surface(ddd) = NaN;
    data.bottom(ddd) = NaN;
    
    [~,iy] = size(data.surface);
    
    inc = 1;
    for i = 1:iy
        xd = data.surface(:,i);
        if sum(isnan(xd)) < length(xd)
            xd(isnan(xd)) = mean(xd(~isnan(xd)));
            data.pred_lim_ts(:,inc) = plims(xd,pred_lims);
            data.date(inc,1) = tdate(i);
            inc = inc + 1;
        end
    end
    
    inc = 1;
    for i = 1:iy
        xd = data.bottom(:,i);
        if sum(isnan(xd)) < length(xd)
            xd(isnan(xd)) = mean(xd(~isnan(xd)));
            data.pred_lim_ts_b(:,inc) = plims(xd,pred_lims);
            data.date_b(inc,1) = tdate(i);
            inc = inc + 1;
        end
    end
    
else
    data.surface = [];
    data.bottom = [];
    data.date(:,1) = tdate;
    data.date_b(:,1) = tdate;
    data.pred_lim_ts(1:length(pred_lims),1:length(tdate)) = NaN;
    data.pred_lim_ts_b(1:length(pred_lims),1:length(tdate)) = NaN;
    
end

