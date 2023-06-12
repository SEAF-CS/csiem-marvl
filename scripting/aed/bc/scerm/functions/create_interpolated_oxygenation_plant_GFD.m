function create_interpolated_oxygenation_plant_GFD(oxy,headers,datearray)


Flow_t = oxy.GFD.flow;
Oxy_T = oxy.GFD.oxy;



for i = 1:length(headers)
    switch headers{i}
        case 'Flow'
            Flow = interp1(oxy.GFD.mdate(~isnan(Flow_t)),Flow_t(~isnan(Flow_t)),datearray);
            Flow(isnan(Flow)) = 0;
        case 'Oxy'
            Oxy = interp1(oxy.GFD.mdate(~isnan(Oxy_T)),Oxy_T(~isnan(Oxy_T)),datearray);
            Oxy(isnan(Oxy)) = 0;
        case 'Sal'
            Sal(1:length(datearray),1) = 10;
        case 'Temp'
            Temp(1:length(datearray),1) = 20;
        case 'ones',
            ones(1:length(datearray),1) = 1;
        case 'ISOTime'
            ISOTime = datearray;
        otherwise
            eval([headers{i},'(1:length(datearray),1) = 0;']);
    end
end


filename = 'Guildford_Oxygenation_Plant.csv';
outdir = 'BCs/OxyPlants/';



if ~exist(outdir,'dir')
    mkdir(outdir);
end

disp('Writing the inflow file');


fid = fopen([outdir,filename],'wt');

for i = 1:length(headers)
    if i == length(headers)
        fprintf(fid,'%s\n',headers{i});
    else
        fprintf(fid,'%s,',headers{i});
    end
end


for j = 1:length(ISOTime)
    for i = 1:length(headers)
        if i == length(headers)
            eval(['fprintf(fid,','''','%4.6f\n','''',',',headers{i},'(j));']);
        else
            if i == 1
                eval(['fprintf(fid,','''','%s,','''',',datestr(',headers{i},'(j),','''','dd/mm/yyyy HH:MM:SS','''','));']);
            else
                eval(['fprintf(fid,','''','%4.6f,','''',',',headers{i},'(j));']);
            end
        end
    end
end

fclose(fid);

