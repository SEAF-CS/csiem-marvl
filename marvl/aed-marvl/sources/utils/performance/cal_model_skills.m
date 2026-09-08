function [errorMatrix,T,str] = cal_model_skills(MatchedData,config,shp,site,loadname,errorMatrix)   

MatchedData_obs=[];
MatchedData_sim=[];
str={};
SkillNames={};
SkillScores={};
sitename = regexprep(shp(site).Name,' ','_');

layer_obs={};
layer_sim={};

if iscell(MatchedData)
    for ll = 1:length(MatchedData)
        if isempty(MatchedData{ll})
            continue;
        end
        layer_obs{end+1} = MatchedData{ll}(:,2); %#ok<*AGROW>
        layer_sim{end+1} = MatchedData{ll}(:,3);
        MatchedData_obs=[MatchedData_obs; MatchedData{ll}(:,2)];
        MatchedData_sim=[MatchedData_sim; MatchedData{ll}(:,3)];
    end
else
    if (exist('MatchedData','var') && ~isempty(MatchedData))
        layer_obs{end+1} = MatchedData(:,2);
        layer_sim{end+1} = MatchedData(:,3);
        MatchedData_obs=[MatchedData_obs; MatchedData(:,2)];
        MatchedData_sim=[MatchedData_sim; MatchedData(:,3)];
    end
end

if isempty(MatchedData_obs)
    MatchedData_obs = [];
    MatchedData_sim = [];
else
    ind=~isnan(MatchedData_obs) & ~isnan(MatchedData_sim);
    MatchedData_obs=MatchedData_obs(ind);
    MatchedData_sim=MatchedData_sim(ind);
end

if length(MatchedData_obs)>config.obsTHRESH
    
    [stat_mae,stat_r,stat_rms,stat_nash,stat_nmae,stat_nrms]=do_error_calculation_2layers(MatchedData_obs,MatchedData_sim);
    
    devia=(mean(MatchedData_sim)-mean(MatchedData_obs))/mean(MatchedData_obs);
    
    if abs(devia)>10
        deviaS='Out of range';
        deviaSn=devia*100;
        disp(['warning here ....',num2str(devia,'%3.2f')]);
        
    else
        deviaS=[num2str(devia*100,'%3.2f'),'%'];
        deviaSn=devia*100;
    end
    
    headers='\bfModel skill metrics:\rm';
    str{1}=headers;
    inc=2;
    for i=1:length(config.skills)
        if config.skills(i)==1
            switch i
                case 1
                    str{inc}=['  R    = ',num2str(stat_r,'%1.4f')];
                    SkillNames{inc}='R';
                    SkillScores{inc}=num2str(stat_r,'%1.4f');
                    inc=inc+1;
                    
                case 2
                    str{inc}=['  BIAS = ',deviaS];
                    SkillNames{inc}='BIAS';
                    SkillScores{inc}=deviaS;
                    inc=inc+1;
                    
                case 3
                    str{inc}=['  MAE  = ',num2str(stat_mae,'%2.4f')];
                    SkillNames{inc}='MAE';
                    SkillScores{inc}=num2str(stat_mae,'%2.4f');
                    inc=inc+1;
                    
                case 4
                    str{inc}=['  RMS  = ',num2str(stat_rms,'%2.4f')];
                    SkillNames{inc}='RMS';
                    SkillScores{inc}=num2str(stat_rms,'%2.4f');
                    inc=inc+1;
                    
                case 5
                    str{inc}=['  NMAE = ',num2str(stat_nmae*100,'%2.2f'),'%'];
                    SkillNames{inc}='NMAE';
                    SkillScores{inc}=[num2str(stat_nmae*100,'%2.2f'),'%'];
                    inc=inc+1;
                    
                case 6
                    str{inc}=['  NRMS = ',num2str(stat_nrms*100,'%2.2f'),'%'];
                    SkillNames{inc}='NRMS';
                    SkillScores{inc}=[num2str(stat_nrms*100,'%2.2f'),'%'];
                    inc=inc+1;
                   
                case 7
                    str{inc}=['  MEF  = ',num2str(stat_nash,'%2.4f')];
                    SkillNames{inc}='MEF';
                    SkillScores{inc}=num2str(stat_nash,'%2.4f');
                    inc=inc+1;
                    
                otherwise
                    disp('Error skill option out of range');
            end
          
        end
    end

    errorMatrix.(sitename).(loadname).R=stat_r;
    errorMatrix.(sitename).(loadname).BIAS=deviaSn;
    errorMatrix.(sitename).(loadname).MAE=stat_mae;
    errorMatrix.(sitename).(loadname).RMS=stat_rms;
    errorMatrix.(sitename).(loadname).NMAE=stat_nmae;
    errorMatrix.(sitename).(loadname).NRMS=stat_nrms;
    errorMatrix.(sitename).(loadname).MEF=stat_nash;
else
    errorMatrix.(sitename).(loadname).R=NaN;
    errorMatrix.(sitename).(loadname).BIAS=NaN;
    errorMatrix.(sitename).(loadname).MAE=NaN;
    errorMatrix.(sitename).(loadname).RMS=NaN;
    errorMatrix.(sitename).(loadname).NMAE=NaN;
    errorMatrix.(sitename).(loadname).NRMS=NaN;
    errorMatrix.(sitename).(loadname).MEF=NaN;
end

T = table(SkillNames',SkillScores','VariableNames',{'Skils','Scores'}); 
errorMatrix.(sitename).(loadname).rawOBS=MatchedData_obs;
errorMatrix.(sitename).(loadname).rawSIM=MatchedData_sim;
errorMatrix.(sitename).(loadname).rawOBS_layers=layer_obs;
errorMatrix.(sitename).(loadname).rawSIM_layers=layer_sim;

end
