function SBE38 = read_tsg_SBE38(tsgdir,tmin,tmax)

%convert to datetime format
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([tsgdir 'SBE38-RAW_' loaddate '-*.Raw'],''));
loadname = [tsgdir loadname.name];
SBE38 = struct();

try

    %read .RAW file
    if floor(ddmin) == 117 || floor(ddmin) == 137 %fix no data issue when SBE38 is started
        format = '%s %s %s';
        fileID = fopen(loadname,'r');
        data = textscan(fileID,format,'Delimiter',',');
        fclose(fileID);
        %convert from string to number
        for ii = 1:length(data{3})
            try
                data{3}{ii} = str2double(data{3}{ii}); 
            catch 
                data{3}{ii} = NaN; 
            end
        end
        data{3} = cell2mat(data{3});
    else
        format = '%s %s %f';
        fileID = fopen(loadname,'r');
        data = textscan(fileID,format,'Delimiter',',');
        fclose(fileID);
    end
    
    %index for specified time chunk
    time = join([data{1} data{2}]);
    dd = days(datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
    itt = find(dd >= ddmin & dd < ddmax);

    % Check if processing was done before data file was updated
    if max(dd)<ddmax & round(ddmax)~=ddmax
        SBE38.status = 1;
    else
        SBE38.status = 0;
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

    %convert data
    intakeT = data{3};
    
    %bin
    ddint = 1/1440;
    ddnew = [ddmin:ddint:ddmax-ddint]';
    dtnew = datetime(2024,1,1) + days(ddnew);
    SBE38.dd = ddnew + 30/(60*1440);
    SBE38.intakeT=NaN.*ddnew;
    
    for k=1:length(ddnew)
        ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
        if ~isempty(ii)
            SBE38.intakeT(k)=nanmean(intakeT(ii));
        end
    end

catch

    SBE38.status = 1; % Data file doesn't exist

end

end
