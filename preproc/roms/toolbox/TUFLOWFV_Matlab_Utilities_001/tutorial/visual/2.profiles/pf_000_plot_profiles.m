% pf_000_plot_profiles.m
%
% Plot an interactive profile plot at a given point. Useful for looking at
% the velocity structure and sediment distribution in the water column.
%
% Use the slider bar in the bottom left hand corner to shift the time.
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_profile = '../../../../Complete_Model/TUFLOWFV/results/HYD_001_PROFILES.nc';                % Profiles file created by ts_000_create_profile_file.m
site_plot   = 'Point_1';                                                    % Site name from profile file
var3d       = 'SAL';                                                          % 3D variable from profile file e.g. V, TEMP, SAL, RHOW

% ------------- Advanced Plot Settings ------------

smooth_plt  = true;                                                         % if false, plots gridded else plots the smoothed profile
plot_xlimit = [0 40];                                                        % Profile plot xlimit
line_color  = [ 1 0.41 0];                                                  % Colour for the line being plotted [r,g,b]
plot_xlabel = 'Salinity [PSU]';                                    % Xlabel
plot_ylabel = 'elevation [mMSL]';                                           % Ylabel

%---------------- Initialise a figure --------------

fvobj   = fvgraphics(2,'a4','portrait');                                    % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,1,1,'Left_buff',0.07,'bot_buff',0.13);     % place a axis on the figure

%---------------- Extract Data to plot --------------

TMP         = netcdf_get_var(tfv_profile);                                  % Load the profile file
time        = convtime(TMP.ResTime);                                        % Convert between FV time and Matlab time
elevations  = TMP.(site_plot).layerface_Z;                                  % Get the elevations

if strcmpi(var3d,'V')                                                       % Special case of V to get the magnitude of V_x and V_y
    data = hypot(TMP.(site_plot).V_x,TMP.(site_plot).V_y);                  
else
    data = TMP.(site_plot).(var3d);
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

h   = fvg_profile(fvobj, ax, time , elevations, data, line_color,true);     % Plotting the line

%----------------------- Formating ------------------
set(ax,'XLim',plot_xlimit,...
       'xgrid','on',...
       'ygrid','on',...
       'ylim',get(ax,'YLim'))
ylabel(ax,plot_ylabel,'fontsize',9);                                        % adds in the ylabel
xlabel(ax,plot_xlabel,'fontsize',9);                                        % adds in the ylabel

