% ts_001_plot_2D_variable_timeseries.m
%
% This script takes a profile .nc file and plots timeseries of a 2D
% variable at a given site. 
%
% Using the variable save_png the user can output the plot as a png to
% disk.
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_profile = '../../../../Complete_Model/TUFLOWFV/results/HYD_000_PROFILES.nc';                     % Profiles file created by ts_000_create_profile_file.m
site_plot   = 'Point_4';                                                    % Site name from profile file
var2d       = 'TEMP';                                                          % 2D variable from profile file
plot_xlimit = [datenum(2011,5,2) datenum(2011,5,7)];                        % Xlimit for the plot

save_png    = true;                                                         % Choose to save the figure (true|false)
out_plotdir = './plots/';                                                   % Plot output directory


% ------------- Advanced Plot Settings ------------

line_color  = [ 1 0.41 0];                                                  % Colour for the line being plotted [r,g,b]
plot_ylabel = 'Temperature [C]';

%---------------- Initialise a figure --------------

f   = myfigure(2);                                                          % initilise a figure
ax  = myaxes(f,1,1,'Left_buff',0.07);                                       % place a axis on the figure

%---------------- Extract Data to plot --------------

[y,x] = gettseries(tfv_profile,site_plot,var2d);                            % script to extract the data from the profiles file

%------------------- Plot the data ------------------

h = line(x,y,'parent',ax,'color',line_color);                               % Plotting the line

%----------------------- Formating ------------------
set(ax,'XLim',plot_xlimit,...
       'xgrid','on',...
       'ygrid','on')
dynamicDateTicks(ax,[],'dd/mm')                                             % adds dates on the xaxis
ylabel(ax,plot_ylabel,'fontsize',9);                                        % adds in the ylabel

%-----------------Save the output ------------------
if save_png
    outname = sprintf('TS_2D_%s_at_%s',var2d,site_plot);                    % output name
    print(f,[out_plotdir outname],'-dpng','-r200');                         % saves the plot
end
