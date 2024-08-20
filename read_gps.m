function read_gps(logstart,logend,sharedrive,datadrive)
% create netcdf file with GPS data for specified start and end time

%for testing (will loop through this)
% logstart = '20240428_0000'; logend = '20240428_0010';
% logstart = '20240502_1450'; logend = '20240502_1500';

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
tmin = datetime(logstart,'InputFormat',dateFormat);
tmax = datetime(logend,'InputFormat',dateFormat);
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%global parameters
gpsdir = [datadrive,':\TN432\scs\NAV\'];
savedir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\gps\'];

%% Read in data from each instrument

INGGA = read_gps_INGGA(gpsdir,tmin,tmax);
INVTG = read_gps_INVTG(gpsdir,tmin,tmax);
PASHR = read_gps_PASHR(gpsdir,tmin,tmax);

%% Save as netcdf file
% Check statuses of files 
if INGGA.status==0 & INVTG.status==0 & PASHR.status==0

    %create netcdf file
    sname = join(['GPS_' logstart '.nc'],'');
    savename = join([savedir sname],'');
    
    %delete the existing file
    if isfile(savename)
    delete(savename)
    end
    
    %save variables in netcdf file
    dims = {'dday',length(INGGA.dd)};
    create_nc_file(savename,INGGA.dd,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
    create_nc_file(savename,INGGA.lat,'lat',dims,'latitude','deg')
    create_nc_file(savename,INGGA.lon,'lon',dims,'longitude','deg')
    create_nc_file(savename,INVTG.cog,'cog',dims,'course over ground','deg')
    create_nc_file(savename,INVTG.sog,'sog',dims,'speed over ground','m/s')
    create_nc_file(savename,PASHR.heading,'hdg',dims,'heading','deg')
    create_nc_file(savename,PASHR.roll,'roll',dims,'roll','deg')
    create_nc_file(savename,PASHR.pitch,'pitch',dims,'pitch','deg')
    create_nc_file(savename,PASHR.heave,'heave',dims,'heave','deg')

    disp(["Created GPS file for ",logstart])

else
    disp(['GPS status not ready for ',logstart])

end

end
