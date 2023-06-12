function create_interpolated_BC_for_inflow_Fremantle(swan,headers,datearray,shift_AHD)

load Tidaldata.mat;


ISOTime = datearray;



filename = 'Fremantle_Inflow.csv';
outdir = 'BCs/Tide/';



if ~exist(outdir,'dir')
    mkdir(outdir);
end

% %__________________________________________________________________________
% 
varname = 'height';


[t_date,ind] = unique(data.bar.date);
t_data = data.bar.height(ind);

[t_date1,ind] = unique(data.free.date);
t_data1 = data.free.height(ind);

ss = find(~isnan(t_data1) == 1);
sss = find(~isnan(t_data) == 1);

wl = interp1(t_date1(ss),t_data1(ss),datearray,'linear',mean(t_data1(ss)));

wl1 = interp1(t_date(sss),t_data(sss),datearray,'linear',mean(t_data(sss)));

ttt = find(wl < -50);
wl(ttt) = wl1(ttt);

if shift_AHD% AHD shift
    wl = wl - 0.74;
else
    wl(wl < 0.18) = 0.18;
end

figure;plot(wl);title('wl');




clear t_date t_data;







%__________________________________________________________________________

varname = 'SAL';


Sal = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% Sal = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

figure;plot(Sal);title('Sal');

clear t_date t_data;

%__________________________________________________________________________

varname = 'TEMP';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% Temp = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

Temp = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(Temp);title('Temp');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_OXY_OXY';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% Oxy = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

Oxy = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(Oxy);title('Oxygen');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_SIL_RSI';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% Sil = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));


Sil = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(Sil);title('Silica');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_NIT_AMM';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% Amm = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

Amm = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(Amm);title('Amm');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TN';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% TN = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

TN = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(TN);title('TN');

clear t_date t_data;



%__________________________________________________________________________

varname = 'WQ_PHS_FRP';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% FRP = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

FRP = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(FRP);title('FRP');

clear t_date t_data;

%__________________________________________________________________________
%BB

varname = 'FRP_ADS';


FRP_ADS = FRP .* 0.1;

figure;plot(FRP_ADS);title('FRP_ADS');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_OGM_DON';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% DON_T = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));
% 
% DON = DON_T .* 0.3;

DON_T = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);

DON = DON_T .* 0.3;


figure;plot(DON);title('DON');

clear t_date t_data;



%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TKN';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% TKN = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

TKN = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(TKN);title('TKN');

clear t_date t_data;

%__________________________________________________________________________

varname = 'TON';

TON = TKN-Amm;

figure;plot(TON);title('TON');

%__________________________________________________________________________

varname = 'WQ_NIT_NIT';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.1);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% Nit = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

Nit = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(Nit);title('NIT');

clear t_date t_data;


%__________________________________________________________________________

varname = 'PON';

PON = TN - Amm - Nit - DON;

PON(PON < 0) = 0;

figure;plot(PON);title('PON');

%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TP';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% TP = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

TP = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


figure;plot(TP);title('TP');

clear t_date t_data;


%__________________________________________________________________________

varname = 'DOP';

DOP = (TP-FRP-FRP_ADS).* 0.4;

DOP(DOP < 0) = 0;


figure;plot(DOP);title('DOP');

%__________________________________________________________________________

varname = 'POP';

POP = (TP-FRP-FRP_ADS).* 0.5;

POP(POP < 0) = 0;


figure;plot(POP);title('POP');

%__________________________________________________________________________

varname = 'WQ_OGM_DOC';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% DOC_T = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));
% 
% DOC = DOC_T .* 0.4;
% 
% DOC(DOC < 0) = 0;

DOC_T = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);

DOC = DOC_T .* 0.4;

DOC(DOC < 0) = 0;


figure;plot(DOC);title('DOC');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_OGM_POC';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% POC = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));
% 
% POC(POC < 0) = 0;
POC = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);

POC(POC < 0) = 0;

figure;plot(POC);title('POC');

clear t_date t_data;


%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TSS';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.5);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% SS1_T = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

SS1_T = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);


SS1 = SS1_T * 0.3;
SS2 = SS1_T * 0.7;


figure;plot(SS1);title('SS1');

clear t_date t_data;

% ______________________________________________________________________

varname = 'WQ_DIAG_PHY_TCHLA';

% t_depth = swan.s6160258.(varname).Depth;
% tt = find(t_depth > -0.1);
% 
% [t_date,ind] = unique(swan.s6160258.(varname).Date(tt));
% t_data = swan.s6160258.(varname).Data(tt(ind));
% 
% ss = find(~isnan(t_data) == 1);
% 
% CHLA = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));

CHLA = create_interpolated_dataset(swan,varname,'s6160258','Bottom',datearray);



GRN = CHLA .* 0.04;


GRN(GRN < 0) = 0;


figure;plot(GRN);title('GRN');

clear t_date t_data;


% ______________________________________________________________________

varname = 'BGA';

BGA = CHLA .* 0.03;

BGA(BGA < 0) = 0;


figure;plot(BGA);title('BGA');

% ______________________________________________________________________

varname = 'FDIAT';

FDIAT = CHLA .* 0.08;

FDIAT(FDIAT < 0) = 0;


figure;plot(FDIAT);title('FDIAT');

% ______________________________________________________________________

varname = 'MDIAT';

MDIAT = CHLA .* 0.55;

MDIAT(MDIAT < 0) = 0;


figure;plot(MDIAT);title('MDIAT');

% ______________________________________________________________________

varname = 'KARLO';

KARLO = CHLA .* 0.3;

KARLO(KARLO < 0) = 0;


figure;plot(KARLO);title('KARLO');

% ______________________________________________________________________

varname = 'TRACE_1';

TRACE_1(1:length(GRN),1) = 0;


figure;plot(TRACE_1);title('TRACE_1');

% ______________________________________________________________________

varname = 'AGE';

AGE(1:length(GRN),1) = 0;


figure;plot(AGE);title('AGE');

% ______________________________________________________________________

varname = 'DOCR';

DOCR = DOC_T .* 0.6;

DOCR(DOCR < 0) = 0;

figure;plot(DOCR);title('DOCR');

% ______________________________________________________________________

varname = 'DONR';

DONR = DON_T .* 0.7;

DONR(DONR < 0) = 0;

figure;plot(DONR);title('DONR');

% ______________________________________________________________________

varname = 'DOPR';

DOPR = (TP - FRP - FRP_ADS) .* 0.1;

DOPR(DOPR < 0) = 0;

figure;plot(DOPR);title('DOPR');

% ______________________________________________________________________

varname = 'CPOM';

CPOM = POC .* 0.05;

CPOM(CPOM < 0) = 0;

figure;plot(CPOM);title('CPOM');

% ______________________________________________________________________

CRYPT = FDIAT; 

DIATOM = MDIAT;

DINO = KARLO; 
%_______________________________________________________________________

%Reduced totals for replication

ones(1:length(datearray)) = 1;
zeroes(1:length(datearray)) = 0;
CHLA(CHLA < 0) = 0;
POC_T = POC;
POC_T(POC_T < 0) = 0;
PON_T = PON;
PON_T(PON_T < 0) = 0;
TSS = SS1_T;
TSS(TSS < 0) = 0;
OP = (TP-FRP-FRP_ADS);
OP(OP < 0) = 0;
% ________________________________

FDIAT_IN = FDIAT * 16/106;
FDIAT_IP = FDIAT * 1/106;
FDIAT_RHO(1:length(GRN)) = 1000;

MDIAT_IN = MDIAT * 16/106;
MDIAT_IP = MDIAT * 1/106;
MDIAT_RHO(1:length(GRN)) = 1000;

KARLO_IN = KARLO * 16/106;
KARLO_IP = KARLO * 1/106;
KARLO_RHO(1:length(GRN)) = 1000;

DINO_IN = DINO * 16/106;
DINO_IP = DINO * 1/106;
DINO_RHO(1:length(GRN)) = 1000;

DIATOM_IN = DIATOM * 16/106;
DIATOM_IP = DIATOM * 1/106;
DIATOM_RHO(1:length(GRN)) = 1000;

CRYPT_IN = CRYPT * 16/106;
CRYPT_IP = CRYPT * 1/106;
CRYPT_RHO(1:length(GRN)) = 1000;

CHLA_IN = CHLA * 16/106;
CHLA_IP = CHLA * 1/106;
CHLA_RHO(1:length(GRN)) = 1000;

BGA_IN = BGA * 16/106;
BGA_IP = BGA * 1/106;
BGA_RHO(1:length(GRN)) = 1000;

GRN_IN = GRN * 16/106;
GRN_IP = GRN * 1/106;
GRN_RHO(1:length(GRN)) = 1000;
% EXPORT ROUTINE___________________________________________________________

disp('Writing the inflow file');


fid = fopen([outdir,filename],'wt');

% Headers

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