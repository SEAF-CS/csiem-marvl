function fdata = marvl_load_fielddata(master)

for ff=1:length(master.fielddata_files)
    matfile=[master.fielddata_folder,master.fielddata_files{ff},'.mat'];
    disp(['loading field data: ',matfile, ' ...']);
    tmp=load(matfile,master.fielddata);

    if ff==1
        fdata=tmp.(master.fielddata);
    else
        fields=fieldnames(tmp.(master.fielddata));
        
        for f=1:length(fields)
            fdata.(fields{f})=tmp.(master.fielddata).(fields{f});
        end
    end
    clear tmp;
end

% find unique agency names
sites=fieldnames(fdata);
inc=1;
%Agencys={};
for ss=1:length(sites)
    vars=fieldnames(fdata.(sites{ss}));
	
	
    for vv=1:length(vars)
        str=fdata.(sites{ss}).(vars{vv}).Agency;
        Agencys{inc}=str;
        inc=inc+1;
    end
end

fdata.agencynames=unique(Agencys);
%save('datacheck.mat','fdata','ss','sites','vars','-mat','-v7.3');
