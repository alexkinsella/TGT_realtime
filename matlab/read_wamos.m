function read_wamos(logstart,logend,sharedrive,datadrive)
% create netcdf file with WAMOS data for specified start and end time

% %for testing (will loop through this)
% logstart = '20240428_0010'; logend = '20240428_0020';

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
tmin = datetime(logstart,'InputFormat',dateFormat);
tmax = datetime(logend,'InputFormat',dateFormat);
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%global parameters
wamosdir = [datadrive,':\TN432\scs\ANCILLARY\'];
gpsdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\gps\'];
savedir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\wamos\'];

%% Read in data from each instrument

WAMOS = read_wamos_WAMOS(wamosdir,tmin,tmax);

%% Save as netcdf file

if WAMOS.status==0

    %create netcdf file
    sname = join(['WAMOS_' logstart '.nc'],'');
    savename = join([savedir sname],'');
    
    try 
        %load position data 
        fname = join([gpsdir 'GPS_' logstart '.nc'],'');
        dd = ncread(fname,'dday');
        lat = ncread(fname,'lat');
        lon = ncread(fname,'lon');
        WAMOS.lat = interp1(dd,lat,WAMOS.dd);
        WAMOS.lon = interp1(dd,lon,WAMOS.dd);
        
        %delete the existing file
        if isfile(savename)
        delete(savename)
        end
        
        %save variables in netcdf file
        dims = {'dday',length(WAMOS.dd)};
        create_nc_file(savename,WAMOS.dd,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
        create_nc_file(savename,WAMOS.lat,'lat',dims,'latitude','deg')
        create_nc_file(savename,WAMOS.lon,'lon',dims,'longitude','deg')
        create_nc_file(savename,WAMOS.sig_wave_h,'sig_wave_h',dims,'significant wave height','m')
        create_nc_file(savename,WAMOS.mean_period,'mean_period',dims,'mean period','s')
        create_nc_file(savename,WAMOS.peak_wavedir,'peak_wavedir',dims,'peak wave direction','deg (coming from)')
        create_nc_file(savename,WAMOS.peak_waveperiod,'peak_waveperiod',dims,'peak wave period','s')
        create_nc_file(savename,WAMOS.peak_wavelength,'peak_wavelength',dims,'peak wavelength','m')
        create_nc_file(savename,WAMOS.swell_wavedir,'swell_wavedir',dims,'swell wave direction','deg (coming from)')
        create_nc_file(savename,WAMOS.swell_waveperiod,'swell_waveperiod',dims,'swell wave period','s')
        create_nc_file(savename,WAMOS.swell_wavelength,'swell_wavelength',dims,'swell wavelength','m')
        create_nc_file(savename,WAMOS.wind_seawave_dir,'wind_seawave_dir',dims,'wind sea wave direction','deg (coming from)')
        create_nc_file(savename,WAMOS.wind_seawave_waveperiod,'wind_seawave_waveperiod',dims,'wind sea wave period','s')
        create_nc_file(savename,WAMOS.wind_seawave_currentdir,'wind_seawave_currentdir',dims,'wind sea wave current direction','deg')
        create_nc_file(savename,WAMOS.currentdir,'currentdir',dims,'current direction','deg')
        create_nc_file(savename,WAMOS.currentspeed,'currentspeed',dims,'current speed','m/s')
    catch 
        disp(['WAMOS: GPS data not created yet for ',logstart])
    end

else
    disp(['WAMOS status not ready for ',logstart])

end

end
