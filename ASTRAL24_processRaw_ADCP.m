% program to extract shipboard ADCP data
% from Janet Sprintall (June 2023)

datadrive = 'W';
cruisedrive = 'U';

%subdirectories to change
%path_data = [datadrive':/Users/ankit/Documents/SIO/Academics/Research/23_ASTRAL/Data/adcp_uhdas';
path_save = [cruisedrive,':/For_Science/Situational_Awareness_Processing/data/adcp']; 

instru = 'wh300';
% cruise = 'RR2306';
cruise = 'TN432';
d0 = datenum(2024,1,1);
%instru = 'OS75bb'

%% load allbins_* data from ADCP subdirectory process
% period 1 and 2

disp(fullfile([datadrive,':/',cruise,'/adcp/','proc','/',instru,'/','contour','/'], 'allbins_'))
[sadcp, test] = func_loadADCP(fullfile([datadrive,':/',cruise,'/adcp/','proc','/',instru,'/','contour','/'], 'allbins_'),'all');
fname = [path_save '/' 'ASTRAL24_procADCP_' cruise '_' instru '.mat']; %use 75kHz 
dnum = datenum(sadcp.time');
sadcp.dn = dnum'; 
sadcp.d0day = d0; 


adcp.dday = sadcp.dday;
adcp.time = sadcp.time;
adcp.lon = sadcp.lon;
adcp.lat = sadcp.lat;
adcp.depth = sadcp.depth;
adcp.u = sadcp.u;
adcp.v = sadcp.v;
adcp.dudz = diff(adcp.u)./diff(-adcp.depth);
adcp.dvdz = diff(adcp.v)./diff(-adcp.depth);
adcp.shear = sqrt(adcp.dudz.^2 + adcp.dvdz.^2);

eval(['save ' fname ' adcp']);
