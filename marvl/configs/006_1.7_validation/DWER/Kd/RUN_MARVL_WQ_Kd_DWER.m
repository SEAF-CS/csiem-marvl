% Template runner for MARVL configs, change the configuration path, label, and windows,
% and reuse it for any other scenario.

clear;

addpath(genpath('../../../../aed-marvl'));
global MARVLs;
style = 'matlab';

configPath = 'MARVL_WQ_Kd_DWER.m';
jobLabel   = 'Kd_DWER';

dateWindows = [...
    datetime(2021,1,12)  datetime(2023,8,25);...
    datetime(2023,8,21)  datetime(2023,11,24);...
    datetime(2024,5,12)  datetime(2024,9,18);...
    datetime(2024,11,26) datetime(2025,1,10)];

ticksPerWindow = 5; % number of x-axis ticks in each plot window
scriptDir = fileparts(mfilename('fullpath'));
configFile = fullfile(scriptDir, configPath);
repoRoot = ascendPath(scriptDir, 4); % .../csiem-marvl
outputRoot = fullfile(repoRoot, 'outputs','001_ValidationSnapshot', jobLabel);

run_marvl_windows_single(configFile, jobLabel, dateWindows, ticksPerWindow, style, outputRoot);
mergeHtmlFilesDeterministic(outputRoot, sprintf('%s_merged.html', jobLabel));

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

    runTag = sprintf('%s_%s', datestr(startDate,'ddmmyyyy'), ...
        datestr(endDate,'ddmmyyyy'));
    runDir = fullfile(outputRoot, runTag);
    rawDir = fullfile(runDir,'RAW');
    htmlDir = fullfile(runDir,'HTML');

    ensureDir(rawDir);
    ensureDir(htmlDir);

    MARVLs.timeseries.outputdirectory = addSep(rawDir);
    MARVLs.timeseries.htmloutput = addSep(htmlDir);
    MARVLs.timeseries.ErrFilename = fullfile(runDir,'errormatrix.mat');

    fprintf('[%s] %s to %s\n', label, ...
        datestr(startDate,'ddmmyyyy'), datestr(endDate,'ddmmyyyy'));

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

function mergedFile = mergeHtmlFilesDeterministic(rootFolder, outputFile)
% Merge .html files from first-level subfolders in deterministic A-Z order.
% Usage example:
% mergeHtmlFilesDeterministic( ...
%   'G:\CSIEM\1.7.0\csiem-marvl\outputs\001_ValidationSnapshot\Kd_DWER', ...
%   'Kd_DWER_merged.html');

if nargin < 2
    error('mergeHtmlFilesDeterministic requires rootFolder and outputFile.');
end
if ~exist(rootFolder, 'dir')
    error('Input folder does not exist: %s', rootFolder);
end

if isAbsolutePath(outputFile)
    mergedFile = outputFile;
else
    mergedFile = fullfile(rootFolder, outputFile);
end
ensureDir(fileparts(mergedFile));

subfolders = dir(rootFolder);
subfolders = subfolders([subfolders.isdir]);
names = {subfolders.name};
subfolders = subfolders(~ismember(names, {'.', '..'}));
subfolders = sortStructByName(subfolders);

mergeList = {};
for ii = 1:numel(subfolders)
    subPath = fullfile(rootFolder, subfolders(ii).name);
    htmlFiles = listHtmlFilesRecursive(subPath);
    if isempty(htmlFiles)
        continue;
    end

    [~, baseNames, exts] = cellfun(@fileparts, htmlFiles, 'UniformOutput', false);
    fileNames = strcat(baseNames(:), exts(:));
    [~, idx] = sortrows([lower(fileNames), lower(htmlFiles)], [1 2]);
    htmlFiles = htmlFiles(idx);

    for jj = 1:numel(htmlFiles)
        mergeList{end+1,1} = htmlFiles{jj}; %#ok<AGROW>
    end
end

fprintf('[mergeHtmlFilesDeterministic] Output: %s\n', mergedFile);
if isempty(mergeList)
    fprintf('[mergeHtmlFilesDeterministic] No HTML files found under: %s\n', rootFolder);
end
for kk = 1:numel(mergeList)
    fprintf('[mergeHtmlFilesDeterministic] %3d/%3d %s\n', ...
        kk, numel(mergeList), mergeList{kk});
end

fidOut = fopen(mergedFile, 'w');
if fidOut == -1
    error('Cannot open output file for writing: %s', mergedFile);
end
cleanupObj = onCleanup(@() fclose(fidOut)); %#ok<NASGU>

for kk = 1:numel(mergeList)
    inFile = mergeList{kk};
    fidIn = fopen(inFile, 'r');
    if fidIn == -1
        error('Cannot open input HTML file: %s', inFile);
    end
    fileCleanup = onCleanup(@() fclose(fidIn)); %#ok<NASGU>

    content = fread(fidIn, '*uint8');
    fwrite(fidOut, content, 'uint8');

    clear fileCleanup;
    if kk < numel(mergeList)
        fwrite(fidOut, sprintf('\n'), 'char');
    end
end

fprintf('[mergeHtmlFilesDeterministic] Merged %d file(s).\n', numel(mergeList));
end

function files = listHtmlFilesRecursive(folderPath)
files = {};
entries = dir(folderPath);
entries = entries(~ismember({entries.name}, {'.', '..'}));
entries = sortStructByName(entries);

for ii = 1:numel(entries)
    p = fullfile(folderPath, entries(ii).name);
    if entries(ii).isdir
        nested = listHtmlFilesRecursive(p);
        if ~isempty(nested)
            files = [files; nested]; %#ok<AGROW>
        end
    else
        [~,~,ext] = fileparts(entries(ii).name);
        if strcmpi(ext, '.html')
            files{end+1,1} = p; %#ok<AGROW>
        end
    end
end
end

function tf = isAbsolutePath(p)
tf = false;
if isempty(p)
    return;
end

if numel(p) >= 2 && p(2) == ':'
    tf = true; % Windows drive path, e.g. C:\...
elseif numel(p) >= 2 && p(1) == '\' && p(2) == '\'
    tf = true; % UNC path, e.g. \\server\share\...
elseif p(1) == '/'
    tf = true; % Unix absolute path
end
end

function s = sortStructByName(s)
if isempty(s)
    return;
end

nameLower = lower({s.name}');
nameOrig = {s.name}';
[~, idx] = sortrows([nameLower, nameOrig], [1 2]);
s = s(idx);
end
