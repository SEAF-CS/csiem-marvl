clear; close all;

start_p=[115.685 -32.2];
end_p  =[115.775 -32.2];
int    =0.0005;
tdist  =sqrt((end_p(1)-start_p(1)).^2+(end_p(2)-start_p(2)).^2);
darray=0:int:tdist;

xarray=zeros(size(darray));
yarray=zeros(size(darray));

xarray(1)=start_p(1);
yarray(1)=start_p(2);

for dd=2:length(darray)
    xarray(dd)=xarray(dd-1)+int*(end_p(1)-start_p(1))/tdist;
    yarray(dd)=yarray(dd-1)+int*(end_p(2)-start_p(2))/tdist;
end

%%
shp=struct;
for dd=1:length(darray)
    shp(dd,1).Geometry='Point';
    shp(dd,1).X=xarray(dd);
    shp(dd,1).Y=yarray(dd);
    shp(dd,1).fid=0;
end

shapewrite(shp,'Transec_line_LL_PSDP.shp');



