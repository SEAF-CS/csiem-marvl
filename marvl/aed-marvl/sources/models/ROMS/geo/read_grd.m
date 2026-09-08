function [xs,ys,ndat] = read_grd(fil,xg,yg)

[~,~,endian] = computer;
if strcmpi(endian,'L')
    fid = fopen(fil);
else
    fid = fopen(fil,'l');
end

header = fread(fid,9,'ubit8=>char');
dims = fread(fid,[1,2],'int16=>double');
xlim = fread(fid,2,'double=>double'); %64
ylim = fread(fid,2,'double=>double'); %64
zlim = fread(fid,2,'single=>double'); %32

fseek(fid,1023,'bof');
typ = fread(fid,1,'ubit8=>double');
if typ==0
    data = fread(fid,dims,'uint16=>double');
elseif typ==2
    data = fread(fid,dims,'uint8=>double');
end
fclose(fid);

rng = 1:65535;
zrng = double(zlim(1):diff(zlim)/65534:zlim(2));

xs = xlim(1):diff(xlim)/(dims(1)-1):xlim(2);
ys = ylim(1):diff(ylim)/(dims(2)-1):ylim(2);
is = find(xs>min(xg) & xs<max(xg));
js = find(ys>min(yg) & ys<max(yg));

xs = xs(is);
ys = ys(js);

data = flipud(data');
data = data(js,is);

ndat = interp1(rng,zrng,data);

end