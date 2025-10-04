%% check wave

wwmFile='W:\csiem\Model\WAVES\2023_addition\his_20230101.nc';
swanVars={'Hsig','Dir','TPsmoo','Ubot'};
wwmVars= {'HS','DM','TPP','UBOT'};
tfvVars= {'WVHT','WVDIR','WVPER','UBOT'};
names =  {'Sig-Height','Direction','Peak-period','UBOT'};
names2 =  {'Significant Wave Height','Wave Direction','Wave Peak Period','Bottom Velocity'};

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
inc=1;
oceantime=datenum(1858,11,17)+ncread(wwmFile,'ocean_time')/86400;

for tt=13 %:length(oceantime)
    disp(datestr(oceantime(tt),'yyyymmddHH'));
    output.time(inc)=oceantime(tt);
    for vv=1:3

        tmpW=ncread(wwmFile,wwmVars{vv},[1 tt],[Inf 1]);
        F=scatteredInterpolant(lon, lat, double(tmpW));

        newHS=F(Xp,Yp);
        newHS(~inds)=NaN;

        output.(swanVars{vv})(:,:,inc)=newHS;
        %   output.(wwmVars{vv})(:,tt)=tmpW;

    end
    inc=inc+1;
end
%%
tfvFile='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results\tests_OBC_2023_waves_wave.nc';
dat = tfv_readnetcdf(tfvFile,'time',1);
timesteps = dat.Time;


t0=datenum(2023,1,1,20,1,1);
ind0=find(abs(timesteps-t0)==min(abs(timesteps-t0)));
allvars = tfv_infonetcdf(tfvFile);
dat = tfv_readnetcdf(tfvFile,'timestep',ind0);
vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;

faces = dat.cell_node';

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

%%
gcf=figure;
set(gcf,'Position',[100 100 2500 1000]);
set(0,'DefaultAxesFontSize',15);

limLow = [0 0 0 0];
limHigh= [4 360 20 2];

xlimi=[115.3 115.92];
ylimi=[-32.7 -31.6];

for vv=1 %:3
    clf;

    subplot(1,3,1);
    newHS=output.(swanVars{vv})(:,:,tt);

    pcolor(Xp,Yp,newHS); shading flat;
    axis equal;
    caxis([limLow(vv) limHigh(vv)]);
    colorbar;
    box on;
    set(gca,'xlim',xlimi,'ylim',ylimi);
    title([swanVars{vv},' CONV: ',names2{vv}]);

    subplot(1,3,2);

    tmpW=ncread(wwmFile,wwmVars{vv},[1 tt],[Inf 1]);
    scatter(lon,lat,3,tmpW,'filled');
    axis equal;
    caxis([limLow(vv) limHigh(vv)]);
    colorbar;
    box on;
    set(gca,'xlim',xlimi,'ylim',ylimi);

    title([wwmVars{vv},' WWM: ',names2{vv}]);

    subplot(1,3,3);

    cdata = dat.(tfvVars{vv});
    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata);shading flat
    set(gca,'box','on');

    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
axis equal;
    caxis([limLow(vv) limHigh(vv)]);
    colorbar;
    box on;
    title([wwmVars{vv},' TFV: ',names2{vv}]);
set(gca,'xlim',xlimi,'ylim',ylimi);

    print(gcf,[datestr(oceantime(tt),'yyyymmddHH'),'_INTERPOLATION_',names{vv},'.png'],'-dpng');

end
