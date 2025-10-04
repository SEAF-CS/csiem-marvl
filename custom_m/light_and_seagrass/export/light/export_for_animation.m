clear; close all;

ncfile.name='/Projects2/csiem/Model/TFV/csiem_model_tfvaed_1.1/outputs/results/tests_PH_map_light2_OASIM_restart_08_hourly_WQ.nc';

dat = tfv_readnetcdf(ncfile.name,'time',1);
timesteps = dat.Time;

dat = tfv_readnetcdf(ncfile.name,'timestep',1);
clear funcions

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

XX0=115.7225;YY0=-32.1824;
config.siteX=XX0;config.siteY=YY0;

xdist=dat.cell_X-XX0;ydist=dat.cell_Y-YY0;
tdist=sqrt(xdist.^2+ydist.^2);
cellind=find(abs(tdist)==min(abs(tdist)));

groups={'A','B','DIR','DIF','DIR_SF','DIF_SF'};
allvars = tfv_infonetcdf(ncfile(1).name);


%%

readdata=1;

if readdata
    %load('./export_light_data_profiles_all_20240226.mat');
    for vv=1:length(allvars)
        varname=allvars{vv};
		if any([strfind(varname,'OAS'),   strfind(varname,'PHY_PAR'), ...
                strfind(varname,'TOT_EXTC')])
				tic
        disp(varname);
        loadname=varname;
        rawData=load_AED_vars(ncfile,1,loadname,allvars);
        [rawData.data.(loadname),c_units,isConv]  = tfv_Unit_Conversion(rawData.data.(loadname),loadname);
        dataALL.(allvars{vv}) = tfv_getmodeldatalocation(ncfile(1).name,rawData.data,config.siteX,config.siteY,{loadname});
		toc
        end
    end
    
    save('./export_light_data_profiles_all_restart_08_hourly.mat','dataALL','-mat','-v7.3');
else
    
    load('./export_light_data_profiles_all_restart_08_hourly.mat');
end
