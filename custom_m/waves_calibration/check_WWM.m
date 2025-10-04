% check wave

clear; close all;
wwmVars= {'HS','DM','TPP','UBOT'};
wwmFile='W:\csiem\Model\WAVES\WWM\2022\his_20220101.nc';

lon=ncread(wwmFile,'lon');
lat=ncread(wwmFile,'lat');

minlon=min(lon); maxlon=max(lon);
minlat=min(lat); maxlat=max(lat);
int=0.0025;

newlon=minlon:int:maxlon;
newlat=minlat:int:maxlat;

[Xp, Yp]=meshgrid(newlon,newlat);
Xp=Xp';Yp=Yp';

% boundary shape
Boundary='W:\csiem\Model\WAVES\WWM_SWAN_conversion\GIS\Boundary.shp';
BS=shaperead(Boundary);
% add a patch for missing grids outside the Cockburn model domain boundary
patchxx=[115.4000 115.4000 115.6930 115.6930 115.6700 NaN];
patchyy=[-31.6336 -31.8151 -31.8151 -31.6676 -31.6336 NaN];

inds1=inpolygon(Xp,Yp,BS.X,BS.Y);
inds2=inpolygon(Xp,Yp,patchxx,patchyy);
inds=inds1+inds2;

% read in and interpolate the wave data

                tmpW=ncread(wwmFile,'depth');
                F=scatteredInterpolant(lon, lat, double(tmpW));
                
                newD=F(Xp,Yp);
                newD(~inds)=NaN;
 

sitenames={'PB','SBA','SBB','PBA','PBB','S01','S02'};
siteXutm=[381417.02, 379268.75, 380032.24, 378568.03, 379279.01];
siteYutm=[6455449.94, 6449572.59, 6448864.65, 6445541.44, 6444071.61];

[~, ~, grid_zone] = ll2utm (115.6976, -32.1463);

for ss=1:length(siteXutm)
    [siteX(ss), siteY(ss)] = utm2ll (siteXutm(ss), siteYutm(ss), grid_zone);
end

siteX(6:7)  =[115.762710, 115.730832];
siteY(6:7)  =[-32.200942, -32.180925];

for ss=1:length(sitenames)

X0=siteX(ss);
Y0=siteY(ss);

X1=lon-X0;
Y1=lat-Y0;

T1=sqrt(X1.^2+Y1.^2);

inds(ss)=find(abs(T1)==min(abs(T1)));
D2c(ss)=tmpW(inds(ss));


end