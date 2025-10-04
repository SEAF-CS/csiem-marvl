% initialize the seagrass model parameter and biomass

% load in model information
ncfile(1).name='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\tests_PH_map_light2_OASIM_WQ.nc';
tdat= tfv_readnetcdf(ncfile(1).name,'time',1);
PAR_time = tdat.Time;

allvars = tfv_infonetcdf(ncfile(1).name);
dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
cellx=ncread(ncfile(1).name,'cell_X');
celly=ncread(ncfile(1).name,'cell_Y');

Bottcells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
Bottcells(length(dat.idx3)) = length(dat.idx3);

Surfcells=dat.idx3(dat.idx3 > 0);

% allocate biomass for AG, BG, and Fruits

MAC_A = zeros(length(dat.cell_X), length(PAR_time));  % leaf biomass
MAC_B = zeros(length(dat.cell_X), length(PAR_time));  % below-ground biomass
MAC_F = zeros(length(dat.cell_X), length(PAR_time));  % fruits biomass

% allocate parameters for spectral-resoved model
npp = zeros(length(dat.cell_X), length(PAR_time));    % net production
light_int_out = zeros(length(dat.cell_X), length(PAR_time));    % photon
kI = zeros(length(dat.cell_X), length(PAR_time));    % fI
resp = zeros(length(dat.cell_X), length(PAR_time));   % respiration of AG due to compensation light
mort_A = zeros(length(dat.cell_X), length(PAR_time)); % mortality of leaf
mort_B = zeros(length(dat.cell_X), length(PAR_time)); % mortality of roots
f_tran = zeros(length(dat.cell_X), length(PAR_time)); % translocation rates between AG/BG
A_eff = zeros(length(dat.cell_X), length(PAR_time));  % effective area

% allocate parameters for total light model
gpp = zeros(length(dat.cell_X), length(PAR_time));           % gross production
respiration_A = zeros(length(dat.cell_X), length(PAR_time)); % respiraton of leaf
respiration_B = zeros(length(dat.cell_X), length(PAR_time)); % respiration of roots

% allocate parameters for fruiting processes
f_tran_fruit = zeros(length(dat.cell_X), length(PAR_time));  % translocation rate of leaf to fruits
f1 = zeros(length(dat.cell_X), length(PAR_time));            % f1 function for growth
f2 = zeros(length(dat.cell_X), length(PAR_time));           % f2 function for release
trigger_fruit_growth = ones(length(dat.cell_X), length(PAR_time));           % f2 function for release
%trigger_fruit_growth(:,1)=1;
% % allocate parameters for spectral-resoved model
% 
% % initialize the biomass for AG, BG, and Fruits
% Bfile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\gis_repo\2_benthic\ecology\csiem_aed_benthic_map_A001_AUG2024_ABF.csv';
% T= readtable(Bfile);
% 
% % MAC_A(:,1)=T.MAC_seagrass_ag;
% % MAC_B(:,1)=T.MAC_seagrass_bg;
% % MAC_F(:,1)=T.MAC_seagrass_fr;
% INI=load([outdir,'results1.mat']);
% MAC_A(:,1)=INI.MAC_A(:,end);
% MAC_B(:,1)=INI.MAC_B(:,end);
% MAC_F(:,1)=INI.MAC_F(:,end);