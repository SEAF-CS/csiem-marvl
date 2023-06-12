function process_tide_filter

tidefile=tfv_readBCfile('BCs/Tide/Fremantle_Inflow_2019_ARMS.csv');

days=tidefile.Date;tempC=tidefile.wl;
alpha = 0.45;
exponentialMA = filter(alpha, [1 alpha-1], tempC);


fields=fieldnames(tidefile);

fileID = fopen('BCs/Tide/Fremantle_Inflow_2019_ARMS_filtered.csv','w');

%fprintf(fileID,'ISOTime,wl,Sal,Temp,TRACE_1,AGE,SS1,SS2,Oxy,Sil,Amm,Nit,FRP,FRP_ADS,DOC,POC,DON,PON,DOP,POP,DOCR,DONR,DOPR,CPOM,GRN,BGA,CRYPT,DIATOM,DINO,DINO_IN\n'); 

fprintf(fileID,'ISOTime,');
for i = 2:length(fields)
    if i == length(fields)
        fprintf(fileID,'%s\n',fields{i});
    else
        fprintf(fileID,'%s,',fields{i});
    end
end





for i=1:length(tidefile.Date)
    if mod(i,100)==0
        disp(i);
    end
fprintf(fileID,datestr(tidefile.Date(i),'dd/mm/yyyy HH:MM'));
fprintf(fileID,',%4.4f',exponentialMA(i));
  for j=3:length(fields)
    fprintf(fileID,',%4.4f',tidefile.(fields{j})(i));
  end
fprintf(fileID,'\n');
end
fclose(fileID);


hoursPerDay = 24;
coeff24hMA = ones(1, hoursPerDay)/hoursPerDay;
fDelay = (length(coeff24hMA)-1)/2;

plot(days,tempC, ...
     days-1/24,exponentialMA)

axis tight
legend('Hourly Tide', ...
       'Binomial Weighted Average', ...
       'Exponential Weighted Average','location','best')
ylabel('Tide (m)')
