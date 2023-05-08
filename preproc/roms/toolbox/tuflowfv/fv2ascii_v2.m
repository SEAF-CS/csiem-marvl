%  ---  fv2ascii_v2  ---   
% A Quicker simpler version of fv2ascii that uses cell faces to quickly do
% the inpolygon.
% Requires just the file, and a vector of data, and the grd spacing.
% If spherical and the grid spacing is > 1, then it assumes it is in meters
% and attempts to convert to degrees.
% Takes most of the same optional inputs as fv2ascii, but the format of the 'idmap' 
% is different to the 'grd2cell'.  
%
%
% inputs
%   resfil = The netcdf results file
%   data = data that is number of cells long (any vector)
%   grd    = grid spacing, metres | degrees depending on whether the simulation was performed in spherical
%
% optional inputs
%   'bounds' / [x_BotLeft y_BotLeft; x_TopRight y_TopRight] output grid limits ie. create a subset of the model results default: no subsetting
%   'outfil' / name of the outfil default: a name based on the simulation name and the grid spacing
%   'idmap'  / grid to cell indexing: array created on a previous call to this function.
%       If you are creating a set of .asc files within a loop, on your first
%       call to fv2ascii you can create the indexing and then save yourself the
%       trouble for the following calls to fv2ascii. eg.
%           for aa = 1:n_sed
%            ......
%            if aa == 1
%               idmap = fv2ascii(fvresObj,grd,'outfil',outfil);
%            else
%               fv2ascii(fvresObj,grd,'outfil',outfil,'idmap',idmap);
%            end
%           end
%
% optional outputs
%   'idmap' see above optional inputs.
%
% Toby Devlin, October 2016
% Built off JN original
%
% Updates:
%
% 10/05/2017: Fixed NaNs from dry cells in output - TDEVLIN


function idmap = fv2ascii_v2(resfil,data,grd,varargin)

% defaults
bounds = [];
outfil = []; % default outfil specified later
idmap = [];

% variable arguments
nva = length(varargin);
if mod(nva,2) > 0
    error('Expecting variable arguments as descriptor / value pairs')
end

for aa = 1 : 2 : nva
    varargtyp = varargin{aa};
    varargval = varargin{aa+1};
    switch lower(varargtyp)
        case {'bound','bounds'}
            bounds = varargval;
        case 'outfil'
            outfil = varargval;
        case 'idmap'
            idmap = varargval;
        otherwise
            error('unexpected variable argument type')
    end
end

% check bounds
if ~isempty(bounds) && size(bounds,1) ~= 2 && size(bounds,2) ~= 2
    error('input bounds must be of size [2,2]')
end

% are the TUFLOW-FV results in spherical coordinates
tmp = ncreadatt(resfil,'/','spherical');
switch tmp
    case 'true'
        spherical = true;
    case 'false'
        spherical = false;
end

% generate the grid
% -- extents
TMP = netcdf_get_var(resfil,'names',{'node_X';'node_Y';'cell_node'});
vertx = TMP.node_X; verty = TMP.node_Y;
cell_node = TMP.cell_node';
if isempty(bounds)
    x1 = min(vertx); y1 = min(verty);
    x2 = max(vertx); y2 = max(verty);
else
    x1 = bounds(1,1); y1 = bounds(1,2);
    x2 = bounds(2,1); y2 = bounds(2,2);
end

if spherical && grd>=1
    display('Assuming grd is in metres')
    [xutm,yutm] = ll2utm([x1;x2],[y1;y2]);
    lenutm = hypot(diff(xutm),diff(yutm));
    grd = hypot(x2-x1,y2-y1).*grd./lenutm;
end

xvec = x1:grd:x2+grd;
yvec = y1:grd:y2+grd;
yvec = fliplr(yvec);
nx = length(xvec);
ny = length(yvec);

% Get idmaps
if isempty(idmap)
    % Loop through and find total faces
    nc3 = sum(cell_node(:,4)==0);  nc4 = length(cell_node)-nc3;
    nfmax = nc4*4+nc3*3;
    faces = zeros(nfmax,2);  cells = zeros(nfmax,1);  typ = false(nfmax,1);
    ntmp=0;
    for aa = 1 : length(cell_node)
        if cell_node(aa,4)==0,ne=3;else ne=4;end
        for bb = 1:ne
            ntmp = ntmp+1;
            [faces(ntmp, :)] = cell_node(aa,[bb,mod(bb,ne)+1]);
            cells(ntmp) = aa;
        end
    end
    
   
    faces = faces(1:ntmp,:);
    cells = cells(1:ntmp);
    typ = verty(faces(:,1))<=verty(faces(:,2)); % is right faces
    faces = sort(faces,2);
    
    
    [~,ind ] = sortrows(faces);
    faces = faces(ind,:);  cells = cells(ind);   typ = typ(ind);
    stat = [true;any(faces(1:end-1,1:2)~=faces(2:end,1:2),2)];
    typ2 = [(stat(1:ntmp-1) & stat(2:ntmp)); stat(end)]; % Ext
    
    cells(typ) = NaN;    
    logs = find(typ2 | ~typ);
    
    faces = faces(logs,:);
    cells = cells(logs);
    
    x1 = vertx(faces(:,1));
    x2 = vertx(faces(:,2));
    y1 = verty(faces(:,1));
    y2 = verty(faces(:,2));
    M = (x2-x1)./(y2-y1);
    
    idmap = NaN(ny,nx);
    for aa = 1:ny
        y = yvec(aa);
        yd1 = y-y1;
        yd2 = y-y2;
        isl = find(xor(yd1>=0,yd2>=0));
        x = x1(isl)+M(isl).*yd1(isl);
        ctmp = cells(isl);
        [x,ii] = sort(x);
        ctmp = ctmp(ii);
        for bb = 1 : length(x)
            idmap(aa,xvec>=x(bb)) = ctmp(bb);
        end
    end
else
    % Check if idmap matches size 
    if max(idmap)>size(cell_node,1);
        error('idmap doesn''t match number of cells in model')
    end
    if ~isequal(size(idmap),[ny,nx])
        error('idmap of wrong size')
    end
end

% preallocate
res_grd = -9999 * ones(ny,nx);
log = ~isnan(idmap);
res_grd(log) = data(idmap(log));
res_grd(~log) = -9999;
res_grd(isnan(res_grd)) = -9999;

% output file
if isempty(outfil)
    if spherical
        ext = ['_' num2str(grd,'%.4f') 'deg'];
    else
        ext = ['_' num2str(grd,'%.0f') 'm'];
    end
    ext = strrep(ext,'.','pnt');
    outfil = strrep(resfil,'.nc',[ext '.asc']);
end

% -- write the headers
fid = fopen(outfil,'W');
fprintf(fid,'%s %d\n','ncols',nx);
fprintf(fid,'%s %d\n','nrows',ny);
fprintf(fid,'%s %f\n','xllcorner',xvec(1));
fprintf(fid,'%s %f\n','yllcorner',yvec(end));
fprintf(fid,'%s %f\n','cellsize',grd);
fprintf(fid,'%s %d\n','NODATA_value',-9999);

% -- write the body
fmat = ['%f' repmat(' %f',1,nx-1) '\n'];
inc = 0;
tic
for aa = 1:ny
    fprintf(fid,fmat,res_grd(aa,:));
    inc = mytimer(aa,[1 ny],inc);
end
fclose(fid);
