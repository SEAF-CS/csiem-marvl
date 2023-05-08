% sh_004_save_sheet_animation.m
%
% Saves an animation of the sheet plots between a specific time interval.
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/HYD_000.nc';     % Model results file
sheet_var   = 'H';                                                          % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
vec_var     = 'V';                                                          % 2D or 3D variable with x ad y components e.g V, W10
ref         = 'sigma';                                                      % Model reference (TFV convention)
range       = [0 1];                                                        % Model range (TFV convention)
ts          = datenum(2011,5,2,0,0,0);                                      % Start time for the animation
te          = datenum(2011,5,7,0,0,0);                                      % End time for the animation
out_plots   = './plots/';                                                   % output directory to save the plots

% ------------- Advanced Plot Settings ------------

clim        = [-0.2 0.2] ;                                                  % Colour Limit
long_name   = 'Water Level [mMSL]';                                         % Title for the currents

%---------------- Initialise a figure --------------

fvobj   = fvgraphics(2,'a3','portrait');                                    % initilise a interactive FV figure
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
                'vecgrid',10,...                                            % grid that vectors are displayed on
                'vecscale',100,...                                          % scale the vector length
                'peerobj',ax,...                                            % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

%----------------------- Formating ------------------
set(ax, 'clim',clim,...
        'xcolor','none',...
        'ycolor','none')
axis equal
set(ax,'xlim',get(ax,'Xlim'),...
       'ylim',get(ax,'ylim'))
   
hcbar = colorbar(ax,'location','Southoutside');                             % Adds in a colour bar
set(hcbar,'position',[0.05 0.04 0.9 0.05])
title(hcbar,long_name,'fontsize',9)


%-------------------- save figure ------------------

outname = sprintf('Animation_%s_%s_%s',sheet_var,datestr(ts,'yyyymmddHHMMSS'),datestr(te,'yyyymmddHHMMSS'));    % name of output
animatefvg_2016a(fvobj,[out_plots outname],'ts',ts,'te',te)

