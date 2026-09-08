function[ydata,units,isConv,ylab] = tfv_Unit_Conversion(ydata,varname)
% A Simple function to plug into the plottfv_prof function to convert model
% and field data on the fly.
%
% Simply add to the switch function to add more units.

isConv = 1;

convFile = fullfile(fileparts(mfilename('fullpath')),'Variable_Conversions.xlsx');

% Feb 11, 2026: Keep xlsread for compatibility, but fall back to readcell
% when Excel/COM RPC fails in long batch runs on Windows.
try
    [snum,sstr] = xlsread(convFile,'A2:E10000');

    conv = snum(:,1);

    oldvar = sstr(:,1);
    newvar = sstr(:,2);
    newunits = sstr(:,3);
    symbol = sstr(:,5);
catch
    raw = readcell(convFile,'Range','A2:E10000');
    if isempty(raw)
        ydata = ydata * 1;
        units = [];
        isConv = 0;
        ylab = varname;
        return
    end

    oldvar = raw(:,1);
    newvar = raw(:,2);
    newunits = raw(:,3);
    symbol = raw(:,5);

    convRaw = raw(:,4);
    conv = nan(numel(convRaw),1);
    for ii = 1:numel(convRaw)
        if isnumeric(convRaw{ii}) && isscalar(convRaw{ii})
            conv(ii,1) = convRaw{ii};
        elseif ischar(convRaw{ii}) || (isstring(convRaw{ii}) && isscalar(convRaw{ii}))
            conv(ii,1) = str2double(string(convRaw{ii}));
        end
    end
end

sss = find(strcmpi(string(oldvar),string(varname)) == 1);


if isempty(sss)
    ydata = ydata * 1;
    units = [];
    isConv = 0;
    ylab = varname;
else
    ydata = ydata * conv(sss);
    if iscell(newunits)
        units = newunits{sss};
    else
        units = newunits(sss);
    end
    if isstring(units)
        units = char(units);
    end

    if iscell(symbol)
        ylabSym = symbol{sss};
    else
        ylabSym = symbol(sss);
    end
    if isstring(ylabSym)
        ylabSym = char(ylabSym);
    end

    if ~isempty(ylabSym)
        ylab = ylabSym;
    else
        if iscell(newvar)
            ylab = newvar{sss};
        else
            ylab = newvar(sss);
        end
        if isstring(ylab)
            ylab = char(ylab);
        end
    end
end





% switch varname
%  	case 'D'
% 		ydata = ydata * 1;
% 		units = 'm';   
% 		
% 	case 'ECOLI_PASSIVE'
% 		ydata = ydata * 1;
% 		units = 'cfu/100mL';
% 		
% 	case 'ENTEROCOCCI_PASSIVE'
% 		disp('hi');
% 		ydata = ydata * 1;
% 		units = 'cfu/100mL';
%     
%     %
%     case  'SAL'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (1);
%         units = 'psu';
%     case  'TEMP'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (1);
%         units = 'C';    
%     
%     case  'WQ_OXY_OXY'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (32/1000);
%         units = 'mg/L';
%     case  'WQ_OXY_SAT'
%         % mmol/m^3 to mg/L
%         ydata = ydata * 1;
%         units = '%';        
%     case  'WQ_OGM_DON'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%      case  'WQ_OGM_DONR'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';       
%     case  'WQ_OGM_DOC'
%         % mmol/m^3 to mg/L
%         ydata = ydata / 83.333333;
%         units = 'mg/L';
%         
%     case  'WQ_OGM_POC'
%         % mmol/m^3 to mg/L
%         ydata = ydata / 83.333333;
%         units = 'mg/L';
%         
%         
%     case 'WQ_OGM_DOP'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%     case 'WQ_SIL_RSI'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (28.1/1000);
%         units = 'mg/L';
%         
%     case 'TN'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%         
%     case 'WQ_NIT_AMM'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%     case 'WQ_NIT_NIT'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%         
%     case 'WQ_DIAG_PHY_TCHLA'
%         ydata = ydata;
%         units = 'ug/L';
%         
%         
%     case 'WQ_PHS_FRP'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%     case 'WQ_PHS_FRP_ADS'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%     case 'WQ_OGM_POP'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%         
%     case 'WQ_OGM_PON'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%         
%     case 'WQ_OGM_DOCR'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (12/1000);
%         units = 'mg/L';
%         
%     case 'WQ_OGM_DONR'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%         
%     case 'WQ_OGM_DOPR'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%     case 'ON'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%         
%     case 'OP'
%         % mmol/m^3 to mg/L
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%     case 'WQ_DIAG_TOT_TP'
%         ydata = ydata * (31/1000);
%         units = 'mg/L';
%         
%     case 'WQ_DIAG_TOT_TN'
%         ydata = ydata * (14/1000);
%         units = 'mg/L';
%     case 'WQ_DIAG_TOT_TKN'
%         ydata = ydata * (14/1000);
%         units = 'mg/L';        
%     case 'WQ_DIAG_TOT_TOC'
%         ydata = ydata * (12/1000);
%         units = 'mg/L';
%         
%     case 'WQ_DIAG_TOT_TURBIDITY'
%         ydata = ydata * 1;
%         units = 'NTU';
%     case 'WQ_DIAG_TOT_TSS'
%         ydata = ydata * 1;
%         units = 'mg/L';
% 	case 'TSS'
%         ydata = ydata * 1;
%         units = 'mg/L';
%     case 'WQ_NCS_SS1'
%         ydata = ydata * 1;
%         units = 'mg/L';
%     case 'WQ_TRC_AGE'
%         ydata = ydata * 1/86400;
%         units = 'Days';
%         
%     case 'TN_TP'
%         ydata = ydata * 1;
%         units = 'mg/L';
%     case 'TN_CHX'
%         ydata = ydata * (14/1000);
%         units = 'mg/L';        
%         %     case 'SAL'
%         %         %PPT to uS/cm
%         %           ydata = ydata * (31/1000);
%         %         units = 'mg/L';
%         %
%         
%     otherwise
%         %  disp(['No Conversion Made for: ',varname]);
%         
%         ydata = ydata .* 1;
%         units = [];
%         isConv = 0;
%         
%         
%         
% end



