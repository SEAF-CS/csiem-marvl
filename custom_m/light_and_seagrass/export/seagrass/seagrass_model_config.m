

%% configuration for general parameters

% initial condition
MAC_A_INI = 20000;  % above-ground (AG, leaf without seeds) biomass, mmol C/m2
MAC_B_INI = 20000;  % below-ground (BG) biomass, mmol C/m2

% options
Light_model = 2;   % 1: total light model; 2: spectral-resolved model
Fruiting    = 1;   % 0: no fruiting; 1: include fruiting

% BGC parameters
R_growth = 0.2;    % maximum AG growth rate, /day
theta_resp=1.01;   % theta coefficient for respiration
T_standard=20;     % standard temperature for respiration
f_below=0.5;       % BG/(AG+BG) fraction
Omega_MAC = 3e-3;  %0.0011; % carbon-specific area of seagrass (mmol C/m2)^-1, converted from (240 mgC/m2)^-1
tau_tran = 0.06; %0.033;  % AG/BG translocation rate, /day
sine_blade = 0.5;  % sine blade shape

% fruiting parameters
MAC_F_INI = 0;    % initial fruit biomass, mmol C/m2
tau_tran_fruit=0.1;  % translocation rate from leaves to fruit, /day
r_release=0.5;    % fruit releasing rate, /day (assume all fruit released in 10 days)

f_seed =0.1;       % seed biomass/(AG+seed biomass) fraction
t_start_g = 210;   % calenda day to grow, days of the year
t_dur_g = 30;      % duration to reach maximum growth, days

t_start_r = 270;   % calenda day to release fruits, days of the year
t_dur_r = 5;       % duration to reach maximum release, days




%% total light model parameters

I_K=80; % Half saturation constant for light limitation of growth
%I_S=120;  % Saturating light intensity for optimum photosynthesis
kA = 1;   % shelf shading effect

R_resp_A = 0.06;   % maximum AG respiration rate, /day
R_resp_B = 0.004;  % maximum BG respiration rate, /day

% fT = 1; % no temperature limiation
% fS = 1; % no salinity limiation
% fN = 1; % no sediment nutrient limiation

%% spectral-resolved parameters

WL_range = [300 800]; % wavelength range
WL_mean  = 550;       % mean wavelength, nm

h = 6.626e-34;  % Planck constant, Js;
c = 2.998e8;    % light speed, m/s;
Av= 6.02e23;    % Avagadro number, /mol, convert light capture to units of mol photon/m2/s;

E_comp = 5; %4.5*3.5; % compensation scalar PAR irradiance, mol photon/m2/d;
R_mort_A = 0.01;   % maximum AG mortality rate, /day
R_mort_B = 0.004;  % maximum BG mortality rate, /day

%% clear-sky wave lengths and irradiance at a particular wave-band W/m2/nm, from EMS model
% wave lengths
wavei = [140.00, 150.00, 160.00, 170.00, ...
    180.00, 190.00, 200.00, 205.00, 210.00, 215.00, 220.00, ...
    225.00, 230.00, 235.00, 240.00, 245.00, 250.00, 255.00, ...
    260.00, 265.00, 270.00, 275.00, 280.00, 285.00, 290.00, ...
    295.00, 300.00, 305.00, 310.00, 315.00, 320.00, 325.00, ...
    330.00, 335.00, 340.00, 345.00, 350.00, 355.00, 360.00, ...
    365.00, 370.00, 375.00, 380.00, 385.00, 390.00, 395.00, ...
    400.00, 405.00, 410.00, 415.00, 420.00, 425.00, 430.00, ...
    435.00, 440.00, 445.00, 450.00, 455.00, 460.00, 465.00, ...
    470.00, 475.00, 480.00, 485.00, 490.00, 495.00, 500.00, ...
    505.00, 510.00, 515.00, 520.00, 525.00, 530.00, 535.00, ...
    540.00, 545.00, 550.00, 555.00, 560.00, 565.00, 570.00, ...
    575.00, 580.00, 585.00, 590.00, 595.00, 600.00, 610.00, ...
    620.00, 630.00, 640.00, 650.00, 660.00, 670.00, 680.00, ...
    690.00, 700.00, 710.00, 720.00, 730.00, 740.00, 750.00, ...
    800.00, 850.00, 900.00, 950.00, 1000.00, 1100.00, 1200.00, ...
    1300.00, 1400.00, 1500.00, 1600.00, 1700.00, 1800.00, 1900.00, ...
    2000.00, 2100.00, 2200.00, 2300.00, 2400.00, 2500.00, 2600.00, ...
    2700.00, 2800.00, 2900.00, 3000.00, 3100.00, 3200.00, 3300.00, ...
    3400.00, 3500.00, 3600.00, 3700.00, 3800.00, 3900.00, 4000.00, ...
    4100.00, 4200.00, 4300.00, 4400.00, 4500.00, 4600.00, 4700.00, ...
    4800.00, 4900.00, 5000.00, 6000.00, 7000.00, 8000.00 ];

% clear-sky irradiance at a particular wave-band W/m2/nm, from EMS model
landai = [ 0.0000, 0.0001, 0.0000, 0.0004, ...
    0.0009,0.0017,0.0030,0.0050,0.0100,0.0180,0.0300,0.0420,0.0520, ...
    0.0540,0.0580,0.0640,0.0640,0.1000,0.1300,0.2000,0.2500,0.2200, ...
    0.2400,0.3400,0.5200,0.6300,0.6100,0.6700,0.7600,0.8200,0.8500, ...
    1.0200,1.1500,1.1100,1.1100,1.1700,1.1800,1.1600,1.1600,1.2900, ...
    1.3300,1.3200,1.2300,1.1500,1.1200,1.2000,1.5400,1.8800,1.9400, ...
    1.9200,1.9200,1.8900,1.7800,1.8200,2.0300,2.1500,2.2000,2.1900, ...
    2.1600,2.1500,2.1700,2.2000,2.1600,2.0300,1.9900,2.0400,1.9800, ...
    1.9700,1.9600,1.8900,1.8700,1.9200,1.9500,1.9700,1.9800,1.9800, ...
    1.9500,1.9200,1.9000,1.8900,1.8700,1.8700,1.8700,1.8500,1.8400, ...
    1.8300,1.8100,1.7700,1.7400,1.7000,1.6600,1.6200,1.5900,1.5500, ...
    1.5100,1.4800,1.4400,1.4100,1.3700,1.3400,1.3000,1.2700,1.1270, ...
    1.0030,0.8950,0.8030,0.7250,0.6060,0.5010,0.4060,0.3280,0.2670, ...
    0.2200,0.1820,0.1520,0.1274,0.1079,0.0917,0.0785,0.0676,0.0585, ...
    0.0509,0.0445,0.0390,0.0343,0.0303,0.0268,0.0230,0.0214,0.0191, ...
    0.0171,0.0153,0.0139,0.0125,0.0114,0.0103,0.0095,0.0087,0.0080, ...
    0.0073,0.0067,0.0061,0.0056,0.0051,0.0048,0.0044,0.0042,0.0021, ...
    0.0012,0.0006];

% calculate the integrated irradiance over the 300-800 nm wave lengths
WLint=wavei(27:103);              % 300-800 nm
landaiint=landai(27:103);         % corresponding irradiance at 300-800 nm

% total irradiance integrate over the 300-800 nm
landaiSUM=0;
for ww=1:length(WLint)-1
    landaimid = (landaiint(ww)+landaiint(ww+1))/2;
    WLmid = (WLint(ww)+WLint(ww+1))/2;
    landaiSUM=landaiSUM+landaimid*(WLint(ww+1)-WLint(ww));
end

%% leaf light absorbance at wave lengths, from Baird et al., 2016
Wli =[300  390  500  530  640  680  705  800];
ALli=[0.72 0.72 0.68 0.38 0.38 0.60 0.04 0.0];
WLrange=[350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780.];
% interpolate into fine-resolution wave lengths for further processing
%ALlint=interp1(Wli,ALli,WLint);
ALlint=interp1(Wli,ALli,WLrange);
ALl=mean(ALlint);  % overall leaf absorbance

