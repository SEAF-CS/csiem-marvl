function replace_flows_with_calculated

thefiles = {...
    'Bayswater_Inflow.csv',...
    'Bennett_Inflow.csv',...
    'Ellenbrook_Inflow.csv',...
    'Helena_Inflow.csv',...
    'Jane_Inflow.csv',...
    };

theflows = {...
    'Daily_Bayswater_012016_012020.csv',...
    'Daily_Bennet_012015_012020 .csv',...
    'Daily_EllenBrook_112018_012020.csv',...
    'Daily_Helena_122014_112017.csv',...
    'Daily_Jane_122014_012020.csv',...
    };

for bb = 1:length(thefiles)
    


filename = thefiles{bb};%'Bayswater_Inflow.csv';
outdir = 'BCs/Flow/';

[snum,sstr] = xlsread(['Calc Flow/',theflows{bb}],'A2:B100000');

mdate = [];

for i = 1:length(sstr)
    mdate(i,1) = datenum(sstr{i},'dd/mm/yyyy');
end
disp(thefiles{bb});

data = tfv_readBCfile([outdir,filename]);

for i = 1:length(mdate)
    ss = find(data.Date == mdate(i));
    
    if ~isempty(ss)
        data.Flow(ss(1)) = snum(i,1);
    end
end


%%%______________________________

headers = fieldnames(data);

fid = fopen([outdir,filename],'wt');

fprintf(fid,'ISOTime,');

% Headers

for i = 2:length(headers)
    if i == length(headers)
        fprintf(fid,'%s\n',headers{i});
    else
        fprintf(fid,'%s,',headers{i});
    end
end

for i = 1:length(data.Date)
    fprintf(fid,'%s,',datestr(data.Date(i),'dd/mm/yyyy HH:MM'));
    
    for j = 2:length(headers)
        if j == length(headers)
            fprintf(fid,'%4.4f\n',data.(headers{j})(i));
        else
            fprintf(fid,'%4.4f,',data.(headers{j})(i));
        end
    end
end

fclose(fid);
end