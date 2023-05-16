function [Willmott,Brier,BIAS,RMSE,COR_Coef, MAE] = Willmott_BR_SKILL(tmeas,Meas_Data,tmodel,Mod_Res,PLOT_SWitch)
%BIAS_SKILL Calculates the basic statistical Comparison of Measured Data Vs. Model Result including :BIAS,RMSE,COR_Coef,Mod_Skill
%written by HDF 18/07/2019
%   Detailed explanation goes here
%The time input should be datenum format


%crop the non overlaping times
iind=find(tmeas>=(tmodel(1)) & tmeas<=(tmodel(end))); % selects one day before and aafter the model to make sure the interp doesn't start and end to NAN
tmeas_trm=tmeas(iind);
Meas_DataTrm=Meas_Data(iind);

%% interpolate observation data over model data timeseries (hourly)
Meas_Interp=interp1(tmeas_trm,Meas_DataTrm,tmodel);
Num_nans=sum(isnan(Meas_Interp));
Meas_InterpTRM=Meas_Interp(~isnan(Meas_Interp));
% removing model results when there is no measure data in the time series
tmodel_Trm=tmodel(~isnan(Meas_Interp));
Mod_ResTrm=Mod_Res(~isnan(Meas_Interp));

%plot
if PLOT_SWitch
    figure;
    plot(tmodel,Mod_Res,'go');hold on;datetick
    plot(tmodel_Trm,Mod_ResTrm,'b.');
    plot(tmodel_Trm,Meas_InterpTRM,'r.');
    plot(tmodel(isnan(Meas_Interp)),Mod_Res(isnan(Meas_Interp)),'k*'); grid on
       legend ('Raw Model result','Trim Model result','Measured data','NAN Measured Data RemovedModel')
    
end

%% Bias
BIAS(1,1)=mean(Mod_ResTrm)-mean(Meas_InterpTRM);
%% RMSE
RMSE(1,1)=sqrt(mean((Mod_ResTrm-Meas_InterpTRM).^2));
%% MAE
MAE(1,1)= mean(abs(Mod_ResTrm-Meas_InterpTRM));

%% Correlation Coefficient
COR_Coef=corrcoef(Mod_ResTrm,Meas_InterpTRM);
COR_Coef=COR_Coef(1,2);
%% Brier Skill Score
Brier=1-(var((Mod_ResTrm-Meas_InterpTRM))/(var((Meas_InterpTRM-mean(Meas_InterpTRM)))));
Willmott=1-(sum((Mod_ResTrm-Meas_InterpTRM).^2)/(sum((abs(Mod_ResTrm-mean(Meas_InterpTRM))+abs(Meas_InterpTRM-mean(Meas_InterpTRM))).^2)));
% Mod_Skill(1,1)=1-sum((Mod_ResTrm-Meas_InterpTRM).^2)/sum((abs(Mod_ResTrm-mean(Meas_InterpTRM))+abs(Meas_InterpTRM-mean(Meas_InterpTRM))).^2);

disp(['BIAS=' num2str(BIAS,'%10.3f')])
disp(['RMSE=' num2str(RMSE,'%10.3f')])
disp(['MAE=' num2str(MAE,'%10.3f')])
disp(['Brier Skill Score: Bss=' num2str(Brier,'%10.3f')])
disp(['Willmott correlation factor: Wcf=' num2str(Willmott,'%10.3f')])
disp(['Correlation Coef: Cor_Coef=' num2str(COR_Coef,'%10.3f')])

end

