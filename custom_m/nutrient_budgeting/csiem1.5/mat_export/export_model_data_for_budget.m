clear all; close all;

addpath(genpath('Functions'));

% define NC file path
ncfile = 'Z:\csiem\model\csiem_model_tfvaed_1.6\outputs\results/csiem_A001_20201101_20211231_WQ_WQ.nc';
% ncfile = '/Projects2/csiem/model/csiem_model_tfvaed_1.6/outputs/results/csiem_A001_20201101_20211231_WQ_WQ.nc ';

% define output path
outdir = './extracted_ECO05/';

    if exist(outdir,'dir')
        mkdir(outdir);
    end
    disp(ncfile);
    
% define variables to export to mat format	
run('./varlist/varConfig_CSIEM_ECO05.m');

% shape file for study area
shp = shaperead('./gis/shape_for_export.shp');
%shp(1).Name='EB';

% import basic GEO info
    data = tfv_readnetcdf(ncfile,'names',{'idx2';'idx3';'cell_X';'cell_Y';'cell_A';'NL';'layerface_Z';'cell_Zb'});clear functions;
    names = tfv_infonetcdf(ncfile);
    mdata = tfv_readnetcdf(ncfile,'time',1);clear functions;
    Time = mdata.Time;
    
% get cell info
    for i = 1:length(shp)

        inpol = inpolygon(data.cell_X,data.cell_Y,shp(i).X,shp(i).Y);

        ttt = find(inpol == 1);
        fsite(i).theID = ttt;
        fsite(i).Name = shp(i).Name;
        
        
    end
    
    % go through variables to export
    for i = 1:length(vars)
        
        if sum(strcmpi(names,vars{i})) == 1
            
            disp(['Importing ',vars{i}]);
            
            tic
            mod = tfv_readnetcdf(ncfile,'names',vars(i));clear functions;
            
            for j = 1:length(shp)
                savedata = [];
                
                findir = [outdir,shp(j).Name,'/'];
                if ~exist(findir,'dir')
                    mkdir(findir);
                end
                %if ~exists([findir,vars{i},'.mat'],'file')
                
                savedata.X = data.cell_X(fsite(j).theID);
                savedata.Y = data.cell_Y(fsite(j).theID);
                
                
                
                
                if strcmpi(vars{i},'H') == 1 | strcmpi(vars{i},'D') == 1 | strcmpi(vars{i},'cell_A') == 1
                    savedata.(vars{i}) = mod.(vars{i})(fsite(j).theID,:);
                else
                    for k = 1:length(fsite(j).theID)
                        
                        ss = find(data.idx2 == fsite(j).theID(k));
                        
                        surfIndex = min(ss);
                        botIndex = max(ss);
                        savedata.(vars{i}).Top(k,:) = mod.(vars{i})(surfIndex,:);
                        savedata.(vars{i}).Bot(k,:) = mod.(vars{i})(botIndex,:);
                        
                        cell_num = fsite(j).theID(k);
                        cell_Area = data.cell_A(cell_num);
                        num_layers = data.NL(cell_num);
                        startlayer = sum(data.NL(1:cell_num-1))+cell_num;
                        endlayer = startlayer + num_layers;
                        layer_depths = data.layerface_Z(startlayer:endlayer,:);
                        
                        
                        for l = 1:length(ss)
                            
                            vol(l,:) = (layer_depths(l,:) - layer_depths(l+1,:)) * cell_Area;
                            mass(l,:) = vol(l) * mod.(vars{i})(ss(l),:);
                            
                        end
                        savedata.(vars{i}).ColumnMass(k,:) = sum(mass,1);
                        savedata.(vars{i}).Area(k) = cell_Area;
                        
                        clear vol mass;
                    end
                end
                
                savedata.Time = Time;
             %   disp(findir);
                save([findir,vars{i},'.mat'],'savedata','-mat','-v7.3');
                clear savedata;
                % end
            end
            toc
        end
    end




