function pvar = Swanbourne_plotvars_conv(vname,CHLconv,scalefactor)

% Extract model data and apply unit conversions if required
switch vname
    case 'WL'
        pvar.fvnam={'H'};
        pvar.uconv=1;
    case 'temp'
        pvar.fvnam={'temp'};
        pvar.uconv=1;
    case 'salt'
        pvar.fvnam={'salt'};
        pvar.uconv=1;
    case 'TEMP'
        pvar.fvnam={'TEMP'};
        pvar.uconv=1;
    case 'SALT'
        pvar.fvnam={'SAL'};
        pvar.uconv=1;
    case 'V_x'
        pvar.fvnam = {'V_x'};
        pvar.uconv=1;
    case 'V_y'
        pvar.fvnam = {'V_y'};
        pvar.uconv=1;
    case 'VMAG'
        pvar.fvnam = {'V_x', 'V_y'};
        pvar.uconv=1;
    case 'TURB'
        pvar.fvnam={'TSS'};
        pvar.uconv=TSSconv;
    case 'TSS'
        pvar.fvnam={'TSS'};
        pvar.uconv=1;
    case {'DO','DOsat'}
        pvar.fvnam={'WQ_OXY_OXY'};
        pvar.uconv=32/1000;
    case 'SIL'
        pvar.fvnam={'WQ_SIL_RSI'};
        pvar.uconv=28.1/1000;
    case 'NH3'
        pvar.fvnam={'WQ_NIT_AMM'};
        pvar.uconv=14;
    case 'NH4'
        pvar.fvnam={'WQ_NIT_AMM'};
        pvar.uconv=14/1000;
    case 'NOx'
        pvar.fvnam={'WQ_NIT_NIT'};
        pvar.uconv=14/1000;
    case 'NIT'
        pvar.fvnam={'WQ_NIT_NIT'};
        pvar.uconv=14;
    case 'DIN'
        pvar.fvnam={'WQ_NIT_AMM','WQ_NIT_NIT'};
        pvar.uconv=[14/1000,14/1000];
    case 'PHOS'
        pvar.fvnam={'WQ_PHS_FRP'};
        pvar.uconv=31;
    case 'FRP'
        pvar.fvnam={'WQ_PHS_FRP'};
        pvar.uconv=31/1000;
    case 'P_ADS'
        pvar.fvnam={'WQ_PHS_FRP_ADS'};
        pvar.uconv=31/1000;
    case 'DON'
        pvar.fvnam={'WQ_OGM_DON'};
        pvar.uconv=14/1000;
    case 'PON'
        pvar.fvnam={'WQ_OGM_PON'};
        pvar.uconv=14/1000;
    case 'DOP'
        pvar.fvnam={'WQ_OGM_DOP'};
        pvar.uconv=31/1000;
    case 'POP'
        pvar.fvnam={'WQ_OGM_POP'};
        pvar.uconv=31/1000;
    case 'OrgN'
        pvar.fvnam={'WQ_OGM_DON','WQ_OGM_PON'};
        pvar.uconv=14/1000;
    case 'OrgP'
        pvar.fvnam={'WQ_OGM_DOP','WQ_OGM_POP'};
        pvar.uconv=31/1000;
    case 'CHLA'
        pvar.fvnam={'WQ_PHY_MDIAT'};
        pvar.uconv=CHLconv;
    case 'DINOF'
        pvar.fvnam={'WQ_PHY_DINOF'};
        pvar.uconv=CHLconv;
    case 'MDIAT'
        pvar.fvnam={'WQ_PHY_MDIAT'};
        pvar.uconv=CHLconv;
    case 'CYANO'
        pvar.fvnam={'WQ_PHY_CYANO'};
        pvar.uconv=CHLconv;
    case 'GRN'
        pvar.fvnam={'WQ_PHY_GRN','WQ_PHY_MDIAT'};
        pvar.uconv=1;
    case 'BGA'
        pvar.fvnam={'WQ_PHY_BGA'};
        pvar.uconv=1;
    case 'TOT_ALG'
        pvar.fvnam={'WQ_PHY_GRN','WQ_PHY_BGA'};
        pvar.uconv=0.03*100000;
    case 'BGA_ALG' %Note doubled 3/11/2019 after checking conversion used in B19138
        pvar.fvnam={'WQ_PHY_BGA'};
        pvar.uconv=0.03*160000;
    case 'BVOL_ALG'
        pvar.fvnam={'WQ_PHY_BGA','WQ_PHY_BGA'};
        pvar.uconv=0.03;
    case 'TN' 
        pvar.fvnam={'WQ_NIT_AMM','WQ_NIT_NIT','WQ_OGM_DON','WQ_OGM_PON','WQ_PHY_MDIAT'};
        pvar.uconv=[14/1000,14/1000,14/1000,14/1000,0.137*14/1000];
    case 'TP' 
        pvar.fvnam={'WQ_PHS_FRP','WQ_OGM_DOP','WQ_OGM_POP','WQ_PHY_MDIAT'};
        pvar.uconv=[31/1000,31/1000,31/1000,0.0037*31/1000];
    case 'FCOLI'
        pvar.fvnam={'WQ_PAT_FCOLI_F'};
        pvar.uconv=1;
    case 'FCOLI_D'
        pvar.fvnam={'WQ_PAT_FCOLI_D'};
        pvar.uconv=1;
    case 'ENT'
        pvar.fvnam={'WQ_PAT_ENT_F'};
        pvar.uconv=1;
    case 'ENT_D'
        pvar.fvnam={'WQ_PAT_ENT_D'};
        pvar.uconv=1;
    case 'DILN' % Dilution
        pvar.fvnam={'TRACE_2'};
        pvar.uconv=1;
     case 'TRACE_1' % 
        pvar.fvnam={'TRACE_1'};
        pvar.uconv=scalefactor.TRACE_1;
     case 'TRACE_3' % 
        pvar.fvnam={'TRACE_3'};
        pvar.uconv=scalefactor.TRACE_3;

    otherwise
        pvar.fvnam={vname};
        pvar.uconv=1;
end
end