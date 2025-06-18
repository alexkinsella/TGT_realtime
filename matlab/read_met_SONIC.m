function SONIC = read_met_SONIC(metdir,tmin,tmax)

%parameters
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([metdir 'SONIC-TWIND-RAW_' loaddate '-*.Raw'],''));
loadname = [metdir loadname.name];
SONIC = struct();

try 

    %read .RAW file
    format = '%s %s %s %f %f %f %f %f %f %f';
    fileID = fopen(loadname,'r');
    data = textscan(fileID,format,'Delimiter',',');
    fclose(fileID);
    
    %index for specified time chunk
    time = join([data{1} data{2}]);
    dd = days(datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
    itt = find(dd >= ddmin & dd < ddmax);
    
    % Check if processing was done before data file was updated
    if max(dd)<ddmax & round(ddmax)~=ddmax
        SONIC.status = 1;
    else
        SONIC.status = 0;
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
    
    %load in atmospheric data
    TWS = data{4};
    TWD = data{5};
    
    %conversions
    TWS = TWS*0.514444; %knots to m/s
    
    %QC
    TWS(TWS>100) = nan;
    
    %bin
    ddint = 1/1440;
    ddnew = [ddmin:ddint:ddmax-ddint]';
    dtnew = datetime(2024,1,1) + days(ddnew);
    SONIC.dd = ddnew + 30/(60*1440);
    SONIC.TWS=NaN.*ddnew;
    SONIC.TWD=NaN.*ddnew; 
    
    for k=1:length(ddnew)
        ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
        if ~isempty(ii)
            SONIC.TWS(k)=nanmean(TWS(ii));
            SONIC.TWD(k)=average_WD(TWD(ii));
        end
    end

catch
    
    SONIC.status = 1;

end

end