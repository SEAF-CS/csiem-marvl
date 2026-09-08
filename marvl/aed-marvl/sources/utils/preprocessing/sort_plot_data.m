
function [MatchedData_surf,MatchedData_bottom]=sort_plot_data(data,fdata,config,def,isvalidation,mod,shp,site,loadname,var,ncfile)

% allocate arrays for matching modelled and observed data
MatchedData_surf=[];
MatchedData_bottom=[];

% temporal varialbes for matched data
xdata_dt=[];
ydata_dt=[];

% if isvalidatoin, finding field sites within each polygon
if isvalidation
sitenames = fieldnames(fdata);

X=zeros(size(sitenames));
Y=zeros(size(sitenames));
for i = 1:length(sitenames)
    vars = fieldnames(fdata.(sitenames{i}));
    X(i) = fdata.(sitenames{i}).(vars{1}).X;
    Y(i) = fdata.(sitenames{i}).(vars{1}).Y;
end

    inpol = inpolygon(X,Y,shp(site).X,shp(site).Y);
    sss = find(inpol == 1);
    agencyLib=struct;
    agencyinc=1;
end

% going through surface and bottom layers (each or both)
for lev = 1:length(config.plotdepth)
     
           
    if strcmpi(config.plotdepth{lev},'bottom') == 1 % bottome layer
        
        % adding percentile band plot, optional
        if config.plotmodel && config.isRange_Bottom == 1
            fig = fillyy(data(mod).date_b,data(mod).pred_lim_ts_b(1,:),data(mod).pred_lim_ts_b(2*nn-1,:),def.dimc,def.col_pal_bottom(1,:));hold on
            set(fig,'DisplayName',[ncfile(mod).legend,' (Botm Range)']);
            set(fig,'FaceAlpha', def.alph);
            hold on
            
            for plim_i=2:(nn-1)
                fig2 = fillyy(data(mod).date_b,data(mod).pred_lim_ts_b(plim_i,:),data(mod).pred_lim_ts_b(2*nn-plim_i,:),def.dimc.*0.9.^(plim_i-1),def.col_pal_bottom(plim_i,:));
                set(fig2,'HandleVisibility','off');
                set(fig2,'FaceAlpha', def.alph);
            end
            uistack(fig, 'bottom');
            uistack(fig2,'bottom');
        end
        
        % adding field data, optional
        if isvalidation && mod == 1
            if ~isempty(sss)
                agencyused2 = []; % for data agency
                site_string = ['     field: '];

                for j = 1:length(sss)
                    if isfield(fdata.(sitenames{sss(j)}),loadname)
                        xdata_t = [];
                        ydata_t = [];
                        
                        % daily average or raw intervals
                        if ~config.validation_raw
                            [xdata_ta,ydata_ta,ydata_max_ta,ydata_min_ta] = get_field_at_depth(fdata.(sitenames{sss(j)}).(loadname).Date,fdata.(sitenames{sss(j)}).(loadname).Data,...
                                fdata.(sitenames{sss(j)}).(loadname).Depth,config.plotdepth{lev});
                            
                        else
                            [xdata_ta,ydata_ta,ydata_max_ta,ydata_min_ta] = get_field_at_depth_raw(fdata.(sitenames{sss(j)}).(loadname).Date,fdata.(sitenames{sss(j)}).(loadname).Data,...
                                fdata.(sitenames{sss(j)}).(loadname).Depth,config.plotdepth{lev});
                        end
                        
                        gfg = find(xdata_ta >= def.datearray(1) & xdata_ta <= def.datearray(end));
                        
                        if ~isempty(gfg)
                            xdata_t = xdata_ta(gfg);
                            ydata_t = ydata_ta(gfg);
                            if ~config.validation_raw
                                ydata_max_t = ydata_max_ta(gfg);
                                ydata_min_t = ydata_min_ta(gfg);
                            else
                                ydata_max_t = [];
                                ydata_min_t = [];
                            end
                        end
                        
                        if ~isempty(xdata_t)
                            if ~config.validation_raw
                                [xdata_d,ydata_d] = process_daily(xdata_t,ydata_t);
                                [~,ydata_max_d] = process_daily(xdata_t,ydata_max_t);
                                [~,ydata_min_d] = process_daily(xdata_t,ydata_min_t);
                            else
                                xdata_d =  xdata_t;
                                ydata_d = ydata_t;
                                ydata_max_d = [];
                                ydata_min_d = [];
                            end

                            % convert data based on AED conventtion
                            [ydata_d,c_units,isConv] = tfv_Unit_Conversion(ydata_d,loadname);
                            [ydata_max_d,~,~] = tfv_Unit_Conversion(ydata_max_d,loadname);
                            [ydata_min_d,~,~] = tfv_Unit_Conversion(ydata_min_d,loadname);
                            
                            % aggregating surface and bottomm data
                            xdata_dt=[xdata_dt xdata_d'];
                            ydata_dt=[ydata_dt ydata_d];
                         %   save('export_xdata.mat','xdata*','ydata*','-mat','-v7.3');
                            
                         % find agency names
                            if isfield(fdata.(sitenames{sss(j)}).(loadname),'Agency')
                                agency = fdata.(sitenames{sss(j)}).(loadname).Agency;
                            else
                                agency = 'Observations';
                            end
                            agencyinc=agencyinc+1;
                            site_string = [site_string,' ',sitenames{sss(j)},'(',agency,'),'];
                            
                            % for plotting features for different agency data
                            [mface,mcolor,agencyname] = sort_agency_information_inc(agencyinc,agency);
                            agencyused2 = [agencyused2;{agencyname}];
                            if config.plotvalidation
                                fgf = sum(strcmpi(agencyused2,agencyname));
                                
                                if fgf > 1
                                    fp = plot(xdata_d,ydata_d,mface,...
                                        'markeredgecolor',def.bottom_edge_color,'markerfacecolor',mcolor,'markersize',3,'HandleVisibility','off');hold on
                                    uistack(fp,'top');
                                    
                                    % option to add max and min
                                    % observations
                                    if config.validation_minmax
                                        fp = plot(xdata_d,ydata_max_d,'r+',...
                                            'HandleVisibility','off');hold on
                                        fp = plot(xdata_d,ydata_min_d,'r+',...
                                            'HandleVisibility','off');hold on
                                    end
                                    uistack(fp,'top');
                                    
                                else
                                    fp = plot(xdata_d,ydata_d,mface,...
                                        'markeredgecolor',def.bottom_edge_color,'markerfacecolor',mcolor,'markersize',3,'displayname',[agency, ' Bot']);hold on
                                    if config.validation_minmax
                                        fp = plot(xdata_d,ydata_max_d,'r+',...
                                            'HandleVisibility','off');hold on
                                        fp = plot(xdata_d,ydata_min_d,'r+',...
                                            'HandleVisibility','off');hold on
                                    end
                                    uistack(fp,'top');
                                end
                                
                                if def.isYlim
                                    if ~isempty(def.cAxis(var).value)
                                        ggg = find(ydata_d > def.cAxis(var).value(2));
                                        
                                        if ~isempty(ggg)
                                            agencyused2 = [agencyused2;{'Outside Range'}];
                                            fgf = sum(strcmpi(agencyused2,'Outside Range'));
                                            rdata = [];
                                            rdata(1:length(ggg),1) = def.cAxis(var).value(2);
                                            
                                            hhh = find(ydata_d(ggg) >= def.datearray(1) & ...
                                                ydata_d(ggg) <= def.datearray(end));
                                            
                                            if ~isempty(hhh)
                                                if fgf > 1
                                                    fp = plot(xdata_d(ggg),rdata,'k+',...
                                                        'markersize',4,'linewidth',1,'HandleVisibility','off');hold on
                                                    uistack(fp,'top');
                                                    
                                                else
                                                    fp = plot(xdata_d(ggg),rdata,'k+',...
                                                        'markersize',4,'linewidth',1,'displayname','Outside Range');hold on
                                                    uistack(fp,'top');
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                
                            end
                            
                        end
                    end
                    
                    
                end
                if(strlength(site_string)>7)
                    disp(site_string)
                end
                clear site_string;
            end
        end
        
        % plot median time series
        if config.plotmodel
            [xdata,ydata] = tfv_averaging(data(mod).date_b,data(mod).pred_lim_ts_b(3,:),def);
            diagVar = regexp(loadname,'DIAG');
            if diagVar>0 % removes inital zero value (eg in diganostics)
                xdata(1:2) = NaN;
            end
%         end
% 
%         if config.plotmodel
            plot(xdata,ydata,'color',ncfile(mod).colour{lev},'linewidth',0.5,'DisplayName',[ncfile(mod).legend,' (Botm Median)'],...
                'linestyle',ncfile(mod).symbol{1});hold on
%            plotdate(1:length(xdata),mod) = xdata;
%            plotdata(1:length(ydata),mod) = ydata;
        end

        % find matched model/observed data
        if config.add_error
            MatchedData_bottom=[];
            if exist('xdata_d','var') && ~isempty(xdata_dt)

         %       disp('find field data ...');
                alldayso=floor(xdata_dt);
                unidayso=unique(alldayso);
                obsData(:,1)=unidayso;
                
                for uuo=1:length(unidayso)
                    tmpinds=find(alldayso==unidayso(uuo));
                    tmpydatatt=ydata_dt(tmpinds);
                    obsData(uuo,2)=mean(tmpydatatt(~isnan(tmpydatatt)));
                    clear tmpydatatt;
                end
                
                alldays=floor(xdata);
                unidays=unique(alldays);
                simData(:,1)=unidays;
                
                for uu=1:length(unidays)
                    tmpinds=find(alldays==unidays(uu));
                    simData(uu,2)=mean(ydata(tmpinds));
                end
                
                [v, loc_obs, loc_sim] = intersect(obsData(:,1), simData(:,1));
                MatchedData_bottom = [v obsData(loc_obs,2) simData(loc_sim,2)];
                clear simData obsData v loc* alldays unidays
                clear xdata_d ydata_d
            end
            
        end
        
    else % for surface layer
        %option to plot percentile band
        if config.plotmodel && config.isRange_Surface == 1
            num_lims = length(config.pred_lims);
            nn = (num_lims+1)/2;
            fig = fillyy(data(mod).date,data(mod).pred_lim_ts(1,:),data(mod).pred_lim_ts(2*nn-1,:),def.dimc,def.col_pal_surface(mod,:));hold on
            set(fig,'DisplayName',[ncfile(mod).legend,' (Range)']); %Surf
            set(fig,'FaceAlpha', def.alph);
            hold on
            
            for plim_i=2:(nn-1)
                fig2 = fillyy(data(mod).date,data(mod).pred_lim_ts(plim_i,:),data(mod).pred_lim_ts(2*nn-plim_i,:),def.dimc.*0.9.^(plim_i-1),def.col_pal_surface(plim_i,:));
                set(fig2,'HandleVisibility','off');
                set(fig2,'FaceAlpha', def.alph);
                
            end
            uistack(fig,'bottom');
            uistack(fig2,'bottom');

        end
        %  add field data if isvalidation
        if isvalidation && mod == 1
            if ~isempty(sss)

                site_string = ['     field: '];
                agencyused = [];
                for j = 1:length(sss)
                    if isfield(fdata.(sitenames{sss(j)}),loadname)
                        xdata_t = [];
                        ydata_t = [];
                        
                        if ~config.validation_raw
                            
                            [xdata_ta,ydata_ta,ydata_max_ta,ydata_min_ta] = get_field_at_depth(fdata.(sitenames{sss(j)}).(loadname).Date,fdata.(sitenames{sss(j)}).(loadname).Data,...
                                fdata.(sitenames{sss(j)}).(loadname).Depth,config.plotdepth{lev});
                            
                        else
                            [xdata_ta,ydata_ta,ydata_max_ta,ydata_min_ta] = get_field_at_depth_raw(fdata.(sitenames{sss(j)}).(loadname).Date,fdata.(sitenames{sss(j)}).(loadname).Data,...
                                fdata.(sitenames{sss(j)}).(loadname).Depth,config.plotdepth{lev});
                        end

                        gfg = find(xdata_ta >= def.datearray(1) & xdata_ta <= def.datearray(end));
                        
                        if ~isempty(gfg)
                            
                            xdata_t = xdata_ta(gfg);
                            ydata_t = ydata_ta(gfg);
                            if ~config.validation_raw
                                ydata_max_t = ydata_max_ta(gfg);
                                ydata_min_t = ydata_min_ta(gfg);
                            else
                                ydata_max_t = [];
                                ydata_min_t = [];
                            end
                        end
                        
                        if ~isempty(xdata_t)
                            if ~config.validation_raw
                                [xdata_d,ydata_d] = process_daily(xdata_t,ydata_t);
                                [~,ydata_max_d] = process_daily(xdata_t,ydata_max_t);
                                [~,ydata_min_d] = process_daily(xdata_t,ydata_min_t);
                            else
                                xdata_d =  xdata_t;
                                ydata_d = ydata_t;
                                ydata_max_d = [];
                                ydata_min_d = [];
                            end
                            
                            
                            [ydata_d,c_units,isConv] = tfv_Unit_Conversion(ydata_d,loadname);
                            [ydata_max_d,~,~] = tfv_Unit_Conversion(ydata_max_d,loadname);
                            [ydata_min_d,~,~] = tfv_Unit_Conversion(ydata_min_d,loadname);
                            %  disp('doing field 2...')
                            xdata_dt=[xdata_dt xdata_d'];
                            ydata_dt=[ydata_dt ydata_d];
                          %  save('export_xdata.mat','xdata*','ydata*','-mat','-v7.3');

                            if isfield(fdata.(sitenames{sss(j)}).(loadname),'Agency')
                                    agency = fdata.(sitenames{sss(j)}).(loadname).Agency;
                            else
                                agency = 'Observations';
                            end
                            site_string = [site_string,' ',sitenames{sss(j)},'(',agency,'),'];
                            %                     if strcmpi(agency,'DEWNR')
%                             if sum(strcmpi(agencyused,agency))==0
%                                 agencyinc=agencyinc+1;
%                                 [mface,mcolor,agencyname] = sort_agency_information_inc(agencyinc,agency);
%                             else
%                                 
%                             end
                            [mface,mcolor,agencyname] = sort_agency_information_Coorong2(agency);
                            agencyused = [agencyused;{agencyname}];
                            
                            if config.plotvalidation
                                fgf = sum(strcmpi(agencyused,agencyname));
                                
                                if fgf > 1
                                   fp = plot(xdata_d,ydata_d,mface,'markeredgecolor',def.surface_edge_color,'markerfacecolor',mcolor,'markersize',3,'HandleVisibility','off');hold on
                                    uistack(fp,'top');
                                    if config.validation_minmax
                                        
                                        fp = plot(xdata_d,ydata_max_d,'+','color',[0.6 0.6 0.6],...
                                            'HandleVisibility','off');hold on
                                        fp = plot(xdata_d,ydata_min_d,'+','color',[0.6 0.6 0.6],...
                                            'HandleVisibility','off');hold on
                                    end
                                    uistack(fp,'top');
                                else
                                    fp = plot(xdata_d,ydata_d,mface,'markeredgecolor',def.surface_edge_color,'markerfacecolor',mcolor,'markersize',3,'displayname',[agency]);hold on; %,' Surf'
                                    uistack(fp,'top');
                                    if config.validation_minmax
                                        
                                        fp = plot(xdata_d,ydata_max_d,'+','color',[0.6 0.6 0.6],...
                                            'HandleVisibility','off');hold on
                                        fp = plot(xdata_d,ydata_min_d,'+','color',[0.6 0.6 0.6],...
                                            'HandleVisibility','off');hold on
                                    end
                                    uistack(fp,'top');
                                end
                                
                                if def.isYlim
                                    
                                    if ~isempty(def.cAxis(var).value)
                                        
                                        ggg = find(ydata_d > def.cAxis(var).value(2));
                                        
                                        if ~isempty(ggg)
                                            agencyused = [agencyused;{'Outside Range'}];
                                            fgf = sum(strcmpi(agencyused,'Outside Range'));
                                            rdata = [];
                                            rdata(1:length(ggg),1) = def.cAxis(var).value(2);
                                            hhh = find(xdata_d(ggg) >= def.datearray(1) & ...
                                                xdata_d(ggg) <= def.datearray(end));
                                            
                                            if ~isempty(hhh)
                                                if fgf > 1
                                                    
                                                    fp = plot(xdata_d(ggg),rdata,'k+',...
                                                        'markersize',4,'linewidth',1,'HandleVisibility','off');hold on
                                                    uistack(fp,'top');
                                                    
                                                else
                                                    
                                                    fp = plot(xdata_d(ggg),rdata,'k+',...
                                                        'markersize',4,'linewidth',1,'displayname','Outside Range');hold on
                                                    uistack(fp,'top');
                                                end
                                                uistack(fp,'top');
                                                
                                            end
                                        end
                                    end
                                end
                                %
                            end
                            
                            
                        end
                    end
                    
                end
                
                if(strlength(site_string)>7)
                    disp(site_string)
                end
                clear site_string;
                
            end
        end
        
        
        
        if config.plotmodel
            [xdata,ydata] = tfv_averaging(data(mod).date,data(mod).pred_lim_ts(3,:),def);
            diagVar = regexp(loadname,'DIAG');
            
            if diagVar>0 % removes inital zero value (eg in diganostics)
                xdata(1:2) = NaN;
            end
        end

        if config.plotmodel
        %    mod
            plot(xdata,ydata,'color',ncfile(mod).colour{1},'linewidth',0.5,'DisplayName',[ncfile(mod).legend,' (Surf Median)'],...
                'linestyle',ncfile(mod).symbol{1});hold on
         %   plotdate(1:length(xdata),mod) = xdata;
         %   plotdata(1:length(ydata),mod) = ydata;
        end
        if config.add_error
            MatchedData_surf=[];
            if (exist('xdata_dt','var') && ~isempty(xdata_dt))

                disp('find field data ...');
                alldayso=floor(xdata_dt);
                unidayso=unique(alldayso);
                obsData(:,1)=unidayso;
                
                for uuo=1:length(unidayso)
                    tmpinds=find(alldayso==unidayso(uuo));
                    tmpydatatt=ydata_dt(tmpinds);
                    obsData(uuo,2)=mean(tmpydatatt(~isnan(tmpydatatt)));
                    clear tmpydatatt;
                end
                
                alldays=floor(xdata);
                unidays=unique(alldays);
                simData(:,1)=unidays;
                
                for uu=1:length(unidays)
                    tmpinds=find(alldays==unidays(uu));
                    simData(uu,2)=mean(ydata(tmpinds));
                end
                
                [v, loc_obs, loc_sim] = intersect(obsData(:,1), simData(:,1));
                MatchedData_surf = [v obsData(loc_obs,2) simData(loc_sim,2)];
                clear simData obsData v loc* alldays unidays
                clear xdata_d ydata_d 
            end
        end

    end
    
end

end