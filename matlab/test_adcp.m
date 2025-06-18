clear; close all; 

sharedrive = 'U';
datadir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\adcp\'];
compiledir = [sharedrive,':\For_Science\Situational_Awareness_ShipboardData\'];

%load compiled data
load(join([compiledir,'adcp_compiled.mat'],''));

%load og data
datadir2 = "W:\TN432\adcp\proc\wh300\contour\wh300.nc";
t2 = ncread(datadir2,'time');
u2 = ncread(datadir2,'u');

tcond = ADCP_c.dday >= days(datetime(2024,5,17) - datetime(2024,1,1));

%% 
%load SA 10min files
finfo = dir([datadir, 'ADCP_*.nc']);
nz = NaN(length(finfo),1); 
nt = NaN(length(finfo),1);
t = NaN(length(finfo),1);
for iif = 2201:length(finfo)
    fname = finfo(iif).name;
    u = ncread([datadir,fname],'u');
    tpr = ncread([datadir,fname],'dday'); 
    t(iif) = tpr(1);
    nz(iif) = size(u,1);
    nt(iif) = size(u,2);
end

%%
dd = ADCP_c.dday(tcond) + datetime(2024,1,1);
figure();
subplot(3,1,1); plot(t+ datetime(2024,1,1),nt); xlim([dd(1),dd(end)])
subplot(3,1,2); pcolor(ADCP_c.dday(tcond) + datetime(2024,1,1),ADCP_c.depth(:,1),ADCP_c.u(:,tcond)); shading flat
subplot(3,1,3); pcolor(t2 + datetime(2024,1,1),ADCP_c.depth(:,1),u2); shading flat; xlim([dd(1),dd(end)])

%%

u3 = ncread([datadir, 'ADCP_20240519_0730.nc'],'u'); u4 = ncread([datadir, 'ADCP_20240519_0740.nc'],'u'); 
t3 = ncread([datadir, 'ADCP_20240519_0730.nc'],'dday'); t4 = ncread([datadir, 'ADCP_20240519_0740.nc'],'dday'); 

it = find(t2 >= t3(1) & t2 < t4(end));
test = u2(:,it);




