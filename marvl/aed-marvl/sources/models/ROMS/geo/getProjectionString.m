% Provides a Mapinfo projection string for placing at the header of the mif file.
% Requires a coordinate in lat/lon somewhere within the domain
% 
% Inputs:
%           xc        -- longitude within the domain
%           yc        -- latitude within the domain
%           spherical -- true/false if output string needs to be spherical (lat/lon) or cartesian (UTM)
%
% Outputs:
%           str       -- projection string for mif header
%
% TDEVLIN Feb 2018

function str = getProjectionString(xc,yc,spherical)
    if spherical
        str = 'CoordSys Earth Projection 1, 104';
    else
        xs = mod(xc,360); xs(xs>183) = xs(xs>183)-360; % Trim to (-180, 180) range
        zonebnd = -177 + (floor((xs--177)./6)+1).*6; % Starting coordinate of UTM Zone
        hemisph = 10000000.*double(yc<0);            % Offset whether northern hemisphere or not

        str = sprintf('CoordSys Earth Projection 8, 104, “m”, %4f, 0, 0.9996, 500000, %d',zonebnd,hemisph);
    end
end
        