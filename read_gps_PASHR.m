function PASHR = read_gps_PASHR(gpsdir,tmin,tmax)

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([gpsdir 'POSMV-V5-PASHR-RAW_' loaddate '-*.Raw'],''));
loadname = [gpsdir loadname.name];

%read .RAW file
format = '%s %s %s %f %f %s %f %f %f %f %f %f %f %s';
try 
    fileID = fopen(loadname,'r');
    data = textscan(fileID,format,'Delimiter',',');
    fclose(fileID);
    
    %index for specified time chunk
    time = join([data{1} data{2}]);
    dd = days(datetime(time,'InputFormat','MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
    itt = find(dd >= ddmin & dd < ddmax);
    
    % Check if processing was done before data file was updated
    if max(dd)<ddmax & round(ddmax)~=ddmax
        PASHR.status = 1;
    else
        PASHR.status = 0;
    end
    
    %subset data
    for ic = 1:length(data)
        data{ic} = data{ic}(itt);
    end
    
    %read in time data and convert to decimal day for saving
    time = join([data{1} data{2}]);
    dt = datetime(time,'InputFormat','MM/dd/uuuu HH:mm:ss.SSS'); %datetime
    dn = datenum(dt); %datenum
    dd = days(dt - datetime(2024,1,1)); %decimal day
    heading = data{5};
    roll = data{7};
    pitch = data{8};
    heave = data{9};
    
    %bin
    ddint = 1/1440;
    ddnew = [ddmin:ddint:ddmax-ddint]';
    dtnew = datetime(2024,1,1) + days(ddnew);
    PASHR.dd = ddnew + 30/(60*1440);
    PASHR.heading=NaN.*ddnew;
    PASHR.roll=NaN.*ddnew;
    PASHR.pitch=NaN.*ddnew;
    PASHR.heave=NaN.*ddnew; 
    
    for k=1:length(ddnew)
        ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
        if ~isempty(ii)
            PASHR.heading(k)=nanmean(heading(ii));
            PASHR.roll(k)=nanmean(roll(ii));
            PASHR.pitch(k)=nanmean(pitch(ii));
            PASHR.heave(k)=nanmean(heave(ii));
        end
    end
catch 
    PASHR.status = 1; % Data file doesn't exist yet 
end

end