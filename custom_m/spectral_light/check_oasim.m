
clear; close all;

modeldata=load('W:\csiem\csiem-marvl-dev\others\CSIEM20_reporting\light\extracted_2023_light.mat');
bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

vars={'SS1','TCHLA','POC','DOC'};
varnames={'WQ_NCS_SS1','WQ_DIAG_PHY_TCHLA','WQ_OGM_POC','WQ_OGM_DOC'};

iop_types=[10 9 6 8];