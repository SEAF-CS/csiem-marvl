function [theta,rho] = cart2compass(u,v)
%CART2COMPASS convert cartesian coordinates into
% speed and direction data (degN).
%    [THETA,RHO] = CART2COMPASS convert the vectors u and v
%      from a cartesian reference system into rho (e.g. speed) with
%      direction theta (degree North).
%
%   See also CART2POL
%
%
% Author: Arnaud Laurent
% Creation: March 20th 2009.
% MATLAB version: R2007b
%
% Revised by M Baum, May 12th 2020.
% MATLAB version: R2019b
%

[theta,rho] = cart2pol(u,v);

theta = theta*180/pi;

degN = 90 - theta;
idx = find(degN < 0);
degN(idx) = degN(idx) + 360;

theta = degN;
