classdef fvg_profile < handle
    % Dirty class for plotting ADCP and model profiles. Should work in a similar way to fvg_sheet
    %
    % Takes Several Inputs:
    %
    % fobj - fvgraphics object
    % time_data - timesteps (1*nt [dim 2 of data])
    % elevations - elevations data is to be plotted at (nzl*[nt|1])
    % data  - data to be plotted (nzl*nt)
    % colour - colour of line to be plotted
    %
    % Steven Ettema April 2018
    
    properties
        controlObj
        timeCurrent
        lineObj
        data
        time_data
        elevations
        colour
        ax
        ListObj_ut
        cont = linspace(0,1,21)
        titletime = true
    end
    
    methods
        % Constructor
        function obj = fvg_profile(fobj, ax, time_data, elevations, data, colour, titletime)
                        
            obj.controlObj = fobj;
            obj.time_data = time_data;
            obj.elevations = elevations;
            obj.data = data;
            obj.ax = ax;
            obj.colour = colour;
            obj.titletime = titletime;
            obj.getTimes
            obj.createLine;
            
            obj.ListObj_ut = addlistener(obj.controlObj,'update_timestep',@(src,evnt)respondTimestep(obj,src,evnt));
        end
        
        % Create the plot
        function createLine(obj)
            x_dat = obj.data(:,1);
            y_dat = obj.elevations(:,1);
            obj.lineObj = line(x_dat,y_dat,...
                                'color',obj.colour,...
                                'parent',obj.ax);
        end
        
        
        % Get time vector and set to fvgraphics object as required
        function getTimes(obj)
            tmp = struct('M1',obj.time_data);
            set(obj.controlObj,'TimeSlider',tmp);
        end
        
        % Update on new timestep
        function respondTimestep(obj,~,evnt)
            tstep = evnt.TimeCurrent;
            [~,ii] = min(abs(obj.time_data-tstep));
            
            x_dat = obj.data(:,ii);
            if size(obj.elevations,2)>1
                y_dat = obj.elevations(:,ii);
            else
                y_dat = obj.elevations;
            end
            
            set(obj.lineObj,'Xdata',x_dat,'Ydata',y_dat)
            
            if obj.titletime
                title(obj.ax,datestr(tstep,'dd/mm/yyyy HH:MM:SS'))
            end
        end
        
    end
    
end

