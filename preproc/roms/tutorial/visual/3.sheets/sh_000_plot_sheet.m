% sh_000_plot_sheet.m
%
% Plot an interactive sheet plot. This allows you to step through time and
% look at a variable
%
% Use the time slider in the bottom left of the plot to step through time.
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/HYD_000.nc';                              % Model results file
var         = 'TEMP';                                                          % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
ref         = 'sigma';                                                      % Model reference (TFV convention) ignored if variable is 2D
range       = [0 1];                                                        % Model range (TFV convention) ignorded if variable is 2D

% ------------- Advanced Plot Settings ------------

clim        = [10 20];                                                      % Colour Limit
long_name   = 'Temperature [deg C]';                                    % Title for the currents

%---------------- Initialise a figure --------------

fvobj   = fvgraphics(2,'a4','portrait');                                    % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,1,1,'bot_buff',0.15);                      % place a axis on the figure

%------------------- Plot the sheet -----------------
                                                                            % Initialise an interactive sheet plot
h   = fvg_sheet(fvobj,tfv_resfile,...                                       % figure to plot on and results file to use
                'variables',var,...                                         % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax,...                                            % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot

%----------------------- Formating ------------------
set(ax, 'clim',clim,...
        'xcolor','none',...
        'ycolor','none')
axis equal
hcbar = colorbar(ax,'location','Southoutside');                             % Adds in a colour bar and adjusts it position
set(hcbar,'position',[0.05 0.04 0.9 0.05])
title(hcbar,long_name,'fontsize',9)


