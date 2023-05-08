%% fv_create_profiles
% 
% This creates profile files similar to that which are output by TUFLOWFV
% If no inputs are specified GUI window prompts will pop-up
%
% RUN on blaydos might break on windows
%
% optional inputs:
%
%        infil = '';        filename of full model results in netcdf format
%        outfil = '';       filename of file that will be created.
%        locations = [x1,y1
%                     x2,y2;
%                       ...
%                     xn,yn]; coordinates of locations to extract profiles
%       location_names = {'name1'; 
%                         'name2'}  cell array of same length as locations
%                                   with names corresponding to those 
%                                   points
%
% Toby Devlin, Copyright (C) BMTWBM 2014
%
%{
    REVISIONS

    1.1 - Fixed multi Location name bug - TD
    1.2 - Added GUI Selections - TD

%}

function fv_create_profiles(varargin)

    % Check Number of Inputs
    if nargin == 0
        [fil,pat] = uigetfile({'*.nc','TUFLOW-FV Results File'},'Select Results File');
        infil = [pat fil];
        if isempty(infil) || ~exist(infil,'file')
            error('No File Selected')
            return %#ok<*UNRCH>
        end
        outfil = strrep(infil,'.nc','_PROFILE.nc');
    elseif nargin==2
        infil=varargin{1};
        outfil=varargin{2};
    elseif nargin==3
        infil=varargin{1};
        outfil=varargin{2};
        locations=varargin{3};
        for aa = 1 : length(locations);
        	location_names{aa}=['Point_' num2str(aa)];
        end
		elseif nargin==4
		    infil=varargin{1};
        outfil=varargin{2};
        locations=varargin{3};
        location_names=varargin{4};    
    end

    % Check if Outfil Exists
    if exist(outfil,'file')
        display([outfil ' exists - press enter to delete and continue with profiling'])
        pause
        delete(outfil)
    end


    if nargin==2 || nargin==0
        try
        [cellids,location_names,locations] = userpromptids(infil);
        catch
            disp('WARNING: Locations Not Set, Exiting')
            return
        end
    elseif nargin==4
        cellids = fv_get_ids(locations,infil,'cell'); %#ok<*NODEF>
        
        sz = size(locations);
        if sz(1)==2
            if sz(2)~=2
                locations=locations';
            end
        end
        names = location_names;
    else
        error('Incorrect Number of Inputs')
    end
    
        tmp = unique(cellids);
        n=histc(cellids,tmp);
        remtag = [];
        for aa = 1:length(n)
            if n(aa)>1
                itag = find(cellids==tmp(aa));
                loctag = sprintf([repmat('%s, ',1,length(itag)-1) 'and %s'],location_names{itag});
                disp(['WARNING: locations ' loctag ' are in the same cell. Removing all but ' location_names{itag(1)}])
                remtag = [remtag;itag(2:end)]; %#ok<*AGROW>
            end
        end
%         if ~isempty(remtag)
% %             location_names(remtag) = [];
% %             locations(remtag) = [];  % this line breaks it on windows go locations(remtag,:)
% %             cellids(remtag) = [];
%             location_names = location_names(~remtag);
%             locations = locations(~remtag,:);
%             cellids = cellids(~remtag);
%         end
        if ~isempty(remtag)
        %             location_names(remtag) = [];
        %             locations(remtag) = [];  % this line breaks it on windows go locations(remtag,:)
        %             cellids(remtag) = [];
                    tmp = zeros(length(location_names),1);
                    tmp(remtag)=1;
                    location_names = location_names(~tmp);
                    locations = locations(~tmp,:);
                    cellids = cellids(~tmp);
        end

        for aa=1:length(location_names)
            l_name = location_names{aa};
            try
                tmpstruc = struct(l_name,[]);
            catch
                ssi = regexp(l_name,' ','ONCE');
                if isempty(ssi)
                    error([l_name ' is an invalid location name, must be compatible with matlab fieldnames for structures']);
                else
                    error([l_name 'is invalid location name, try replacing spaces with underscores'])
                end
            end
        end
        
    fill = -9999; OLDINFO = ncinfo(infil);
    
    %___________________________________________
    % get the profiles
    disp('Processing Profile Series...')
    out = fv_get_profile(infil,cellids,[1 inf]);
    %___________________________________________
    
    
    
    ntim = length(out.time);

    disp('Writing Output File...')

        
      
%% Setup the Schema
schema.Name = '/';
schema.Format = 'netcdf4';

% Global Attributes
schema.Attributes(1).Name = 'Origin';
schema.Attributes(1).Value = 'Created By TUFLOWFV';
schema.Attributes(2).Name = 'Type';
schema.Attributes(2).Value = 'TUFLOWFV Profile Output';
if length(OLDINFO.Attributes)>2
schema.Attributes(3).Name = 'Spherical';
schema.Attributes(3).Value = OLDINFO.Attributes(3).Value;
else
    % must be an old file format..
end
% Global Dimensions
schema.Dimensions(1).Name = 'N1';
schema.Dimensions(1).Length = 1;
schema.Dimensions(1).Unlimited = false;
schema.Dimensions(2).Name = 'Time';
schema.Dimensions(2).Length = length(out.time);
schema.Dimensions(2).Unlimited = true;
schema.Dimensions(3).Name = 'NumSedFrac';
schema.Dimensions(3).Length = 1;
schema.Dimensions(3).Unlimited = false;

% Root Variable (just time)
schema.Variables(1).Name = 'ResTime';
schema.Variables(1).Dimensions(1) = schema.Dimensions(2);
schema.Variables(1).Datatype = 'double';
schema.Variables(1).ChunkSize = ntim;

% Now progress through Locations
cells = fieldnames(out);
counter=0;
for aa = 1 : length(cells)
    if strcmp(cells{aa},'time'); continue; end
    counter=counter+1;
    
    % How many Variables and Layers..
    varnames = fieldnames(out.(cells{aa}));
    nlay = size(out.(cells{aa}).layerface_Z,1)-1;
    nlayf = size(out.(cells{aa}).layerface_Z,1);
    
    % Group Dimensions
    grdims(1).Name = 'NumLayers';
    grdims(1).Length = nlay;
    grdims(1).Unlimited = false;
    grdims(2).Name = 'NumLayerFaces';
    grdims(2).Length = nlayf;
    grdims(2).Unlimited = false;
    
    % Group Variables
    % X
    grvars(1).Name = 'X';
    grvars(1).Datatype = 'double';
    grvars(1).Dimensions(1) = schema.Dimensions(1);
    grvars(1).Dimensions(1).Name = ['/' schema.Dimensions(1).Name];
    grvars(1).Attributes(1).Name = 'Long_Name';
    grvars(1).Attributes(1).Value = 'Longitude';
    grvars(1).Attributes(2).Name = 'Units';
    grvars(1).Attributes(2).Value = 'Degrees';
    
    % Y
    grvars(2).Name = 'Y';
    grvars(2).Datatype = 'double';
    grvars(2).Dimensions(1) = schema.Dimensions(1);
    grvars(2).Dimensions(1).Name = ['/' schema.Dimensions(1).Name];
    grvars(2).Attributes(1).Name = 'Long_Name';
    grvars(2).Attributes(1).Value = 'Latitude';
    grvars(2).Attributes(2).Name = 'Units';
    grvars(2).Attributes(2).Value = 'Degrees';
    
    % All other variables
    for bb = 1 : length(varnames)
        
        % set the basics
        grvars(bb+2).Name = varnames{bb};
        grvars(bb+2).Datatype = 'single';
        grvars(bb+2).FillValue = fill;
        grvars(bb+2).DeflateLevel = 9;
        
        % find out if it is 2D, 3D, or is layerface..
        ss = size(out.(cells{aa}).(varnames{bb}));
        if ss(1)==nlay
            grvars(bb+2).ChunkSize = [nlay,ntim];
            grvars(bb+2).Dimensions(1) = grdims(1);
        elseif ss(1)==nlayf
            grvars(bb+2).ChunkSize = [nlayf,ntim];
            grvars(bb+2).Dimensions(1) = grdims(2);
        elseif ss(1)==1;
            grvars(bb+2).ChunkSize = [1,ntim];
            grvars(bb+2).Dimensions(1) = schema.Dimensions(1);
        else
            disp('Unknown Dimensions'), return;
        end
        
        % setup Dimensions and attributes
        grvars(bb+2).Dimensions(2) = schema.Dimensions(2);
        grvars(bb+2).Dimensions(2).Name = ['/' schema.Dimensions(2).Name];
        grvars(bb+2).Attributes = longnamesandunits(varnames{bb},OLDINFO);
        
        % Check for sediment Dimensions
        if length(ss)==3
            schema.Dimensions(3).Length = ss(3);
            grvars(bb+2).Dimensions(3) = schema.Dimensions(3);
            grvars(bb+2).Dimensions(3).Name = ['/' schema.Dimensions(3).Name];
            grvars(bb+2).ChunkSize = [grvars(bb+2).ChunkSize,ss(3)];
        end
    end
    
    % Finally give the Group its place in the schema
    schema.Groups(counter).Name = ['/' location_names{counter}];
    schema.Groups(counter).Variables = grvars;
    schema.Groups(counter).Dimensions = grdims;
end

%% Write the new PROFILES file
% Create the empty netcdf
ncwriteschema(outfil,schema);

% open it up
nci = netcdf.open(outfil,'WRITE');

% write the time by timestep
for aa = 1 : length(out.time)
    netcdf.putVar(nci,0,aa-1,1,out.time(aa))
end

% get the group ids
cells(strcmp(cells,'time')) = [];
grid = netcdf.inqGrps(nci);

% for each group, write all its variables
for aa=1:length(cells)
    var = fieldnames(out.(cells{aa}));
    for bb = 1 : length(var)
        varid = netcdf.inqVarID(grid(aa),var{bb});
        netcdf.putVar(grid(aa),varid,out.(cells{aa}).(var{bb}));
    end
    xid = netcdf.inqVarID(grid(aa),'X');
    yid = netcdf.inqVarID(grid(aa),'Y');
    netcdf.putVar(grid(aa),xid,locations(aa,1));
    netcdf.putVar(grid(aa),yid,locations(aa,2));
end
% done :)
netcdf.close(nci)
disp('Profile file is ready')
end



%% Nested functions
% function to find the long name and units from a variable

function atts = longnamesandunits(var,OLDINFO)
    nvar = length(OLDINFO.Variables);
    for aa = 1 : nvar
        if strcmp(var,OLDINFO.Variables(aa).Name)
            atts = OLDINFO.Variables(aa).Attributes;
        end
    end
end  
  
