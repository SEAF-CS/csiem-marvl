% ////////// Animate fvg objects \\\\\\\\\\
%
%
%   This function produces a simple animation of anything visualised with
%   and fvgcontrol object. Doesnt require screen on top.
%   Allows custom time inputs, currently as a matlab time number, and a
%   custom file name input.
%
%   
%       inputs: 
%                fobj  :  the handle to the fvg control object
%                outfil:  the filename to the animation (no file extension)
%
%       optional:
%                ts    :  the time to start from,                {start}
%                te    :  the time to finish,                    {end}
% 
%                   NOTE: the time inputs can be in matlab time, integer
%                         timesteps, or a date string 'dd/mm/yyyy HH:MM'.
%                         It will find the closest timestep in the model.
% 
%               Quality:  Video quality, from 0 to 100,          {100}
%             FrameRate:  Frames per Second,                     {30}
%                 undoc:  Use undocumented Feature (see below)   {true}
%              renderer:  Graphics rendering (see mathworks)     {zbuffer}
%
%
%   Author: Toby Devlin
%   Copyright (C) BMTWBMT 2014
%   Revision 1.1
%
%
%
%{ 
      WARNING: This function uses the undocumented 'hardcopy' feature, to 
               stop the figure from having to be on top of the screen, and
               to not get lovely 'screen saver' videos. 
               This will sometimes cause matlab to crash if you have a
               complicated image, such as a google map or high res bitmap,
               as it stores the image in memory instead of taking a screen
               cap. 
               If you are getting crashes, switch the 'undoc' option to
               false, and you will go back to normal animation methods.
               MATLAB will then animate the screen where the figure is, so
               the figure must be 'on top'.
%}


function animatefvg(fobj,outfil,varargin)


%______________________________________________________________
%%%%% check basic inputs %%%%%

        if ~strncmp(fobj.Type,'fvgcontrol',10);
            error('first input is not a valid fvg control object');
        end

        if exist(outfil,'file');
            disp('WARNING: file already exists, press enter to delete');
            pause
        end

        
%______________________________________________________________        
%%%%% check inputs %%%%%
        time = fobj.TimeSlider;
        cntrl = inputchecker(varargin,time);     
        
        
%______________________________________________________________        
%%%%% setup videowriter object %%%%%
        if isunix
            vidob = VideoWriter(outfil);
        else
            vidob = VideoWriter(outfil,'MPEG-4');
        end
        vidob.Quality = cntrl.Quality;
        vidob.FrameRate = cntrl.FrameRate;
        open(vidob)


%______________________________________________________________        
%%%%% customize object for efficiency %%%%%        
        
        set(fobj.SliderObj,'visible','off')
        set(fobj.FigureObj,'renderer','painters')

        
%______________________________________________________________        
%%%%% scroll through time %%%%%

for i = cntrl.ts : cntrl.dt: cntrl.te
    fobj.TimeCurrent = time(i);
    drawnow
%     if cntrl.undoc
%         frm = im2frame(hardcopy(fobj.FigureObj,['-d' cntrl.renderer],'-r0'));
%     else
%         frm = getframe(fobj.FigureObj);
%     end
    set(gcf,'renderer',[cntrl.renderer]);
    frm = im2frame(print(fobj.FigureObj,'-r0','-RGBImage'));
    writeVideo(vidob,frm);
end

close(vidob)%cleanup
set(fobj.sliderObj,'visible','on')



    disp('Your Animation is Ready!')
end













function cntrl = inputchecker(inputs,time)

    % defaults
    Quality = 100;
    FrameRate = 30;
    t{1} = 1;
    t{2} = length(time);
    dt = 1;
    undoc = true;
    if isunix
        renderer = 'zbuffer';
    else
        renderer = 'opengl';
    end
    
    % Check all the inputs
    if rem(length(inputs),2)>0
        error('Variable Arguments must be in descriptor/value pairs')
    end %if
    
    
    vargtyp = inputs(1:2:end);
    vargval = inputs(2:2:end);
    
    % cycle through varargin
    for aa = 1:length(vargtyp)
        switch lower(vargtyp{aa})
            
            % quality
            case 'quality'
                if vargval{aa}<=100 && vargval{aa}>=0
                    Quality = vargval{aa};
                else
                    display('WARNING: Quality input not in valid range. Setting to 100%')
                end %if
                
                
            % framerate    
            case {'framerate';'fps'}
                if isunix && ~ismac
                    disp('WARNING: FrameRate may have no effect on Linux')
                end %if
                if vargval{aa}>0
                    FrameRate = vargval{aa};
                end %if
                
                
            % start time    
            case {'ts';'starttime';'start'}
                t{1} = vargval{aa};
                
                
            % end time    
            case {'te';'endtime';'end'}
                t{2} = vargval{aa};
                
            case 'dt'
                dt = vargval{aa};
                
            case 'renderer'
                options = {'zbuffer';'opengl';'painters'};
                ii = strcmpi(vargval{aa},options);
                if any(ii);
                    renderer = options{ii};
                else
                    renderer = options{1};
                end %if
                
            case 'undoc'
                if islogical(vargval{aa})
                    undoc = vargval{aa};
                else
                    error('undoc input must be logical  true/false')
                end %if
                
                
            % any other stuff    
            otherwise
                disp(['WARNING: Unknown Parameter ' vargtyp{aa} '. Press Enter to Continue'])
                pause
                
        end %switch
        
        
    end %for
    
    
    
    % Check Time inputs
    for aa = 1:2
        
        
        if ischar(t{aa})  %it might be a time string
            
            try
                tmp = datenum(t{aa},'dd/mm/yyyy');
            catch
                tmp = datenum(t{aa},'dd/mm/yyyy HH:MM');
            end
            
        else              %it might already be a number
            tmp = t{aa};
            
        end %if
        
        
        if tmp>(time(1)-10) && tmp<(time(end)+10) 
            % within matlab time range. convert to integer
            t{aa} = find(abs(time-tmp)==min(abs(time-tmp)));
            
        elseif tmp>=1 && tmp<=length(time)        
            % within integer time range
            t{aa} = tmp;
            
        else
            % dunno...
            disp('WARNING: Could not parse time inputs, To Animate the Whole model, press enter')
            pause
            
        end %if
        
        
    end %for
    
    % make control structure
    cntrl.dt = dt;
    cntrl.ts = t{1};
    cntrl.te = t{2};  
    cntrl.Quality = Quality;
    cntrl.FrameRate = FrameRate;
    cntrl.undoc = undoc;
    cntrl.renderer = renderer;
end