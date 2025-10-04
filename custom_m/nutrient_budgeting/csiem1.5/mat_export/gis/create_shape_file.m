%% create_polygon

clear all; close all;

shpfile='W:\csiem\csiem-marvl-dev\gis\MLAU_Zones_v3_ll.shp';
shp1=shaperead(shpfile);

shp(1)=shp1(6);

nsfile='W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\gis_repo\1_domain\nodestrings\ns_005_nutrient_6OBC.shp';

ns=shaperead(nsfile);

shp(2)=shp(1);

shp(2).Unit_Name='CS shelf';
shp(2).Name='CS-Shelf';
shp(2).BP_Order=1;

xx=[115.74962 115.77206 115.7838];
yy=[-32.13388 -32.13789 -32.1876];

shp(2).X=ns(10).X;
shp(2).Y=ns(10).Y;

%%
for i=1:length(xx)
    shp(2).X(length(ns(10).X)+i-1)=xx(4-i);
    shp(2).Y(length(ns(10).X)+i-1)=yy(4-i);
end

%
shp(2).X(length(ns(10).X)+i)=NaN;
shp(2).Y(length(ns(10).X)+i)=NaN;

shapewrite(shp,'shape_for_export.shp');