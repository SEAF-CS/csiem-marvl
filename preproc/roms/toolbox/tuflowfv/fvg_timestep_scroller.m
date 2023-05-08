classdef fvg_timestep_scroller < handle
    % Class to scroll through time on a axis
    %
    % Takes Several Inputs:
    %
    % fobj - fvgraphics object
    % ax  - to plot on
    % colour - colour of line to be plotted
    %
    % Steven Ettema April 2018
    
    properties
        controlObj
        timeCurrent
        lineObj
        colour
        ax
        ListObj_ut
    end
    
    methods
        % Constructor
        function obj = fvg_timestep_scroller(fobj, ax, colour)
                        
            obj.controlObj = fobj;
            obj.ax = ax;
            obj.colour = colour;
            
            obj.createLine;
            
            obj.ListObj_ut = addlistener(obj.controlObj,'update_timestep',@(src,evnt)respondTimestep(obj,src,evnt));
        end
        
        % Create the plot
        function createLine(obj)
            y_dat = get(obj.ax,'ylim');
            x_dat = [nan nan];

            obj.lineObj = line(x_dat,y_dat,...
                                'color',obj.colour,...
                                'parent',obj.ax);
        end
        
        
         
        % Update on new timestep
        function respondTimestep(obj,~,evnt)
            tstep = evnt.TimeCurrent;
            
            
            x_dat = [tstep tstep];
            y_dat = get(obj.ax,'ylim');

            
            set(obj.lineObj,'Xdata',x_dat,'Ydata',y_dat)
        end
        
    end
    
end

