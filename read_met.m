function read_met(logstart,logend,sharedrive,datadrive)
% create netcdf file with MET data for specified start and end time

% %for testing (will loop through this)
% logstart = '20240429_0100'; logend = '20240429_0110';

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
tmin = datetime(logstart,'InputFormat',dateFormat);
tmax = datetime(logend,'InputFormat',dateFormat);
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%global parameters
metdir = [datadrive,':\TN432\scs\MET\'];
gpsdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\gps\'];
savedir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\met\'];

%% Read in data files for each instrument

SONIC = read_met_SONIC(metdir,tmin,tmax);
PORT_TW = read_met_BRIDGE_WIND_PORT_DRV(metdir,tmin,tmax);
STBD_TW = read_met_BRIDGE_WIND_STBD_DRV(metdir,tmin,tmax);
BOWMET = read_met_BOWMET(metdir,tmin,tmax);
RAD = read_met_RAD(metdir,tmin,tmax);

%% Save as netcdf file
% Check statuses of files 
if SONIC.status==0 & BOWMET.status==0 & RAD.status==0
    
    try 
        %load position data 
        fname = join([gpsdir 'GPS_' logstart '.nc'],'');
        latnew = ncread(fname,'lat');
        lonnew = ncread(fname,'lon');
        
        %create netcdf file
        sname = join(['MET_' logstart '.nc'],'');
        savename = join([savedir sname],'');
        
        %delete the existing file
        if isfile(savename)
        delete(savename)
        end

        %fix heading issues with wind
        TWS = [SONIC.TWS, PORT_TW.TWS, STBD_TW.TWS];
        TWD = [SONIC.TWD, PORT_TW.TWD, STBD_TW.TWD];
        TWU = -TWS.*cosd(90 - TWD); %convert into u and v components
        TWV = -TWS.*sind(90 - TWD);
        TWU_median = median(TWU,2); %find median value
        TWV_median = median(TWV,2);
        TWS_median = sqrt(TWU_median.^2 + TWV_median.^2);
        TWD_median = mod(90 - atan2d(TWV_median, TWU_median) + 180,360);

        %save variables in netcdf file
        dims = {'dday',length(SONIC.dd)};
        create_nc_file(savename,SONIC.dd,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
        create_nc_file(savename,latnew,'lat',dims,'latitude','deg')
        create_nc_file(savename,lonnew,'lon',dims,'longitude','deg')
        create_nc_file(savename,TWS_median,'TWS',dims,'median true wind speed','m/s')
        create_nc_file(savename,TWD_median,'TWD',dims,'median true wind  direction','deg')
        create_nc_file(savename,SONIC.TWS,'TWS_SONIC',dims,'SONIC true wind speed','m/s')
        create_nc_file(savename,SONIC.TWD,'TWD_SONIC',dims,'SONIC true wind  direction','deg')
        create_nc_file(savename,PORT_TW.TWS,'TWS_port',dims,'port true wind speed','m/s')
        create_nc_file(savename,PORT_TW.TWD,'TWD_port',dims,'port true wind  direction','deg')
        create_nc_file(savename,STBD_TW.TWS,'TWS_stbd',dims,'starboard true wind speed','m/s')
        create_nc_file(savename,STBD_TW.TWD,'TWD_stbd',dims,'starboard true wind  direction','deg')
        create_nc_file(savename,BOWMET.RWS,'RWS',dims,'relative wind speed','m/s')
        create_nc_file(savename,BOWMET.RWD,'RWD',dims,'relative wind direction','deg')
        create_nc_file(savename,BOWMET.AT,'AT',dims,'atmospheric temperature','deg C')
        create_nc_file(savename,BOWMET.RH,'RH',dims,'relative humidity','%')
        create_nc_file(savename,BOWMET.P,'P',dims,'barometric pressure','mbar')
        create_nc_file(savename,RAD.LW,'LW',dims,'longwave radiation','W/m^2')
        create_nc_file(savename,RAD.SW,'SW',dims,'shortwave radiation','W/m^2')
        
        disp(["Created MET file for ",logstart])

    catch
        disp(['MET: GPS data not created yet for ',logstart])
    end

else
    disp(['MET status not ready for ',logstart])

end

end
