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
run('.\Seagrass_model_config.m');

% load in light data
scenario='restart_08_dredge';
load(['.\extracted_bottom_totalight_2022_',scenario,'.mat']);

outdir=['.\',scenario,'\'];
if ~exist(outdir,'dir')
    mkdir(outdir);
end
%oasim=output.Kwinana; clear output;

% light info
bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

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

%%
timestep = 4/24;                   % timestpes
save_results=1;
outname='results2_dredge.mat';

%% initialize

seagrass_model_initialize_reINI;
PAR_time=PAR_time(1:533);
% a control on fruit growth, becomes 0 when start releasing
%trigger_fruit_growth = 1;

% loop through the timesteps and cells

for cc=1:length(Bottcells)

    if mod(cc,100)==0
        disp(['Working on cell ', num2str(cc)]);
    end

for dd=2:length(PAR_time)

        % integrated over 300-800nm to calculate photons being captured
        % Eq(8) of Baird et al. 2016
        light_int=0;
        for ll=1:length(WLrange)
            lterm1 = 1 - exp(-ALlint(ll)*Omega_MAC.*MAC_A(cc,dd-1)*sine_blade);
            varname=upper(['LIGHT_BAND',num2str(ll+2)]);
            Ltotal=output2.(varname);
            
            light_int=light_int+Ltotal(cc,dd)*WLrange(ll)*WLwidths(ll)*lterm1;
        end
        light_int_out(cc,dd)=light_int; %*par(dd)/landaiSUM; %proportion of incoming irradiation par(dd) to clear-sky irradiance
        
        factor    = 1/(h*c*Av*1e9);    % conversion constant of photons from W/m2 to photon/m2/s
        kI(cc,dd) = factor*light_int_out(cc,dd);         % rate of photon capture, mol photon/m2/s;
        
        % respiration
        
        term1 = E_comp*ALl*Omega_MAC.*sine_blade; % compensation light
        term2 = 5500/550/1000*R_mort_A;           % respiration, converted to mol photon/m2/s;
        k_resp = 2*(term1 - term2)*MAC_A(cc,dd-1);   % respiration rate in photon, Eq(9) of Baird et al. 2016
        
        
        % net production
        factor2 = 550/5500*1000*86400; % factor to converting photon to carbon, mmol C/m2/day
        
        resp(cc,dd) = k_resp/86400;        % respiration rate in mmol C/m2/day
        npp0 = max(0,(kI(cc,dd)-resp(cc,dd))*factor2);    % net production rate
        npp(cc,dd) = min(R_growth*MAC_A(cc,dd-1),npp0); % cross-check of NPP npp0; %
        
        % mortality
        mort_A(cc,dd) = MAC_A(cc,dd-1)*R_mort_A * theta_resp^(T_standard-20.0);
        mort_B(cc,dd) = MAC_B(cc,dd-1)*R_mort_B * theta_resp^(T_standard-20.0);
        
        % translocation between AG/BG
        if MAC_A(cc,dd-1)>0
          f_tran(cc,dd)=(f_below - (MAC_B(cc,dd-1))/(MAC_A(cc,dd-1)+MAC_B(cc,dd-1)))*(MAC_A(cc,dd-1)+MAC_B(cc,dd-1))*tau_tran;
        else
          f_tran(cc,dd)=0;
        end
        % update AG and BG biomass, and effective projected area fraction
        % A_eff
        MAC_A(cc,dd)= MAC_A(cc,dd-1) + (npp(cc,dd) - mort_A(cc,dd) - f_tran(cc,dd))*timestep;
        MAC_B(cc,dd)= MAC_B(cc,dd-1) + (- mort_B(cc,dd) + f_tran(cc,dd))*timestep;
        A_eff(cc,dd) = 1 - exp(-Omega_MAC.*MAC_A(cc,dd));

        MAC_A(cc,dd)=max(0,MAC_A(cc,dd));
        MAC_B(cc,dd)=max(0,MAC_B(cc,dd));
            
    % seagrass fruiting growth and release
    if Fruiting == 1
        
        % 1. get the day of the year
        t_vec = datevec(PAR_time(1));
        t = PAR_time(dd)-datenum(t_vec(1),1,1);
        
        % reset trigger for fruit to grow if t<t_start_g
        if (t<t_start_g && trigger_fruit_growth(cc,dd-1)==1)
            trigger_fruit_growth(cc,dd)=1;
        end
        
        % 1. translocation from AG to seeds
        t_max_g=t_start_g+t_dur_g;
        tmp1=12/t_dur_g*t+6*(t_start_g+t_max_g)/(t_start_g-t_max_g);
        tmp2=exp(-tmp1);
        f1(cc,dd)=1/(1+tmp2);
        
        if MAC_A(cc,dd-1)>0

            f_tran_fruit(cc,dd)=(f_seed-MAC_F(cc,dd-1)/(MAC_F(cc,dd-1)+MAC_A(cc,dd-1)))*...
            (MAC_F(cc,dd-1)+MAC_A(cc,dd-1))*tau_tran_fruit*f1(cc,dd);

        else
           f_tran_fruit(cc,dd)=0;
        end
        
        % assume if fruit ratio reach the 90% of maximum value, then
        % stop fruit growing and start releasing at constant rate
        if MAC_F(cc,dd-1)/(MAC_F(cc,dd-1)+MAC_A(cc,dd-1))>f_seed*0.9
            trigger_fruit_growth(cc,dd)=0;
            
        end
        
        % 2. releasing
        
        t_max_r=t_start_r+t_dur_r;
        tmp12=12/t_dur_r*t+6*(t_start_r+t_max_r)/(t_start_r-t_max_r);
        tmp22=exp(-tmp12);
        f2(cc,dd)=1/(1+tmp22);
        if trigger_fruit_growth(cc,dd)
            MAC_F(cc,dd)=MAC_F(cc,dd-1)+f_tran_fruit(cc,dd)*timestep;
            MAC_A(cc,dd)=MAC_A(cc,dd)-f_tran_fruit(cc,dd)*timestep;
            MAC_F(cc,dd)=max(0,MAC_F(cc,dd));
            MAC_A(cc,dd)=max(0,MAC_A(cc,dd));
        else
            f_tran_fruit(cc,dd)=0;
            MAC_F_release=MAC_F(cc,dd-1)*r_release;
            f_release=MAC_F_release*f2(cc,dd)*timestep;
            MAC_F(cc,dd)=max(0,MAC_F(cc,dd-1)-f_release);
            MAC_F(cc,dd)=max(0,MAC_F(cc,dd));
            MAC_A(cc,dd)=max(0,MAC_A(cc,dd));
        end
    end
    
    
    
end

end

if save_results
    save([outdir,outname],'MAC*','kI','resp','npp','PAR_time','-mat','-v7.3'); 
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

%dat = tfv_readnetcdf(ncfile,'timestep',1);

vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;
faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

vars={'MAC_A','MAC_B','MAC_F','npp','resp','mort_A','mort_B','A_eff','f1','f2','f_tran','f_tran_fruit'};
clim1=[3e4     3e4     2e2    5e2    3e-6   1e2     2e1       1       1    1    1e1      1];
titles={'MAC_A','MAC_B','MAC_F','NPP','Resp','mort_A','mort_B','A_{eff}','f1','f2','f_{tran-BG}','f_{tran-fruit}'};
yls={'mmol C/m^2','mmol C/m^2','mmol C/m^2','mmol C/m^2/d','mmol C/m^2/d','mmol C/m^2/d','mmol C/m^2/d','-','-','-','mmol C/m^2/d','mmol C/m^2/d'};

for dd=1:100:length(PAR_time)

for vv=1:length(vars)
    clf;
eval(['data1 = ',vars{vv},';']);

%colormap('parula');
patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',data1(:,dd));shading flat;
axis equal;
set(gca,'box','on');
hold on;

hl=colorbar;

str = [': ', datestr(double(PAR_time(dd)),'yyyy/mm/dd HH:MM')];
title([vars{vv}, ' at ', str]);
clim([0 clim1(vv)]);

img_name =[outdir,vars{vv},'_',datestr(double(PAR_time(dd)),'yyyymmddHHMM'),'.png'];
saveas(gcf,img_name);

end
end

%%

figure(2);
def.dimensions = [30 20]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

datearray=datenum(2022,1:4:13,1);
cell1 = 3240;
for vv=1:length(vars)
    subplot(3,4,vv);
    eval(['data1 = ',vars{vv},';']);
    data2=data1(cell1,:);

    plot(PAR_time,data2);
    
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mm/yy'));

    set(gca,'FontName','Times New Roman');
    title(titles{vv});
    ylabel(yls{vv});
end

outputName=[outdir,'./site_output_cell1_restart.jpg'];
print(gcf,'-dpng',outputName);

%%

figure(2);
def.dimensions = [30 20]; % Width & Height in cm
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters','PaperOrientation', 'Portrait');
xSize = def.dimensions(1);
ySize = def.dimensions(2);
xLeft = (21-xSize)/2;
yTop = (30-ySize)/2;
set(gcf,'paperposition',[0 0 xSize ySize])  ;

datearray=datenum(2022,1:4:13,1);
cell1 = 3243;
for vv=1:length(vars)
    subplot(3,4,vv);
    eval(['data1 = ',vars{vv},';']);
    data2=data1(cell1,:);

    plot(PAR_time,data2);
    
    set(gca,'xlim',[datearray(1) datearray(end)],'XTick',datearray,'XTickLabel',datestr(datearray,'mm/yy'));

    set(gca,'FontName','Times New Roman');
    title(titles{vv});
    ylabel(yls{vv});
end

outputName=[outdir,'./site_output_cell2_restart.jpg'];
print(gcf,'-dpng',outputName);

