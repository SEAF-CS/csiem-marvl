function [data,c_units,isConv] = marvl_getmodeldatapolygon_quick_ROMS(ncfile,shp,loadname,d_data,config)
%clear; close all;
%run('E:\database\AED-MARVl-v0.3\Examples\Cockburn\MARVL.m');
%ncfile = 'E:\database\AED-MARVl-v0.3\Examples\Cockburn\Data\ROMS\ROMS_combined2.nc';
%master=MARVLs.master;
%config=MARVLs.timeseries;
%loadname={'TEMP'};
%[t_data, d_data]=pre_load_model_GEOs_ROMS(master.ncfile);
X=d_data.all_cellsX;
Y=d_data.all_cellsY;
%[xx,yy]=meshgrid(X,Y);
%shp = shaperead(config.polygon_file);
%[X2,Y2]=ll2utm(Y,X);
%sX=shp.X;
%sY=shp.Y;

for ii=1:length(shp.X)
        [sX(ii),sY(ii)]=utm2ll(shp.X(ii),shp.Y(ii),[50 6]);
end

%D=d_data.D;
%layerface=d_data.layerface;
%rawGeo=d_data.rawGeo;
tdate=d_data.tdate;
%depth_range=config.depth_range;
%surface_offset=config.surface_offset;
pred_lims = config.pred_lims; %[0.05,0.25,0.5,0.75,0.95];

inpol = inpolygon(X,Y,sX,sY);
sss = find(inpol == 1);

%[rawData.(varname{1}),c_units,isConv]  = tfv_Unit_Conversion(rawData.(varname{1}),varname{1});

%disp(['Processing ',varname{1}, ' with unit as ', c_units,'...']);

if length(sss) >= 1
    
    dataSurf=ncread(ncfile,[loadname{1},'surf']);
    dataBot=ncread(ncfile,[loadname{1},'bot']);
    for t=1:length(tdate)
        
        tmpSurf=squeeze(dataSurf(:,:,t));
        tmpBot=squeeze(dataBot(:,:,t));
        tmpSurf2=tmpSurf(inpol);
        tmpBot2=tmpBot(inpol);
        tmpSurf3=tmpSurf2(~isnan(tmpSurf2));
        tmpBot3=tmpBot2(~isnan(tmpBot2));
        
        data.surface(:,t) =NaN; %tmpSurf3;
        data.bottom(:,t) = NaN; %tmpBot3;
        
        if length(sss) <3
            data.pred_lim_ts(1:length(pred_lims),t)=mean(tmpSurf3);
        data.pred_lim_ts_b(1:length(pred_lims),t) = mean(tmpBot3);
        else
        data.pred_lim_ts(:,t)=plims(tmpSurf3,pred_lims);
        data.pred_lim_ts_b(:,t) = plims(tmpBot3,pred_lims);
        end
    end
    
    data.date(:,1) = tdate;
    data.date_b(:,1) = tdate;
    
    
else
    data.surface = [];
    data.bottom = [];
    data.date(:,1) = tdate;
    data.date_b(:,1) = tdate;
    data.pred_lim_ts(1:length(pred_lims),1:length(tdate)) = NaN;
    data.pred_lim_ts_b(1:length(pred_lims),1:length(tdate)) = NaN;
    
end

[data.surface,c_units,isConv]  = tfv_Unit_Conversion(data.surface,loadname{1});