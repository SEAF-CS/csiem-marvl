% Template runner for MARVL configs – tuned here for PAR_WWMSP2 but you can
% copy/paste this file, change the configuration path, label, and windows,
% and reuse it for any other scenario.

clear;

addpath(genpath('../../../../aed-marvl'));
global MARVLs;
style = 'matlab';

configPath = 'MARVL_WQ_PAR_WWMSP3.m';
jobLabel   = 'PAR_WWMSP3';

dateWindows = [...
    datetime(2022,12,12) datetime(2023,12,23);...
];


ticksPerWindow = 5; % number of x-axis ticks in each plot window

scriptDir = fileparts(mfilename('fullpath'));
configFile = fullfile(scriptDir, configPath);
repoRoot = ascendPath(scriptDir, 4); % .../csiem-marvl
outputRoot = fullfile(repoRoot, 'outputs','001_ValidationSnapshot', jobLabel);

run_marvl_windows_single(configFile, jobLabel, dateWindows, ticksPerWindow, style, outputRoot);

% -------------------------------------------------------------------------
function run_marvl_windows_single(configPath, label, dateWindows, ticksPerWindow, style, outputRoot)
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

    fprintf('[%s] %s to %s\n', label, ...
        datestr(startDate,'dd/mmm/yyyy'), datestr(endDate,'dd/mmm/yyyy'));

    marvl_plot_timeseries_DS(MARVLs, style);
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
