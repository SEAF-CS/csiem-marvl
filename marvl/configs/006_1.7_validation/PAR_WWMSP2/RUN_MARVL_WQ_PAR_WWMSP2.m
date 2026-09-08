% Template runner for MARVL configs – tuned here for PAR_WWMSP2 but you can
% copy/paste this file, change the configuration path, label, and windows,
% and reuse it for any other scenario.

clear;

addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'..','..','..','aed-marvl')));
global MARVLs;
style = 'matlab';

configPath = 'MARVL_WQ_PAR_WWMSP2.m';
jobLabel   = 'PAR_WWMSP2';
obsAgencyFilter = {'WAMSI-WWMSP2-MS9'}; % Keep only these observed tags/agency labels.

dateWindows = [...
    datetime(2022,11,28) datetime(2022,12,14);...
    datetime(2023,1,2)   datetime(2023,1,18);...
    datetime(2023,2,16)  datetime(2023,3,4);...
    datetime(2023,3,18)  datetime(2023,4,3);...
    datetime(2023,5,2)   datetime(2023,5,18);...
    datetime(2023,5,18)  datetime(2023,6,3)];


ticksPerWindow = 5; % number of x-axis ticks in each plot window

scriptDir = fileparts(mfilename('fullpath'));
configFile = fullfile(scriptDir, configPath);
repoRoot = ascendPath(scriptDir, 4); % .../csiem-marvl
outputRoot = fullfile(repoRoot, 'outputs','001_ValidationSnapshot', jobLabel);

run_marvl_windows_single(configFile, jobLabel, dateWindows, ticksPerWindow, style, outputRoot, obsAgencyFilter);

% -------------------------------------------------------------------------
function run_marvl_windows_single(configPath, label, dateWindows, ticksPerWindow, style, outputRoot, obsAgencyFilter)
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

    runTag = sprintf('%s_%s', datestr(startDate,'yyyymmdd'), ...
        datestr(endDate,'yyyymmdd'));
    runDir = fullfile(outputRoot, runTag);
    rawDir = fullfile(runDir,'RAW');
    htmlDir = fullfile(runDir,'HTML');

    ensureDir(rawDir);
    ensureDir(htmlDir);

    MARVLs.timeseries.outputdirectory = addSep(rawDir);
    MARVLs.timeseries.htmloutput = addSep(htmlDir);
    MARVLs.timeseries.ErrFilename = fullfile(runDir,'errormatrix.mat');
    MARVLs.master = apply_obs_agency_filter(MARVLs.master, runDir, obsAgencyFilter);

    fprintf('[%s] %s to %s\n', label, ...
        datestr(startDate,'dd/mmm/yyyy'), datestr(endDate,'dd/mmm/yyyy'));

    marvl_plot_timeseries_DS(MARVLs, style);
end

fprintf('[%s] complete.\n', label);
end

function masterOut = apply_obs_agency_filter(masterIn, runDir, keepPatterns)
masterOut = masterIn;

if ~isfield(masterOut,'add_fielddata') || masterOut.add_fielddata ~= 1
    return;
end
if ~isfield(masterOut,'fielddata_files') || isempty(masterOut.fielddata_files)
    return;
end
if isempty(keepPatterns)
    return;
end

srcFileBase = masterOut.fielddata_files{1};
srcMatFile = fullfile(masterOut.fielddata_folder,[srcFileBase,'.mat']);
if ~exist(srcMatFile,'file')
    warning('Obs filter skipped. Source MAT file not found: %s', srcMatFile);
    return;
end

tmp = load(srcMatFile, masterOut.fielddata);
if ~isfield(tmp, masterOut.fielddata)
    warning('Obs filter skipped. Variable "%s" not found in %s.', masterOut.fielddata, srcMatFile);
    return;
end

fdataIn = tmp.(masterOut.fielddata);
[fdataOut, nTotal, nKept] = filter_fielddata_by_agency(fdataIn, keepPatterns);
if nKept == 0
    warning('Obs filter found 0 matching datasets for [%s]. Using original field data.', ...
        strjoin(keepPatterns, ', '));
    return;
end

tmpFieldDir = fullfile(runDir, 'TMP_FIELD_FILTER');
ensureDir(tmpFieldDir);

filteredBase = [srcFileBase,'_MS9_only'];
filteredPath = fullfile(tmpFieldDir, [filteredBase,'.mat']);
tmpSave = struct;
tmpSave.(masterOut.fielddata) = fdataOut;
save(filteredPath, '-struct', 'tmpSave', '-mat', '-v7.3');

masterOut.fielddata_folder = addSep(tmpFieldDir);
masterOut.fielddata_files = {filteredBase};

fprintf('    Obs filter: kept %d/%d datasets matching [%s]\n', ...
    nKept, nTotal, strjoin(keepPatterns, ', '));
end

function [fdataOut, nTotal, nKept] = filter_fielddata_by_agency(fdataIn, keepPatterns)
fdataOut = struct;
nTotal = 0;
nKept = 0;

siteNames = fieldnames(fdataIn);
for ss = 1:numel(siteNames)
    siteName = siteNames{ss};
    if strcmpi(siteName,'agencynames')
        continue;
    end

    vars = fieldnames(fdataIn.(siteName));
    for vv = 1:numel(vars)
        varName = vars{vv};
        entry = fdataIn.(siteName).(varName);
        if ~isstruct(entry)
            continue;
        end

        if isfield(entry,'Agency')
            nTotal = nTotal + 1;
            if agency_matches(entry.Agency, keepPatterns)
                fdataOut.(siteName).(varName) = entry;
                nKept = nKept + 1;
            end
        end
    end
end
end

function tf = agency_matches(agencyValue, keepPatterns)
if ischar(agencyValue)
    agencyText = lower(string(agencyValue));
elseif isstring(agencyValue)
    agencyText = lower(strjoin(agencyValue(:), ' '));
elseif iscell(agencyValue)
    agencyText = lower(strjoin(string(agencyValue(:)), ' '));
else
    agencyText = lower(string(agencyValue));
end

tf = false;
for ii = 1:numel(keepPatterns)
    if contains(agencyText, lower(string(keepPatterns(ii))))
        tf = true;
        return;
    end
end
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
