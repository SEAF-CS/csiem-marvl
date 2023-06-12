function merge_tidal_data_2019
tide = tfv_readBCfile('BCs/Tide/Fremantle_Inflow.csv');

arms = tfv_readBCfile('Ave_Fremantle_Inflow_2016to2026.csv');

headers = fieldnames(tide);

sss = find(tide.Date >= datenum(2019,01,01));

arms.BGA_RHO(1:length(arms.Date),1) = 1000;
arms.BGA_IN = arms.BGA * 16/106;
arms.BGA_IP = arms.BGA * 1/106;

for i = 1:length(sss)
    
    tt = find(arms.Date == tide.Date(sss(i)));
    
    %for j = 2:length(headers)
        tide.wl(sss(i)) = arms.wl(tt);
    %end
end



mkdir('Merged/');


fid = fopen(['BCs/Tide/Fremantle_Inflow_2019_ARMS.csv'],'wt');

fprintf(fid,'ISOTime,');

% Headers

for i = 2:length(headers)
    if i == length(headers)
        fprintf(fid,'%s\n',headers{i});
    else
        fprintf(fid,'%s,',headers{i});
    end
end

for i = 1:length(tide.Date)
    fprintf(fid,'%s,',datestr(tide.Date(i),'dd/mm/yyyy HH:MM'));
    
    for j = 2:length(headers)
        if j == length(headers)
            fprintf(fid,'%4.4f\n',tide.(headers{j})(i));
        else
            fprintf(fid,'%4.4f,',tide.(headers{j})(i));
        end
    end
end

fclose(fid);

%plot_bcfiles('Merged/');
