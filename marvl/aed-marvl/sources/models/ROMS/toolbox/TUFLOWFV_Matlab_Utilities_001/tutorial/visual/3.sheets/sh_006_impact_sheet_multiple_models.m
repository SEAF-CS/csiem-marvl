% sh_007_impact_sheet_multiple_models.m
%
% Plot an interactive difference plot between two models
%
% SDE 2018

clear
close 

% ------------------- User Input ------------------
base_tfvfile    = '../../../../Complete_Model/TUFLOWFV/results/WQ_000_WQ.nc';       % For example...Base case model
dev_tfvfile     = '../../../../Complete_Model/TUFLOWFV/results/WQ_001_WQ.nc';       % For example Developed case model
diff_var        =  'WQ_OXY_OXY';                                                    % 2D or 3D variable from file e.g. H, V, TEMP, SAL, RHOW
vec_var         =  'WQ_OXY_OXY';                                                    % 2D or 3D variable with x ad y components e.g V, W10
ref             =  'sigma';                                                 % Model reference (TFV convention)
range           =  [0 1];                                                   % Model range (TFV convention)
scales.WQ_OXY_OXY = [[8.5 10]*1000/32 160];	
scaletick.WQ_OXY_OXY = [8.5:0.5:10]*1000/32;	
scalefactor.WQ_OXY_OXY = 32/1000;
diff_scales.WQ_OXY_OXY = [[-0.25 0.25]*1000/32 160];	
diff_scaletick.WQ_OXY_OXY = [-0.25:0.1:0.25]*1000/32;	
diff_scalefactor.WQ_OXY_OXY = 32/1000;


% ------------- Advanced Plot Settings ------------

clim       =  [0 0.2] ;                                                     % Colour Limit
diff_clim  =  [-0.25 0.25];                                                 % Difference plot colour limits
long_name  =  'Dissolved Oxygen [mg/L]';                                    % variable long name
plot_title =  {'Base Case','Developed Case','Impact'};                      % Titles for the plots

%---------------- Initialise a figure --------------

fvobj   = fvgraphics(3,'a3','portrait');                                    % initilise a interactive FV figure
ax      = myaxes(fvobj.FigureObj,1,3,'bot_buff',0.15);                      % place a several axes on the figure

%------------------- Plot the sheet -----------------

% Base Case
h(1)    = fvg_sheet(fvobj,base_tfvfile,...                                  % figure to plot on and results file to use
                'variables',diff_var,...                                    % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax(1),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot
v(1)    =  fvg_sheetvec(fvobj,base_tfvfile,...                              % figure to plot on and results file to use
                'variables',vec_var,...                                     % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'vecgrid',10,...                                            % grid that vectors are displayed on
                'vecscale',100,...                                          % scale the vector length
                'peerobj',ax(1),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot
% Developed Case
h(2)    = fvg_sheet(fvobj,dev_tfvfile,...                                   % figure to plot on and results file to use
                'variables',diff_var,...                                    % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax(2),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot
v(2)    =  fvg_sheetvec(fvobj,dev_tfvfile,...                               % figure to plot on and results file to use
                'variables',vec_var,...                                     % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'vecgrid',10,...                                            % grid that vectors are displayed on
                'vecscale',100,...                                          % scale the vector length
                'peerobj',ax(2),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot

% Difference
if strcmpi(diff_var,'V')                                                    % formulate the difference expression
    expres = 'hypot(M2.V_x,M2.V_y)-hypot(M1.V_x,M1.V_y)';                   % special case for vector quantities
else
    expres = sprintf('M2.%s-M1.%s',diff_var,diff_var);
end

h(3)    = fvg_sheet(fvobj,{base_tfvfile,dev_tfvfile},...                    % multiple models are specified in a cell array
                'expression',expres,...                                     % variable to plot
                'ref',ref,...                                               % depth averaging reference
                'range',range,...                                           % depth averaging range
                'peerobj',ax(3),...                                         % axis to plot on
                'titletime','on');                                          % choose to add the title to the plot

%----------------------- Formating ------------------

set(ax([1,2]), 'clim',clim,...
        'xcolor','none',...
        'ycolor','none')
set(ax(3), 'clim',diff_clim ,...
        'xcolor','none',...
        'ycolor','none')
                                                                            % format the axis zoom and scalling
axis equal
set(ax,'xlim',get(gca,'Xlim'),...
       'ylim',get(gca,'ylim'))

    
hcbar = mycolor(ax(1),scales.(vec_var),'location','Southoutside');          % add in a colour bar
set(hcbar,'ytick',scaletick.(vec_var))
set(hcbar,'yticklabel',num2str(scaletick.(vec_var)'*scalefactor.(vec_var),'%.1f'))
pos = get(ax(1),'position'); pos(2) = 0.05; pos(4) = 0.05;
set(hcbar,'position',pos)
title(hcbar,[plot_title{1} ' ' long_name],'fontsize',9)

hcbar = mycolor(ax(2),scales.(vec_var),'location','Southoutside');          % add in a colour bar
set(hcbar,'ytick',scaletick.(vec_var))
set(hcbar,'yticklabel',num2str(scaletick.(vec_var)'*scalefactor.(vec_var),'%.1f'))
pos = get(ax(2),'position'); pos(2) = 0.05; pos(4) = 0.05;
set(hcbar,'position',pos)

title(hcbar,[plot_title{2} ' ' long_name],'fontsize',9)

hcbar = mycolor(ax(3),diff_scales.(diff_var),'location','Southoutside');    % add in a colour bar
set(hcbar,'ytick',diff_scaletick.(diff_var))
set(hcbar,'yticklabel',num2str(diff_scaletick.(diff_var)'*diff_scalefactor.(diff_var),'%.1f'))
pos = get(ax(3),'position'); pos(2) = 0.05; pos(4) = 0.05;
set(hcbar,'position',pos)
title(hcbar,[plot_title{3} ' ' long_name],'fontsize',9)

hold on
plot(159.1269, -31.41123,'xk','MarkerSize',12)
linkaxes(ax,'xy')


