clear; close all;

shp=shaperead('\\uniwa.uwa.edu.au\userhome\staff5\00064235\Downloads\coastlines_v2.0.0.shp\coastlines_v2.0.0_shorelines_annual.shp');

inc=1;
for i=1:length(shp)
    tname=shp(i).id_primary;
    tyear=shp(i).year;
    if contains(tname,'WA13') & tyear==2020
        shp2(inc)=shp(i);
        inc=inc+1;
    end
end

for j=1:length(shp2)
    plot(shp2(j).X,shp2(j).Y);hold on;
end

shapewrite(shp2,'CS_coastline.shp');

