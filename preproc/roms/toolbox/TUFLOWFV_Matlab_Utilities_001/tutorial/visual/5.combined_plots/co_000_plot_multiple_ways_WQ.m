% co_000_plot_multiple_ways.m
%
% Plots a timeseries, profile, curtain  and sheet all on the same plot.
% Good for investigating the 3D structure of a model at a specific point.
%
% SDE 2018
% CAV 2018 - WQVars

clear
close 

% ------------------- User Input ------------------

% File information
tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/WQ_000.nc';
tfv_WQ_resfile = '../../../../Complete_Model/TUFLOWFV/results/WQ_000_WQ.nc';

% Model results files;
tfv_profile = '../../../../Complete_Model/TUFLOWFV/results/WQ_000_PROFILES.nc';  
tfv_WQ_profile = '../../../../Complete_Model/TUFLOWFV/results/WQ_000_WQ_PROFILES.nc';

geofile     = '../../../../Complete_Model/TUFLOWFV/runs/log/WQ_000_geo.nc';                        % geofile '.nc' file
site_plot   = 'Point_5';                                                    % Site name from profile file

% variables to plot
var_profile     = 'V';                                                       % 3D variable from file e.g.  V, TEMP, SAL, RHOW
var_timeseries  = 'V';                                                       % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
var_sheet       = 'WQ_OXY_OXY';                                                       % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
var_curt        = 'WQ_OXY_OXY';                                                       % 3D variable from file e.g. V, TEMP, SAL, RHOW


%H = '(WQ_PHS_FRP+WQ_PHS_FRP_ADS+WQ_OGM_DOP+WQ_OGM_POP+(WQ_PHY_GRN*(1/106)))*(31/1000)';
%H = '(WQ_NIT_AMM+WQ_NIT_NIT+WQ_PHS_FRP+WQ_SIL_RSI+(WQ_PHY_GRN*(16/106)))*(14/1000)';
%H = '(WQ_PHY_GRN*(12/50))';
% H = 'WQ_OXY_OXY*(32/1000)';


% Titles
long_names  = {'Current Magnitude [m/s]';
               'Current Magnitude [m/s]';
               'DO [mmol]';
               'DO [mmol]'} ;                                 % Title for the plots


% Timeseries settings
ts_xlimit = [datenum(2011,5,1) datenum(2011,5,7)];                          % Xlimit for the plot
line_color  = [ 1 0.41 0];                                                  % Colour for the line being plotted [r,g,b]
ref_timeseries      = 'sigma';
range_timeseries    = [0 1];

% Profile plot settings
smooth_plt  = false;                                                        % if false, plots gridded else plots the smoothed profile
pro_xlim    = [0 0.5];                                                      % Xlimit for the plot

% Sheet settings
clim_sheet  = [100 350];
ref_sheet           = 'sigma';
range_sheet         = [0 1];


% curtain settings
clim_curt   = [ 100 350];                                                     % Colour limits for curtain
zlim        = [-10 2];                                                      % zlimit of plot
pline       = [ 159.0728  -31.3591                                          % line for the curtain
				159.0758  -31.3630
				159.0774  -31.3676
				159.0786  -31.3696
				159.0822  -31.3723
				159.0863  -31.3738
				159.0894  -31.3771
				159.0902  -31.3796
				159.0900  -31.3846
				159.0898  -31.3880
				159.0914  -31.3901
				159.1016  -31.3955
				159.1104  -31.3961
				159.1129  -31.3991
				159.1157  -31.4024
				159.1185  -31.4052
				159.1226  -31.4077
				159.1258  -31.4097
				159.1274  -31.4121
				159.1272  -31.4137
				159.1204  -31.4165
				159.1170  -31.4190
				159.1167  -31.4220
				159.1181  -31.4241
				159.1224  -31.4281
				159.1263  -31.4330
				159.1294  -31.4365
				159.1290  -31.4388];
            
%% ---------------- Initialise a figure --------------

fvobj   = fvgraphics(1,'a4','landscape');                                   % initilise a interactive FV figure
ax_dum  = myaxes(fvobj.FigureObj,1,1,'left_buff',0.07,'bot_buff',0.1,'top_gap',0.05);     % dummy axis to plot the title on
set(ax_dum,'xcolor','none','ycolor','none','color','none')                                % hide everything except the title in the dummy axis
ax      = myaxes(fvobj.FigureObj,2,2,'left_buff',0.07,'bot_buff',0.1,'top_gap',0.05);     % place a axis on the figure
h_ti    = fvg_title(fvobj, ax_dum);
%% -------------- Plot the Timeseries ----------------

%---------------- Extract Data to plot --------------

if strcmpi(var_timeseries,'V')                                              % Special case of V to get the magnitude of V_x and V_y
    [y,x] = gettseries(tfv_profile,site_plot,'hypot(V_x,V_y)',...
            ref_timeseries,range_timeseries);                               % script to extract the data from the profiles file
else
    [y,x] = gettseries(tfv_profile,site_plot,var_timeseries,...
            ref_timeseries,range_timeseries);                               % script to extract the data from the profiles file
end

%------------------- Plot the data ------------------

h = line(x,y,'parent',ax(1),'color',line_color);                            % Plotting the line

%----------------------- Formating ------------------
set(ax(1),'XLim',ts_xlimit,...
       'xgrid','on',...
       'ygrid','on')
dynamicDateTicks(ax(1),[],'dd/mm')                                          % adds dates on the xaxis
ylabel(ax(1),long_names{1},'fontsize',9);                                   % adds in the ylabel

% ------------------ Add in a scroller --------------
h_scroll = fvg_timestep_scroller(fvobj,ax(1),[0 0 0]);                      % add in a line to scroll through time

%% -------------- Plot the Profile ----------------

%---------------- Extract Data to plot --------------

TMP         = netcdf_get_var(tfv_profile);                                  % Load the profile file
time        = convtime(TMP.ResTime);                                        % Convert between FV time and Matlab time
elevations  = TMP.(site_plot).layerface_Z;                                  % Get the elevations

TMPWQ         = netcdf_get_var(tfv_WQ_profile); 

if strcmpi(var_profile,'V')                                                 % Special case of V to get the magnitude of V_x and V_y
    data = hypot(TMP.(site_plot).V_x,TMP.(site_plot).V_y);                  
else
    data = TMPWQ.(site_plot).(var_profile);
end

%------------------- Plot the data ------------------

if smooth_plt
    elevations = [elevations(1,:);(elevations(2:end,:)+elevations(1:end-1,:))*0.5];     % plot at the center of the depth cells
    data = [data(1,:) ; data];
else 
    indx = [1 floor(2:0.5:size(elevations,1))];                             % Plot the whole cell (top and bottom)
    elevations = elevations(indx,:);
    indx = [floor(1:0.5:size(data,1)) size(data,1)];
    data = data(indx,:);
end

h   = fvg_profile(fvobj, ax(2), time , elevations, data, line_color,false);  % Plotting the line

%----------------------- Formating ------------------
set(ax(2),'XLim',pro_xlim,...
       'xgrid','on',...
       'ygrid','on',...
       'ylim',zlim)
ylabel(ax(2),'Depth','fontsize',9);                                         % adds in the ylabel
xlabel(ax(2),long_names{2},'fontsize',9);                                   % adds in the ylabel

%% -------------- Plot the sheet plot ----------------

%------------------- Plot the sheet -----------------
                                                                            % Initialise an interactive sheet plot
h   = fvg_sheet(fvobj,tfv_WQ_resfile,...                                       % figure to plot on and results file to use
                'variables',var_sheet,...                                   % variable to plot
                'ref',ref_sheet,...                                         % depth averaging reference
                'range',range_sheet,...                                     % depth averaging range
                'peerobj',ax(3),...                                         % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

v   =  fvg_sheetvec(fvobj,tfv_resfile,...                                   % figure to plot on and results file to use
                'variables','V',...                                         % variable to plot
                'ref',ref_sheet,...                                         % depth averaging reference
                'range',range_sheet,...                                     % depth averaging range
                'vecgrid',20,...                                            % grid that vectors are displayed on
                'vecscale',30,...                                           % scale the vector length
                'peerobj',ax(3),...                                         % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

%----------------------- Formating ------------------
set(ax(3), 'clim',clim_sheet,...
        'xcolor','none',...
        'ycolor','none')
axis(ax(3),'equal')
pos = get(ax(3),'Position');
hcbar = colorbar(ax(3),'location','Southoutside');                          % add the colour bar and adjust
set(hcbar,'Position',[0.535 0.52 0.425 0.02]);
title(hcbar,long_names{3},'fontsize',9)


%% -------------- Plot the curtain plot --------------

%----------------- Plot the curtain ---------------
curt    = fvg_curtain(fvobj,tfv_WQ_resfile,geofile,pline,...                   % Initialise an interactive curtain plot
                'variables',var_curt,...                                    % Variable to plot
                'peerobj',ax(4),...                                         % Axis to plot on
                'chainage',true,...                                         % choose to plot it with respect to a chainage
                'titletime','off');                                         % Choose to display the time as the title
                                                                            

%----------------------- Formating ------------------
set(ax(4), 'clim',clim_curt,'zlim', zlim,'color','none')                    % Adjust plot limits
view(ax(4),[0 0])                                                           % Adjust view angle 
xlabel(ax(4),'Chainage [m]','Fontsize',8)                                   % Xlabel
zlabel(ax(4),'Height [mMSL]','Fontsize',8)                                  % Zlabel
pos = get(ax(4),'Position'); pos(2) = 0.17; pos(4)=0.3;                     % Adjust the axis
set(ax(4),'position',pos)                   
hcbar = colorbar(ax(4),'location','Southoutside');                          % Add and adjust the colour bar
set(hcbar,'Position',[0.535 0.04 0.425 0.02]);
title(hcbar,long_names{4},'fontsize',8)


%% Final points to show transect location

lin(1) = line(pline(:,1),pline(:,2),...                                     % x and y coordinates
            'parent',ax(3),...                                              % axis to plot on
            'color','r',...                                                 % colour to plot
            'displayname','Curtain');                                       % Name for legend
x = TMP.(site_plot).X;
y = TMP.(site_plot).Y;
lin(2) = line(x,y,...                                                       % x and y data
            'parent',ax(3),...                                              % axis to plot on
            'color','g',...                                                 % colour to plot
            'linestyle','none',...                                          % line style
            'marker','o',...                                                % marker style
            'DisplayName',strrep(site_plot,'_',' '));                       % Name for legend

hl = legend(lin);                                                           % insert a legend
set(hl,'fontsize',8,'box','off')                                            % Adjust legend 
