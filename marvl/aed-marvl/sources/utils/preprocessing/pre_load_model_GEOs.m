
%--------------------------------------------------------------------------
function [t_data, d_data]=pre_load_model_GEOs(ncfile)
    t_data=struct;
    d_data=struct;
    allvars = tfv_infonetcdf(ncfile(1).name);
    for mod = 1:length(ncfile)
        disp(['Model to plot: ',ncfile(mod).name]);
        t_data(mod).fields = tfv_readnetcdf(ncfile(mod).name,'timestep',1);
        d_data(mod).all_cellsX = double(t_data(mod).fields.cell_X);
        d_data(mod).all_cellsY = double(t_data(mod).fields.cell_Y);
        
        if isfield(ncfile(mod),'tfv')
            ttdata = tfv_readnetcdf(ncfile(mod).tfv,'names','D');
        else
            if sum(strcmpi(allvars,'D')) == 1
                ttdata = tfv_readnetcdf(ncfile(mod).name,'names','D');
            else
                tttdata = tfv_readnetcdf(ncfile(mod).name,'names',{'cell_Zb';'H'}); 
                ttdata.D = tttdata.H - tttdata.cell_Zb;clear tttdata;
            end
        end

        d_data(mod).D = ttdata.D;
        ttdata_1 = tfv_readnetcdf(ncfile(mod).name,'names',{'layerface_Z';'NL'});
        d_data(mod).layerface = ttdata_1.layerface_Z;
        d_data(mod).NL = ttdata_1.NL;
        d_data(mod).rawGeo = t_data(mod).fields;
        
        dat = tfv_readnetcdf(ncfile(mod).name,'time',1);
        d_data(mod).tdate = dat.Time;

    end
end

