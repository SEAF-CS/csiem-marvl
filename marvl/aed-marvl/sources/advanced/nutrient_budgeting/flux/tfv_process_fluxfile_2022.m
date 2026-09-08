function tfv_process_fluxfile_2022(filename,matfile,wqfile,nodefile,start_date)

% clear; close all;
% 
% wqfile = 'Flux_Order_WQ_MER_2022.xlsx';
% nodefile = 'Flux_Nodestrings_MER_noDIR_2022.xlsx';
% 
% scens={'basecase','Scen1','Scen2','Scen3','Scen4'};
% mDir='W:\CDM2022\eWater2022-scenarios\';
% i=1;    
%  filename = [mDir,'output_',scens{i},'\Coorong_BMT_BK_20170701_20210701_LT13_newMZ_FLUX.csv'];
%  matfile = ['.\Flux_',scens{i},'_noDIR.mat'];

[~,col_headers] = xlsread(wqfile,'A2:A1000');

%%
fid = fopen(filename,'rt');

headers = strsplit(fgetl(fid),',');

num_cols = length(headers);

frewind(fid)
x  = num_cols;
textformat = [repmat('%s ',1,x)];
% read single line: number of x-values
datacell = textscan(fid,textformat,'Headerlines',1,'Delimiter',',');
fclose(fid);

% Dates are the first column.
%disp('************** Processing Dates... *********************************');
mDates = datenum(datacell{:,1},'dd/mm/yyyy HH:MM:SS');
%disp('************** Finished Dates...   *********************************');

%%
nodestrings = {};
for i = 1:length(headers)
    tt = strsplit(headers{i},'_');
    nodestrings(i) = tt(1);
end

uni_NS = unique(nodestrings,'stable');

data = [];

inc = 2;

disp(['Number of NS: ' num2str(length(uni_NS))]);

%%
for i = 2:length(uni_NS)
    disp(uni_NS(i));
    for j = 1:length(col_headers)
        data.(uni_NS{i}).(col_headers{j}) = str2double(datacell{inc});
        inc = inc + 1;
        data.(uni_NS{i}).mDate = mDates;
    end
end

%%
[nnum,nstr] = xlsread(nodefile,'A2:D21');

nodes = fieldnames(data);

flux = [];

for i = 1:length(nodes)
    disp(nodes{i});
    ss = find(strcmp(nstr(:,1),nodes{i}) == 1);
    flux.(nstr{ss,3}) = data.(nodes{i});
    
    vars = fieldnames(flux.(nstr{ss,3}));
    
    for ii = 1:length(vars)
        if strcmp(vars{ii},'mDate') == 0
          flux.(nstr{ss,3}).(vars{ii}) =  flux.(nstr{ss,3}).(vars{ii}) * nnum(ss); 
        end
    end
end


% if isfield(flux,'NS14')
%     flux = rmfield(flux,'NS14');
%     disp('Removing Nodestring 14.........');
% end


sites = fieldnames(flux);
for i = 1:length(sites)
    disp(sites{i});
    vars = fieldnames(flux.(sites{i}));
    sss = find(flux.(sites{i}).mDate >= start_date);
    for j = 1:length(vars)
        flux1.(sites{i}).(vars{j}) = flux.(sites{i}).(vars{j})(sss);
    end
end
flux = [];
flux = flux1;

save(matfile,'flux','-mat');