function read_tsg(logstart,logend,sharedrive,datadrive)
% create netcdf file with TSG data for specified start and end time

%for testing (will loop through this)
% logstart = '20240428_0000'; logend = '20240428_0010';
% datadrive = 'Z'; sharedrive = 'Y';

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
tmin = datetime(logstart,'InputFormat',dateFormat);
tmax = datetime(logend,'InputFormat',dateFormat); 
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%global parameters
tsgdir = [datadrive,':\TN432\scs\SEAWATER\'];
gpsdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\gps\'];
savedir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\tsg\'];

%% Read in data files for each instrument

TSG = read_tsg_TSG(tsgdir,tmin,tmax);
SBE38 = read_tsg_SBE38(tsgdir,tmin,tmax);

%% Save as netcdf file
%Check statuses of files 
if TSG.status==0 & SBE38.status == 0
    
    try 
        %load position data 
        fname = join([gpsdir 'GPS_' logstart '.nc'],'');
        latnew = ncread(fname,'lat');
        lonnew = ncread(fname,'lon');
        
        %create netcdf file
        sname = join(['TSG_' logstart '.nc'],'');
        savename = join([savedir sname],'');
        
        %delete the existing file
        if isfile(savename)
        delete(savename)
        end
        
        %save variables in netcdf file
        dims = {'dday',length(TSG.dd)};
        create_nc_file(savename,TSG.dd,'dday',dims,'decimal day','days since Jan 01, 2024') % Add 30 seconds to center bins
        create_nc_file(savename,latnew,'lat',dims,'latitude','deg')
        create_nc_file(savename,lonnew,'lon',dims,'longitude','deg')
        create_nc_file(savename,TSG.T,'T',dims,'temperature','deg C')
        create_nc_file(savename,SBE38.intakeT,'intakeT',dims,'intake temperature','deg C')
        create_nc_file(savename,TSG.S,'S',dims,'salinity','psu')
        create_nc_file(savename,TSG.C,'C',dims,'conductivity','V')
        create_nc_file(savename,TSG.soundsp,'sound_speed',dims,'sound speed','m/s')

    catch
        disp(['TSG: GPS data not created yet for ',logstart])
    end

else
    disp(['TSG status not ready for ',logstart])

end

end
