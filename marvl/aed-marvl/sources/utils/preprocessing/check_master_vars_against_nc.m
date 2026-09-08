function missingVars = check_master_vars_against_nc(configPath, commentMissing)
%CHECK_MASTER_VARS_AGAINST_NC Compare master.varname entries against NetCDF contents.
%   missingVars = CHECK_MASTER_VARS_AGAINST_NC(configPath) loads the MARVL
%   configuration file specified by configPath, interrogates the NetCDF
%   files listed in master.ncfile, and returns the variables present in
%   master.varname that are not found in any NetCDF file.
%
%   CHECK_MASTER_VARS_AGAINST_NC(configPath, true) also comments the
%   missing entries directly in the configuration file so they are skipped
%   next time MARVL runs. The function only modifies the file when the
%   NetCDF files can be inspected successfully.
%
%   Example:
%       missing = check_master_vars_against_nc( ...
%           'config/004_1.6_validation/MARVL_WQ_2018_2019_CORE.m');
%       % To automatically comment missing entries:
%       missing = check_master_vars_against_nc( ...
%           'config/.../MARVL_WQ_2018_2019_CORE.m', true);
%
%   The helper prints a summary of findings and returns the list of missing
%   AED variable names for further processing or logging.
%
%   Note: this utility expects MATLAB R2015b or newer for string support.

arguments
    configPath (1,1) string
    commentMissing (1,1) logical = false
end

% Ensure we do not inherit stale MARVL structures from the base workspace.
clear('MARVLs','master','timeseries');

if ~isfile(configPath)
    error('Configuration file not found: %s', configPath);
end

run(configPath);

if ~exist('MARVLs','var') || ~isfield(MARVLs,'master') || ...
        ~isfield(MARVLs.master,'varname')
    error('The configuration file did not populate MARVLs.master.varname.');
end

masterVars = string(MARVLs.master.varname(:,1));
masterVars = masterVars(masterVars ~= ""); % guard against empty cells

% Collect variables present in all referenced NetCDF files.
ncVars = string.empty(0,1);
missingSources = string.empty(0,1);
for ii = 1:numel(MARVLs.master.ncfile)
    ncPath = string(MARVLs.master.ncfile(ii).name);
    if strlength(ncPath) == 0
        warning('master.ncfile(%d).name is empty; skipping.', ii);
        continue;
    end
    if ~isfile(ncPath)
        warning('NetCDF file not found: %s', ncPath);
        missingSources(end+1,1) = ncPath; %#ok<AGROW>
        continue;
    end
    info = ncinfo(ncPath);
    theseVars = string({info.Variables.Name});
    ncVars = union(ncVars, theseVars(:));
end

if isempty(ncVars)
    warning(['No NetCDF variables were read. Verify the paths in master.ncfile ' ...
        'before attempting to comment configuration entries.']);
    missingVars = string.empty(0,1);
    return;
end

missingVars = setdiff(masterVars, ncVars, 'stable');

if isempty(missingVars)
    fprintf('All %d master variables exist in the referenced NetCDF files.\n', ...
        numel(masterVars));
else
    fprintf('Found %d missing variable(s):\n', numel(missingVars));
    fprintf('  - %s\n', missingVars);
end

if ~commentMissing || isempty(missingVars)
    return;
end

if ~isempty(missingSources)
    warning(['Some NetCDF files could not be read; skipping automatic ' ...
        'commenting to avoid false positives.']);
    return;
end

commentedCount = apply_comments(configPath, missingVars);
fprintf('Commented %d configuration entr%s in %s.\n', commentedCount, ...
    ternary(commentedCount ~= 1, 'ies', 'y'), configPath);
end

function count = apply_comments(configPath, missingVars)
%APPLY_COMMENTS Prefix offending lines with ''% '' within master.varname block.

text = fileread(configPath);
lines = splitlines(string(text));

blockStart = find(contains(lines, 'master.varname'), 1, 'first');
if isempty(blockStart)
    error('Could not locate master.varname block in %s.', configPath);
end
blockEnd = find(contains(lines(blockStart:end), '};'), 1, 'first');
if isempty(blockEnd)
    error('Could not locate the end of master.varname block in %s.', configPath);
end
blockEnd = blockStart + blockEnd - 1;

count = 0;
for varName = missingVars(:)'
    pattern = "'" + varName + "'";
    candidates = blockStart:blockEnd;
    matchIdx = candidates(contains(lines(candidates), pattern));
    for idx = matchIdx
        trimmed = strtrim(lines(idx));
        if startsWith(trimmed, '%')
            continue;
        end
        lines(idx) = "% " + lines(idx);
        count = count + 1;
    end
end

if count == 0
    return;
end

if ispc
    newlineChar = sprintf('\r\n');
else
    newlineChar = sprintf('\n');
end
newText = strjoin(lines, newlineChar);

fid = fopen(configPath, 'w');
if fid < 0
    error('Failed to open %s for writing.', configPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, '%s%s', newText, newlineChar);
end

function out = ternary(cond, trueVal, falseVal)
%TERNARY Convenience inline conditional.
if cond
    out = trueVal;
else
    out = falseVal;
end
end
