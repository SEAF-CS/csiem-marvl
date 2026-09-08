% Template runner for MARVL configs, change the configuration path, label, and windows,
% and reuse it for any other scenario.

clear;

scriptDir = fileparts(mfilename('fullpath'));
aedMarvlRoot = fullfile(scriptDir,'..','..','aed-marvl');
if ~exist(aedMarvlRoot,'dir')
    error('aed-marvl not found at: %s', aedMarvlRoot);
end
addpath(genpath(aedMarvlRoot));
global MARVLs;
style = 'matlab';

configPath = 'MARVL_WQ_SI.m';
jobLabel   = 'SUMMARY_IMAGES';

dateWindows = [...
    %datetime(1989,01,01) datetime(2000,01,01);...
    %datetime(2001,01,01)  datetime(2012,01,01);...
    %datetime(2013,01,01)  datetime(2024,01,01);...
    datetime(2021,01,01)  datetime(2025,01,01)...
    ];
ticksPerWindow = 12; % number of x-axis ticks in each plot window
configFile = fullfile(scriptDir, configPath);
repoRoot = ascendPath(scriptDir, 2); % .../csiem-marvl
outputRoot = fullfile(repoRoot,'outputs','005_1.7_summarry_images');

run_marvl_windows_single(configFile,jobLabel, dateWindows, ticksPerWindow, style, outputRoot);

% -------------------------------------------------------------------------
function run_marvl_windows_single(configPath, label,dateWindows, ticksPerWindow, style, outputRoot)
global MARVLs;

windows = datenum(dateWindows);
tickCount = max(2, ticksPerWindow);

for ww = 1:size(windows,1)
    run(configPath);

    startDate = windows(ww,1);
    endDate = windows(ww,2);
    if startDate >= endDate
        error('%s window %d start (%s) must be before end (%s).', ...
            label, ww, datestr(startDate), datestr(endDate));
    end

    MARVLs.timeseries.datearray = linspace(startDate, endDate, tickCount);

    startVec = datevec(startDate);
    endVec = datevec(endDate);
    runTag = sprintf('%04d_%04d', startVec(1), endVec(1));
    runDir = fullfile(outputRoot, runTag);
    rawDir = fullfile(runDir,'RAW');
    htmlDir = fullfile(runDir,'HTML');

    ensureDir(rawDir);
    ensureDir(htmlDir);

    MARVLs.timeseries.outputdirectory = addSep(rawDir);
    MARVLs.timeseries.htmloutput = addSep(htmlDir);
    MARVLs.timeseries.ErrFilename = fullfile(runDir,'errormatrix.mat');

    fprintf('[%s] %s to %s\n', label, ...
        datestr(startDate,'dd/mmm/yyyy'), datestr(endDate,'dd/mmm/yyyy'));
    marvl_plot_timeseries_DS(MARVLs, style);
    prune_no_fielddata_figures(rawDir, MARVLs);
    standardizeVariableFolders(rawDir);
end

fprintf('[%s] complete.\n', label);
end


function ensureDir(p)
if ~exist(p,'dir')
    mkdir(p);
end
end

function out = addSep(p)
if isempty(p) || p(end)==filesep
    out = p;
else
    out = [p filesep];
end
end

function root = ascendPath(startDir, levels)
root = startDir;
for ii = 1:levels
    root = fileparts(root);
end
end

function standardizeVariableFolders(rawDir)
nameMap = {...
    'WQ_NIT_AMM',            'AMM'; ...
    'WQ_DIAG_TOT_EXTC',      'EXTC'; ...
    'WQ_PHS_FRP',            'FRP'; ...
    'WQ_NIT_NIT',            'NIT'; ...
    'WQ_OXY_OXY',            'OXY'; ...
    'WQ_DIAG_TOT_PAR',       'PAR'; ...
    'WQ_CAR_PH',             'PH'; ...
    'WQ_DIAG_OAS_SECCHI',    'SECCHI'; ...
    'WQ_DIAG_PHY_TCHLA',     'TCHLA'; ...
    'WQ_DIAG_TOT_TN',        'TN'; ...
    'WQ_DIAG_TOT_TP',        'TP'; ...
    'WQ_DIAG_TOT_TSS',       'TSS'; ...
    'WQ_DIAG_TOT_TURBIDITY', 'TURBIDITY'; ...
    'WQ_DIAG_ZOO_TZOO',      'TZOO' ...
    };

for ii = 1:size(nameMap,1)
    srcDir = fullfile(rawDir, nameMap{ii,1});
    dstDir = fullfile(rawDir, nameMap{ii,2});
    if ~exist(srcDir,'dir')
        continue;
    end

    if ~exist(dstDir,'dir')
        movefile(srcDir, dstDir);
        continue;
    end

    files = dir(fullfile(srcDir,'*.png'));
    for jj = 1:numel(files)
        movefile(fullfile(srcDir,files(jj).name), fullfile(dstDir,files(jj).name), 'f');
    end

    leftovers = dir(srcDir);
    leftovers = leftovers(~ismember({leftovers.name},{'.','..'}));
    if isempty(leftovers)
        rmdir(srcDir);
    end
end
end

function prune_no_fielddata_figures(rawDir, MARVLsIn)
% Keep standard MARVL flow, then remove figures for sites without field
% data inside the selected window.
if ~isfield(MARVLsIn,'master') || ~isfield(MARVLsIn,'timeseries')
    return;
end
if ~isfield(MARVLsIn.master,'add_fielddata') || MARVLsIn.master.add_fielddata == 0
    return;
end

cfg = MARVLsIn.timeseries;
shp = shaperead(cfg.polygon_file);
for kk = 1:length(shp)
    shp(kk).Name = regexprep(shp(kk).Name,'-','_');
    shp(kk).Name = regexprep(shp(kk).Name,'\.','');
end
fdata = marvl_load_fielddata(MARVLsIn.master);

siteList = 1:length(shp);
if isfield(cfg,'plotAllsites') && cfg.plotAllsites == 0
    siteList = cfg.plotsite;
end

for varID = cfg.start_plot_ID:cfg.end_plot_ID
    loadname = MARVLsIn.master.varname{varID,1};
    varDir = fullfile(rawDir, loadname);
    if ~exist(varDir,'dir')
        continue;
    end

    validSites = sites_with_fielddata_local(fdata, shp, siteList, loadname, ...
        cfg.datearray, cfg.includeINT);
    keep = build_keep_site_set(shp, validSites);

    pngs = dir(fullfile(varDir,'*.png'));
    for ii = 1:numel(pngs)
        [~,stem] = fileparts(pngs(ii).name);
        if ~isKey(keep, stem)
            delete(fullfile(varDir, pngs(ii).name));
        end
    end
end
end

function keep = build_keep_site_set(shp, siteIdx)
keep = containers.Map('KeyType','char','ValueType','logical');
for ii = 1:numel(siteIdx)
    ss = siteIdx(ii);
    if isfield(shp(ss),'Plot_Order')
        stem = [sprintf('%04d',shp(ss).Plot_Order),'_',shp(ss).Name];
    else
        stem = shp(ss).Name;
    end
    keep(stem) = true;
end
end

function validSites = sites_with_fielddata_local(fdata, shp, siteList, loadname, datearray, includeINT)
validSites = [];
sitenames = fieldnames(fdata);
t0 = datearray(1);
t1 = datearray(end);

for ss = siteList
    hasData = false;
    for ii = 1:length(sitenames)
        sname = sitenames{ii};
        if ~isfield(fdata.(sname), loadname)
            continue;
        end

        rec = fdata.(sname).(loadname);
        if isfield(rec,'Deployment') && strcmpi(rec.Deployment,'Integrated') && ~includeINT
            continue;
        end
        if ~isfield(rec,'Date') || isempty(rec.Date)
            continue;
        end

        inWindow = rec.Date >= t0 & rec.Date <= t1;
        if ~any(inWindow)
            continue;
        end
        if ~isfield(rec,'X') || ~isfield(rec,'Y')
            continue;
        end

        inPoly = inpolygon(rec.X, rec.Y, shp(ss).X, shp(ss).Y);
        if any(inPoly)
            hasData = true;
            break;
        end
    end

    if hasData
        validSites(end+1) = ss; %#ok<AGROW>
    end
end
end
