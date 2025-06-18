function INGGA = read_gps_INGGA(gpsdir,tmin,tmax)

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([gpsdir 'POSMV-V5-INGGA-RAW_' loaddate '-*.Raw'],''));
loadname = [gpsdir loadname.name];

%read .RAW file
format = '%s %s %s %f %f %s %f %s %f %f %f %f %s %s %s %s %s';
try 
    fileID = fopen(loadname,'r');
    data = textscan(fileID,format,'Delimiter',',');
    fclose(fileID);
    
    %index for specified time chunk
    time = join([data{1} data{2}]);
    dd = days(datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
    itt = find(dd >= ddmin & dd < ddmax);
    
    % Check if processing was done before data file was updated
    if max(dd)<ddmax & round(ddmax)~=ddmax
        INGGA.status = 1;
    else
        INGGA.status = 0;
    end
    
    %subset data
    for ic = 1:length(data)
        data{ic} = data{ic}(itt);
    end
    
    %read in time data and convert to decimal day for saving
    time = join([data{1} data{2}]);
    dt = datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS'); %datetime
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
    INGGA.dd = ddnew + 30/(60*1440);
    INGGA.lat=NaN.*ddnew;
    INGGA.lon=NaN.*ddnew; 
    
    for k=1:length(ddnew)
        ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
        if ~isempty(ii)
            INGGA.lat(k)=nanmean(lat(ii));
            INGGA.lon(k)=nanmean(lon(ii));
        end
    end
catch 
    INGGA.status = 1; % Data file doesn't exist yet
end

end