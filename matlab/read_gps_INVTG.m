function INVTG = read_gps_INVTG(gpsdir,tmin,tmax)

%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([gpsdir 'POSMV-V5-INVTG-RAW_' loaddate '-*.Raw'],''));
loadname = [gpsdir loadname.name];

%read .RAW file
format = '%s %s %s %f %s %s %s %f %s %f %s %s';
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
        INVTG.status = 1;
    else
        INVTG.status = 0;
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
    cog = data{4};
    sog = data{10};
    
    %conversions
    sog = (sog*10^3)/3600; %km/h to m/s
    
    %bin
    ddint = 1/1440;
    ddnew = [ddmin:ddint:ddmax-ddint]';
    dtnew = datetime(2024,1,1) + days(ddnew);
    INVTG.dd = ddnew + 30/(60*1440);
    INVTG.cog=NaN.*ddnew;
    INVTG.sog=NaN.*ddnew; 
    
    for k=1:length(ddnew)
        ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
        if ~isempty(ii)
            INVTG.cog(k)=nanmean(cog(ii));
            INVTG.sog(k)=nanmean(sog(ii));
        end
    end
catch
    INVTG.status = 1; % Data file doesn't exist yet 
end

end
