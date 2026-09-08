clear; close all

shp=shaperead('CS_coastline.shp');

inc=1;
for ss=1:5 %length(shp)
    for i=1:length(shp(ss).X)
        ncst(inc,1)=shp(ss).X(i);
        ncst(inc,2)=shp(ss).Y(i);
        inc=inc+1;
    end
end
