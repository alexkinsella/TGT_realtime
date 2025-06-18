function chunk_ADCP(sharedrive,datadrive)
% Subset ADCP netcdf to send to shore 

% sharedrive = 'Y'; datadrive = 'Z';
datadir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\'];

% generate filenames to loop over
% cruisestart = datetime(2024,4,27,22,50,00); %start of cruise
cruisestart = datetime(2024,5,17,0,0,0);
today = datetime("now",'TimeZone','UTC'); 
%disp(join(['Run time:' string(today)]))
yr = year(today); mn = month(today); dy = day(today); hr = hour(today); mm = minute(today) - mod(minute(today),10);
cruisetemp = datetime(yr,mn,dy,hr,mm,0); %temporary end time
loopint = minutes(10);
looptime = cruisestart:loopint:cruisetemp;
loopfile = string(looptime,'yyyyMMdd_HHmm');

time = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'time');
lon = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'lon');
lat = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'lat');
u = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'u');
v = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'v');
depth = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'depth');
depth_cell = depth(:,1);
amp = ncread([datadrive,':\TN432\adcp\proc\wh300\contour\wh300.nc'],'amp');

for il = 1:length(loopfile)-1
    filename = join([datadir 'adcp\' 'ADCP_', loopfile(il),'.nc'],'');
    if ~isfile(filename)
        logstart = loopfile(il); logend = loopfile(il+1);

        %delete the existing file
        if isfile(filename)
        delete(filename)
        end

        dateFormat = 'yyyyMMdd_HHmm';
        tmin = datetime(logstart,'InputFormat',dateFormat);
        tmax = datetime(logend,'InputFormat',dateFormat);
        ddmin = days(tmin - datetime(2024,1,1));
        ddmax = days(tmax - datetime(2024,1,1));
        timecheck = time>=ddmin & time<ddmax;
        
        if ~isempty(time(timecheck))
            dims1 = {'dday',length(time(timecheck))};
            dims1_z = {'depth_cell',length(depth_cell)};
            dims2 = {'depth_cell',length(depth_cell),'dday',length(time(timecheck))};
            create_nc_file(filename,time(timecheck),'dday',dims1,'decimal day (UTC)','days since Jan 01, 2024')
            create_nc_file(filename,lat(timecheck),'lat',dims1,'latitude','deg')
            create_nc_file(filename,lon(timecheck),'lon',dims1,'longitude','deg')
            create_nc_file(filename,u(:,timecheck),'u',dims2,'eastward velocity','m/s')
            create_nc_file(filename,v(:,timecheck),'v',dims2,'northward velocity','m/s')
            create_nc_file(filename,depth(:,timecheck),'depth',dims2,'depth','m')
            create_nc_file(filename,amp(:,timecheck),'amp',dims2,'received signal strength','')
            disp(["Created ADCP file for ",loopfile(il)])

        end
    end
end
end



