
%%
 
% infolder=['Z:\csiem\csiem-marvl-dev\others\mat_export_CSIEM_ECO05\extracted_csiem1p5\CS-Region\'];
infolder=['G:\CSIEM\1.6.0\outputs\sh\2023B\extracted_v1p5\CS-Region\'];

disp(infolder);

%%

disp('processing MPB_BENXNC ...');
varname='MPB_BENXNC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_BEN.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_BEN.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XNC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XNC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_BENXNC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_BEN.Area;
savedata.MPB_BENXNC.Bot=tmp3;

outfile=[infolder,'MPB_BENXNC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

%%

disp('processing MPB_BENXPC ...');
varname='MPB_BENXPC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_BEN.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_BEN.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XPC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XPC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_BENXPC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_BEN.Area;
savedata.MPB_BENXPC.Bot=tmp3;

outfile=[infolder,'MPB_BENXPC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

