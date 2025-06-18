% program to combine shipboard ADCP data
% from Janet Sprintall (June 2023)

clear; close all

% join data sets
instru = 'os150nb';
path_save = 'C:/Users/ankit/Documents/SIO/Academics/Research/23_ASTRAL/Processed_Data'; 
FP1 = [path_save,'/','ASTRAL23_procADCP_RR2306_os150nb'];
FP2 = [path_save,'/','ASTRAL23_procADCP_RR2306a_os150nb'];

sadcp1 = load([FP1]);
sadcp2 = load([FP2]);

fnames = {...
'dday' ,'time' ,'iblkprf' ,'lon' ,'lat' ,'heading' ,...
'umeas' ,'uship' ,'umean' ,'u' ,...
'vmeas' ,'vship' ,'vmean' ,'v' ,...
'w' ,'wmean' ,'e','tr_temp','last_temp' ,...
'depth' ,'dn', 'd0day',...
'head_misalign', 'scale_factor' };

for ii = 1:length(fnames)
    eval(['sadcp.' fnames{ii} ' = ([sadcp1.sadcp.' fnames{ii} ' sadcp2.sadcp.' fnames{ii} ']);']);
end

%compute shear
sadcp.time = datetime(sadcp.dn,"ConvertFrom",'datenum');
sadcp.dudz = diff(sadcp.u)./diff(-sadcp.depth);
sadcp.dvdz = diff(sadcp.v)./diff(-sadcp.depth);
sadcp.shear = sqrt(sadcp.dudz.^2 + sadcp.dvdz.^2);
for ii = 1:length(sadcp.depth)  % each time step
    sadcp.middepth(:,ii) = runmean(sadcp.depth(:,ii),2);
end

fname = [path_save '/' 'ASTRAL23_procADCP_' 'full' '_' instru '.mat']; %use 75kHz 
eval(['save ' fname ' sadcp']);

