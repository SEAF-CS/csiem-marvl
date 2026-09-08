
function rawdata=load_AED_vars(ncfile,mod,loadname,allvars)

switch loadname
    case 'OXYPC'
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_AED_OXYGEN_OXY'});clear functions
        tra = tfv_readnetcdf(ncfile(mod).name,'names',{'TRACE_1'});
        rawdata.data.OXYPC = tra.TRACE_1 ./ oxy.WQ_AED_OXYGEN_OXY;
        clear tra oxy
    case 'TNTP'
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_DIAG_TOT_TP'});
        tra = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_DIAG_TOT_TN'});
        rawdata.data.TNTP = tra.WQ_DIAG_TOT_TN ./ oxy.WQ_DIAG_TOT_TP;
        rawdata.data.TNTP(isnan(rawdata.data.TNTP))=16;
        clear tra oxy
    case 'PONDON'
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_DON'});
        tra = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_PON'});
        rawdata.data.PONDON = tra.WQ_OGM_PON ./ oxy.WQ_OGM_DON;
        rawdata.data.PONDON(isnan(rawdata.data.PONDON))=1;
        clear tra oxy
    case 'DINDIP'
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PHS_FRP'});
        tra = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_NIT_NIT'});
        tra2 = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_NIT_AMM'});
        
        rawdata.data.DINDIP = (tra.WQ_NIT_NIT+tra2.WQ_NIT_AMM) ./ oxy.WQ_PHS_FRP;
        rawdata.data.DINDIP(isnan(rawdata.data.DINDIP))=16;
        clear tra tra2 oxy
    case 'WindSpeed'
        
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'W10_x';'W10_y'});clear functions
        rawdata.data.WindSpeed = sqrt(power(oxy.W10_x,2) + power(oxy.W10_y,2));
        clear  oxy
        
    case 'WindDirection'
        
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'W10_x';'W10_y'});clear functions
        rawdata.data.WindDirection = (180 / pi) * atan2(-1*oxy.W10_x,-1*oxy.W10_y);
        clear  oxy
        
    case 'WQ_DIAG_PHY_TCHLA'
        
        if sum(strcmpi(allvars,'WQ_DIAG_PHY_TCHLA')) == 0
            tchl = tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PHY_GRN';'WQ_PHY_CRYPT';'WQ_PHY_DIATOM';'WQ_PHY_DINO';'WQ_PHY_BGA'});clear functions
            rawdata.data.WQ_DIAG_PHY_TCHLA = (((tchl.WQ_PHY_GRN / 50)*12) + ...
                ((tchl.WQ_PHY_CRYPT / 50)*12) + ...
                ((tchl.WQ_PHY_DIATOM / 26)*12) + ...
                ((tchl.WQ_PHY_DINO / 40)*12) + ...
                ((tchl.WQ_PHY_BGA / 40)*12));
            clear tchl
        else
            rawdata.data = tfv_readnetcdf(ncfile(mod).name,'names',{loadname});
        end
        
    case 'V'
        
        oxy = tfv_readnetcdf(ncfile(mod).name,'names',{'V_x';'V_y'});
        rawdata.data.V = sqrt(power(oxy.V_x,2) + power(oxy.V_y,2));
        clear tra oxy
        
    case 'ON'
DON =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_DON'});clear functions
        PON =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_PON'});clear functions
        rawdata.data.ON = DON.WQ_OGM_DON + PON.WQ_OGM_PON;
        clear DON PON
     
    case 'OP'
     DON =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_DOP'});clear functions
        PON =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_POP'});clear functions
        rawdata.data.OP = DON.WQ_OGM_DOP + PON.WQ_OGM_POP;
        clear TP FRP
        
    case 'TN_CHX'
        TN =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_DIAG_TOT_TN'});clear functions
        CPOM =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_OGM_CPOM'});clear functions
        rawdata.data.TN_CHX = TN.WQ_DIAG_TOT_TN - CPOM.WQ_OGM_CPOM;
        clear TP FRP
        
        
    case 'ECOLI'
        
        ECOLI_F =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ECOLI_F'});clear functions
        ECOLI_A =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ECOLI_A'});clear functions
        rawdata.data.ECOLI = (ECOLI_F.WQ_PAT_ECOLI_F)  +  (ECOLI_A.WQ_PAT_ECOLI_A) ;
        clear ECOLI_F ECOLI_A
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ECLOI')
                fdata.(thesites{bdb}).ECOLI = fdata.(thesites{bdb}).ECLOI;
            end
        end
        
    case 'ECOLI_TOTAL'
        
        ECOLI_F =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ECOLI_F'});clear functions
        ECOLI_A =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ECOLI_A'});clear functions
        ECOLI_D =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ECOLI_D'});clear functions
        rawdata.data.ECOLI_TOTAL = (ECOLI_F.WQ_PAT_ECOLI_F)  +  (ECOLI_A.WQ_PAT_ECOLI_A) + (ECOLI_D.WQ_PAT_ECOLI_D) ;
        clear ECOLI_F ECOLI_A ECOLI_D
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ECLOI')
                fdata.(thesites{bdb}).ECOLI_TOTAL = fdata.(thesites{bdb}).ECLOI;
            end
        end
        
    case 'ECOLI_PASSIVE'
        
        ECOLI_P =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_TRC_TR1'});clear functions
        rawdata.data.ECOLI_PASSIVE = (ECOLI_P.WQ_TRC_TR1) ;
        clear ECOLI_P
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ECLOI')
                fdata.(thesites{bdb}).ECOLI_PASSIVE = fdata.(thesites{bdb}).ECLOI;
            end
        end
        
    case 'ECOLI_SIMPLE'
        
        ECOLI_P =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_TRC_TR2'});clear functions
        rawdata.data.ECOLI_SIMPLE = (ECOLI_P.WQ_TRC_TR2) ;
        clear ECOLI_P
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ECLOI')
                fdata.(thesites{bdb}).ECOLI_SIMPLE = fdata.(thesites{bdb}).ECLOI;
            end
        end
        
    case 'ENTEROCOCCI'
        
        ENT_F =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ENTEROCOCCI_F'});clear functions
        ENT_A =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ENTEROCOCCI_A'});clear functions
        %ENT_D =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ENTEROCOCCI_D'});
        rawdata.data.ENTEROCOCCI = (ENT_F.WQ_PAT_ENTEROCOCCI_F)  +  (ENT_A.WQ_PAT_ENTEROCOCCI_A)  ;
        clear ENT_F ENT_A
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ENT')
                fdata.(thesites{bdb}).ENTEROCOCCI = fdata.(thesites{bdb}).ENT;
            end
        end
        
    case 'ENTEROCOCCI_TOTAL'
        
        ENT_F =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ENTEROCOCCI_F'});clear functions
        ENT_A =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ENTEROCOCCI_A'});clear functions
        ENT_D =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PAT_ENTEROCOCCI_D'});clear functions
        rawdata.data.ENTEROCOCCI_TOTAL = (ENT_F.WQ_PAT_ENTEROCOCCI_F)  +  (ENT_A.WQ_PAT_ENTEROCOCCI_A) + (ENT_D.WQ_PAT_ENTEROCOCCI_D) ;
        clear ENT_F ENT_A ENT_D
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ENT')
                fdata.(thesites{bdb}).ENTEROCOCCI_TOTAL = fdata.(thesites{bdb}).ENT;
            end
        end
        
    case 'ENTEROCOCCI_PASSIVE'
        
        ENT_P =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_TRC_TR2'});clear functions
        rawdata.data.ENTEROCOCCI_PASSIVE = (ENT_P.WQ_TRC_TR2) ;
        clear ENT_P
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ENT')
                fdata.(thesites{bdb}).ENTEROCOCCI_PASSIVE = fdata.(thesites{bdb}).ENT;
            end
        end
        
    case 'ENTEROCOCCI_SIMPLE'
        
        ENT_P =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_TRC_TR4'});clear functions
        rawdata.data.ENTEROCOCCI_SIMPLE = (ENT_P.WQ_TRC_TR4) ;
        clear ENT_P
        
        thesites = fieldnames(fdata);
        for bdb = 1:length(thesites)
            if isfield(fdata.(thesites{bdb}),'ENT')
                fdata.(thesites{bdb}).ENTEROCOCCI_SIMPLE = fdata.(thesites{bdb}).ENT;
            end
        end
        
    case 'HSI_CYANO'
        TEM =  tfv_readnetcdf(ncfile(mod).name,'names',{'TEMP'});clear functions
        SAL =  tfv_readnetcdf(ncfile(mod).name,'names',{'SAL'});clear functions
        NIT =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_NIT_NIT'});clear functions
        AMM =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_NIT_AMM'});clear functions
        FRP =  tfv_readnetcdf(ncfile(mod).name,'names',{'WQ_PHS_FRP'});clear functions
        DEP =  tfv_readnetcdf(ncfile(mod).name,'names',{'D'});clear functions
        V_x =  tfv_readnetcdf(ncfile(mod).name,'names',{'V_x'});clear functions
        V_y =  tfv_readnetcdf(ncfile(mod).name,'names',{'V_y'});clear functions
        
        %------ temperature
        %The numbers I've used for Darwin Reservoir cyanobacteria are:
        %Theta_growth (v) = 1.08;
        %T_std = 28; %T_opt = 34; %T_max = 40;
        k =  4.1102;
        a = 35.0623;
        b =  0.1071;
        v =  1.0800;
        fT = v.^(TEM.TEMP-20)-v.^(k.*(TEM.TEMP-a))+b;
        
        %------ nitrogen
        KN = 4;                %   in mmol/m3
        fN = (NIT.WQ_NIT_NIT+AMM.WQ_NIT_AMM) ./ (KN+(NIT.WQ_NIT_NIT+AMM.WQ_NIT_AMM));
        
        %------ phosphorus
        KP = 0.15;    % in mmol/m3
        fP = FRP.WQ_PHS_FRP./(KP+FRP.WQ_PHS_FRP);
        
        %------ salinity
        KS = 5;                %   in PSU
        fS = KS ./ (KS+(SAL.SAL));
        fS(SAL.SAL<KS/2.)=1;
        
        %------ stratification/velocity
        KV = 0.5;
        V = (V_x.V_x.*V_x.V_x + V_y.V_y.*V_y.V_y).^0.5; %   in m/s
        fV = KV ./ (KV+V);
        fV(V<0.05)=0.;
        
        rawdata.data.HSI_CYANO = ( fT .* min(fN,fP) .* fS .* fV);
        rawdata.data.HSI_CYANO(rawdata.data.HSI_CYANO<0.5) = 0;
        
        clear fT;
        
    otherwise
        
        rawdata.data = tfv_readnetcdf(ncfile(mod).name,'names',{loadname});
        
end

end