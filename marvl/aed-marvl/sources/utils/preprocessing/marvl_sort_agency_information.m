function [mface, mcolor, markerSize, agencyname] = marvl_sort_agency_information(agency, varargin)
% Returns marker face, color, and size for a given agency using a JSON configuration.
%
% Optional second argument is the number of points being plotted so dynamic
% marker sizing can react to data density.
%
% - Looks for agency_config_v2.json in the same folder as this function
% - If an agency has "mface" or "mcolor" defined in JSON, those are used
% - Otherwise, cyclic assignment from mface_options and mcolor_options
% - Defaults are used if agency is not listed

% -------------------- persistent config dynamicCache --------------------
persistent config dynamicCache
if isempty(config)
    thisDir = fileparts(mfilename('fullpath')); % folder where this .m file lives
    cfgPath = fullfile(thisDir, 'agency_config_v2.json');
    if ~isfile(cfgPath)
        error('Config file not found: %s', cfgPath);
    end
    config = jsondecode(fileread(cfgPath));
end

% -------------------- prepare variables --------------------
agency = strtrim(string(agency));
if strcmpi(agency, "__reset__")
    dynamicCache = [];
    mface = [];
    mcolor = [];
    markerSize = [];
    agencyname = '';
    return;
end
numPoints = [];
if ~isempty(varargin)
    numPoints = varargin{1};
end

% AgencyConfigs a cell array of structs
tmp = config.AgencyConfigs;
if isstruct(tmp)
    agencies = num2cell(tmp);
elseif iscell(tmp)
    agencies = tmp;
else
    error('AgencyConfigs must be a struct array or cell array.');
end

% mface_options como celda de char
mface_options = config.mface_options;
if isstring(mface_options), mface_options = cellstr(mface_options); end

% mcolor_options como matriz Nx3
mcolor_options = config.mcolor_options;
if iscell(mcolor_options), mcolor_options = cell2mat(mcolor_options); end

% Defaults si la agencia no aparece
default_marker = 'xk';
default_color  = [255, 61, 9] / 255;
default_size   = 5;

% -------------------- find agency (case-insensitive) --------------------
matchIndex = [];
agConfig  = struct();
for ii = 1:numel(agencies)
    ai = agencies{ii};
    if isfield(ai,'name') && strcmpi(string(ai.name), agency)
        matchIndex = ii;
        agConfig = ai;
        break;
    end
end

% -------------------- assign outputs --------------------
if isempty(matchIndex)
    % Not found -> defaults
    mface      = default_marker;
    mcolor     = default_color;
    markerSize = default_size;
else
    % marker size
    dynamicFlag = isfield(agConfig, 'dynamic_plotting') && logical(agConfig.dynamic_plotting);
    if dynamicFlag
        if isempty(dynamicCache)
            dynamicCache = containers.Map('KeyType','char','ValueType','double'); % cache per agency for consistent sizing
        end
        agencyKey = lower(char(agency));
        hasCache = isKey(dynamicCache, agencyKey);

        validPoints = numPoints;
        isValidCount = ~(isempty(validPoints) || ~isscalar(validPoints) || ~isfinite(validPoints) || validPoints <= 0);

        if isValidCount
            if hasCache
                validPoints = max(dynamicCache(agencyKey), validPoints);
            end
            dynamicCache(agencyKey) = validPoints;
            markerSize = compute_dynamic_marker_size(validPoints, default_size);
        elseif hasCache
            markerSize = compute_dynamic_marker_size(dynamicCache(agencyKey), default_size);
        else
            markerSize = default_size;
        end
    elseif isfield(agConfig,'msize')
        markerSize = agConfig.msize;
    else
        markerSize = default_size;
    end

    % marker face overrides or cyclic assignment
    if isfield(agConfig,'mface')
        mface = agConfig.mface;
    else
        nMarker   = numel(mface_options);
        idxMarker = mod(matchIndex-1,nMarker) + 1;
        mface     = mface_options{idxMarker};
    end

    % color overrides or cyclic assignment
    if isfield(agConfig,'mcolor')
        mcolor = agConfig.mcolor(:);
        mcolor = reshape(mcolor, 1, []);
    else
        nColor   = size(mcolor_options,1);
        idxColor = mod(matchIndex-1,nColor) + 1;
        mcolor   = mcolor_options(idxColor,:);
    end
end

% -------------------- return agency name --------------------
agencyname = char(agency);

end
% -------------------- end of function --------------------

function markerSize = compute_dynamic_marker_size(numPoints, fallbackSize)
% Return a marker size that shrinks as the number of observations grows.

if isempty(numPoints) || ~isscalar(numPoints) || ~isfinite(numPoints) || numPoints <= 0
    markerSize = fallbackSize;
    return;
end

% Breakpoints tuned to keep symbols legible while dense series stay tidy.
dynamicBreaks = [0, 30, 60, 120, 240, 480];
dynamicSizes  = [6, 5.5, 4, 3, 0.8, 0.4];

idx = find(numPoints >= dynamicBreaks, 1, 'last');
if isempty(idx)
    idx = 1;
elseif idx > numel(dynamicSizes)
    idx = numel(dynamicSizes);
end

markerSize = dynamicSizes(idx);
end






