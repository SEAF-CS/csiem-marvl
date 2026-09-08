
%%
 
infolder=['./mat_export/extracted_12KIP/EB/'];
disp(infolder);

varname='MAG_SLOUGHXNC';

tmp1=load([infolder,'WQ_DIAG_MAG_IN_BEN.mat']);
tmp11=tmp1.savedata.WQ_DIAG_MAG_IN_BEN.Bot;

tmp2=load([infolder,'WQ_DIAG_MAG_SLG_BEN.mat']);
tmp22=tmp2.savedata.WQ_DIAG_MAG_SLG_BEN.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MAG_SLOUGHXNC.Area=tmp1.savedata.WQ_DIAG_MAG_IN_BEN.Area;
savedata.MAG_SLOUGHXNC.Bot=tmp3;

outfile=[infolder,'MAG_SLOUGHXNC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;


varname='MAG_SLOUGHXPC';

tmp1=load([infolder,'WQ_DIAG_MAG_IP_BEN.mat']);
tmp11=tmp1.savedata.WQ_DIAG_MAG_IP_BEN.Bot;

tmp2=load([infolder,'WQ_DIAG_MAG_SLG_BEN.mat']);
tmp22=tmp2.savedata.WQ_DIAG_MAG_SLG_BEN.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MAG_SLOUGHXPC.Area=tmp1.savedata.WQ_DIAG_MAG_IP_BEN.Area;
savedata.MAG_SLOUGHXPC.Bot=tmp3;

outfile=[infolder,'MAG_SLOUGHXPC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;


%%
disp('processing MPB_GPPXNC ...');
varname='MPB_GPPXNC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_GPP.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_GPP.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XNC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XNC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_GPPXNC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_GPP.Area;
savedata.MPB_GPPXNC.Bot=tmp3;

outfile=[infolder,'MPB_GPPXNC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

disp('processing MPB_RSPXNC ...');
varname='MPB_RSPXNC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_RSP.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_RSP.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XNC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XNC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_RSPXNC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_RSP.Area;
savedata.MPB_RSPXNC.Bot=tmp3;

outfile=[infolder,'MPB_RSPXNC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;


disp('processing MPB_RESXNC ...');
varname='MPB_RESXNC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_RES.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_RES.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XNC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XNC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_RESXNC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_RES.Area;
savedata.MPB_RESXNC.Bot=tmp3;

outfile=[infolder,'MPB_RESXNC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

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

disp('processing PHY_SETXNC ...');
varname='PHY_SETXNC';

tmp1=load([infolder,'WQ_DIAG_PHY_SET.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_SET.Column;
tmp12=tmp1.savedata.WQ_DIAG_PHY_SET.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XNC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XNC.Bot;

tmp3=tmp11.*tmp22;
tmp31=tmp12.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.PHY_SETXNC.Area=tmp1.savedata.WQ_DIAG_PHY_SET.Area;
savedata.PHY_SETXNC.Column=tmp3;
savedata.PHY_SETXNC.Bot=tmp31;

outfile=[infolder,'PHY_SETXNC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

%%

disp('processing MPB_GPPXPC ...');
varname='MPB_GPPXPC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_GPP.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_GPP.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XPC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XPC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_GPPXPC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_GPP.Area;
savedata.MPB_GPPXPC.Bot=tmp3;

outfile=[infolder,'MPB_GPPXPC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

disp('processing MPB_RSPXPC ...');
varname='MPB_RSPXPC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_RSP.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_RSP.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XPC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XPC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_RSPXPC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_RSP.Area;
savedata.MPB_RSPXPC.Bot=tmp3;

outfile=[infolder,'MPB_RSPXPC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

disp('processing MPB_RESXPC ...');
varname='MPB_RESXPC';

tmp1=load([infolder,'WQ_DIAG_PHY_MPB_RES.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_MPB_RES.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XPC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XPC.Bot;

tmp3=tmp11.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.MPB_RESXPC.Area=tmp1.savedata.WQ_DIAG_PHY_MPB_RES.Area;
savedata.MPB_RESXPC.Bot=tmp3;

outfile=[infolder,'MPB_RESXPC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;

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

disp('processing PHY_SETXPC ...');
varname='PHY_SETXPC';

tmp1=load([infolder,'WQ_DIAG_PHY_SET.mat']);
tmp11=tmp1.savedata.WQ_DIAG_PHY_SET.Column;
tmp12=tmp1.savedata.WQ_DIAG_PHY_SET.Bot;

tmp2=load([infolder,'WQ_DIAG_PHY_MPB_XPC.mat']);
tmp22=tmp2.savedata.WQ_DIAG_PHY_MPB_XPC.Bot;

tmp3=tmp11.*tmp22;
tmp31=tmp12.*tmp22;

savedata.Time=tmp1.savedata.Time;
savedata.PHY_SETXPC.Area=tmp1.savedata.WQ_DIAG_PHY_SET.Area;
savedata.PHY_SETXPC.Column=tmp3;
savedata.PHY_SETXPC.Bot=tmp31;

outfile=[infolder,'PHY_SETXPC.mat'];
save(outfile,'savedata','-mat');clear savedata tmp*;
