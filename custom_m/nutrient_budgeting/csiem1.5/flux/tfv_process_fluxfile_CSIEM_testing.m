%function tfv_process_fluxfile_2022(filename,matfile,wqfile,nodefile,start_date)

clear; close all;

wqfile = 'Flux_Order_WQ_CSIEM_ECO05.xlsx';
nodefile = 'Flux_Nodestrings_CSIEM.xlsx';

 filename = 'W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results\csiem_A001_20221101_20240401_ECO05_FLUX.csv';
 matfile = './Flux_CSIEM_ECO05.mat';

 start_date=datenum(2022,11,01,00,00,00);

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
    if str2double(tt{1})>9
        nodestrings(i) = {['NS',tt{1}]};
    else
    nodestrings(i) = tt(1);
    end
end

uni_NS = unique(nodestrings,'stable');

data = [];

inc = 2;

disp(['Number of NS: ' num2str(length(uni_NS)-1)]);

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