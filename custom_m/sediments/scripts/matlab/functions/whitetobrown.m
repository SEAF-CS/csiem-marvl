% WHITETOBROWN

function map = whitetobrown(cont,varargin)
    map = 255*ones(3,cont);
    
    if nargin>1
        wi = min(varargin{1},round(cont./4));
        wi = max(wi,1);
    else
        wi = round(cont./10);
    end
    bi = round(cont./4)+round(cont./20);
    gi = round(cont./2);
    yi = round(cont*3./4);
    bri = cont;
        
    idxs = [wi,bi,gi,yi,bri];
    clrsw = [255;255;255];
    clrsb = [0;255;255];
    clrsg = [0;255;0];
    clrsy = [255;255;0];
    clrsbr = [175;165;130];
    clr = [clrsw,clrsb,clrsg,clrsy,clrsbr];
    nrng = wi:cont;
    for i=1:3
    nmp(i,:) = interp1(idxs,clr(i,:),nrng);
    end
    
    map(:,wi:cont) = nmp;
    map= map'./255;
    map(map>1) = 1;
    map(map<0) = 0;
end