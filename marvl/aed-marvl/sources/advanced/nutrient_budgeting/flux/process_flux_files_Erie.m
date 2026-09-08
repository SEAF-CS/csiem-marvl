clear; close all;

% flux file variable name order and node string IDs

wqfile = 'Flux_Order_WQ_Erie.xlsx';
nodefile = 'Flux_Nodestrings_Erie.xlsx';

%__________________________________________________________________________

disp('Running processing in Parrallel: Dont cancel...');

outdir='.\';

if ~exist(outdir,'dir')
    mkdir(outdir);
end

% define a date before the model starts
start_data=datenum(2013,04,30,00,00,00);

% define file path and output
 filename = '/Projects2/Erie/erie_tfv_aed_2013_ver012_rev0/Output_IP_V2/erie_12_k_NDIP_FLUX.csv';
 matout = './Flux_Erie_12KIP.mat';
 disp(filename);

 tfv_process_fluxfile_2022(filename,matout,wqfile,nodefile,start_data);
