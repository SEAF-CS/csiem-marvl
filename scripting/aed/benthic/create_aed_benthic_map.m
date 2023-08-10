clear all; close all;

addpath(genpath('functions'));;

filename = '../../../../csiem_model_tfvaed_1.0/gis_repo/1_domain/mesh/csiem_mesh_B009_opt.2dm';

[XX,YY,ZZ,nodeID,faces,X,Y,Z,ID,MAT,A] = tfv_get_node_from_2dm(filename);

for i = 1:length(Z)
    S(i).X = XX(faces(:,i));
    S(i).Y = YY(faces(:,i));
    S(i).Z = Z(i);
    S(i).A = A(i);
    S(i).ID = ID(i);
    S(i).Mat_Zone = MAT(i);
    S(i).Geometry = 'Polygon';

end

shapewrite(S,'Test.shp');

%XYZ File

xyfile = 'ben_utm.xyz';

data = load(xyfile);

pArea = 25*25;

types = unique(data(:,3));

fid = fopen('aed_benthic_v1.csv','wt');
fprintf(fid,'ID,');
for j = 1:length(types)
    fprintf(fid,'%d,',types(j));
end
fprintf(fid,'Summed Area,Grid Area\n');

fid1 = fopen('aed_benthic_v1_percentage.csv','wt');
fprintf(fid1,'ID,');
for j = 1:length(types)
    fprintf(fid1,'%d,',types(j));
end
fprintf(fid1,'Summed Area,Grid Area\n');


for i = 1:length(S)

    fprintf(fid,'%d,',S(i).ID);
    fprintf(fid1,'%d,',S(i).ID);

    sumArea = 0;

    inpol = find(inpolygon(data(:,1),data(:,2),S(i).X,S(i).Y) == 1);


    for j = 1:length(types)

        sss = find(data(inpol,3) == types(j));

        if ~isempty(sss)
            typesum = length(sss)* pArea;
            fprintf(fid,'%4.2f,',typesum);
            sumArea = sumArea + typesum;
        else
            fprintf(fid,'0,');
        end
    end
    fprintf(fid,'%6.2f,%6.2f\n',sumArea,S(i).A);


    for j = 1:length(types)

        sss = find(data(inpol,3) == types(j));

        if ~isempty(sss)
            typesum = length(sss)* pArea;
            fprintf(fid1,'%4.2f,',typesum / sumArea);
        else
            fprintf(fid1,'0,');
        end
    end
    fprintf(fid1,'%6.2f,%6.2f\n',sumArea,S(i).A);




end
fclose(fid);
fclose(fid1);










