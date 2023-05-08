classdef fvg_title < handle
    % Class for plotting title on axis
    %
    % Takes Several Inputs:
    %
    % fvobj - fvgraphics object
    % ax   - axis to plot on
    %
    % Steven Ettema April 2018
    
    properties
        fvobj
        ax
        ListObj_ut
    end
    
    methods
        % Constructor
        function obj = fvg_title(fvobj, ax)
                        
            obj.fvobj = fvobj;
            obj.ax = ax;
            obj.ListObj_ut = addlistener(obj.fvobj,'update_timestep',@(src,evnt)respondTimestep(obj,src,evnt));
        end
        
       
        % Update on new timestep
        function respondTimestep(obj,~,evnt)
            tstep = evnt.TimeCurrent;
            title(obj.ax,datestr(tstep,'dd/mm/yyyy HH:MM:SS'))
        end
        
    end
    
end

