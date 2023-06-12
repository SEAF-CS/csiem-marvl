function create_interpolated_BC_for_inflow_NAR_v1(swan,headers,datearray,shift_AHD)

load Tidaldata.mat;


ISOTime = datearray;


filename = 'MSB_Depth.csv';
outdir = 'BCs/Tide/';



if ~exist(outdir,'dir')
    mkdir(outdir);
end

% %__________________________________________________________________________
%
% varname = 'height';
% 
% 
% [t_date,ind] = unique(data.bar.date);
% t_data = data.bar.height(ind);
% 
% [t_date1,ind] = unique(data.free.date);
% t_data1 = data.free.height(ind);
% 
% ss = find(~isnan(t_data) == 1);
% sss = find(~isnan(t_data1) == 1);
% 
% wl = interp1(t_date(ss),t_data(ss),datearray,'linear',mean(t_data(ss)));
% 
% wl1 = interp1(t_date1(sss),t_data1(sss),datearray,'linear',mean(t_data1(sss)));
% 
% ttt = find(wl < -50);
% wl(ttt) = wl1(ttt);
% 
% if shift_AHD% AHD shift
%     wl = wl - 0.74;
% else
%     wl(wl < 0.18) = 0.18;
% end

varname = 'Level';

wl = create_interpolated_dataset(swan,varname,'s616004','Bottom',datearray);


clear t_date t_data;

figure;plot(wl);title('wl');




clear t_date t_data;

%__________________________________________________________________________

% Tracers

SS2(1:length(datearray)) = 1;
SS3(1:length(datearray)) = 0;
SS4(1:length(datearray)) = 0;
SS5(1:length(datearray)) = 0;
SS6(1:length(datearray)) = 0;
SS7(1:length(datearray)) = 0;
SS8(1:length(datearray)) = 0;
SS9(1:length(datearray)) = 0;



%__________________________________________________________________________

varname = 'SAL';

Sal = create_interpolated_dataset(swan,varname,'s6167114','Bottom',datearray);

Sal(Sal > 50) = 0;


figure;plot(Sal);title('Sal');

clear t_date t_data;

%__________________________________________________________________________

varname = 'TEMP';

Temp = create_interpolated_dataset(swan,varname,'s6167114','Bottom',datearray);

figure;plot(Temp);title('Temp');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_OXY_OXY';

Oxy = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

figure;plot(Oxy);title('Oxygen');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_SIL_RSI';

Sil = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

figure;plot(Sil);title('Silica');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_NIT_AMM';

Amm = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);


figure;plot(Amm);title('Amm');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TN';

TN = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);


figure;plot(TN);title('TN');

clear t_date t_data;



%__________________________________________________________________________

varname = 'WQ_PHS_FRP';

FRP = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

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

DON_T = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

DON = DON_T .* 0.3;


figure;plot(DON);title('DON');

clear t_date t_data;



%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TKN';

TKN = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);


figure;plot(TKN);title('TKN');

clear t_date t_data;

%__________________________________________________________________________

varname = 'TON';

TON = TKN-Amm;

figure;plot(TON);title('TON');

%__________________________________________________________________________

varname = 'WQ_NIT_NIT';

Nit = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

figure;plot(Nit);title('NIT');

clear t_date t_data;


%__________________________________________________________________________

varname = 'PON';

PON = TN - Amm - Nit - DON;

PON(PON < 0) = 0;

figure;plot(PON);title('PON');

%__________________________________________________________________________

varname = 'WQ_DIAG_TOT_TP';

TP = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

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

DOC_T = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

DOC = DOC_T .* 0.4;

DOC(DOC < 0) = 0;


figure;plot(DOC);title('DOC');

clear t_date t_data;

%__________________________________________________________________________

varname = 'WQ_OGM_POC';

POC = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

POC(POC < 0) = 0;

figure;plot(POC);title('POC');

clear t_date t_data;


%__________________________________________________________________________

varname = 'TRC_SS1';


SS1_T = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);

SS1 = SS1_T * 0.3;
SS2 = SS1_T * 0.7;

figure;plot(SS1);title('SS1');

clear t_date t_data;

% ______________________________________________________________________

varname = 'WQ_DIAG_PHY_TCHLA';

CHLA = create_interpolated_dataset(swan,varname,'s6160262','Bottom',datearray);


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

varname = 'TRACE_2';

TRACE_2(1:length(GRN),1) = 0;


figure;plot(TRACE_2);title('TRACE_2');
% ______________________________________________________________________

varname = 'TRACE_3';

TRACE_3(1:length(GRN),1) = 1;


figure;plot(TRACE_3);title('TRACE_3');

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