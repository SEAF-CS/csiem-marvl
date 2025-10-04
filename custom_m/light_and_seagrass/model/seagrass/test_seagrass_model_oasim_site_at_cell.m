%% This is a Matlab script for the seagrass dynamic model, only consider
%  the light limitation, e.g. no temperature, salinity, and sediment
%  nutrient limitation is included.
%
%  configurations: in Seagrass_model_config.m;
%  forcing data: surface PAR data at Cockburn Sound centre, exported
%                CSIEM model, then bottom PAR is calculated based on
%                pre-set water depth and extinction coefficient

clear; close all;

% load in configuration file
run('./Seagrass_model_config.m');

% load in light data
scenario='restart_08';
load(['.\extracted_bottom_totalight_2022_',scenario,'.mat']);
outdir=['.\',scenario,'\'];
if ~exist(outdir,'dir')
    mkdir(outdir);
end

bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

%%
ncfile(1).name='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\tests_PH_map_light2_OASIM_WQ.nc';
tdat= tfv_readnetcdf(ncfile(1).name,'time',1);
PAR_time = tdat.Time;

timestep = 4/24;                   % timestpes
cellID=3240; %3243;%2955; %2955; %

save_results=1;
restart=1;
outname=['results_cell',num2str(cellID),'.mat'];

Bfile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\gis_repo\2_benthic\ecology\csiem_aed_benthic_map_A001_AUG2024_ABF.csv';
T= readtable(Bfile);

% loop through the timesteps

WLrange=[350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780.];
WLbounds=zeros(length(WLrange)+1,1);
WLwidths=zeros(length(WLbounds)-1,1);

WLbounds(1)=300;
for w=1:length(WLrange)-1
    WLbounds(w+1)=(WLrange(w+1)+WLrange(w))/2;
end
WLbounds(end)=800;

for w2=1:length(WLwidths)
    WLwidths(w2)=WLbounds(w2+1)-WLbounds(w2);
end


for b=3:14
varname=upper(['LIGHT_BAND',num2str(b)]);
Ltotal(b-2,:)=output2.(varname)(cellID,:);
end
% 
%     for b=3:14
%        varname=upper(['WQ_DIAG_OAS_DIR_BAND',num2str(b)]);
%        Ldir(b-2,:)=oasim.(varname).bottom;
% 
%        varname=upper(['WQ_DIAG_OAS_DIF_BAND',num2str(b)]);
%        Ldif(b-2,:)=oasim.(varname).bottom;
% 
%     end
% 
%     Ltotal=(Ldir+Ldif)*1.0;


    %%
for dd=1:length(PAR_time)
   PAR(dd)=sum(Ltotal(:,dd).*WLwidths);

end
% allocate biomass for AG, BG, and Fruits
MAC_A = zeros(size(PAR_time));  % leaf biomass
MAC_B = zeros(size(PAR_time));  % below-ground biomass
MAC_F = zeros(size(PAR_time));  % fruits biomass

% allocate parameters for spectral-resoved model
npp = zeros(size(PAR_time));    % net production
resp = zeros(size(PAR_time));   % respiration of AG due to compensation light
mort_A = zeros(size(PAR_time)); % mortality of leaf
mort_B = zeros(size(PAR_time)); % mortality of roots
f_tran = zeros(size(PAR_time)); % translocation rates between AG/BG
A_eff = zeros(size(PAR_time));  % effective area

% allocate parameters for total light model
gpp = zeros(size(PAR_time));           % gross production
respiration_A = zeros(size(PAR_time)); % respiraton of leaf
respiration_B = zeros(size(PAR_time)); % respiration of roots

% allocate parameters for fruiting processes
f_tran_fruit = zeros(size(PAR_time));  % translocation rate of leaf to fruits
f1 = zeros(size(PAR_time));            % f1 function for growth
f2 = zeros(size(PAR_time));            % f2 function for release

% allocate parameters for spectral-resoved model

% initialize the biomass for AG, BG, and Fruits

if restart==1
  INI=load([outdir,outname]);
  MAC_A(1)=INI.MAC_A(end);
  MAC_B(1)=INI.MAC_B(end);
  MAC_F(1)=INI.MAC_F(end);
else
MAC_A(1)=T.MAC_seagrass_ag(cellID);
MAC_B(1)=T.MAC_seagrass_bg(cellID);
MAC_F(1)=T.MAC_seagrass_fr(cellID);
end

% a control on fruit growth, becomes 0 when start releasing
trigger_fruit_growth = 1;

% loop through the timesteps
for dd=2:length(PAR_time)

        % integrated over 300-800nm to calculate photons being captured
        % Eq(8) of Baird et al. 2016
        light_int=0;
        for ll=1:length(WLrange)
            lterm1 = 1 - exp(-ALlint(ll)*Omega_MAC.*MAC_A(dd-1)*sine_blade);
            %landaimid = (landaiint(ll)+landaiint(ll+1))/2;
            %WLmid = (WLint(ll)+WLint(ll+1))/2;
            
            light_int=light_int+Ltotal(ll,dd)*WLrange(ll)*WLwidths(ll)*lterm1;
        end
        light_int_out(dd)=light_int; %*par(dd)/landaiSUM; %proportion of incoming irradiation par(dd) to clear-sky irradiance
        
        factor    = 1/(h*c*Av*1e9);    % conversion constant of photons from W/m2 to photon/m2/s
        kI(dd) = factor*light_int_out(dd);         % rate of photon capture, mol photon/m2/s;
        
        % respiration
        
        term1 = E_comp*ALl*Omega_MAC.*sine_blade; % compensation light
        term2 = 5500/550/1000*R_mort_A;           % respiration, converted to mol photon/m2/s;
        k_resp = 2*(term1 - term2)*MAC_A(dd-1);   % respiration rate in photon, Eq(9) of Baird et al. 2016
        
        
        % net production
        factor2 = 550/5500*1000*86400; % factor to converting photon to carbon, mmol C/m2/day
        
        resp(dd) = k_resp/86400;        % respiration rate in mmol C/m2/day
        npp0 = max(0,(kI(dd)-resp(dd))*factor2);    % net production rate
        npp(dd) = min(R_growth*MAC_A(dd-1),npp0); % cross-check of NPP npp0; %
        
        % mortality
        mort_A(dd) = MAC_A(dd-1)*R_mort_A * theta_resp^(T_standard-20.0);
        mort_B(dd) = MAC_B(dd-1)*R_mort_B * theta_resp^(T_standard-20.0);
        
        % translocation between AG/BG
        if MAC_A(dd-1)>0
          f_tran(dd)=(f_below - (MAC_B(dd-1))/(MAC_A(dd-1)+MAC_B(dd-1)))*(MAC_A(dd-1)+MAC_B(dd-1))*tau_tran;
        else
          f_tran(dd)=0;
        end
        
        % update AG and BG biomass, and effective projected area fraction
        % A_eff
        MAC_A(dd)= max(0,MAC_A(dd-1) + (npp(dd) - mort_A(dd) - f_tran(dd))*timestep);
        MAC_B(dd)= max(0,MAC_B(dd-1) + (- mort_B(dd) + f_tran(dd))*timestep);
        A_eff(dd) = 1 - exp(-Omega_MAC.*MAC_A(dd));
            
    % seagrass fruiting growth and release
    if Fruiting == 1
        
        % 1. get the day of the year
        t_vec = datevec(PAR_time(1));
        t = PAR_time(dd)-datenum(t_vec(1),1,1);
        
        % reset trigger for fruit to grow if t<t_start_g
        if t<t_start_g
            trigger_fruit_growth=1;
        end
        
        % 1. translocation from AG to seeds
        t_max_g=t_start_g+t_dur_g;
        tmp1=12/t_dur_g*t+6*(t_start_g+t_max_g)/(t_start_g-t_max_g);
        tmp2=exp(-tmp1);
        f1(dd)=1/(1+tmp2);

        if MAC_A(dd-1)>0
        f_tran_fruit(dd)=(f_seed-MAC_F(dd-1)/(MAC_F(dd-1)+MAC_A(dd-1)))*...
            (MAC_F(dd-1)+MAC_A(dd-1))*tau_tran_fruit*f1(dd);
        else
          f_tran_fruit(dd)=0;
        end
        
        % assume if fruit ratio reach the 90% of maximum value, then
        % stop fruit growing and start releasing at constant rate
        if MAC_F(dd-1)/(MAC_F(dd-1)+MAC_A(dd-1))>f_seed*0.9
            trigger_fruit_growth=0;
            MAC_F_release=MAC_F(dd-1)*r_release;
        end
        
        % 2. releasing
        
        t_max_r=t_start_r+t_dur_r;
        tmp12=12/t_dur_r*t+6*(t_start_r+t_max_r)/(t_start_r-t_max_r);
        tmp22=exp(-tmp12);
        f2(dd)=1/(1+tmp22);
        if trigger_fruit_growth
            MAC_F(dd)=MAC_F(dd-1)+f_tran_fruit(dd)*timestep;
            MAC_A(dd)=MAC_A(dd)-f_tran_fruit(dd)*timestep;
        else
            f_tran_fruit(dd)=0;
            f_release=MAC_F_release*f2(dd)*timestep;
            MAC_F(dd)=max(0,MAC_F(dd-1)-f_release);
            MAC_A(dd)=MAC_A(dd);
        end
    end
    
    
    
end

if save_results
    if restart==1
      save([outdir,'restart_',outname],'MAC*','kI','resp','npp','PAR_time','-mat','-v7.3'); 
    else
      save([outdir,outname],'MAC*','kI','resp','npp','PAR_time','-mat','-v7.3'); 
    end
end

%% ploting and checking

figure(1);
def.dimensions = [30 20]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

datearray=datenum(2022,1:4:13,1);

vars={'MAC_A','MAC_B','MAC_F','npp','resp','mort_A','mort_B','A_eff','f1','f2','f_tran','f_tran_fruit'};
titles={'MAC_A','MAC_B','MAC_F','NPP','Resp','mort_A','mort_B','A_{eff}','f1','f2','f_{tran-BG}','f_{tran-fruit}'};
yls={'mmol C/m^2','mmol C/m^2','mmol C/m^2','mmol C/m^2/d','mmol C/m^2/d','mmol C/m^2/d','mmol C/m^2/d','-','-','-','mmol C/m^2/d','mmol C/m^2/d'};

for vv=1:length(vars)
    subplot(3,4,vv);
    eval(['data1 = ',vars{vv},';']);

    plot(PAR_time,data1);
    
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mm/yy'));

    set(gca,'FontName','Times New Roman');
    title(titles{vv});
    ylabel(yls{vv});
end

if restart==1
  outputName=[outdir,'./seagrass-model-test-spectral-resolved-model_cellID',num2str(cellID),'_restart.jpg'];
else
  outputName=[outdir,'./seagrass-model-test-spectral-resolved-model_cellID',num2str(cellID),'.jpg'];
end
print(gcf,'-dpng',outputName);

figure(2);
plot(kI); hold on;
plot(resp,'r');