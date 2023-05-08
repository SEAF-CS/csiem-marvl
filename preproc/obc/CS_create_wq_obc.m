%% CS_create_WQ_obc
%
% Script to create scalar water quality open bc file from:
%   1) CSMC grab samples from wq monitoring data
%   2) NASA Chla weekly data interpolated
%   3) POPCORN
% Written for A11348 Cockburn Sound BGC Model
%
% Inputs:
%   WQ_locs = location data of observed Cockburn Sound marine water quality data
%   NASA_fname = direction and file names for NASA Chla data
%   WQ_mat = matfile of Cockburn Sound observed data
%
% Ouputs:
%   bcdata = MATLAB data structure containing processed wq bc data for
%   TUFLOW FV scalar bc file
%
% Uses:
%     myfigure.m myaxes.m
%
% Keywords:  CSMC WQ open bc create
%
% Created by: Louise Bruce <Louise.Bruce@bmtglobal.com>
% Created on: 18 December 2022
%
% Based on: "\\bmw-per-fp01\WAP\MPA\1758_BarramundiEIA\2Exectn\3Modelling\Processing\02_Preprocessed\bcs\obc\scripts\create_ConeBay_wq_bc.m"
%
% Modified
%   1) 
%

%% Clean up
clear
close all
%clear path

%% Set path to functions
addpath(genpath('..\..\3Functions\'));

%% Set folder and file locations
NS_locs = '..\..\..\2Modelling\2TUFLOWFV\model\gis\csv\WQ_OBC_nodestring_midpoints.csv'; %Location of extraction points;
WQ_mat = '..\..\WQ_data\matfiles\WQ_data_2013to2015.mat';
NASA_fname = '..\..\WQ_data\matfiles\NASA_data_2013to2015.mat';
mod_fname = '..\..\..\2Postprocessed\1Matlab_scripts\matfiles\000_OBC_A14_20130101_20131231_ts.mat'; %Name of model profiles for temp and salt
bc_dir= '..\files\';
bc_fname = 'CS_obc_WQ_NSX_20130101_20131231.csv';
plot_dir = '..\plots\';

%% Set user info
bc_yrs = {'2013'};
bc_mnths = {'July','August','September','October','November','December', ...
            'January','February','March','April','May','June'};
tm_rng = [datenum('1-Jan-2013') datenum('31-Dec-2013')];
bc_time = (tm_rng(1):tm_rng(2))';

%Variables to include in open bc - 1 TFV tracer and 1 AED SS, 11 WQ and 5
%Phytos = 18 total
varnames = {'TSS','DO','AMM','NIT','FRP', ...
            'POC','DOC','PON','DON','POP','DOP', ...
            'GRN','BGA','CRYPT','MDIAT','DINO','ZEROS','ONES'};
 
%% Figure properties
%Set figure properties
fig_orientation='portrait';
leg_pos=[0.3455 0.02 0.309 0.0353]; % position of legend on figure
text_size=10; % size of label font on plot.0
% Set the colours from BMT colour pallete
load('BMT_colour_palette.mat');
BMT_lncol{1} = BMTcolours.line.Pantone302_100; %blue
BMT_lncol{2} = BMTcolours.line.Pantone802_100; %green
BMT_lncol{3} = BMTcolours.line.Pantone166_100; %orange
BMT_lncol{4} = BMTcolours.line.Pantone7466_100; %aqua
BMT_lncol{5} = BMTcolours.line.RubineRed_100; %pink
BMT_lncol{6} = BMTcolours.line.Pantone397_100; %pink
% load variable names and units
CS_plotvars_setup

%% Load CSMC field data
load(WQ_mat)
%Sample locations
CSMC_locs = readtable(NS_locs);

%% Plot corellations between Chla and other observed variables
%Variables
vars2plot={'TSS','DO','AMM','NIT','FRP','TN','TP'};
plt_sites = {'CS4','CS8','CS13','CS11','WSS4'};
%set up figure
fg=myfigure(1,'papertype','A4','paperorientation',fig_orientation);
ax=myaxes(fg,length(vars2plot),1,...
    'left_buff',0.08,'right_buff',0.05,'top_buff',0.05,'bot_buff',0.08);
mod_plts=[]; % arrays for plot handles
set(ax,'nextplot','add'); % subsequent plots to axes do not overwrite existing
% plot
for var_i = 1:length(vars2plot)
    vname = vars2plot{var_i};
    for ii = 1:length(plt_sites)
        sname = plt_sites{ii};
        if length(CS_data.(sname).(vname).Surface.data) == length(CS_data.(sname).CHLA.Surface.data)
            bc_plts(var_i)=plot(ax(var_i),CS_data.(sname).CHLA.Surface.data,CS_data.(sname).(vname).Surface.data, ...
                           'linestyle','none','markeredgecolor',BMT_lncol{ii},'markerfacecolor',BMT_lncol{ii},'marker','.');
        end
    end
    xlabel(ax(var_i),[pltvars.CHLA.longname ' (' pltvars.CHLA.units ')']);%,'fontsize',text_size,'fontweight','bold');
    ylabel(ax(var_i),[pltvars.(vname).longname ' (' pltvars.(vname).units ')']);%,'fontsize',text_size,'fontweight','bold');
end
% Add legend
ax_hidden=axes('position',[0,0,1,1]); % hidden axes to aid legend control
lg_str = {};
for site_i = 1:length(plt_sites)
    sname = plt_sites{site_i};
    h(site_i)=plot(ax_hidden,[nan,nan],'linestyle','none','markeredgecolor',BMT_lncol{site_i},'markerfacecolor',BMT_lncol{site_i},'marker','.'); hold on;
    lg_str = [lg_str sname];
end
lg = legend(h,lg_str);
set(ax_hidden,'visible','off');
set(lg,'Position',leg_pos,'Interpreter', 'none',...
    'box','off','Orientation','horizontal','fontsize',8);
%save figure
pname='../plots/CSMC_Chla_vs_wq.jpeg';
print(fg,'-r400','-djpeg',pname);

%% Import NASA Chla data

% Load NASA data
load(NASA_fname);

%Read in nodestring points
NS_data = readtable(NS_locs);

%% Phytoplankton concentration
% Assume:
%   1) Dominant group is marine diatoms 80%, rest 5% each
%   2) NASA data no need for scaling
for st_i = 1:length(NS_data.Site)
    sname = NS_data.Site{st_i};
    OBC_WQ.CHLA(:,st_i) = interp1(NASA_chla.(sname).date(~isnan(NASA_chla.(sname).data)),NASA_chla.(sname).data(~isnan(NASA_chla.(sname).data)),bc_time);
end
%Fill in for start of year for NS1
OBC_WQ.CHLA(isnan(OBC_WQ.CHLA(:,1)),1) = OBC_WQ.CHLA(find(~isnan(OBC_WQ.CHLA(:,1)),1,'first'),1);

%Fill in for NaNs with median !!!!No longer needed as removed NaNs in save
% for st_i = 1:length(NS_data.Site)
%     OBC_WQ.CHLA(isnan(OBC_WQ.CHLA(:,st_i)),st_i) = median(OBC_WQ.CHLA(~isnan(OBC_WQ.CHLA(:,st_i)),st_i));
% end

%Convert from CHLA to mmolC/m3 for 5 species of phytoplankton
Phytos = {'GRN','BGA','CRYPT','MDIAT','DINO'};
CHLA_conv = [50,40,50,26,40];
fCHLA = [5,5,5,80,5];
for phy_i = 1:length(Phytos)
    OBC_WQ.(Phytos{phy_i}) = fCHLA(phy_i)/100*OBC_WQ.CHLA*CHLA_conv(phy_i)/12;
end


%% Using CSMC observed data medians at CS5 for nutrients
nut_vars = {'TSS','AMM','NIT','FRP'};
nut_conv = [1,     1/14,1/14, 1/31, 1/14,1/31];
for var_i=1:length(nut_vars)
    vname = nut_vars{var_i};
    for st_i = 1:length(NS_data.Site)
        sname = NS_data.Site{st_i};
        switch vname
            case 'TSS'
                OBC_WQ.(vname)(1:length(bc_time),st_i) = median(CS_data.CS11.(vname).Surface.data(~isnan(CS_data.CS11.(vname).Surface.data)))*nut_conv(var_i);
            otherwise
                OBC_WQ.(vname)(1:length(bc_time),st_i) = median(CS_data.CS5.(vname).Surface.data(~isnan(CS_data.CS5.(vname).Surface.data)))*nut_conv(var_i);
        end
    end
end

%% Calculate organic matter from POCORN

% Assumumptions
%   1) Ratio of DOC to POC in marine waters is 10:1
%           Based on Murray, J.W., 2000. The oceans. In International Geophysics (Vol. 72, pp. 230-278). Academic Press., Table 10.6
%           REF: https://www.sciencedirect.com/topics/earth-and-planetary-sciences/particulate-organic-carbon
%                https://doi.org/10.1016/S0074-6142(00)80116-3
%   2) Partition DON/PON and DOP/POP same ratio 10:1
%   3) Use median GO-POPCORN POC/PON/POP for Latitude -30:-33 surface
%   (Depth <10)
%           REF: Tanioka, T., Larkin, A.A., Moreno, A.R. et al. 
%           Global Ocean Particulate Organic Phosphorus, Carbon, Oxygen for Respiration, and Nitrogen (GO-POPCORN).
%           Sci Data 9, 688 (2022). https://doi.org/10.1038/s41597-022-01809-1 
%   
%       

% Calculae medians of GO-POPCORN cruises for POC/PON/POP
pocnp_data = readtable('\\bmw-per-fp01\WAP\UWA\A11348_Cockburn_Sound_BCG_Model\2Exectn\1Data\1Rcvd\20230106_GO-POPCORN\CNP_data_DRYAD_edit_2.csv');
CS_idx = find(pocnp_data.Latitude<-30&pocnp_data.Latitude>-33&pocnp_data.Depth_m_<10);
POC_med = median(pocnp_data.POC__molL_1_(CS_idx));
PON_med = median(pocnp_data.PON__molL_1_(CS_idx));
POP_med = median(pocnp_data.POP__molL_1_(CS_idx));

%Calculate POC timeseries from NASA Chla timeseries
for st_i = 1:length(NS_data.Site)
    CHLA_med = median(OBC_WQ.CHLA(:,st_i));
    OBC_WQ.POC(:,st_i) = OBC_WQ.CHLA(:,st_i)/CHLA_med*POC_med;
    OBC_WQ.DOC(:,st_i) = OBC_WQ.POC(:,st_i)*10;
    OBC_WQ.PON(:,st_i) = OBC_WQ.CHLA(:,st_i)/CHLA_med*PON_med;
    OBC_WQ.DON(:,st_i) = OBC_WQ.PON(:,st_i)*10;
    OBC_WQ.POP(:,st_i) = OBC_WQ.CHLA(:,st_i)/CHLA_med*POP_med;
    OBC_WQ.DOP(:,st_i) = OBC_WQ.POP(:,st_i)*10;
end

%% Calculate OBC TN and TP
OBC_WQ.TN = OBC_WQ.AMM + OBC_WQ.NIT + OBC_WQ.PON + OBC_WQ.DON;
OBC_WQ.TP = OBC_WQ.FRP + OBC_WQ.POP + OBC_WQ.DOP;
X_ncon = [0.151,0.151,0.151,0.137,0.151]; % Constant internal nitrogen concentration (mmol N/ mmol C)
X_pcon = [0.0094,0.0094,0.0039,0.0039,0.0094]; % Constant internal phosphorus concentration (mmol P/ mmol C)
for phy_i = 1:length(Phytos)
    OBC_WQ.TN = OBC_WQ.TN + X_ncon(phy_i)*OBC_WQ.(Phytos{phy_i});
    OBC_WQ.TP = OBC_WQ.TP + X_pcon(phy_i)*OBC_WQ.(Phytos{phy_i});
end


%% Use temperature and salinity to get DO
%Load model output
load(mod_fname);
%Calculate DO
for st_i = 1:length(NS_data.Site)
    sname = NS_data.Site{st_i};
    mod_DO = get_DO_sat_RS(CockburnSound.(sname).SAL.sigma.data,CockburnSound.(sname).TEMP.sigma.data,10.1*ones(length(CockburnSound.(sname).SAL.sigma.data),1));
    OBC_WQ.DO(:,st_i) = interp1(CockburnSound.(sname).SAL.sigma.date,mod_DO,bc_time)/32*1000;
    OBC_WQ.DO(1,st_i) = OBC_WQ.DO(2,st_i); %Remove NaN at start
    OBC_WQ.SALT(:,st_i) = interp1(CockburnSound.(sname).SAL.sigma.date,CockburnSound.(sname).SAL.sigma.data,bc_time);
    OBC_WQ.TEMP(:,st_i) = interp1(CockburnSound.(sname).SAL.sigma.date,CockburnSound.(sname).TEMP.sigma.data,bc_time);
end %loop sites


%% Plot bc Temp, salinity and DO
vars2plot={'TEMP','SALT','DO'};
uconv=[1,1,32/1000];
plt_sites = {'NS_1','NS_2','NS_3','NS_4','NS_5','NS_6'};
%set up figure
fg=myfigure(2,'papertype','A4','paperorientation',fig_orientation);
ax=myaxes(fg,length(vars2plot),1,...
    'left_buff',0.08,'right_buff',0.05,'top_buff',0.05,'bot_buff',0.1);
mod_plts=[]; % arrays for plot handles
set(ax,'nextplot','add'); % subsequent plots to axes do not overwrite existing
% plot
for var_i = 1:length(vars2plot)
    vname = vars2plot{var_i};
    for ii = 1:length(plt_sites)
        sname = plt_sites{ii};
        bc_plts(var_i)=plot(ax(var_i),bc_time,OBC_WQ.(vname)(:,ii)*uconv(var_i),'linestyle','-','color',BMT_lncol{ii},'linewidth',1);
    end
    set(ax(var_i),'xlim',[datenum('01-Jan-2013') datenum('01-Jan-2014')])
    %set(ax(plt_i),'ylim',([15 25]))
    ylabel(ax(var_i),[pltvars.(vname).longname ' (' pltvars.(vname).units ')']);%,'fontsize',text_size,'fontweight','bold');
end
dynamicDateTicks(ax,[],'dd/mm');
% Add legend
ax_hidden=axes('position',[0,0,1,1]); % hidden axes to aid legend control
lg_str = {};
for ns_i = 1:length(plt_sites)
    ns_id = ['NS_' num2str(ns_i)];
    h(ns_i)=plot(ax_hidden,[nan,nan],'-','Color',BMT_lncol{ns_i}); hold on;
    lg_str = [lg_str ns_id];
end
lg = legend(h,lg_str);
set(ax_hidden,'visible','off');
set(lg,'Position',leg_pos,'Interpreter', 'none',...
    'box','off','Orientation','horizontal','fontsize',8);
%save figure
pname='../plots/CS_obc_hd.jpeg';
print(fg,'-r400','-djpeg',pname);

%% Plot Cockburn Sound obc against observed data for CS8
%Variables
vars2plot={'TSS','TN','TP','AMM','NIT','FRP','CHLA'};
plt_sites = {'CS4','CS8','CS13','CS11','WSS4'};
uconv = [1,14,31,14,14,31,1];
%set up figure
fg=myfigure(1,'papertype','A4','paperorientation',fig_orientation);
ax=myaxes(fg,length(vars2plot),1,...
    'left_buff',0.08,'right_buff',0.05,'top_buff',0.05,'bot_buff',0.08);
mod_plts=[]; % arrays for plot handles
set(ax,'nextplot','add'); % subsequent plots to axes do not overwrite existing
% plot
for var_i = 1:length(vars2plot)
    vname = vars2plot{var_i};
    for ii = 1:length(plt_sites)
        sname = plt_sites{ii};
        bc_plts(var_i)=plot(ax(var_i),CS_data.(sname).(vname).Surface.date,CS_data.(sname).(vname).Surface.data, ...
                           'linestyle','none','markeredgecolor',BMT_lncol{ii},'markerfacecolor',BMT_lncol{ii},'marker','.');
    end
    for ii = 1:length(NS_data.Site)
        bc_plts(var_i)=plot(ax(var_i),bc_time,uconv(var_i)*OBC_WQ.(vname)(:,ii),'linestyle','-','color',BMT_lncol{ii},'linewidth',1);
    end
    set(ax(var_i),'xlim',[datenum('01-Jan-2013') datenum('01-Jan-2014')])
    %set(ax(plt_i),'ylim',([15 25]))
    ylabel(ax(var_i),[pltvars.(vname).longname ' (' pltvars.(vname).units ')']);%,'fontsize',text_size,'fontweight','bold');
end
dynamicDateTicks(ax,[],'dd/mm');
% Add legend
ax_hidden=axes('position',[0,0,1,1]); % hidden axes to aid legend control
lg_str = {};
for site_i = 1:length(plt_sites)
    sname = plt_sites{site_i};
    h(site_i)=plot(ax_hidden,[nan,nan],'linestyle','none','markeredgecolor',BMT_lncol{site_i},'markerfacecolor',BMT_lncol{site_i},'marker','.'); hold on;
    lg_str = [lg_str sname];
end
lg = legend(h,lg_str);
set(ax_hidden,'visible','off');
set(lg,'Position',leg_pos,'Interpreter', 'none',...
    'box','off','Orientation','horizontal','fontsize',8);
%save figure
pname='../plots/CS_obc_wq_obs_comp.jpeg';
print(fg,'-r400','-djpeg',pname);

%% Write TUFLOW FV scalar obc file

OBC_WQ.ZEROS = zeros(size(OBC_WQ.CHLA));
OBC_WQ.ONES = ones(size(OBC_WQ.CHLA));

for ii = 1:length(NS_data.Site)
    % Create .csv file.
    fid = fopen([bc_dir strrep(bc_fname,'X',num2str(ii))], 'w');
    % Write header information
    header_str = 'Date           ';
    for var_i = 1:length(varnames)
        header_str = [header_str ',       ' varnames{var_i}];
    end
    fprintf(fid,'%s \n', header_str);
    %Date format must be "dd/mm/yyyy HH:MM:SS" (or some truncation)
    fmtOut = '%02d/%02d/%04d %02d:%02d';
    for var_i = 1:length(varnames)
        fmtOut = [fmtOut,', %f '];
    end
    fmtOut = [fmtOut,'\n'];
    %convert time
    [yyyy,mm,dd,HH,MM] = datevec(bc_time);
    %flow data matrix
    dataout = zeros(length(bc_time),length(varnames));
    for var_i = 1:length(varnames)
        dataout(:,var_i) = OBC_WQ.(varnames{var_i})(:,ii);
    end
    fprintf(fid,fmtOut,[dd,mm,yyyy,HH,MM,dataout]');
    
    fclose(fid);                                      % Close the file.

end