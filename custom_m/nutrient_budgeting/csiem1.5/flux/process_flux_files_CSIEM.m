clear; close all;

% flux file variable name order and node string IDs

wqfile = 'Flux_Order_WQ_CSIEM_1p5.xlsx';
nodefile = 'Flux_Nodestrings_CSIEM.xlsx';

%__________________________________________________________________________

disp('Running processing in Parrallel: Dont cancel...');

outdir='.\';

if ~exist(outdir,'dir')
    mkdir(outdir);
end

% define a date before the model starts
% start_date=datenum(2022,11,01,00,00,00);
start_date=datenum(2020,11,01,00,00,00);
% define file path and output
%  filename = 'W:\csiem\Model\TFV\csiem_model_tfvaed_2.0\outputs\results\csiem_A001_20221101_20240401_WQ_test_3round_FLUX.csv';
  filename = '/Projects2/csiem/model/csiem_model_tfvaed_1.6/outputs/results/csiem_A001_20201101_20211231_WQ_FLUX.csv';
 matout = './Flux_CSIEM_1p5.mat';
 disp(filename);

 tfv_process_fluxfile_CSIEM(filename,matout,wqfile,nodefile,start_date);
