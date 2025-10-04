clear; close all;

data_dredge=load('W:\csiem\Model\TFV\export\extracted_bottom_light_2022_restart_08_dredge_IOPs.mat');
data_ori=load('W:\csiem\Model\TFV\export\extracted_bottom_light_2022_restart_08_IOPs.mat');

shp=shaperead('area_of_interest.shp');

ncfile='W:/csiem/Model/TFV/csiem_model_tfvaed_1.1/outputs/results/tests_PH_map_light2_OASIM_restart_08_WQ.nc';

dat = tfv_readnetcdf(ncfile,'time',1);
timesteps = dat.Time;

dat = tfv_readnetcdf(ncfile,'timestep',1);
clear funcions;
cellx=dat.cell_X;
celly=dat.cell_Y;
incells=inpolygon(cellx,celly,shp(1).X,shp(1).Y);

% vert(:,1) = dat.node_X;
% vert(:,2) = dat.node_Y;
% 
% faces = dat.cell_node';
% 
% %--% Fix the triangles
% faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);
% 
% surf_cellsHR=dat.idx3(dat.idx3 > 0);
% bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
% bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

for i=1:4
    for b=1:16
        varname=['WQ_DIAG_OAS_A_IOP',num2str(i),'_BAND',num2str(b)];
        disp(varname);
        tmp=data_dredge.output.(varname)(incells,:);
        WQ_dredge.iop_mean(i,b)=mean(tmp(:));
        WQ_dredge.iop_std(i,b)=std(tmp(:));

        tmp2=data_ori.output.(varname)(incells,:);
        WQ_ori.iop_mean(i,b)=mean(tmp2(:));
        WQ_ori.iop_std(i,b)=std(tmp2(:));
    end
end

vars={'WQ_NCS_SS1','WQ_OGM_DOC','WQ_DIAG_PHY_TCHLA','WQ_OGM_POC'};

for v=1:length(vars)
    varname=vars{v};
    disp(varname);
    tmp=data_dredge.output.(varname)(incells,:);
    WQ_dredge.(varname)=tmp;

    tmp2=data_ori.output.(varname)(incells,:);
    WQ_ori.(varname)=tmp2;
end

save('extracted_drdge_scens.mat','WQ*','-mat','-v7.3');
