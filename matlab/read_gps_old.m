function read_gps(logstart,logend,sharedrive,datadrive)
% create netcdf file with GPS data for specified start and end time

% %for testing (will loop through this)
% logstart = '20240428_0000'; logend = '20240428_0010';

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
tmin = datetime(logstart,'InputFormat',dateFormat);
tmax = datetime(logend,'InputFormat',dateFormat);
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%file parameters
gpsdir = [datadrive,':\TN432\scs\NAV\'];
savedir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\gps\'];

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([gpsdir 'POSMV-V5-INGGA-RAW_' loaddate '-*.Raw'],''));
loadname = [gpsdir loadname.name];

%read .RAW file
format = '%s %s %s %f %f %s %f %s %f %f %f %f %s %s %s %s %s';
fileID = fopen(loadname,'r');
data = textscan(fileID,format,'Delimiter',',');
fclose(fileID);

%index for specified time chunk
time = join([data{1} data{2}]);
dd = days(datetime(time,'InputFormat','MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
itt = find(dd >= ddmin & dd < ddmax);

%subset data
for ic = 1:length(data)
    data{ic} = data{ic}(itt);
end

%read in time data and convert to decimal data for saving
time = join([data{1} data{2}]);
dt = datetime(time,'InputFormat','MM/dd/uuuu HH:mm:ss.SSS'); %datetime
dn = datenum(dt); %datenum
dd = days(dt - datetime(2024,1,1)); %decimal day

%convert position into decimal format
lat = convert_nav(data{5});
lat(strcmp(data{6},'S')) = -lat(strcmp(data{6},'S'));
lon = convert_nav(data{7});
lon(strcmp(data{6},'W')) = -lon(strcmp(data{6},'W'));

%bin
ddint = 1/1440;
ddnew = [ddmin:ddint:ddmax-ddint]';
dtnew = datetime(2024,1,1) + days(ddnew);
latnew=NaN.*ddnew;
lonnew=NaN.*ddnew; 

for k=1:length(ddnew)
    ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
    if ~isempty(ii)
        latnew(k)=nanmean(lat(ii));
        lonnew(k)=nanmean(lon(ii));
    end
end

%create netcdf file
sname = join(['GPS_' logstart '.nc'],'');
savename = join([savedir sname],'');

%delete the existing file
if isfile(savename)
delete(savename)
end

%save variables in netcdf file
dims = {'dday',length(ddnew)};
create_nc_file(savename,ddnew+30/86400,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024') % Add 30 seconds to center bins
create_nc_file(savename,latnew,'lat',dims,'latitude','deg')
create_nc_file(savename,lonnew,'lon',dims,'longitude','deg')

% %create structure
% GPS = struct();

end
