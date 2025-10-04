clear; close all;

model=load('extracted_2022_restart.mat');
wq=load('extracted_2022_restart.mat');

bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

%%
band6_mod=model.output.Kwinana.WQ_DIAG_OAS_A_IOP3_BAND6.profile;

wq_model =wq.output.Kwinana.WQ_OGM_DOC.profile;

a=band6_mod./wq_model;

figure(1);
clf;

subplot(3,1,1);
plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,band6_mod(1,:));
legend('output');
datearray=datenum(2022,1:3:13,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,2);
plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,wq_model(1,:));
legend('DOC');
datearray=datenum(2022,1:3:13,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);
plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,a(1,:));
legend('IOP3');
datearray=datenum(2022,1:3:13,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

%%
band6_mod=model.output.Kwinana.WQ_DIAG_OAS_A_IOP4_BAND6.profile;

wq_model =wq.output.Kwinana.WQ_NCS_SS1.profile;

a=band6_mod./wq_model;

figure(2);
clf;

subplot(3,1,1);
plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,band6_mod(1,:));
legend('output');
datearray=datenum(2022,1:3:13,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,2);
plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,wq_model(1,:));
legend('SS1');
datearray=datenum(2022,1:3:13,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));

subplot(3,1,3);
plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,a(1,:));
legend('IOP4');
datearray=datenum(2022,1:3:13,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));