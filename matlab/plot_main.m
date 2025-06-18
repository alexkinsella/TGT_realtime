% function plot_main(sharedrive)
%Plots underway data

%for testing
close all; clear;
sharedrive = 'U'; 

%plot parameters
start = days(datetime(2024,5,18,'TimeZone','UTC') - datetime(2024,1,1,'TimeZone','UTC'));
stop = days(datetime('now','TimeZone','UTC') - datetime(2024,1,1,'TimeZone','UTC'));
cruise = 'IOP2';

%% load data
compiledir = [sharedrive,':\For_Science\Situational_Awareness_ShipboardData\'];
load(join([compiledir,'tsg_compiled.mat'],''));
load(join([compiledir,'met_compiled.mat'],''));
load(join([compiledir,'flux_compiled.mat'],''));
load(join([compiledir,'wamos_compiled.mat'],''));
load(join([compiledir,'adcp_compiled.mat'],''));

%% meteorological 
f= figure();
f.Units = 'normalized';
f.Position = [0,0,1,1];

nr = 7; nc = 1;

tcond = (MET_c.dday >= start) & (MET_c.dday < stop);
vars = {'TWS','TWD','AT','RH','P','LW','SW'};
varnames = {'wind speed','wind direction','atmospheric temperature','relative humditiy','pressure','longwave radiation','shortwave radiation'};
units = {'m/s','\circ','\circC','%','dbar','W/m^2','W/m^2'};

for ip = 1:length(vars)
ax = subplot(nr,nc,ip);
plot_timeseries(MET_c.dday(tcond) + datetime(2024,1,1),MET_c.(vars{ip})(tcond),varnames{ip},units{ip})
end

% end