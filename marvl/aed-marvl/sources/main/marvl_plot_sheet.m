function marvl_plot_sheet(MARVLs)

%--------------------------------------------------------------------------
disp('plot_sheet: START');
%
%clear; close all;
%run('E:\database\MARVL\examples\Cockburn_Sound\MARVL.m');
master=MARVLs.master;
config=MARVLs.sheet;
def=config;
ncfile=master.ncfile;
%--------------------------------------------------------------------------
%disp('plottfv_transect: START')
disp('')

% read in basic data
dat = tfv_readnetcdf(ncfile(1).name,'time',1);
timesteps = double(dat.Time);

dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
vert(:,1) = dat.node_X;
vert(:,2) = dat.node_Y;
faces = dat.cell_node';

cellx=dat.cell_X;
celly=dat.cell_Y;

%--% Fix the triangles
faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);

if config.add_coastline==1
    shp2=shaperead(config.coastline_file);
end

if strcmpi(config.meshstype,'meshgrid')
    disp('interpolating mesh grids ...');
    tic;
    cellInt=floor((config.xlim(2)-config.xlim(1))*1111111/500);
    XX=config.xlim(1):cellInt/1111111:config.xlim(2);
    YY=config.ylim(1):cellInt/1111111:config.ylim(2);
    [xxx,yyy]=meshgrid(XX,YY);
    cell_X=dat.cell_X;
    cell_Y=dat.cell_Y;
    cell_inds=inpolygon(xxx,yyy,shp2.X,shp2.Y);
    toc;
end

if strcmpi(config.plotdepth{1},'bottom') == 1
    cells(1:length(dat.idx3)-1) = dat.idx3(2:end) - 1;
    cells(length(dat.idx3)) = length(dat.idx3);
else
    cells=dat.idx3(dat.idx3 > 0);
end

ts=find(abs(timesteps-def.datearray(1))==min(abs(timesteps-def.datearray(1))));
tf=find(abs(timesteps-def.datearray(2))==min(abs(timesteps-def.datearray(2))));

%%
% start plotting, loop through selected variables
for var = config.start_plot_ID:config.end_plot_ID
    
    loadname = master.varname{var,1};       % AED name
    loadname_human = master.varname{var,2}; % User-define name
    savedir = [config.outputdirectory,loadname,'/']; % output path
    if ~exist(savedir,'dir')
        mkdir(savedir);
    end
    
    disp(['Plotting ',loadname]);
    
    % create movie file
    
    if strcmpi(config.plottype,'movie')
        if strcmpi(config.FileFormat,'mp4')==1
            sim_name = [config.outputdirectory,loadname,'.mp4'];
            hvid = VideoWriter(sim_name,'MPEG-4');
        else
            sim_name = [config.outputdirectory,loadname,'.avi'];
            hvid = VideoWriter(sim_name,'avi');
        end
        
        set(hvid,'Quality',config.Quality);
        set(hvid,'FrameRate',config.FrameRate);
        framepar.resolution = config.resolution;
        
        open(hvid);
        
        % define time
        first_plot = 1;
        
        % loop through time
        for i = ts:def.plot_interval:tf
            disp(['Plotting ',datestr(timesteps(i),'dd mmm yyyy HH:MM'),'...']);
            tdat = tfv_readnetcdf(ncfile(1).name,'timestep',i);
            if strcmpi(loadname,'H') == 0
                cdata = tdat.(loadname)(cells);
            else
                cdata = tdat.(loadname);
            end
            
            [cdata,c_units,isConv,ylab] = tfv_Unit_Conversion(cdata,loadname);
            
            Depth = tdat.D;
            
            if def.clip_depth < 900
                Depth(Depth < def.clip_depth) = 0;
                cdata(Depth == 0) = NaN;
            end
            
            
            if first_plot
                gcf=figure('visible',master.visible);
                pos=get(gcf,'Position');
                xSize = def.dimensions(1);
                ySize = def.dimensions(2);
                newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
                newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
                set(gcf,'Position',[pos(1) pos(2)/2 newPos3 newPos4],'color','w');
                set(0,'DefaultAxesFontName',master.font);
                set(0,'DefaultAxesFontSize',master.fontsize);
                
                axes('position',[0.1 0.1 0.8 0.8]);
                if strcmpi(config.style,'m_map') == 1
                    m_proj('miller','lon',config.xlim,'lat',config.ylim);
                    hold on;
                    LONG=vert(:,1);LAT=vert(:,2);
                    [X,Y]=m_ll2xy(LONG,LAT);
                    vert(:,1)=X;vert(:,2)=Y;
                    
                    if strcmpi(config.meshstype,'meshgrid')
                    [aa,bb]=m_ll2xy(xxx,yyy);
                    xxxq=aa;yyyq=bb;
                    end
                    
                    
                    [Cx,Cy]=m_ll2xy(cellx,celly);
                    cellx=Cx;celly=Cy;
                end
                
                if strcmpi(config.meshstype,'meshgrid')
                    if strcmpi(config.style,'m_map') == 1
                        F = scatteredInterpolant(cell_X,cell_Y,double(cdata));
                        zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
                        patFig=m_pcolor(xxx,yyy,zzz);shading interp;
                        % [cs,patFig]=m_contour(xxx,yyy,zzz);
                    else
                        F = scatteredInterpolant(cell_X,cell_Y,double(cdata));
                        zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
                        patFig=pcolor(xxx,yyy,zzz);shading interp;
                    end
                else
                    
                    patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata);shading flat
                    set(gca,'box','on');
                    
                    set(findobj(gca,'type','surface'),...
                        'FaceLighting','phong',...
                        'AmbientStrength',.3,'DiffuseStrength',.8,...
                        'SpecularStrength',.9,'SpecularExponent',25,...
                        'BackFaceLighting','unlit');
                end
                
                caxis(def.cAxis(var).value);
                colormap(config.colormap);
                cb = colorbar;
                set(cb,'position',def.colorbarposition,...
                    'units','normalized','ycolor','k','FontSize',master.fontsize-2);
                if master.add_human
                    bar_str=[regexprep(loadname_human,'_',' '),' (',c_units,')'];
                else
                    bar_str=[regexprep(loadname,'_',' '),' (',c_units,')'];
                end
                set(get(cb,'ylabel'),'String',bar_str);
                
                cbarrow;
                
                hold on;
                
                if strcmpi(config.meshstype,'meshgrid') && config.add_quiver == 1
                    hold on;
                    intv=round(size(xxxq,1)/50);
                    xxxx=xxxq(1:intv:end,1:intv:end);
                    yyyy=yyyq(1:intv:end,1:intv:end);
                    Fx = scatteredInterpolant(cell_X,cell_Y,double(tdat.V_x(cells)));
                    zzzx=Fx(xxx,yyy);zzzx(~cell_inds)=NaN;
                    xxxu=zzzx(1:intv:end,1:intv:end);
                    Fy = scatteredInterpolant(cell_X,cell_Y,double(tdat.V_y(cells)));
                    zzzy=Fy(xxx,yyy);zzzy(~cell_inds)=NaN;
                    xxxv=zzzy(1:intv:end,1:intv:end);
                    
                    hq=quiver(xxxx,yyyy,xxxu,xxxv);
                end
                
                hold on;
                
                if strcmpi(config.style,'none') == 1
                    %   colorTitleHandle = get(cb,'Title');
                    %   set(colorTitleHandle,'String',c_units);
                    axis equal;
                    
                    if ~isempty(config.xlim)
                        set(gca,'xlim',config.xlim,'ylim',config.ylim);
                    end
                    
                    if config.isAxison
                        axis on;
                        xlim=get(gca,'xlim');
                        set(gca,'XTick',xlim(1):(xlim(2)-xlim(1))/3:xlim(2));
                        ylim=get(gca,'ylim');
                        set(gca,'YTick',ylim(1):(ylim(2)-ylim(1))/3:ylim(2));
                        ax = ancestor(gca, 'axes');
                        ax.XAxis.Exponent = 0;
                        xtickformat('%.3f');
                        ax.YAxis.Exponent = 0;
                        ytickformat('%.3f');
                    else
                        axis off;
                    end
                    
                else
                    m_grid('box','fancy','tickdir','out');
                    m_ruler([.6 .9],.1,3,'tickdir','out','ticklen',[.007 .007],'fontsize',8)
                    hold on;
                end
                
                if config.add_coastline == 1
                    
                    if strcmpi(config.style,'m_map') == 1
                        m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
                        hold on;
                        
                    else
                        plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
                        hold on;
                    end
                end
                
                if isConv
                    if master.add_human
                        title_str=[regexprep(loadname_human,'_',' '),' (',c_units,')'];
                    else
                        title_str=[regexprep(loadname,'_',' '),' (',c_units,')'];
                    end
                else
                    if master.add_human
                        title_str=[regexprep(loadname_human,'_',' '),' (model units)'];
                    else
                        title_str=[regexprep(loadname,'_',' '),' '];
                    end
                end
                
                title([ncfile(1).legend,': ', datestr(timesteps(i),'yyyy-mm-dd HH:MM')],...
                    'Units','Normalized',...
                    'Fontname',master.font,...
                    'Fontsize',master.titlesize,...
                    'color','k');
                
                first_plot = 0;
                
            else
                %  disp(['Plotting ',datestr(timesteps(i),'dd mmm yyyy HH:MM'),'...']);
                
                if strcmpi(config.meshstype,'meshgrid')
                    F = scatteredInterpolant(cell_X,cell_Y,double(cdata));
                    zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
                    set(patFig,'Cdata',zzz);
                    
                    if config.add_quiver
                        Fx = scatteredInterpolant(cell_X,cell_Y,double(tdat.V_x(cells)));
                        zzzx=Fx(xxx,yyy);zzzx(~cell_inds)=NaN;
                        xxxu=zzzx(1:intv:end,1:intv:end);
                        Fy = scatteredInterpolant(cell_X,cell_Y,double(tdat.V_y(cells)));
                        zzzy=Fy(xxx,yyy);zzzy(~cell_inds)=NaN;
                        xxxv=zzzy(1:intv:end,1:intv:end);
                        
                        set(hq,'UData',xxxu);
                        set(hq,'VData',xxxv);
                    end
                    
                else
                    set(patFig,'Cdata',cdata);
                end
                
                drawnow;
                
                title([ncfile(1).legend,': ', datestr(timesteps(i),'yyyy-mm-dd HH:MM')],...
                    'Units','Normalized',...
                    'Fontname',master.font,...
                    'Fontsize',master.titlesize,...
                    'color','k');
                caxis(def.cAxis(var).value);
                
            end
            writeVideo(hvid,getframe(gcf));
            
            if config.save_images
                img_dir = [config.outputdirectory,loadname,'/'];
                if ~exist(img_dir,'dir')
                    mkdir(img_dir);
                end
                img_name =[img_dir,datestr(timesteps(i),'yyyymmddHHMM'),'.png'];
                % saveas(gcf,img_name);
                print(gcf,'-dpng',img_name,'-opengl');
            end
            clear data cdata
        end
        
        % close movie handle
        close(hvid);
        
    else
        tmpdata=ncread(ncfile(1).name,loadname);
        tmpdata2=tmpdata(cells,ts:tf);
        
        [tmpdata2,c_units,isConv,ylab] = tfv_Unit_Conversion(tmpdata2,loadname);
        
        Depth0 = ncread(ncfile(1).name,'D');
        Depth2=Depth0(:,ts:tf);
        
        if def.clip_depth < 900
            Depth2(Depth2 < def.clip_depth) = 0;
            tmpdata2(Depth2 == 0) = NaN;
        end
        cdata=mean(tmpdata2,2);
        % clear tmpdata tmpdata2 Depth0 depth2 cdata0;
        
        gcf=figure('visible',master.visible);
        pos=get(gcf,'Position');
        xSize = def.dimensions(1);
        ySize = def.dimensions(2);
        newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize);
        newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize);
        set(gcf,'Position',[pos(1) pos(2)/2 newPos3 newPos4],'color','w');
        set(0,'DefaultAxesFontName',master.font);
        set(0,'DefaultAxesFontSize',master.fontsize);
        
        axes('position',[0.15 0.1 0.8 0.8]);
        
        if strcmpi(config.style,'m_map') == 1
            m_proj('miller','lon',config.xlim,'lat',config.ylim);
            hold on;
            LONG=vert(:,1);LAT=vert(:,2);
            [X,Y]=m_ll2xy(LONG,LAT);
            vert(:,1)=X;vert(:,2)=Y;
            
            %    [Bx,By]=m_ll2xy(shp2.X,shp2.Y);
            %    shp2.X=Bx;shp2.Y=By;
            
            [Cx,Cy]=m_ll2xy(cellx,celly);
            cellx=Cx;celly=Cy;
        end
        
        if strcmpi(config.meshstype,'meshgrid')
            if strcmpi(config.style,'m_map') == 1
                F = scatteredInterpolant(cell_X,cell_Y,double(cdata));
                zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
                patFig=m_pcolor(xxx,yyy,zzz);shading interp;
                % [cs,patFig]=m_contour(xxx,yyy,zzz);
            else
                F = scatteredInterpolant(cell_X,cell_Y,double(cdata));
                zzz=F(xxx,yyy);zzz(~cell_inds)=NaN;
                patFig=pcolor(xxx,yyy,zzz);shading interp;
            end
        else
            
            patFig = patch('faces',faces,'vertices',vert,'FaceVertexCData',cdata);shading flat;
            set(gca,'box','on');
            
            set(findobj(gca,'type','surface'),...
                'FaceLighting','phong',...
                'AmbientStrength',.3,'DiffuseStrength',.8,...
                'SpecularStrength',.9,'SpecularExponent',25,...
                'BackFaceLighting','unlit');
        end
        
        %   caxis(def.cAxis(1).value);
        colormap(config.colormap);
        cb = colorbar;
        set(cb,'position',def.colorbarposition,...
            'units','normalized','ycolor','k','FontSize',master.fontsize-2);
        if master.add_human
            bar_str=[regexprep(loadname_human,'_',' '),' (',c_units,')'];
        else
            bar_str=[regexprep(loadname,'_',' '),' (',c_units,')'];
        end
        set(get(cb,'ylabel'),'String',bar_str);
        
        caxis(def.cAxis(var).value);
        cbarrow;
        
        hold on;
        
        if strcmpi(config.meshstype,'meshgrid') && config.add_quiver == 1
            tmpdata=ncread(ncfile(1).name,'V_x');
            tmpdata2=tmpdata(cells,ts:tf);
            cdataX=mean(tmpdata2,2);
            
            tmpdata=ncread(ncfile(1).name,'V_y');
            tmpdata2=tmpdata(cells,ts:tf);
            cdataY=mean(tmpdata2,2);
            
            hold on;
            intv=round(size(xxx,1)/50);
            xxxx=xxx(1:intv:end,1:intv:end);
            yyyy=yyy(1:intv:end,1:intv:end);
            Fx = scatteredInterpolant(cell_X,cell_Y,double(cdataX));
            zzzx=Fx(xxx,yyy);zzzx(~cell_inds)=NaN;
            xxxu=zzzx(1:intv:end,1:intv:end);
            Fy = scatteredInterpolant(cell_X,cell_Y,double(cdataY));
            zzzy=Fy(xxx,yyy);zzzy(~cell_inds)=NaN;
            xxxv=zzzy(1:intv:end,1:intv:end);
            
            hq=m_quiver(xxxx,yyyy,xxxu,xxxv);
        end
        
        
        if strcmpi(config.style,'none') == 1
            
            axis equal;
            if ~isempty(config.xlim)
                set(gca,'xlim',config.xlim,'ylim',config.ylim);
            end
            
            if config.isAxison
                axis on;
                xlim=get(gca,'xlim');
                set(gca,'XTick',xlim(1):(xlim(2)-xlim(1))/3:xlim(2));
                ylim=get(gca,'ylim');
                set(gca,'YTick',ylim(1):(ylim(2)-ylim(1))/3:ylim(2));
                ax = ancestor(gca, 'axes');
                ax.XAxis.Exponent = 0;
                xtickformat('%.3f');
                ax.YAxis.Exponent = 0;
                ytickformat('%.3f');
            else
                axis off;
            end
            
        else
            m_grid('box','fancy','tickdir','out');
            m_ruler([.6 .9],.1,3,'tickdir','out','ticklen',[.007 .007],'fontsize',8)
            hold on;
        end
        
        if config.add_coastline == 1
            
            if strcmpi(config.style,'m_map') == 1
                m_plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
                hold on;
                
            else
                plot(shp2.X,shp2.Y,'Color',[0.2 0.2 0.2]);
                hold on;
            end
        end
        
        
        if isConv
            if master.add_human
                title_str=[regexprep(loadname_human,'_',' '),' (',c_units,')'];
            else
                title_str=[regexprep(loadname,'_',' '),' (',c_units,')'];
            end
        else
            if config.add_human
                title_str=[regexprep(loadname_human,'_',' '),' (model units)'];
            else
                title_str=[regexprep(loadname,'_',' '),' '];
            end
        end
        
        title(['Mean Period: ', datestr(def.datearray(1),'dd/mmm/yyyy'),...
            ' - ',datestr(def.datearray(2),'dd/mmm/yyyy')],...
            'Units','Normalized',...
            'Fontname',master.font,...
            'Fontsize',master.titlesize,...
            'color','k');
        img_dir = [config.outputdirectory,loadname,'/'];
        if ~exist(img_dir,'dir')
            mkdir(img_dir);
        end
        img_name =[img_dir,loadname,' ', datestr(def.datearray(1),'dd-mmm-yyyy'),...
            ' to ',datestr(def.datearray(2),'dd-mmm-yyyy'),'.png'];
        % saveas(gcf,img_name);
        print(gcf,'-dpng',img_name,'-opengl');
    end
    
end