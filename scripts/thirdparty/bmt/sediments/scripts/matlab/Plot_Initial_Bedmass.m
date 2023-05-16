%% Plot Inital Bedmass
% 
% Description: Plots bed files against field samples for assessment of bed
% warmup 
% Copyright (C) BMT 2023
% 


%% Preliminary Commands

clear all;
close all;
clc;

addpath(genpath('.\functions\'))
%addpath(genpath('.\Ext functions\'))

%% Input
%This is the model output file path
model_path = 'K:\scratch2\A11348_CSound\Modelling\01-FV\results\Csound_SED_016\';

%output file
model_file = 'CSound_000_A14_20130101_20130101_SED_016_warmup_SED.nc'; % used for geometry only

%bed restart file can be found under the log folder.
%bed_path = 'M:\UWA\A11348_Cockburn_Sound_BCG_Model\2Exectn\2Modelling\2TUFLOWFV\runs\CSound_SED\SED_ambientV2\log\';
bed_path = '..\..\..\..\..\2TUFLOWFV\runs\CSound_SED\SED_ambientV2\log\';
bed_file = 'CSound_000_A14_20130101_20130101_SED_016_warmup_bed.rst';

%Sediment sampling data produced from 2005 AusGeoScience study
point_files = ...
    {
        'matfiles\CS_CompiledSedimentSummary.mat';
    };

windows = ...
    {
        [115.5561, -32.9515, 115.8601, -32.3310]
        [115.6582, -32.2786, 115.7780, -32.1302]
    };

names = {'CockBurn Sound - Model domain' 'Cockburn Sound - Zoomed'};

base_map = 'base_map\EPSG32750_Date20221121_Lat-32.206443_Lon115.724071_Mpp2.389.jpg';

%Sediment types
seds = {'Sand', 'Fines'};
clims = {[0, 100], [0, 100]};
n_band = 10;

rho = 800;

out_root = '..\..\plots\';
out_fmt = 'Initial_Bedmass_%s_Distribution_at_%s';

%% Script

% Prepare output location
name = strrep(bed_file, '.rst', '');
out_folder = [out_root name '\'];
if ~isfolder(out_folder)
    mkdir(out_folder); 
end

% Load Restart
base_rst = fvwbm_read_bed_restart([bed_path bed_file],'single');
base_mass = base_rst.data;

nc = size(base_mass,1);
nl = size(base_mass,2);
ns = size(base_mass,3);

if ns > 3
    ns = 3;
end

% Load Geometry
geo = netcdf_get_var([model_path model_file],'names',...
    {'cell_X','cell_Y','node_X','node_Y','cell_node','ResTime'});

time = convtime(geo.ResTime);
cells = [geo.cell_X, geo.cell_Y];
nodes = [geo.node_X, geo.node_Y];
faces = geo.cell_node'; 
faces(faces == 0) = nan;

% Calculate and Plot Resultant Particle Size Distributions
psd = squeeze(base_mass(:, 1, :)./sum(base_mass(:, 1, :),3)*100);
thick = sum(base_mass(:, 1, :), 3)/rho;

% Prepare the Figure
f = figure('units', 'centimeters', 'paperunits', 'centimeters',...
            'position', [5 5 10 12.5], 'paperposition', [0 0 10 12.5],...
            'visible', 'on', 'inverthardcopy', 'off', 'color', 'w');
ax = myaxes(f, 1, 1,'bot_buff', 0.12);
hold on

% cmap = white_to_brown(n_band);

% cmap = jet(n_band);
cmap = whitetobrown(n_band);
%cmap = autumn(n_band);


set(ax,'Xtick',[],'Ytick',[],'Xcolor','w','Ycolor','w','Colormap',cmap,'clim',[0,0.3])
    
set(ax,'color',[170/255 209/255 183/255],'Layer','top','box','on')  % Background color
img = myimage(ax, base_map);
p = patch('Faces',faces,'Vertices',nodes,'Parent',ax,...
          'EdgeColor','None','FaceColor','Flat','CData',nan(nc,1));


cbar = colorbar('peer',ax,'Location','SouthOutside');
set(cbar,'XAxisLocation','Bot','Position',[0.025, 0.05, 0.95, 0.03]);
title_obj = title(cbar,'dummy'); set(title_obj,'fontsize',8); set(cbar,'fontsize',8);


set(p, 'CData', thick);


    for bb = 1:length(windows)
       xlim = windows{bb}([1, 3]);
       ylim = windows{bb}([2, 4]);
       
       set(ax, 'XLim', xlim, 'YLim', ylim, ...
           'DataAspectRatio', [1, 1, 1]);
        
%        out_name = sprintf(out_fmt, seds{aa}, names{bb});
       
%        print(f, [out_folder out_name],'-dpng','-r400');
    end

% Prepare Points
P = struct();
for aa = 1:length(point_files)
    load(point_files{aa});
    points = fieldnames(DATA);
    points(strcmp(points, 'passingSize_micron')) = [];
    
    for bb = 1:length(points)
       P.(points{bb}) = DATA.(points{bb});
    end    
end

thresh = [75 4.2];  % micron
for aa = 1:length(thresh)
    [~, ind(aa)] = min(abs(DATA.passingSize_micron - thresh(aa)));   
end

clear DATA;

% Determine PSD based on threshold values
for aa = 1:length(points)
    for bb = 1:length(thresh)+1
        if bb < length(thresh)+1 && bb == 1
            P.(points{aa}).psd(bb) = 100 - P.(points{aa}).percPassing(ind(bb));
        elseif bb < length(thresh)+1
            P.(points{aa}).psd(bb) = P.(points{aa}).percPassing(ind(bb-1)) - P.(points{aa}).percPassing(ind(bb));
        else
            P.(points{aa}).psd(bb) = P.(points{aa}).percPassing(ind(bb-1));
        end
    end
end

% Assemble point data
for aa = 1:ns
    for bb = 1:length(points)
        P_out.(seds{aa}).Latitude(bb, 1)  = P.(points{bb}).Latitude;
        P_out.(seds{aa}).Longitude(bb, 1) = P.(points{bb}).Longitude;
        P_out.(seds{aa}).psd(bb, 1)       = P.(points{bb}).psd(aa);
    end
    % Remove points based on nan PSD values
    P_out.(seds{aa}).Latitude(isnan(P_out.(seds{aa}).psd)) = [];
    P_out.(seds{aa}).Longitude(isnan(P_out.(seds{aa}).psd)) = [];
    P_out.(seds{aa}).psd(isnan(P_out.(seds{aa}).psd)) = [];
    % 
end

c = 1.5*10^-4;
% for aa = 1:length(points)
%     point = points{aa};
%     
% %     line('Parent', ax, 'XData', P.(point).Longitude, 'YData', P.(point).Latitude, 'LineStyle', 'None',...
% %          'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'MarkerSize', 3);
% %     labels(aa) = text(P.(point).Longitude + c, P.(point).Latitude + c, '', 'FontSize', 5, 'Parent', ax);
% end

for aa = 1:ns
    set(p, 'CData', psd(:, aa)); set(ax, 'clim', clims{aa});
    title_str = sprintf('%s Distribution (%%)', seds{aa});
    set(title_obj, 'string', title_str);
    
    ticks = clims{aa}(1):(clims{aa}(2)-clims{aa}(1))/10:clims{aa}(2);
    set(cbar,'xtick',ticks);
          
    for cc = 1:length(windows)
        xlim = windows{cc}([1, 3]);
        ylim = windows{cc}([2, 4]);
       
        set(ax, 'XLim', xlim, 'YLim', ylim, ...
            'DataAspectRatio', [1, 1, 1]);
              
        if cc == 2
            scat = scatter(P_out.(seds{aa}).Longitude, P_out.(seds{aa}).Latitude, 20, P_out.(seds{aa}).psd, 'filled', 'MarkerEdgeColor',[0 0 0], 'Parent', ax);
            for bb = 1:length(P_out.(seds{aa}).Longitude)
%                 textborder(P_out.(seds{aa}).Longitude(bb) + c, P_out.(seds{aa}).Latitude(bb) + c, num2str(P_out.(seds{aa}).psd(bb), '%.0f'), [0,0,0], [1,1,1], 'FontSize', 5, 'Parent', ax);
                txt(bb) = text(P_out.(seds{aa}).Longitude(bb) + c, P_out.(seds{aa}).Latitude(bb) + c, num2str(P_out.(seds{aa}).psd(bb), '%.0f'), 'FontSize', 5, 'FontWeight', 'bold', 'Color', 'k', 'Parent', ax);
            end
        elseif cc == 1
            scat = scatter(P_out.(seds{aa}).Longitude, P_out.(seds{aa}).Latitude, 20, P_out.(seds{aa}).psd, 'filled', 'MarkerEdgeColor',[0 0 0], 'Parent', ax);
        end
        
        out_name = sprintf(out_fmt, seds{aa}, names{cc});
       
        print(f, [out_folder out_name],'-dpng','-r400');
        
        if cc == 1
            delete(scat)
        elseif cc == 2
            delete(scat)
            delete(txt(:))
        end
             
    end
end

