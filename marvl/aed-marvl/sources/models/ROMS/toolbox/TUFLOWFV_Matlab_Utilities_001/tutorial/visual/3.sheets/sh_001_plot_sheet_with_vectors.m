% sh_001_plot_sheet_with_vectors.m
%
% Plot an interactive sheet plot with vectors on the top.
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/HYD_000.nc';                         % Model results file
sheet_var   = 'TEMP';                                                          % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
vec_var     = 'V';                                                          % 2D or 3D variable with x ad y components e.g V
ref         = 'sigma';                                                      % Model reference (TFV convention)
range       = [0 1];                                                        % Model range (TFV convention)

% ------------- Advanced Plot Settings ------------

clim        = [10 20] ;                                                      % Colour Limit
long_name   = 'Temperature [deg C]';                                         % Title for the currents

%---------------- Initialise a figure --------------

fvobj   = fvgraphics(2,'a4','portrait');                                    % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,1,1,'bot_buff',0.15);                      % place a axis on the figure

%------------------- Plot the sheet -----------------
                                                                            % Initialise an interactive sheet plot
h   = fvg_sheet(fvobj,tfv_resfile,...                                       % figure to plot on and results file to use
                'variables',sheet_var,...                                   % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax,...                                            % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot

v   =  fvg_sheetvec(fvobj,tfv_resfile,...                                   % figure to plot on and results file to use
                'variables',vec_var,...                                     % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'vecgrid',20,...                                            % grid that vectors are displayed on
                'vecscale',250,...                                           % scale the vector length
                'peerobj',ax,...                                            % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

%----------------------- Formating ------------------
set(ax, 'clim',clim,...
        'xcolor','none',...
        'ycolor','none')
axis equal
hcbar = colorbar(ax,'location','Southoutside');                             % add in and adjust a colour bar
set(hcbar,'position',[0.05 0.04 0.9 0.05])
title(hcbar,long_name,'fontsize',9)


