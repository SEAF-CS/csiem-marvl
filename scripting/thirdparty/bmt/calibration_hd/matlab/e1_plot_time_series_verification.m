% Script to plot time series
% Written for A11348 Cockburn Sound BGC Model
%
% Copyright (C) BMT 2023
%
%% Clean up
%clear
close all
clear path
clear


%% Set folder and file locations
run=struct();
run_version_name ='CSound_000_A7_20130101_20130601';
run_version = [run_version_name '_tsFormat_Validation']; %Scenario version number % THIS IS THE MODELLED DATA
plot_directory = '..\plots\';
if ~exist(plot_directory) 
    mkdir(plot_directory); 
end
run_sce_names = {'Modelled', 'Observed'}; 


fname_list=dir('..\data\matfiles\CSound_Calibration\ADCP Data\Westport_S0?_?.mat');


Cell_IDS = readtable('cellID.txt');
[v, w] = unique( Cell_IDS.cell_ids, 'stable' );
duplicate_indices = setdiff( 1:numel(Cell_IDS.cell_ids), w );




for fname_i =  1: length(fname_list)

    fname = fname_list(fname_i).name;
    obs_data_name = ['..\data\matfiles\CSound_Calibration\ADCP Data\' fname];
    mod_data_name = ['..\data\matfiles\CSound_Calibration\' run_version '.mat'];
    %% User inputs
    
    vars = {'VMAG';'VDIR';'V_x';'V_y';}; %'H'};%        

    
    %% Get site location data
    load(obs_data_name);
    load(mod_data_name);

if contains(fname,'a.mat')
    t_rng=[datetime({'01-Jan-2013';}) DATA.PeriodEnd];
else
    t_rng={DATA.PeriodStart DATA.PeriodEnd};
end
    yy = datestr(t_rng(2),'yyyy');
    ylim.V_x = [-0.25 0.25];
    ylim.V_y = [-0.25 0.25];
    ylim.VMAG = [0 0.25];
    ylim.VDIR = [0 370];
    ylim.H = [-1 1];

        if contains(fname,'S01')
            site='SITE01';
        elseif contains(fname,'S02')
            site='SITE02';
        end




        e2_plotvars_setup

                
            for var_i = 1:length(vars)
                %% Extract data
                if vars{var_i} == 'H'
                    levels = {'surface'};
                    
                else
                    OBS=DATA;
                    levels = {'surface';'middle';'sigma';'bottom';};
                    
                end
    
                
                        for i_levels= 1 : length(levels)
                            
                            
    
                            try
                                [obs_data,ind] = rmoutliers(OBS.(levels{i_levels}).(vars{var_i}));
                                obs_dts = OBS.TIME_hydro(~ind);
                            catch
                                obs_dts = OBS.TIME_hydro;
                            end
                            
                            fileTest=find(strcmp(Cell_IDS.sites,(fname(1:end-4))));
                            fileTest2=ismember(Cell_IDS.cell_ids,Cell_IDS.cell_ids(fileTest));
                            fileTest3=find(fileTest2 > 0,1);
                            fname_test=Cell_IDS.sites(fileTest3);

                            MOD=AB.(levels{i_levels}).(fname_test{1});
   
                            if ismember(vars{var_i},'VDIR')
                                try
                                    [mod_data, ~] = cart2compass(MOD.V_x,MOD.V_y);
                                catch
                                    [mod_data, ~] = cart2compass(MOD.V_x,MOD.V_y);
                                end
                                mod_dts = MOD.time;
                            else         
                                mod_dts = MOD.time;

                                if ismember(vars{var_i},'VMAG')
                                    mod_dts = MOD.time;
                                end

                                mod_data= MOD.(vars{var_i});

                            end
                
                
                            
                            
                                if vars{var_i} == 'H'
                                    obs_data = obs_data - mean(obs_data,'omitnan');
                                    mod_data = mod_data - mean(mod_data,'omitnan');
                                end
                    
                               %%___________________________________________________________plotting
                            fg=myfigure(1,'papertype','A4','paperorientation','landscape');
                            ax=myaxes(fg,1,1,'left_buff',0.08,'right_buff',0.08,'top_buff',0.08,'bot_buff',0.12);
                            set(ax,'nextplot','add');
                            grid on ;
                            box on ;
                        
                            h1(1) = plot(ax(1),datetime(obs_dts,'ConvertFrom','Datenum'),obs_data,'LineStyle','none','Marker','o','LineWidth',0.5);hold on;
                            h1(2) = plot(ax(1),datetime(mod_dts,'ConvertFrom','Datenum'),mod_data,'LineStyle','-','LineWidth',1.5);hold on;
                            
                            
                            title(ax(1),[yy ' ' fname(1:end-4)  ' ' strrep((levels{i_levels}),'pnt','.') ],'Interpreter','none','fontsize',12,'fontweight','bold','units','normalized');
                            ylabel(ax(1),[pltvars.(vars{var_i}).longname ' (' pltvars.(vars{var_i}).units ')']  ,'fontsize',12,'fontweight','bold');
                            
                            %% Set legends
                            ax_hidden=axes('position',[0,0,1,1]); % hidden axes to aid legend control
                            h(1)=plot(ax_hidden,[nan,nan],'LineStyle','none','Marker','o'); hold on;
                            h(2)=plot(ax_hidden,[nan,nan],'-'); hold on;
                           
                            lg = legend(h, 'Observed','Modelled');
                            set(ax_hidden,'visible','off');
                            leg_pos=[0.3455 0.02 0.309 0.0353];%[0.2893 0.03 0.4214 0.0321]
                            set(lg,'Position',leg_pos,'Interpreter', 'none',...
                                'box','off','Orientation','horizontal','fontsize',10);
                            set(ax,'xlim',([datetime(t_rng(1)) datetime(t_rng(2))]));
                            set(ax,'ylim',ylim.(vars{var_i}));
                            
                            plot_directory2=char(strcat(plot_directory,(fname(1:end-4))));
    
                            if ~exist(plot_directory2)
                                mkdir(plot_directory2);
                                disp('New Directory Saved')
                            end
    
                            pname = [plot_directory2 '/' (vars{var_i}) '_' (levels{i_levels}) '_' site 'TEST.jpeg'];                          
                            exportgraphics(fg, pname, 'Resolution', 300);
                            savefig(fg,strrep(pname,'.jpeg','.fig'));
                           
                            close(fg);
                            
                        end
            end
end  
    