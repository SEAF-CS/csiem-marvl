% cu_000_plot_curtain.m
%
% Plot an interactive curtain plot for a given 3D variable. It is important
% to note that curtains plot on the x-z plane so view settings usually have
% to be adjusted.
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------
tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/WQ_000_WQ.nc';          % Model results file
var         = 'WQ_OXY_OXY';                                                        % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
geofile     = '../../../../Complete_Model/TUFLOWFV/runs/log/WQ_000_geo.nc';        % geofile '.nc' file

% ------------- Advanced Plot Settings ------------
zlim        = [-10 2];                                                      % zlimit of plot
clim        = [0  400];                                                     % Colour Limit
long_name   = 'Dissolved Oxygen';                                           % Title for the variable
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



scales.WQ_OXY_OXY = [[8.5 10]*1000/32 160];	
scaletick.WQ_OXY_OXY = [8.5:0.5:10]*1000/32;	
scalefactor.WQ_OXY_OXY = 32/1000;

%---------------- Initialise a figure --------------
fvobj   = fvgraphics(2,'a4','portrait');                                    % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,1,1,'bot_buff',0.23,'left_buff',0.07);     % place a axis on the figure

%----------------- Plot the curtain ---------------
curt    = fvg_curtain(fvobj,tfv_resfile,geofile,pline,...                   % Initialise an interactive curtain plot
                'variables',var,...                                         % Variable to plot
                'peerobj',ax,...                                            % Axis to plot on
                'chainage',true,...                                         % choose to plot it with respect to a chainage
                'titletime','on');                                          % Choose to display the time as the title
                                                                            

%----------------------- Formating ------------------
set(ax, 'clim',clim,'zlim', zlim)                                           % set the axis properties
view(ax,[0 0])                                                              % Set the angle to view the curtain side on
xlabel(ax,'Chainage [m]','Fontsize',8)                                      % xlabel
zlabel(ax,'Height [mMSL]','Fontsize',8)                                     % zlabel



% Colour bar setting and adjusting
%hcbar = colorbar(ax,'location','Southoutside');       
hcbar = mycolor(ax,scales.(var),'location','Southoutside');	
set(hcbar,'ytick',scaletick.(var));
set(hcbar,'yticklabel',num2str(scaletick.(var)'*scalefactor.(var),'%.1f'));
set(hcbar,'position',[0.05 0.04 0.9 0.05])
title(hcbar,long_name,'fontsize',8)

