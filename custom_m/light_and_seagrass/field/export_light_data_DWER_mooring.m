clear; close all;

inDir='E:\AED Dropbox\AED_Cockburn_db\CSIEM\Data\data-warehouse\mat\agency\';

files=dir([inDir,'csiem_DWER_public.mat']);
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
            if strfind(vars{vv},'OAS')
                disp('found');
                output.(agency).(sites{ss}).(vars{vv})=csiem.(sites{ss}).(vars{vv});
            end
%             if strfind(vars{vv},'BAND_')
%                 disp('found');
%                 output.(agency).(sites{ss}).(vars{vv})=csiem.(sites{ss}).(vars{vv});
%             end
%             if strfind(vars{vv},'_PAR')
%                 disp('found');
%                 output.(agency).(sites{ss}).(vars{vv})=csiem.(sites{ss}).(vars{vv});
%             end


           % varinfo.vars{inc}=vars{vv};
           % varinfo.sites{inc}=sites{ss};
           % varinfo.agency{inc}=agency;
           % inc=inc+1;
        end
    end

end

save('light_data_DWERmooring','output','-mat','-v7.3')

%% check time and size

fileID = fopen('check_time_DWERmooring.csv','w');
fprintf(fileID,'%s\n','vars,agency,site,start,end');

agencys=fieldnames(output);

    for ss=1:length(agencys)
        disp(agencys{ss});

        sites=fieldnames(output.(agencys{ss}));

        for aa=1:length(sites)
            vars=fieldnames(output.(agencys{ss}).(sites{aa}));

        for vv=1:length(vars)
            data=output.(agencys{ss}).(sites{aa}).(vars{vv}).Data;
            time=output.(agencys{ss}).(sites{aa}).(vars{vv}).Date;

            fprintf(fileID,'%s,',vars{vv});
            fprintf(fileID,'%s,',agencys{ss});
            fprintf(fileID,'%s,',sites{aa});
            fprintf(fileID,'%s,',datestr(time(1),'yyyy-mm-dd'));
            fprintf(fileID,'%s\n',datestr(time(end),'yyyy-mm-dd'));
        end
        end
    end


fclose(fileID);


