% ///////// gettseries \\\\\\\\\
% Get Tseries extracts timeseries at one location from a profile file
% It can take an expression as the variable and return that 2D data
% 
% Inputs:
%           fil --  Profile file
%           loc --  Name of a location in profile file
%           var --  String of variable or expression
% optional, 
%           ref --  Depth averaging Ref
%           range-  Depth averaging Range
%
%
% Example: 
%						[data , time] = gettseries(myfilename, 'Site01', 'SED_1*2+SED_2*2', 'sigma', [0 0.5])
%
%
%
% Version 1.0
% TODO: add checks for 3D and 2D variables being combined in expressions.
%       Any other checks to ensure expressions arent silly.
%
% TD Jul 2015
%


function [res , time] = gettseries(fil,loc,var,ref,range)

    % Sort out variable Input and Defaults
            if nargin==3
                ref = 'sigma';
                range = [0 1];
            elseif nargin~=5
                error('Incorrect number of inputs');
            end

    % Check Inputs    
            fil = inputcheck(fil,true);
            loc = inputcheck(loc,true);
            var = inputcheck(var,true);
            ref = inputcheck(ref,true);
            range = inputcheck(range,false);
    
    % Parse Expression    
            vars = regexpi(var,'[a-z]\w*\.*\w*\w\>|[a-z]','match');
            vars = vars(~ismember(lower(vars),{'sum';'mean';'max';
                                               'min';'sin';'sind';
                                               'cos';'cosd';'hypot';'sqrt';'atan2d'}));
            vars = [vars,{'layerface_Z'}];
            for aa = 1 : length(vars)
                var=strrep(var,vars{aa},['tmp.' vars{aa}]);
            end
            var = ['@(tmp)' var];
            var = strrep(var,'tmp.tmp.','tmp.');
            f = str2func(var);
    
    
    % extract relevant data and run expression
            nci = netcdf.open(fil);
            grpids = netcdf.inqGrps(nci);
            done = false;
            for aa = 1 : length(grpids)
                if strcmpi(netcdf.inqGrpName(grpids(aa)),loc);
                    grid = grpids(aa);
                    done = true;
                    break
                end
            end
    
            if ~done
                error(['Couldnt find location ' loc])
            end

            for aa = 1 : length(vars)
                varid = netcdf.inqVarID(grid,vars{aa});
                dum = netcdf.getVar(grid,varid);
                try
                    fill_value = netcdf.getAtt(nci,varid,'_FillValue','double');
                catch
                    fill_value = NaN;
                end
                dum(dum==fill_value) = NaN;
                try
                    scale_factor = double(netcdf.getAtt(nci,varid,'scale_factor','double'));
                catch
                    scale_factor = 1.;
                end
                dum = double(dum) * scale_factor;
                try
                    add_offset = netcdf.getAtt(nci,varid,'add_offset','double');
                catch
                    add_offset = 0.;
                end
                tmp.(vars{aa}) = double(dum) + add_offset;
            end
    
            res = f(tmp);

            if size(res,1)>1
                % now depth average
                lfz = tmp.layerface_Z;
                [nlf,nt] = size(lfz);
                nl = nlf-1;
                top = lfz(1:end-1,:);
                bot = lfz(2:end,:);

                switch ref % d1 is below d2
                    case 'sigma'
                        depth = top(1,:) - bot(end,:);
                        d1 = bot(end,:) + range(1) * depth;
                        d2 = bot(end,:) + range(2) * depth;
                    case 'elevation'
                        d1 = max(bot(end,:),range(1));
                        d2 = min(top(1,:),range(2));
                    case 'height'
                        d1 = bot(end,:) + range(1);
                        d2 = min(bot(end,:) + range(2),top(1,:));
                    case 'depth'
                        d1 = max(top(1,:)-range(2),bot(end,:));
                        d2 = top(1,:) - range(1);
                    case 'top'
                        d1 = lfz(range(2)+1,:);
                        d2 = lfz(range(1),:);
                    case 'bot'
                        d1 = lfz(nl-range(1) + 2,:);
                        d2 = lfz(nl-range(2) + 1,:);
                    case 'log_interp'
                        
                end

                if ismember(ref,{'elevation';'height';'depth'})
                    if any(d1 > top(1,:)) || any(d2 < bot(end,:))
                        nores = true;
                    end
                end

                % -- Engine
                bot = bsxfun(@max,bot,d1);
                top = bsxfun(@min,top,d2);
                frc = bsxfun(@rdivide,(top-bot),(d2-d1));
                frc = max(frc,0);

                % -- process 3D results into 2D results
                res = sum(res.*frc,1);
            end
    
            if nargout>1

                tid = netcdf.inqVarID(nci,'ResTime');
                time = netcdf.getVar(nci,tid);
                time = convtime(time);

            end
    
    
        netcdf.close(nci);
end
    
function out = inputcheck(in,shouldbestring)
        
    if iscell(in)
        in = in{1};
    end
    if xor(ischar(in),shouldbestring)
        error('File input must be a string');
    else
        out=in;
    end
    
end