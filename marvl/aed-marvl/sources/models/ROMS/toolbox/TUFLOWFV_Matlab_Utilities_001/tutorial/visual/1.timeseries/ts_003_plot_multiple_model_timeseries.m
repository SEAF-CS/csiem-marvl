% ts_003_plot_multiple_model_timeseries.m
%
% This script takes several profile .nc files and plots timeseries of a
% given 2D/3D variable over eachother. Useful for seeing how adjustments in
% the model result in changes to the output.
%
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_profiles= { '../../../../Complete_Model/TUFLOWFV/results/HYD_000_PROFILES.nc';
                '../../../../Complete_Model/TUFLOWFV/results/HYD_001_PROFILES.nc';                   % Cell array of profiles files created by ts_000_create_profile_file.m
                '../../../../Complete_Model/TUFLOWFV/results/HYD_002_PROFILES.nc'};                
model_names = {'Hyd_000','Hyd_001','Hyd_002'};                              % Model names for legend
site_plot   = 'Point_3';                                                    % Site name from profile files
var3d       = 'V';                                                          % 3D variable from profile files
ref         = 'sigma';                                                      % Model reference (TFV convention) if variable is 2d this is ignored
range       = [0 1];                                                        % Model range (TFV convention) if variable is 2d this is ignored

plot_xlimit = [datenum(2011,5,2) datenum(2011,5,7)];                        % Xlimit for the plot

save_png    = true;                                                         % Choose to save the figure (true|false)
out_plotdir = './plots/';                                                   % Plot output directory


% ------------- Advanced Plot Settings ------------

line_color  = [ 1  0.41 0
               0.1 0.74 0.79
               0.0431 0.6588 0.0627];                                       % Colour for the lines being plotted [r,g,b]*number line plotted
plot_ylabel = 'Current Magnitude [m/s]';

%---------------- Initialise a figure --------------

f   = myfigure(2);                                                          % initilise a figure
ax  = myaxes(f,1,1,'Left_buff',0.07);                                       % place a axis on the figure
set(ax,'Nextplot','add')                                                    % ensure that plots are added to the axis and not overwritten

for aa = 1:length(tfv_profiles)                                             % loop over the models
    
%---------------- Extract Data to plot --------------

    if strcmpi(var3d,'V')                                                           % Special case of V to get the magnitude of V_x and V_y
        [y,x] = gettseries(tfv_profiles{aa},site_plot,'hypot(V_x,V_y)',ref,range);  % script to extract the data from the profiles file
    else
        [y,x] = gettseries(tfv_profile{aa},site_plot,var3d,ref,range);              % script to extract the data from the profiles file
    end

%------------------- Plot the data ------------------

    h = line(x,y,'parent',ax,'color',line_color(aa,:));                             % Plotting the line
    
end

%----------------------- Formating ------------------
set(ax,'XLim',plot_xlimit,...
       'xgrid','on',...
       'ygrid','on')
dynamicDateTicks(ax,[],'dd/mm')                                             % adds dates on the xaxis
ylabel(ax,plot_ylabel,'fontsize',9);                                        % adds in the ylabel
h_leg = legend(ax,model_names);                                             % Create a legend
set(h_leg,'Box','off','fontsize',10,'Interpreter','none')    

%-----------------Save the output ------------------
if save_png
    outname = sprintf('TS_3D_MultiModels_%s_at_%s',var3d,site_plot);        % output name
    print(f,[out_plotdir outname],'-dpng','-r200');                         % saves the plot
end
