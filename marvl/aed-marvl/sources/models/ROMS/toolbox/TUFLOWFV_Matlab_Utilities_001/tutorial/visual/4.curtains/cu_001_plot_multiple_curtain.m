% cu_000_plot_curtain.m
%
% Plot an interactive curtain plot with multiple files and multiple
% variables.
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_resfiles= {'../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc';                             % Model results file
               '../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc';
               '../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc';
               '../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc'};
vars        = {'V','SAL','TEMP','RHOW'};                                    % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
geofiles    = {'../../../../Complete_Model/TUFLOWFV/runs/log/HYD_002_geo.nc';                  % geofile '.nc' file
               '../../../../Complete_Model/TUFLOWFV/runs/log/HYD_002_geo.nc';
               '../../../../Complete_Model/TUFLOWFV/runs/log/HYD_002_geo.nc';
               '../../../../Complete_Model/TUFLOWFV/runs/log/HYD_002_geo.nc'};

% ------------- Advanced Plot Settings ------------
zlim        = [-10 2];                                                      % zlimit of plot
clims       = {[0  0.5];[0 35];[10 25];[1000 1030]};                             % Colour Limit
long_names  = {'Current Magnitude [m/s]';
               'Salinity [PSU]';
               'Temperature [\circC]';
               'Density [kg/m^3]'};                                          % Title for the plots
pline       = [ 159.0728  -31.3591
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
%---------------- Initialise a figure --------------

fvobj   = fvgraphics(1,'a4','landscape');                                   % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,2,2,'side_gap',0.05,'top_gap',0,'left_buff',0.07);     % place a axis on the figure

%----------------- Plot the curtain ---------------
for aa = 1:length(vars)
    curt(aa)    = fvg_curtain(fvobj,tfv_resfiles{aa},geofiles{aa},pline,... % Initialise an interactive curtain plot
                'variables',vars{aa},...                                    % Variable to plot
                'peerobj',ax(aa),...                                        % Axis to plot on
                'chainage',true,...                                         % choose to plot it with respect to a chainage
                'titletime','on');                                          % Choose to display the time as the title
            
%----------------------- Formating ------------------
    set(ax(aa), 'clim',clims{aa},'zlim', zlim)                              % axis properties
    view(ax(aa),[0 0])                                                      % view angle adjustment
    xlabel(ax(aa),'Chainage [m]','Fontsize',6)                              % xlabel
    zlabel(ax(aa),'Height [mMSL]','Fontsize',6)                             % ylabel
    hcbar = colorbar(ax(aa),'location','Southoutside');                     % colour bar setting and adjusting
    title(hcbar,long_names{aa},'fontsize',6)
end                                        


