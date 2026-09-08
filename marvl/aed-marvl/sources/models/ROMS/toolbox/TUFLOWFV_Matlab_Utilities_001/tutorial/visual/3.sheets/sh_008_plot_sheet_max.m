% sh_000_plot_sheet.m
%
% Plot the maximum of the variable var. Should work with both vector and scalar variables.

clear all 
close all

% ------------------- User Input ------------------

tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc';                               % Model results file
var         = 'RHOW';                                                          % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
ref         = 'sigma';                                                      % Model reference (TFV convention) ignored if variable is 2D
range       = [0 1];                                                        % Model range (TFV convention) ignorded if variable is 2D

% ------------- Advanced Plot Settings ------------

clim        = [1000 1025];                                                      % Colour Limit
long_name   = 'Density [kg/m3]';                                    % Title for the currents

%---------------- Initialise a figure --------------
% 
fvobj   = fvgraphics(2,'a4','portrait');                                    % initilise a interactive FV figure
ax = myaxes(fvobj.FigureObj,1,1,'bot_buff',0.15);                      % place a axis on the figure

%------------------- Plot the sheet -----------------
                                                                            % Initialise an interactive sheet plot
sheet   = fvg_sheet(fvobj,tfv_resfile,...                                       % figure to plot on and results file to use
                'variables',var,...                                         % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax,...                                            % axis to plot on
                'titletime','off');                                          % choose to add the title to the plot

t = sheet.ResObj.TimeVector.M1;
nt = length(t);
data = sheet.PatchObj.CData;
for ii = 1:length(t)
    set(fvobj, 'TimeCurrent', t(ii));
    set(fvobj.SliderObj, 'Value', t(ii));
    
    data = max([data, sheet.PatchObj.CData], [], 2); 
end

set(fvobj.SliderObj, 'Visible', 'off');
set(sheet.PatchObj, 'CData', data);

%----------------------- Formating ------------------
set(ax, 'clim',clim,...
        'xcolor','none',...
        'ycolor','none')
axis equal
hcbar = colorbar(ax,'location','Southoutside');                             % Adds in a colour bar and adjusts it position
set(hcbar,'position',[0.05 0.04 0.9 0.05])
title(hcbar,long_name,'fontsize',9)


