% co_001_sheet_and_curtain.m
%
% Plots a seties of curtains and a sheet plot.
%
% SDE 2018

clear all
close all

% ------------------- User Input ------------------

% File information
tfv_resfile = '../../../../Complete_Model/TUFLOWFV/results/HYD_002.nc';                              % Model results file;
geofile     = '../../../../Complete_Model/TUFLOWFV/runs/log/HYD_002_geo.nc';                       % geofile '.nc' file
transect_fil= './Transect_forcing.csv';                                     % csv file containing the coordinates for a series of transects

% variables to plot
var_sheet       = 'RHOW';                                                       % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
var_curt        = 'RHOW';                                                       % 3D variable from file e.g. V, TEMP, SAL, RHOW

% Titles
long_names  = {'Density [kg/m^3]';
               'Density [kg/m^3]'} ;                                 % Title for the plots

% Sheet settings
clim_sheet  = [1000 1030];
ref_sheet           = 'sigma';
range_sheet         = [0 1];

% curtain settings
clim_curt   = [1000 1030];                                                     % Colour limits for curtain
zlim        = [-10 2];                                                      % zlimit of plot


%% ---------------- Initialise a figure --------------

fvobj   = fvgraphics(1,'a4','landscape');                                   % initilise a interactive FV figure
ax_dum  = myaxes(fvobj.FigureObj,1,1,'left_buff',0.07,'bot_buff',0.1,'top_gap',0.05);     % dummy axis to plot the title on
set(ax_dum,'xcolor','none','ycolor','none','color','none')                                % hide everything except the title in the dummy axis
ax      = myaxes(fvobj.FigureObj,1,2,'left_buff',0.07,'bot_buff',0.1,'top_gap',0.05);     % place a axis on the figure
set(ax,'Nextplot','add');                                                   % additional lines are added to the plot rather than overwritten
h_ti    = fvg_title(fvobj, ax_dum);

%% -------------- Plot the sheet plot ----------------

%------------------- Plot the sheet -----------------
                                                                            % Initialise an interactive sheet plot
h   = fvg_sheet(fvobj,tfv_resfile,...                                       % figure to plot on and results file to use
                'variables',var_sheet,...                                   % variable to plot
                'ref',ref_sheet,...                                         % depth averaging reference
                'range',range_sheet,...                                     % depth averaging range
                'peerobj',ax(1),...                                         % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

v   =  fvg_sheetvec(fvobj,tfv_resfile,...                                   % figure to plot on and results file to use
                'variables','V',...                                         % variable to plot
                'ref',ref_sheet,...                                         % depth averaging reference
                'range',range_sheet,...                                     % depth averaging range
                'vecgrid',20,...                                            % grid that vectors are displayed on
                'vecscale',30,...                                           % scale the vector length
                'peerobj',ax(1),...                                         % axis to plot on
                'titletime','off');                                         % choose to add the title to the plot

%----------------------- Formating ------------------
set(ax(1), 'clim',clim_sheet,...
        'xcolor','none',...
        'ycolor','none')
axis(ax(1),'equal')
pos = get(ax(1),'Position');
hcbar = colorbar(ax(1),'location','Southoutside');                          % add the colour bar and adjust
pos(2) = 0.05; pos(4) = 0.02;
set(hcbar,'Position',pos)
title(hcbar,long_names{1},'fontsize',9)


%% -------------- Plot the curtain plot --------------

% ----------------- Load the transect ----------------
fid = fopen(transect_fil,'r');
trans = textscan(fid,'%d%f%f%s','headerlines',1,'delimiter',',');
fclose(fid);

ids = unique(trans{1});
for aa = 1:length(ids)
    lgi     =   trans{1}==ids(aa);
    tran_n  =   trans{4}(lgi);
    x       =   trans{2}(lgi);
    y       =   trans{3}(lgi);
    TRANSECT.(tran_n{1}).Pline = [x,y];
end
tran_n  =   fieldnames(TRANSECT);

%----------------- Plot the curtain ---------------
for aa = 1:length(tran_n)
    curt{aa}  = fvg_curtain(fvobj,tfv_resfile,geofile,...
                TRANSECT.(tran_n{aa}).Pline,...                             % Initialise an interactive curtain plot
                'variables',var_curt,...                                    % Variable to plot
                'peerobj',ax(2),...                                         % Axis to plot on
                'chainage',false,...                                        % choose to plot it with respect to a chainage
                'titletime','off');                                         % Choose to display the time as the title
	hlin{aa}  = line(TRANSECT.(tran_n{aa}).Pline(:,1),...                   % Plots the line on the sheet plot 
                     TRANSECT.(tran_n{aa}).Pline(:,2),...
                     'parent',ax(1),...
                     'color',[0 0 0]);
end                                                                
%----------------------- Formating ------------------
set(ax(2),'Projection','perspective')
view(3)
set(ax(2),  'clim',clim_curt,...
            'xcolor','none',...
            'ycolor','none')
pos = get(ax(2),'Position');
hcbar = colorbar(ax(1),'location','Southoutside');                          % add the colour bar and adjust
pos(2) = 0.05; pos(4) = 0.02;
set(hcbar,'Position',pos)
zlabel(ax(2),'Depth [mMSL]','fontsize',9)
title(hcbar,long_names{2},'fontsize',9)

