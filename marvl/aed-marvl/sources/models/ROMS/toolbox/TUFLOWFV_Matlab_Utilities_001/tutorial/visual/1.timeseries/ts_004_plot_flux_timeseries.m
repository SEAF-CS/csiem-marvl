% ts_004_plot_flux_timeseries.m
%
% This script plots the flux through a nodestring. This output is written 
% in the '_FLUX.csv' output file. Useful to plot the tidal prism and
% incomming fluxes.
%
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------

tfv_flux        = '../../../../Complete_Model/TUFLOWFV/results/HYD_002_FLUX.csv';               % TFV FLUX OUTPUT
nodestrin_plt   = 2;                                                        % Nodestring ID
var_plt         = 'FLOW';                                                   % Flux output variable [FLOW,SALT,TEMP,SED_1,...]
plot_xlimit = [datenum(2011,5,2) datenum(2011,5,7)];                        % Xlimit for the plot

save_png    = true;                                                         % Choose to save the figure (true|false)
out_plotdir = './plots/';                                                   % Plot output directory


% ------------- Advanced Plot Settings ------------

line_color  = [ 1  0.41 0];                                                 % Colour for the lines being plotted [r,g,b]*number line plotted
plot_ylabel = 'Flow [m^3/s]';

%---------------- Initialise a figure --------------

f   = myfigure(2);                                                          % initilise a figure
ax  = myaxes(f,1,1,'Left_buff',0.07);                                       % place a axis on the figure
set(ax,'Nextplot','add')                                                    % ensure that plots are added to the axis and not overwritten

   
%---------------- Extract Data to plot --------------

fid     = fopen(tfv_flux,'r');                                              % Open the file to read
heads   = fgetl(fid);                                                       % Get the first line of the file
heads   = strsplit(heads,',');                                              % Split the line based on comma
tmp     = string(heads);                                                    % convert to string type
lgi     = tmp.contains(sprintf('NS%d_%s',nodestrin_plt,var_plt));           % get the index of the column we are looking for
fmt     = repmat('%f',[1 length(tmp)]);                                     % get the format of the line
fmt     = ['%s' fmt(3:end)];                                                % make the first column a string
data    = textscan(fid,fmt,'delimiter',',');                                % read the data
fclose(fid);                                                                % close the file

x       = datenum(data{1},'dd/mm/yyyy HH:MM:SS');                           % convert the text to matlab number format
y       = data{lgi};                                                        % get the variable out

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
    outname = sprintf('TS_NS%d_%s',nodestrin_plt,var_plt);                  % output name
    print(f,[out_plotdir outname],'-dpng','-r200');                         % saves the plot
end
