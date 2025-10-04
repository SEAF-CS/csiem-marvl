clear; close all;

inDir='E:\AED Dropbox\AED_Cockburn_db\CSIEM\Data\data-warehouse\mat\agency\';

files=dir([inDir,'*.mat']);
%%
inc=1;
for i=1:length(files)
    infile=[inDir,files(i).name];
    disp(infile);
    load(infile);

    C = strsplit(files(i).name,'_');
    agency=C{2};

    sites=fieldnames(csiem);

    for ss=1:length(sites)
        disp(sites{ss});
        vars=fieldnames(csiem.(sites{ss}));

        for vv=1:length(vars)
            varinfo.vars{inc}=vars{vv};
            varinfo.sites{inc}=sites{ss};
            varinfo.agency{inc}=agency;
            inc=inc+1;
        end
    end

end

%% sort vars

allvars=varinfo.vars;
[uc, ~, idc] = unique(allvars);

fileID = fopen('IMOS_vars.csv','w');
fprintf(fileID,'%s\n','vars,counts');
for i=1:length(uc)
    fprintf(fileID,'%s,',uc{i});
    fprintf(fileID,'%6.2f\n',sum(idc==i));
end
fclose(fileID);

%% check sites

fileID = fopen('IMOS_vars_sites.csv','w');
fprintf(fileID,'%s\n','vars,sitename,X,Y');


varsID=[77:94 96:104 107];
vars=varinfo.vars;
sites=varinfo.sites;
agency=varinfo.agency;

for vv=1:length(varsID)
    var2s=uc{varsID(vv)};

        Index = find(contains(vars,var2s));

        if ~isempty(Index)
            for j=1:length(Index)
            fprintf(fileID,'%s,',var2s);
            fprintf(fileID,'%s,',sites{Index(j)});
           % fprintf(fileID,'%6.6f,',csiem.(sites{ss}).(var2s).X);
            fprintf(fileID,'%s\n',agency{Index(j)});
            end
        end
end

fclose(fileID);

% %% export data
% 
% for vv=1:length(varsID)
%     var2s=uc{varsID(vv)};
%     data=[];
%     for ss=1:length(sites)
% 
%         vars=fieldnames(csiem.(sites{ss}));
% 
%         Index = find(contains(vars,var2s));
% 
%         if ~isempty(Index)
%             data.(sites{ss}).(var2s)=csiem.(sites{ss}).(var2s);
%         end
%     end
% 
%     save(['IMOS_data_',var2s,'.mat'],'data','-mat');
% end