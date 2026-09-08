% finds the coordinates of a nodestring from a 2dm.
% can create a points file for this
% 
% inputs :  twodm, the 2dm file
%           print, logical (default true) creates a points file csv named 
%                  the same as the 2dm with the suffix 'points'
%           varargin,  any particular node strings required
%
% example:   ns_points('example.2dm,false,2,4,5)
%
% this will return a cell array of the coordinates of all nodes in
% nodestrings 2, 4 and 5 without creating any points files for them
%
% TD Apr 2014

function pts = ns_points(twodm,print,varargin)
    MESH = RD2DM_v2(twodm);
    if nargin==2
        nns=length(MESH.NS);
        ns = 1:nns;
    else 
        for i=1:length(varargin);
            ns(i) = varargin{i};
            nns = length(ns);
        end
    end
    
    for p = 1:nns;
        ndstr = MESH.NS{1,ns(p)};
        pts{p} = MESH.ND(ndstr,2:3); 
        if print
            out = [ndstr ; pts{p}'];
            fid = fopen([strrep(twodm,'.2dm',['_points_' num2str(p) '.csv'])],'w');
            fprintf(fid,'%s,%s,%s \r\n','ID','X','Y');
            fprintf(fid,'%f,%f,%f \r\n',out);
        end
    end
    fclose all;
end



% /////// RD2DM_v2 ///////
%
% MESH = RD2DM_v2(twoDM)
%
% 
%
% Alex Byasse October 2013

function MESH = RD2DM_v2(twoDM)

MESH = struct();

fid = fopen(twoDM,'r');

s = textscan(fid,'%s','Delimiter','\n');
s = s{1};


s_e3t = s(strncmp('E3T',s,3));
s_e4q = s(strncmp('E4Q',s,3));
% s_e6t = s(strncmp('E6T',s,3));
% s_e8q = s(strncmp('E8Q',s,3));
% s_e9q = s(strncmp('E9Q',s,3));
s_nd = s(strncmp('ND',s,2));
s_ns = s(strncmp('NS',s,2));    

nns = size(s_ns,1);
NS = [];
k = 1;

for aa = 1:nns
    lin_ns = [s_ns{aa,1}]; lin_ns = strread(lin_ns,'%s','delimiter',' ');
    if str2double(lin_ns{end-1}) < 0
        lin_ns = char(lin_ns(2:end)); lin_ns = str2num(lin_ns)'; %#ok<ST2NM>
        NS = [NS lin_ns(1:end-1)];
        NS(end) = NS(end)*-1;
        NS_1{k,1} = NS;
        NS_2(k,1) = lin_ns(end);
        NS = [];
        k = k+1;
    else 
        lin_ns = char(lin_ns(2:end)); lin_ns = str2num(lin_ns)'; %#ok<ST2NM>
        NS = [NS lin_ns(1:end)];
    end
end

MESH.NS = NS_1(:,1)';
% MESH.NS_is = NS_2;

matcheck = [s_e3t{1,1}]; matcheck = strread(matcheck,'%s','delimiter',' ');
nc_e3t = length(matcheck);
if strcmp(matcheck{nc_e3t},''); matcheck(nc_e3t) = []; nc_e3t = length(matcheck); end

num_mat_layers = nc_e3t - 5;

format_e3t = ['%*s %u %u %u %u' repmat(' %u',[1 num_mat_layers])];
format_e4q = ['%*s %u %u %u %u %u' repmat(' %u',[1 num_mat_layers])];

C = sscanf(char(s_e3t)',format_e3t); 
MESH.E3T = reshape(C,[nc_e3t-1 length(s_e3t)])';

C = sscanf(char(s_e4q)',format_e4q); 
MESH.E4Q = reshape(C,[nc_e3t length(s_e4q)])'; 

C = sscanf(char(s_nd)','%*s %u %f %f %f'); 
MESH.ND = reshape(C,[4 length(s_nd)])';

end
