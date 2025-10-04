clear; close all;

infile='New_Curtain_line_LL.shp';
outfile='New_Curtain_line_LL_Dist.shp';

shp=shaperead(infile);
shpll=shp;
grid_zone=[50,6];

for i=1:length(shp)
    [shpll(i).utmX,shpll(i).utmY]=ll2utm(shp(i).X,shp(i).Y);
    %utm2ll(shp(i).X,shp(i).Y,grid_zone,3);
    sdata(i,1)=shpll(i).utmX;
    sdata(i,2)=shpll(i).utmY;
end

shpll(1).dist = 0;

for i = 2:length(shpll)
    shpll(i).dist = sqrt(power((sdata(i,1) - sdata(i-1,1)),2) + power((sdata(i,2)- sdata(i-1,2)),2)) + dist(i-1,1);
end

inc=1;
for i=1:2:length(shpll)
    shpll2(inc)=shpll(i);inc=inc+1;
end

shapewrite(shpll2,outfile);