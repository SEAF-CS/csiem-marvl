clear all; close all;

addpath(genpath('functions'));
addpath(genpath('tuflowfv'));

starttime = datenum(2017,03,01);
endtime = datenum(2017,06,01);

  plot_bcfiles_time('D:\Github\SCERM\models\SCERM_v6\BCs\Met/',starttime,endtime);
