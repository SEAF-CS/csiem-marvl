%% CS_SCERM_bc_conv
%
% Script to convert from SCERM to Cockburn Sound BGC model for river
% boundary conditions
% Written for A11348 Cockburn Sound BGC Model
%
% Uses:
%       
%     
% Created by:  <Kabir.Suara@bmtglobal.com>
% Created on: 18 October 2022
%
% Based on: Original
%
% Modified
%   1) 
%

%% Clean up
clear
close all
%clear path

%% Set path to functions
addpath(genpath('..\..\..\3Functions\'));

%% Variables

%SCERM 0 Tracers + 25 AED variables
SCERM_vars = {'ISOTime','WL','Sal','Temp','TRACE_1','TRC_age','NCS_ss1','NCS_ss2', ...
              'OXY_oxy','SIL_rsi','NIT_amm','NIT_nit','PHS_frp','PHS_frp_ads', ...
              'OGM_doc','OGM_poc','OGM_don','OGM_pon','OGM_dop','OGM_pop','OGM_docr','OGM_donr','OGM_dopr','OGM_cpom', ...
              'PHY_grn','PHY_bga','PHY_crypt','PHY_diatom','PHY_dino','PHY_dino_IN'};

%CS BGC 1 tracer + 17 AED variables
CSBGC_vars = {'ISOTime','WL','Sal','Temp','TRACE_1','NCS_ss1', ...
              'OXY_oxy','NIT_amm','NIT_nit','PHS_frp','PHS_frp_ads', ...
              'OGM_doc','OGM_poc','OGM_don','OGM_pon','OGM_dop','OGM_pop', ...
              'PHY_grn','PHY_bga','PHY_crypt','PHY_diatom','PHY_dino'};
          
%% Index
var_idx = zeros(size(CSBGC_vars));
for var_i = 1:length(CSBGC_vars)
    if ~isempty(find(strcmp(SCERM_vars,CSBGC_vars{var_i}), 1))
        var_idx(var_i) = find(strcmp(SCERM_vars,CSBGC_vars{var_i}));
    end
end

%% BC headers
bc_header =  {'ISOTime','wl','Sal','Temp','zeroes','zeroes','TSS','TSS','Oxy','Sil','Amm','Nit','FRP','FRP','DOC_T','POC_T','DON_T','PON_T','OP','OP','DOC_T','DON_T','OP','POC_T','CHLA','CHLA','CHLA','CHLA','CHLA','CHLA'};
bc_scale = [1,1,1,1,1,0.3,0.7,1,1,1,1,1,0.1,0.1,0.5,0.3,1,0.3,0.5,0.9,0.7,0.2,0.5,0.167,0.125,0.333,2.292,1.25,0.00754717];
bc_scale_CS = ones(size(CSBGC_vars));
bc_scale_CS = bc_scale_CS(1:end-1);
for var_i = 1:length(CSBGC_vars)
    if var_i>1
        if var_idx(var_i)>0
            bc_header_CS{var_i} = bc_header{var_idx(var_i)};
            bc_scale_CS(var_i-1) = bc_scale(var_idx(var_i));
        else
            bc_header_CS{var_i} = 'TRACE_1';
            bc_scale_CS(var_i-1) = 1;
        end
    else
        bc_header_CS{var_i} = bc_header{var_idx(var_i)};
    end
end

