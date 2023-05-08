% ca_000_timeseries_calibration.m
%
% This script takes a profile .nc file and plots timeseries of a given
% variable at a given site with specified depth averaging settings. Takes a
% basic formatted csv file.
% The file format is header lines where the name correspond to the variable
% to be plotted. The first column name is 'Time' with dates formated as
% 'dd/mm/yyyy HH:MM:SS'. All remaining data is numbers (no strings)
%
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------
data_file   = '../../generate_synthetic_data/Point_3_H_SAL_synthetic_data.csv';  % data file containing calibration data
tfv_profile = '../../../../Complete_Model/TUFLOWFV/results/HYD_002_PROFILES.nc';                     % Profiles file created by ts_000_create_profile_file.m
site_plot   = 'Point_3';                                                    % Site name from profile file
var         = 'SAL';                                                        % variable ot calibrate
ref         = 'depth';                                                      % Model reference (TFV convention)
range       = [0 1];                                                        % Model range (TFV convention)

plot_xlimit = [datenum(2011,5,2) datenum(2011,5,7)];                        % Xlimit for the plot

save_png    = true;                                                         % Choose to save the figure (true|false)
out_plotdir = './plots/';                                                   % Plot output directory


% ------------- Advanced Plot Settings ------------

line_color  = [ 1 0.41 0];                                                  % Colour for the line being plotted [r,g,b]
data_color  = [0.1020    0.7412    0.7882];
plot_ylabel = 'Salinity [PSU]';

%---------------- Initialise a figure --------------

f   = myfigure(2);                                                          % initilise a figure
ax  = myaxes(f,1,1,'Left_buff',0.07);                                       % place a axis on the figure

%------------ Extract model results to plot --------
if strcmpi(var,'V')                                                        % Special case of V to get the magnitude of V_x and V_y
    [y,x] = gettseries(tfv_profile,site_plot,'hypot(V_x,V_y)',ref,range);   % script to extract the data from the profiles file
else
    [y,x] = gettseries(tfv_profile,site_plot,var,ref,range);               % script to extract the data from the profiles file
end

%------------------- Plot the model ------------------

h = line(x,y,'parent',ax,'color',line_color);                               % Plotting the line

%------------ Extract data to plot ----------------

fid     = fopen(data_file,'r');                                             % Open the data file for reading
headers = fgetl(fid);                                                       % get the header line
headers = strsplit(headers,',');                                            % split on commas
  
t_var_id= strcmpi(headers,'time');                                          % get the time column
var_id  = strcmpi(headers,var);                                             % get the variable column

fmt     = ['%s' repmat('%f',1,length(headers)-1)];                          % Determine the format of the file Assumes a date in the first column and numbers in the remaining.
data    = textscan(fid,fmt,'delimiter',',');                                % Read the data
fclose(fid);                                                                % Close the file

x = datenum(data{t_var_id},'dd/mm/yyyy HH:MM:SS');                          % convert the date to matlab time
y = data{var_id};                                                           % get the data out


%------------------- Plot the data ------------------

d = line(x,y,'parent',ax,'color',data_color,'marker','.','linestyle','none');


%----------------------- Formating ------------------
set(ax,'XLim',plot_xlimit,...
       'xgrid','on',...
       'ygrid','on')
dynamicDateTicks(ax,[],'dd/mm')                                             % adds dates on the xaxis
ylabel(ax,plot_ylabel,'fontsize',9);                                        % adds in the ylabel

%-----------------Save the output ------------------
if save_png
    outname = sprintf('Calibration_%s_at_%s',var,site_plot);                % output name
    print(f,[out_plotdir outname],'-dpng','-r200');                         % saves the plot
end
