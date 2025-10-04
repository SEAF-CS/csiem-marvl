clear; close all;

model=load('extracted_2023.mat');
field=load('..\field\light_spetrum_KwinanaShelf_uW.mat');

bands_str={'280','300','350','380','410','440','490','510','550','590','635','660','700','780','850','1100'};
bands=    [280., 300., 350., 380., 410.,440.,490.,510.,550.,590.,635.,660.,700., 780., 850., 1100. ];
WL2=      [398 448 470 524 554 590 628 656 699];

%%
band6_mod=model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND4.profile+model.output.Kwinana.WQ_DIAG_OAS_DIR_BAND4.profile;
band2_mea=field.spectrum.WL_398_uW;

clf;
plot(band2_mea.Date+8/24,band2_mea.Data/100);
hold on;

plot(model.output.Kwinana.WQ_DIAG_OAS_DIF_BAND6.date,band6_mod(4,:));
legend('obs','modelled');
datearray=datenum(2022,11:3:25,1);
set(gca,'XTick',datearray,'XTickLabel',datestr(datearray,'mmm/yyyy'));