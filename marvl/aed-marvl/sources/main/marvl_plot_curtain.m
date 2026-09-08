function marvl_plot_curtain(MARVLs)

%--------------------------------------------------------------------------
disp('plot_curtain_animation: START');
%
%clear; close all;
%run('E:\database\MARVL\examples\Cockburn_Sound\MARVL.m');
master=MARVLs.master;
config=MARVLs.curtain;
def=config;
ncfile=master.ncfile;
%--------------------------------------------------------------------------
%disp('plottfv_transect: START')
disp('')

% line config
shp = shaperead(config.polyline);
for kk = 1:length(shp)
    line(kk,1) = shp(kk).X;
    line(kk,2)  = shp(kk).Y;
end

% start plotting, loop through selected variables
for var = config.start_plot_ID:config.end_plot_ID
    
    loadname = master.varname{var,1};       % AED name
    loadname_human = master.varname{var,2}; % User-define name
    savedir = [config.outputdirectory,loadname,'/']; % output path
    if ~exist(savedir,'dir')
        mkdir(savedir);
    end
    
    disp(['Plotting ',loadname]);
    
    if strcmpi(config.plottype,'movie')
        % create movie file
        
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
        
    end
    % read in basic data
    dat = tfv_readnetcdf(ncfile(1).name,'time',1);
    timesteps = double(dat.Time);
    
    dat = tfv_readnetcdf(ncfile(1).name,'timestep',1);
    vert(:,1) = dat.node_X;
    vert(:,2) = dat.node_Y;
    faces = dat.cell_node';
    
    %--% Fix the triangles
    faces(faces(:,4)== 0,4) = faces(faces(:,4)== 0,1);
    
    %geo = tfv_readnetcdf(config.geofile);
    %[pt_id,geodata,cells_idx2] = tfv_searchnearest(line,geo);
    X=dat.cell_X;
    Y=dat.cell_Y;
    
    
    for i = 1:length(shp)
        sdata(i,1) = shp(i).X;
        sdata(i,2) = shp(i).Y;
        
        if config.isSpherical
            [sdata2(i,1),sdata2(i,2)]=ll2utm(shp(i).X,shp(i).Y);
        end
    end
    
    dist(1,1) = 0;
    
    if config.isSpherical
        for i = 2:length(shp)
            dist(i,1) = sqrt(power((sdata2(i,1) - sdata2(i-1,1)),2) + power((sdata2(i,2)- sdata2(i-1,2)),2)) + dist(i-1,1);
        end
    else
        for i = 2:length(shp)
            dist(i,1) = sqrt(power((sdata(i,1) - sdata(i-1,1)),2) + power((sdata(i,2)- sdata(i-1,2)),2)) + dist(i-1,1);
        end
    end
    
    dist = dist / 1000; % convert to km
    
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
    
    % define time
    first_plot = 1;
    
    if strcmpi(config.plottype,'movie')
        
        ts=find(abs(timesteps-def.datearray(1))==min(abs(timesteps-def.datearray(1))));
        tf=find(abs(timesteps-def.datearray(2))==min(abs(timesteps-def.datearray(2))));
        plotsteps=ts:def.plot_interval:tf;
    else
        for dd=1:length(def.datearray)
            ddtmp=find(abs(timesteps-def.datearray(dd))==min(abs(timesteps-def.datearray(dd))));
            plotsteps(dd)=ddtmp(1);
        end
    end
    
    % loop through time
    for i = plotsteps %ts:def.plot_interval:tf
        tdat = tfv_readnetcdf(ncfile(1).name,'timestep',i);
        
        [plotdata,c_units,isConv,ylab] = tfv_Unit_Conversion(tdat.(loadname),loadname);
        
        if strcmpi(config.meshstype,'meshgrid')
            XX=curt.dist/1000;
            YY=config.ylim(1):0.1:config.ylim(2);
            
            [xxx,yyy]=meshgrid(XX,YY);
            N = length(geodata.X);
            
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
            
        else
            % Build Patch Grid_________________________________________________
            N = length(geodata.X);
            
            for n = 1 : (N - 1)
                i2 = cells_idx2(n);
                % Traditionl
                NL = tdat.NL(i2);
                i3 = tdat.idx3(i2);
                i3z = i3 + i2 -1;
                
                xv{n} = repmat([curt.dist(n);...
                    curt.dist(n);...
                    curt.dist(n+1);...
                    curt.dist(n+1)],...
                    [1 NL]);
                
                zv{n} = zeros(4,NL);
                for ii = 1 : NL
                    zv{n}(:,ii) = [tdat.layerface_Z(i3z); ...
                        tdat.layerface_Z(i3z+1); ...
                        tdat.layerface_Z(i3z+1); ...
                        tdat.layerface_Z(i3z)];
                    i3z = i3z + 1;
                end
                
                tt.var1{n} = plotdata(i3:i3+NL-1);
                
                
            end
            
            model.x = cell2mat(xv);
            model.z = cell2mat(zv);
            
            model.var1 = cell2mat(tt.var1');
            
        end
        
        if first_plot
            gcf=figure('visible',master.visible);
            pos=get(gcf,'Position');
            xSize = def.dimensions(1);
            ySize = def.dimensions(2);
            newPos3=(pos(3)+pos(4))*xSize/(xSize+ySize)*1.5;
            newPos4=(pos(3)+pos(4))*ySize/(xSize+ySize)*1.5;
            set(gcf,'Position',[pos(1) pos(2) newPos3 newPos4],'color','w');
            set(0,'DefaultAxesFontName',master.font);
            set(0,'DefaultAxesFontSize',master.fontsize);
            
            %--% Paper Size
            set(gcf, 'PaperPositionMode', 'manual');
            set(gcf, 'PaperUnits', 'centimeters');
            set(gcf,'paperposition',[0 0 xSize ySize]);
            
            axes('position',[0.1 0.24 0.82 0.65]);
            if strcmpi(config.meshstype,'meshgrid')
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
            else
                patFig = patch(model.x /1000,model.z,model.var1','edgecolor','none'); hold on;
                F1 = fill(fillX,fillY,[146, 116, 91]./255); %140,81,10
                
                set(findobj(gca,'type','surface'),...
                    'FaceLighting','phong',...
                    'AmbientStrength',.3,'DiffuseStrength',.8,...
                    'SpecularStrength',.9,'SpecularExponent',25,...
                    'BackFaceLighting','unlit');
                
            end
            if def.xtickManual == 1
                set(gca,'xlim',def.xlim,'XTick',def.xticks,'XTickLabel',def.xticklabels,'TickDir','out');
                set(gca,'ylim',def.ylim);
            else
                set(gca,'xlim',def.xlim,'XTick',def.xticks);
                set(gca,'ylim',def.ylim);
                xlabel(def.xlabel,'fontsize',master.xlabelsize,'FontWeight','bold','color','k','FontName',master.font);
            end
            
            ylabel('Depth (m)','fontsize',master.ylabelsize,'FontWeight','bold','color','k','FontName',master.font);
            caxis(def.cAxis(var).value);
            colormap(config.colormap);
            cb = colorbar('southoutside');
            set(cb,'position',def.colorbarposition,...
                'units','normalized','ycolor','k');
            
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
            
            % title([title_str,' at ', datestr(timesteps(i),'dd mmm yyyy HH:MM')],...
            title([ncfile(1).legend,': ', datestr(timesteps(i),'yyyy-mm-dd HH:MM')],...
                'Units','Normalized',...
                'Fontname',master.font,...
                'Fontsize',master.titlesize,...
                'color','k');
            
            colorTitleHandle = get(cb,'Title');
            set(colorTitleHandle,'String',title_str);
            set(gca,'box','on','LineWidth',1.0,'Layer','top');
            
            cbarrow;
            
            first_plot = 0;
            
        else
            disp(['Plotting ',datestr(timesteps(i),'dd mmm yyyy HH:MM'),'...']);
            if strcmpi(config.meshstype,'meshgrid')
                set(Fig,'Cdata',zzz);
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
                    %                     intx=20;
                    %                     inty=floor(length(YY)/20);
                    %                     hq=quiver(xxxn(1:intx:end,1:inty:end),yyyn(1:intx:end,1:inty:end),...
                    %                         tmpun(1:intx:end,1:inty:end),tmpvn(1:intx:end,1:inty:end),...
                    %                         'Color',[0 0.4470 0.7410]);
                    %
                    set(hq,'UData',tmpun(1:inty:end,1:intx:end));
                    set(hq,'VData',tmpvn(1:inty:end,1:intx:end));
                end
                drawnow;
            else
                set(patFig,'Cdata',model.var1);
                drawnow;
            end
            %   title([title_str,' at ', datestr(timesteps(i),'dd mmm yyyy HH:MM')],...
            title([ncfile(1).legend,': ', datestr(timesteps(i),'yyyy-mm-dd HH:MM')],...
                'Units','Normalized',...
                'Fontname',master.font,...
                'Fontsize',master.titlesize,...
                'color','k');
            caxis(def.cAxis(var).value);
            if def.xtickManual == 1
                set(gca,'xlim',def.xlim,'XTick',def.xticks,'XTickLabel',def.xticklabels,'TickDir','out');
                set(gca,'ylim',def.ylim);
            else
                set(gca,'xlim',def.xlim,'XTick',def.xticks);
                set(gca,'ylim',def.ylim);
                xlabel(def.xlabel,'fontsize',master.xlabelsize,'FontWeight','bold','color','k','FontName',master.font);
            end
            ylabel('Depth (m)','fontsize',master.ylabelsize,'FontWeight','bold','color','k','FontName',master.font);
            set(gca,'box','on');
            
            
        end
        
        if strcmpi(config.plottype,'movie')
            writeVideo(hvid,getframe(gcf));
        end
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
    if strcmpi(config.plottype,'movie')
        close(hvid);
    end
end