% -- getCellCrossing -- 
% Much like fv_get_curtain_ids, this returns cell ids that are intersected
% by a pline.
% It should be faster than though, and doesnt need a '_geo.nc' file
%
% Input:
%           modfil:  Full netcdf results file
%           pline:   line to intersect, [x1,y1;
%                                        x2,y2; ....
%                                        xn,yn];
% Output:
%           id:      List of cell ids that were intersected
%           xp,yp:   Coordinates of intersections to those cells
% 
%
% Written by TDevlin, 04/05/2018
% 
%

function [id, xp, yp] = getCellCrossings(modfil, pline)

% Get GEO from netcdf file
nci = netcdf.open(modfil);
vertx = netcdf.getVar(nci, netcdf.inqVarID(nci, 'node_X'), 'double');
verty = netcdf.getVar(nci, netcdf.inqVarID(nci, 'node_Y'), 'double');
cell_node = netcdf.getVar(nci, netcdf.inqVarID(nci, 'cell_node'), 'double')';
netcdf.close(nci);

% Get Cells
cells = repmat([1:length(cell_node)]',4);
ii = cell_node==0;

% Get Faces
cn = cell_node;
cn(ii) = cn(fliplr(ii));
faces=cat(3,cn,cn(:,[2,3,4,1]));

% Cleanup trailing triangle faces.
faces(repmat(ii,1,1,2))=0;
faces = reshape(faces,[],2);
faces(any(faces==0,2),:) = [];
cells(ii) = [];
cells = cells(:);

nf = size(faces,1);

% Find if is right or left face, or is external...
typ = verty(faces(:,1))<=verty(faces(:,2)); % is right faces
faces = sort(faces,2);
[~,ind ] = sortrows(faces);
faces = faces(ind,:);  cells = cells(ind);   typ = typ(ind);
stat = [true;any(faces(1:end-1,1:2)~=faces(2:end,1:2),2)];
typ2 = [(stat(1:nf-1) & stat(2:nf)); stat(end)]; % Ext

% Trim double entries for cells (i.e. left and right faces...)
cells(typ) = NaN;
logs = [typ2 | ~typ];

faces = faces(logs,:);
cells = cells(logs);
nf = sum(logs);

% Prepare matrices to do fast line intersect
np = size(pline,1)-1;

X1 = repmat(vertx(faces(:,1)),1,np);
X2 = repmat(vertx(faces(:,2)),1,np);
Y1 = repmat(verty(faces(:,1)),1,np);
Y2 = repmat(verty(faces(:,2)),1,np);

X3 = repmat(pline(1:end-1,1)',nf,1);
X4 = repmat(pline(2:end,1)'  ,nf,1);
Y3 = repmat(pline(1:end-1,2)',nf,1);
Y4 = repmat(pline(2:end,2)'  ,nf,1);

X4_X3 = (X4-X3);
Y1_Y3 = (Y1-Y3);
Y4_Y3 = (Y4-Y3);
X1_X3 = (X1-X3);
X2_X1 = (X2-X1);
Y2_Y1 = (Y2-Y1);

numerator_a = X4_X3 .* Y1_Y3 - Y4_Y3 .* X1_X3;
numerator_b = X2_X1 .* Y1_Y3 - Y2_Y1 .* X1_X3;
denominator = 1 ./ (Y4_Y3 .* X2_X1 - X4_X3 .* Y2_Y1);

u_a = numerator_a .* denominator;
u_b = numerator_b .* denominator;

% Find Intersections and locations
xint = X1+X2_X1.*u_a;
yint = Y1+Y2_Y1.*u_a;
isint = (u_a >= 0) & (u_a <= 1) & (u_b >= 0) & (u_b <= 1);

% Tidy Up output variables.
id = cells(isint);
id(isnan(id)) = [];
xp = xint(isint);
yp = yint(isint);

end