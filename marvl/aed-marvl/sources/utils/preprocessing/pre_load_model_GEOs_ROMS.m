
%--------------------------------------------------------------------------
function [t_data, d_data]=pre_load_model_GEOs_ROMS(ncfile)
    t_data=struct;
    d_data=struct;
    
    for mod = 1:length(ncfile)
        allvars = tfv_infonetcdf(ncfile(mod).name);
        disp(['Model to plot: ',ncfile(mod).name]);
        
        if isfield(ncfile(mod),'tag') && strcmpi(ncfile(mod).tag,'ROMS')
            d_data(mod).all_cellsX = double(ncread(ncfile(mod).name,'lon'));
            d_data(mod).all_cellsY = double(ncread(ncfile(mod).name,'lat'));
            d_data(mod).D = double(ncread(ncfile(mod).name,'depth'));
            time_origin = ncreadatt(ncfile(mod).name,'time','time_origin');
            d_data(mod).tdate = double(ncread(ncfile(mod).name,'time'))/24 ...
                + datenum(time_origin,'yyyy-mm-dd HH:MM:SS');
            
            ncid = netcdf.open(ncfile(mod).name,'NC_NOWRITE');
            [numdims, numvars, numglobalatts, unlimdimID] = netcdf.inq(ncid);
            
            for n=1:numvars
             varname = netcdf.inqVar(ncid,n-1);
             t_data(mod).fields{n}=varname;
            end
            netcdf.close(ncid);
            t_data(mod).all_cellsX=d_data(mod).all_cellsX;
            t_data(mod).all_cellsY=d_data(mod).all_cellsY;
        else
        t_data(mod).fields = tfv_readnetcdf(ncfile(mod).name,'timestep',1);
        d_data(mod).all_cellsX = double(t_data(mod).fields.cell_X);
        d_data(mod).all_cellsY = double(t_data(mod).fields.cell_Y);
        
        if isfield(ncfile(mod),'tfv')
            ttdata = tfv_readnetcdf(ncfile(mod).tfv,'names','D');
        else
            if sum(strcmpi(allvars,'D')) == 1
                ttdata = tfv_readnetcdf(ncfile(mod).name,'names','D');
            elseif sum(strcmpi(allvars,'H')) == 1
                tttdata = tfv_readnetcdf(ncfile(mod).name,'names',{'cell_Zb';'H'}); 
                ttdata.D = tttdata.H - tttdata.cell_Zb;clear tttdata;
            else
                tttdata = tfv_readnetcdf(ncfile(mod).name,'names',{'cell_Zb'}); 
                ttdata.D = - tttdata.cell_Zb;clear tttdata;    
            end
        end

        d_data(mod).D = ttdata.D;
         vars2D={'H','D','cell_A','cell_Zb','WVHT','WVPER','WVDIR','WVSTR_x',...
        'WVSTR_y','LW_RAD','PRECIP','REL_HUM','SW_RAD','W10_x','W10_y'};
    
%        if sum(strcmp(vars2D,varname{1}))>0
%            continue;
%        else
%         ttdata_1 = tfv_readnetcdf(ncfile(mod).name,'names',{'layerface_Z';'NL'});
%         d_data(mod).layerface = ttdata_1.layerface_Z;
%         d_data(mod).NL = ttdata_1.NL;
%        end
        d_data(mod).rawGeo = t_data(mod).fields;
        
        dat = tfv_readnetcdf(ncfile(mod).name,'time',1);
        d_data(mod).tdate = dat.Time;

        end
    end
end

