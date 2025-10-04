clear ; close all;

inDir='W:\csiem\Model\TFV\csiem_model_tfvaed_1.1\outputs\results_highRes_202204\';
inDirHR='W:\csiem\Model\TFV\csiem_model_tfvaed_1.0\tfvaed_1.0\outputs\results_HighRes\';

WQfile=[inDir,'csiem_v1_C001_20220101_20221231_WQ_highRes_highRes.nc'];
HRfile=WQfile;
%[inDirHR,'csiem_100_A_20130101_20130601_WQ_009_waves_nutirent_trc_GW_HighRes_hires.nc'];
%WQfile=HRfile;

dat = tfv_readnetcdf(WQfile,'time',1);
timesteps_WQ = dat.Time;

dat = tfv_readnetcdf(HRfile,'time',1);
timesteps_HR = dat.Time;

dat = tfv_readnetcdf(WQfile,'timestep',1);
clear funcions;

vertWQ(:,1) = dat.node_X;
vertWQ(:,2) = dat.node_Y;

facesWQ = dat.cell_node';

%--% Fix the triangles
facesWQ(facesWQ(:,4)== 0,4) = facesWQ(facesWQ(:,4)== 0,1);

surf_cellsWQ=dat.idx3(dat.idx3 > 0);
bottom_cellsWQ(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsWQ(length(dat.idx3)) = length(dat.idx3);

dat = tfv_readnetcdf(HRfile,'timestep',1);
clear funcions;

vertHR(:,1) = dat.node_X;
vertHR(:,2) = dat.node_Y;

facesHR = dat.cell_node';

%--% Fix the triangles
facesHR(facesHR(:,4)== 0,4) = facesHR(facesHR(:,4)== 0,1);

surf_cellsHR=dat.idx3(dat.idx3 > 0);
bottom_cellsHR(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
bottom_cellsHR(length(dat.idx3)) = length(dat.idx3);

clip_depth=0.05;
config.add_quiver = 0;

def.xlim = [0 8.48];% xlim in KM
def.xticks = [0    4.2   8.28]; %[0:5:45];
def.xticklabels = {'West','Central CS','East'};

def.ylim=[-24 2];
config.ylim=[-24 2];
config.max_depth = -24;

%%
% line config
coastline_file='../GIS/Boundary.shp';
shp2=shaperead(coastline_file);
%  cell_inds=inpolygon(xxx,yyy,shp2.X,shp2.Y);

polyline_file='../GIS/Transec_line_LL_PSDP.shp';
shp = shaperead(polyline_file);
for kk = 1:length(shp)
    line(kk,1) = shp(kk).X;
    line(kk,2)  = shp(kk).Y;
end

%%
dat = tfv_readnetcdf(WQfile,'timestep',1);

X=dat.cell_X;
Y=dat.cell_Y;


for i = 1:length(shp)
    sdata(i,1) = shp(i).X;
    sdata(i,2) = shp(i).Y;

        [sdata2(i,1),sdata2(i,2)]=ll2utm(shp(i).X,shp(i).Y);

end

dist(1,1) = 0;

    for i = 2:length(shp)
        dist(i,1) = sqrt(power((sdata2(i,1) - sdata2(i-1,1)),2) + power((sdata2(i,2)- sdata2(i-1,2)),2)) + dist(i-1,1);
    end


dist = dist / 1000; % convert to km

for dd=1:length(def.xticks)
    inds=find(abs(dist-def.xticks(dd))==min(abs(dist-def.xticks(dd))));
    lx(dd)=line(inds(1),1);
    ly(dd)=line(inds(1),2);
end

dtri = DelaunayTri(double(X),double(Y));

query_points(:,1) = sdata(~isnan(sdata(:,1)),1);
query_points(:,2) = sdata(~isnan(sdata(:,2)),2);

pt_id = nearestNeighbor(dtri,query_points);
cells_idx2 = pt_id;

geodata.X = X(pt_id);
geodata.Y = Y(pt_id);
geodata.Z = dat.cell_Zb(pt_id);

sXX = geodata.X(1:end);
sYY = geodata.Y(1:end);

%  curt.dist(1:length(geodata.X)) = 0;
curt.dist=dist'*1000;
thetaCOS(1:length(geodata.X)) = 0;
thetaSIN(1:length(geodata.X)) = 0;
for ii = 1:length(geodata.X)-1
    temp_d =sqrt(power((sdata(ii+1,1) - sdata(ii,1)),2) + power((sdata(ii+1,2)- sdata(ii,2)),2));
    %  temp_d = sqrt((sXX(ii+1)-sXX(ii)) .^2 + (sYY(ii+1) - sYY(ii)).^2);
    %  curt.dist(ii+1) = curt.dist(ii) + temp_d;
    thetaCOS(ii)=(sdata(ii+1,1) - sdata(ii,1))./temp_d;
    thetaSIN(ii)=(sdata(ii+1,2) - sdata(ii,2))./temp_d;
end
%     for ii = 1:length(geodata.X)-1
%         temp_d = sqrt((sXX(ii+1)-sXX(ii)) .^2 + (sYY(ii+1) - sYY(ii)).^2);
%         curt.dist(ii+1) = curt.dist(ii) + temp_d;
%         thetaCOS(ii)=(sXX(ii+1)-sXX(ii))./temp_d;
%         thetaSIN(ii)=(sYY(ii+1)-sYY(ii))./temp_d;
%     end

DX(:,1) = sXX;
DX(:,2) = sYY;
curt.base = geodata.Z;

%     if config.isSpherical
%         curt.dist = curt.dist * 111111;
%     end

fillX = [min(curt.dist /1000) sort(curt.dist /1000) max(curt.dist /1000)];
fillY =[config.max_depth;curt.base;config.max_depth];

XX=curt.dist/1000;
YY=config.ylim(1):0.1:config.ylim(2);

[xxx,yyy]=meshgrid(XX,YY);
N = length(geodata.X);

%%
first_plot = 1;

img_dir = '.\animation_PSDP_tr3_HighRes\';

if ~exist(img_dir,'dir')
    mkdir(img_dir);
end


sim_name = [img_dir,'animation.avi'];

hvid = VideoWriter(sim_name);
set(hvid,'Quality',100);
set(hvid,'FrameRate',3);
framepar.resolution = [1024,768];

open(hvid);

%%
hfig = figure('visible','on','position',[304         166         1200        675]);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf,'paperposition',[0.635 6.35 24 13.5])

t0=datenum('20220301 00:00','yyyymmdd HH:MM');
tt = find(abs(timesteps_WQ-t0)==min(abs(timesteps_WQ-t0)));
t1=datenum('20220324 00:00','yyyymmdd HH:MM');
tt1 = find(abs(timesteps_WQ-t1)==min(abs(timesteps_WQ-t1)));
plot_interval=1;

xlim=[115.6300  115.7786]; %[115.6000  115.8];
ylim=[-32.3000  -32.1000]; %[-32.3000  -31.9];


cellInt=floor((xlim(2)-xlim(1))*1111111/500);
    XXs=xlim(1):cellInt/1111111:xlim(2);
    YYs=ylim(1):cellInt/1111111:ylim(2);
    [xxxs,yyys]=meshgrid(XXs,YYs);
  
    
    [aa,bb]=m_ll2xy(xxxs,yyys);
    xxxq=aa;yyyq=bb;
                    
    intv=round(size(xxxq,1)/50);
    xxxx=xxxq(1:intv:end,1:intv:end);
    yyyy=yyyq(1:intv:end,1:intv:end);

coastline_file='../GIS/Boundary.shp';
shp2=shaperead(coastline_file);
cell_inds=inpolygon(xxxs,yyys,shp2.X,shp2.Y);

m_proj('miller','lon',xlim,'lat',ylim);
hold on;

LONG=vertHR(:,1);LAT=vertHR(:,2);
[X,Y]=m_ll2xy(LONG,LAT);
vert(:,1)=X;vert(:,2)=Y;

pos1=[0.1 0.1 0.3 0.8];
pos2=[0.48 0.55 0.45 0.28];
pos3=[0.48 0.15 0.45 0.28];

for i=tt:plot_interval:tt1
    
    disp(datestr(timesteps_WQ(i)));
    clf;
    
    gca=axes('Position',pos1);
    
    t0=timesteps_WQ(i);
    ind0=find(abs(timesteps_HR-t0)==min(abs(timesteps_HR-t0)));
    
    tdat = tfv_readnetcdf(HRfile,'timestep',ind0);
    cdata1=tdat.WQ_TRC_TR3(bottom_cellsWQ)*100;
    d=tdat.D;
    cdata1(d<clip_depth)=NaN;
    
   %  clear tdat d;
    
   % x = [xlim(1) xlim(1) xlim(2) xlim(2)];
   % y = [ylim(1) ylim(2) ylim(2) ylim(1)];
   % [X1,Y1]=m_ll2xy(x,y);
   % vert(:,1)=X;vert(:,2)=Y;

    %m_patch(x,y,'red','FaceAlpha',.3);
   % F1 = fill(X1,Y1,[146, 116, 91]./255); %140,81,10
    hold on;

    tdatWQ = tdat; %tfv_readnetcdf(WQfile,'timestep',i);
    cell_X=tdatWQ.cell_X;
    cell_Y=tdatWQ.cell_Y;
    Fx = scatteredInterpolant(cell_X,cell_Y,double(tdatWQ.V_x(bottom_cellsWQ)));
    zzzx=Fx(xxxs,yyys);zzzx(~cell_inds)=NaN;
    xxxu=zzzx(1:intv:end,1:intv:end);
    Fy = scatteredInterpolant(cell_X,cell_Y,double(tdatWQ.V_y(bottom_cellsWQ)));
    zzzy=Fy(xxxs,yyys);zzzy(~cell_inds)=NaN;
    xxxv=zzzy(1:intv:end,1:intv:end);
    
    Fc = scatteredInterpolant(cell_X,cell_Y,double(cdata1));
    zzzc=Fc(xxxs,yyys);zzzc(~cell_inds)=NaN;
    
    %patFig = patch('faces',facesHR,'vertices',vert,'FaceVertexCData',cdata1);shading flat
    patFig=m_pcolor(xxxs,yyys,zzzc);shading interp;
    hold on;
    set(gca,'box','on');
    
    trange=[0 5];
    caxis(trange);
    
    set(findobj(gca,'type','surface'),...
        'FaceLighting','phong',...
        'AmbientStrength',.3,'DiffuseStrength',.8,...
        'SpecularStrength',.9,'SpecularExponent',25,...
        'BackFaceLighting','unlit');
    
    %  axis off;
    %  axis equal;
    
    %  set(gca,'xlim',xlim,'ylim',ylim);
    
    cmap=colormap('jet');
    
    for cc=1 
      cmap(cc,:)=[0.8 0.8 0.8];
    end
    colormap(cmap);
    cb = colorbar;
    
    hold on;
    m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
    hold on;
    
    m_plot(line(:,1),line(:,2),'Color',[0.1 0.1 0.1],'LineWidth',2);
    hold on;
    
    for dd=1:length(lx)
        m_text(lx(dd)-0.006,ly(dd)-0.003,def.xticklabels{dd},'FontSize',8,...
            'FontWeight','Bold','Color','m');
        hold on;
    end
    
    m_annotation('textarrow',[115.7453 115.7533]-0.008,[-32.192 -32.2],'string','PSDP Discharge','Color','m')
    hold on;
    %  set(cb,'position',[0.9 0.1 0.01 0.25],...
    %      'units','normalized','ycolor','k');
    
    %colorTitleHandle = get(cb,'Title');
    %set(colorTitleHandle ,'String',regexprep(varname,'_',' '),'color','k','fontsize',10);
    
    
    hq3=quiver(xxxx,yyyy,xxxu,xxxv);
    hold on;
    
    title('Bottom PSDP Tracer (%)','color','k','fontsize',14);hold on;
     dim = [0.4 0.91 0.3 0.05];
     str = ['Time: ', datestr(double(timesteps_WQ(i)),'yyyy/mm/dd HH:MM')];
     annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none','FontSize',15);
    m_grid('box','fancy','tickdir','out');
    hold on;
    
    gca=axes('Position',pos2);

   % tdat = tfv_readnetcdf(WQfile,'timestep',i);
    plotdata=tdat.SAL;
    
    for n = 1 : N
                i2 = cells_idx2(n);
                Cell_3D_IDs = find(tdat.idx2==i2);
                
                surfIndex = min(Cell_3D_IDs);
                botIndex = max(Cell_3D_IDs);
                
                data.profile(1) = plotdata(Cell_3D_IDs(1));
                data.profile(2:length(Cell_3D_IDs)+1) = plotdata(Cell_3D_IDs);
                data.profile(length(Cell_3D_IDs)+2) = plotdata(Cell_3D_IDs(length(Cell_3D_IDs)));
                
                if config.add_quiver
                    xu=tdat.V_x;
                    xv=tdat.V_y;
                    xz=tdat.W;
                    
                    data.xu(1) = xu(Cell_3D_IDs(1));
                    data.xu(2:length(Cell_3D_IDs)+1) = xu(Cell_3D_IDs);
                    data.xu(length(Cell_3D_IDs)+2) = xu(Cell_3D_IDs(length(Cell_3D_IDs)));
                    
                    data.xv(1) = xv(Cell_3D_IDs(1));
                    data.xv(2:length(Cell_3D_IDs)+1) = xv(Cell_3D_IDs);
                    data.xv(length(Cell_3D_IDs)+2) = xv(Cell_3D_IDs(length(Cell_3D_IDs)));
                    
                    data.xt=data.xu*thetaCOS(n)+data.xv*thetaSIN(n);
                    
                    data.xz(1) = xz(Cell_3D_IDs(1));
                    data.xz(2:length(Cell_3D_IDs)+1) = xz(Cell_3D_IDs);
                    data.xz(length(Cell_3D_IDs)+2) = xz(Cell_3D_IDs(length(Cell_3D_IDs)));
                end
                
                data.depths(1)  = tdat.layerface_Z(surfIndex + i2 - 1);
                
                for j = 1 : tdat.NL(i2)
                    % mid point of layer
                    data.depths(j+1) = (tdat.layerface_Z(Cell_3D_IDs(j) + i2-1) + tdat.layerface_Z(Cell_3D_IDs(j) + i2-1 +1))/2.;
                end
                data.depths(length(Cell_3D_IDs)+2)  = tdat.layerface_Z(botIndex+i2-1+1);
                
                tmp=interp1(data.depths,data.profile,YY,'linear');
                inds=find(~isnan(tmp));
                
                if ~isempty(inds)
                    tmp(1:inds(1))=tmp(inds(1));
                end
                
                zzz(:,n)=tmp;
                if config.add_quiver
                    tmpu(:,n)=interp1(data.depths,data.xt,YY,'linear');
                    tmpv(:,n)=interp1(data.depths,data.xz,YY,'linear')*1;
                end
                clear data;
    end
            
    Fig=pcolor(xxx,yyy,zzz);shading interp;hold on;
    F1 = fill(fillX,fillY,[146, 116, 91]./255); %140,81,10
                
                if config.add_quiver
                    XXN=0:XX(end)/1000:XX(end);
                    %  YY=config.ylim(1):0.2:config.ylim(2);
                    [xxxn,yyyn]=meshgrid(XXN,YY);
                    tmpun=xxxn*0;
                    tmpvn=xxxn*0;
                    for jj=1:size(xxxn,1)
                        tmpun(jj,:)=interp1(XX,tmpu(jj,:),XXN);
                        tmpvn(jj,:)=interp1(XX,tmpv(jj,:),XXN);
                    end
                    intx=20;
                    inty=floor(length(YY)/20);
                    hq=quiver(xxxn(1:inty:end,1:intx:end),yyyn(1:inty:end,1:intx:end),...
                        tmpun(1:inty:end,1:intx:end),tmpvn(1:inty:end,1:intx:end),...
                        'Color',[0 0.4470 0.7410]);
                end
    title('Salinity - curtain view (PSU)',...
                'Units','Normalized',...
                'color','k','fontsize',14);
            caxis([35 37]);
            colormap(cmap);
            cb=colorbar;%cb.label.string='^oC';
            
%             colorTitleHandle = get(cb,'Title');
%             set(colorTitleHandle,'String','T');
   set(gca,'box','on','LineWidth',1.0,'Layer','top');
            
    set(gca,'xlim',def.xlim,'XTick',def.xticks,'XTickLabel',def.xticklabels,'TickDir','out');
                set(gca,'ylim',def.ylim);
    ylabel('Depth (m)','FontWeight','bold','color','k');
     %       set(gca,'box','on');      
     
     
    gca=axes('Position',pos3);

   % tdat = tfv_readnetcdf(WQfile,'timestep',i);
    plotdata=tdat.WQ_TRC_TR3*100;
    
    for n = 1 : N
                i2 = cells_idx2(n);
                Cell_3D_IDs = find(tdat.idx2==i2);
                
                surfIndex = min(Cell_3D_IDs);
                botIndex = max(Cell_3D_IDs);
                
                data.profile(1) = plotdata(Cell_3D_IDs(1));
                data.profile(2:length(Cell_3D_IDs)+1) = plotdata(Cell_3D_IDs);
                data.profile(length(Cell_3D_IDs)+2) = plotdata(Cell_3D_IDs(length(Cell_3D_IDs)));
                
                if config.add_quiver
                    xu=tdat.V_x;
                    xv=tdat.V_y;
                    xz=tdat.W;
                    
                    data.xu(1) = xu(Cell_3D_IDs(1));
                    data.xu(2:length(Cell_3D_IDs)+1) = xu(Cell_3D_IDs);
                    data.xu(length(Cell_3D_IDs)+2) = xu(Cell_3D_IDs(length(Cell_3D_IDs)));
                    
                    data.xv(1) = xv(Cell_3D_IDs(1));
                    data.xv(2:length(Cell_3D_IDs)+1) = xv(Cell_3D_IDs);
                    data.xv(length(Cell_3D_IDs)+2) = xv(Cell_3D_IDs(length(Cell_3D_IDs)));
                    
                    data.xt=data.xu*thetaCOS(n)+data.xv*thetaSIN(n);
                    
                    data.xz(1) = xz(Cell_3D_IDs(1));
                    data.xz(2:length(Cell_3D_IDs)+1) = xz(Cell_3D_IDs);
                    data.xz(length(Cell_3D_IDs)+2) = xz(Cell_3D_IDs(length(Cell_3D_IDs)));
                end
                
                data.depths(1)  = tdat.layerface_Z(surfIndex + i2 - 1);
                
                for j = 1 : tdat.NL(i2)
                    % mid point of layer
                    data.depths(j+1) = (tdat.layerface_Z(Cell_3D_IDs(j) + i2-1) + tdat.layerface_Z(Cell_3D_IDs(j) + i2-1 +1))/2.;
                end
                data.depths(length(Cell_3D_IDs)+2)  = tdat.layerface_Z(botIndex+i2-1+1);
                
                tmp=interp1(data.depths,data.profile,YY,'linear');
                inds=find(~isnan(tmp));
                
                if ~isempty(inds)
                    tmp(1:inds(1))=tmp(inds(1));
                end
                
                zzz(:,n)=tmp;
                if config.add_quiver
                    tmpu(:,n)=interp1(data.depths,data.xt,YY,'linear');
                    tmpv(:,n)=interp1(data.depths,data.xz,YY,'linear')*1;
                end
                clear data;
    end
            
    Fig=pcolor(xxx,yyy,zzz);shading interp;hold on;
                F1 = fill(fillX,fillY,[146, 116, 91]./255); %140,81,10
                
                if config.add_quiver
                    XXN=0:XX(end)/1000:XX(end);
                    %  YY=config.ylim(1):0.2:config.ylim(2);
                    [xxxn,yyyn]=meshgrid(XXN,YY);
                    tmpun=xxxn*0;
                    tmpvn=xxxn*0;
                    for jj=1:size(xxxn,1)
                        tmpun(jj,:)=interp1(XX,tmpu(jj,:),XXN);
                        tmpvn(jj,:)=interp1(XX,tmpv(jj,:),XXN);
                    end
                    intx=20;
                    inty=floor(length(YY)/20);
                    hq=quiver(xxxn(1:inty:end,1:intx:end),yyyn(1:inty:end,1:intx:end),...
                        tmpun(1:inty:end,1:intx:end),tmpvn(1:inty:end,1:intx:end),...
                        'Color',[0 0.4470 0.7410]);
                end
    title('PSDP tracer - curtain view (%)',...
                'Units','Normalized',...
                'color','k','fontsize',14);
            caxis([0 5]);
            colormap(cmap);
            cb=colorbar; %cb.label.string='mg/L';
            
%             colorTitleHandle = get(cb,'Title');
%             set(colorTitleHandle,'String','T');
    set(gca,'box','on','LineWidth',1.0,'Layer','top');
            
    set(gca,'xlim',def.xlim,'XTick',def.xticks,'XTickLabel',def.xticklabels,'TickDir','out');
                set(gca,'ylim',def.ylim);
    ylabel('Depth (m)','FontWeight','bold','color','k');
     %       set(gca,'box','on');       
     
                
    img_name =[img_dir,'/temp_',datestr(double(timesteps_WQ(i)),'yyyymmddHHMM'),'.png'];
    
    saveas(gcf,img_name);
    
    writeVideo(hvid,getframe(hfig));
    
end

close(hvid);