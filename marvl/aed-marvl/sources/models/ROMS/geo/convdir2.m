% Convert nautical directions to cartesian directions and vice-versa
% More sensible version
%
% Inputs:
%           dir1  -  Directions to be converted
%           flip  -  whether to flip from direction to/from convention
%
% Outputs:
%           dir2  -  Directions corresponding to dir1 but in new convention
%
% 
% TDEVLIN January 2018

function dir2 = convdir2(dir1,flip)
if flip % flip direction to/from if required (often for wind and waves)
    fprintf('Flipping direction from/to\n')
    dir2 = 270 - dir1;
else % only change 0 degrees to North (Nautical) or to East (Cartesian) dont flip from/to
    dir2 = 90 - dir1;
end
% Shift any values <0 or >360.
dir2 = mod(dir2,360);