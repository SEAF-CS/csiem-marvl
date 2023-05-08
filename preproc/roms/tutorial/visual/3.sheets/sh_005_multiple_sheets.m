% sh_005_multiple_sheets.m
%
% plots multiple variables from the same model on the same figure
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc';                              % Model results file
sheet_var1  = 'H';                                                          % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
sheet_var2  = 'V';                                                          % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
vec_var     = 'V';                                                          % 2D or 3D variable with x ad y components e.g V, W10
ref         = 'sigma';                                                      % Model reference (TFV convention)
range       = [0 1];                                                        % Model range (TFV convention)
out_plots   = './plots/';                                                   % output directory to save the plots

% ------------- Advanced Plot Settings ------------

clim1        = [-0.2 0.2] ;                                                 % Colour Limit
clim2        = [-0.5 0.5] ;                                                 % Colour Limit
long_name1   = 'Water Level [mMSL]';                                        % Title for the sheet 1
long_name2   = 'Current Magnitude [m/s]';                                   % Title for the sheet 2

%---------------- Initialise a figure --------------

fvobj   = fvgraphics(2,'a3','portrait');                                    % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,1,2,'bot_buff',0.15);                      % place a several axes on the figure

%------------------- Plot the sheet -----------------
                                                                            % Initialise  the first interactive sheet plot
h1   = fvg_sheet(fvobj,tfv_resfile,...                                      % figure to plot on and results file to use
                'variables',sheet_var1,...                                  % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax(1),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot
                                                                            % Initialise the second sheet plot
h2   = fvg_sheet(fvobj,tfv_resfile,...                                      % figure to plot on and results file to use
                'variables',sheet_var2,...                                  % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax(2),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot

            
v1   =  fvg_sheetvec(fvobj,tfv_resfile,...                                  % figure to plot on and results file to use
                'variables',vec_var,...                                     % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'vecgrid',10,...                                            % grid that vectors are displayed on
                'vecscale',100,...                                          % scale the vector length
                'peerobj',ax(1),...                                         % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

v2   =  fvg_sheetvec(fvobj,tfv_resfile,...                                  % figure to plot on and results file to use
                'variables',vec_var,...                                     % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'vecgrid',12,...                                            % grid that vectors are displayed on
                'vecscale',100,...                                          % scale the vector length
                'peerobj',ax(2),...                                         % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot
%----------------------- Formating ------------------
set(ax(1), 'clim',clim1,...
        'xcolor','none',...
        'ycolor','none')
set(ax(2), 'clim',clim2,...
        'xcolor','none',...
        'ycolor','none')

axis equal
set(ax,'xlim',get(ax(1),'Xlim'),...
       'ylim',get(ax(1),'ylim'))
linkaxes(ax,'xy')
   
hcbar1 = colorbar(ax(1),'location','Southoutside');                         % First colour bar
set(hcbar1,'position',[0.05 0.04 0.40 0.05])
title(hcbar1,long_name1,'fontsize',9)

hcbar2 = colorbar(ax(2),'location','Southoutside');                         % second colour bar
set(hcbar2,'position',[0.55 0.04 0.40 0.05])
title(hcbar2,long_name2,'fontsize',9)



