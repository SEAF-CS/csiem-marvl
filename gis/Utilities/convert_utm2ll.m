clear; close all;

infile='Curtain_polyline_100m_QC.shp';
outfile='Curtain_polyline_100m_QC_ll.shp';

shp=shaperead(infile);
shpll=shp;
grid_zone=[50,6];

for i=1:length(shp)
    [shpll(i).X,shpll(i).Y]=utm2ll(shp(i).X,shp(i).Y,grid_zone,3);
end

shapewrite(shpll,outfile);