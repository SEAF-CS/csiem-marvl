% create synthetic data
clear all
close all

profile = '..\..\..\Complete_Model\TUFLOWFV\results\HYD_002_PROFILES.nc';
site = 'Point_3';
vars = {'H','SAL'};

var = sprintf('_%s',vars{:}); var = var(2:end);
out_name = sprintf('%s_%s_synthetic_data.csv',site,var);

% load the data
TMP = netcdf_get_var(profile);
x = convtime(TMP.ResTime);
x = round(x*24*4)./24./4;

for aa = 1:length(vars)
    y{aa} = TMP.(site).(vars{aa})(1,:);
    d = (max(y{aa})-min(y{aa}))*0.1;
    y{aa} = y{aa} + y{aa}*0.1.*rand(size(y{aa}));
end


fid = fopen(out_name,'w');
fprintf(fid,'Time');
for aa = 1:length(vars)
    fprintf(fid,',%s',vars{aa});
end
fprintf(fid,'\r\n');
for aa = 1:length(x)
    fprintf(fid,'%s',datestr(x(aa),'dd/mm/yyyy HH:MM:SS'));
    for bb = 1:length(vars)
        fprintf(fid,',%f',y{bb}(aa));
    end
    fprintf(fid,'\r\n');
end
fclose(fid);

