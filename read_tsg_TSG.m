function TSG = read_tsg_TSG(tsgdir,tmin,tmax)

%convert to datetime format
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([tsgdir 'TSG-RAW_' loaddate '-*.Raw'],''));
loadname = [tsgdir loadname.name];
TSG = struct();

try

    %read .RAW file
    format = '%s %s %f %f %f %f';
    fileID = fopen(loadname,'r');
    data = textscan(fileID,format,'Delimiter',',');
    fclose(fileID);
    
    %index for specified time chunk
    time = join([data{1} data{2}]);
    dd = days(datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
    itt = find(dd >= ddmin & dd < ddmax);

    % Check if processing was done before data file was updated
    if max(dd)<ddmax & round(ddmax)~=ddmax
        TSG.status = 1;
    else
        TSG.status = 0;
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
    T = data{3};
    C = data{4};
    S = data{5};
    sound_sp = data{6};

    %bin
    ddint = 1/1440;
    ddnew = [ddmin:ddint:ddmax-ddint]';
    dtnew = datetime(2024,1,1) + days(ddnew);
    TSG.dd = ddnew + 30/(60*1440);
    TSG.T=NaN.*ddnew;
    TSG.S=NaN.*ddnew;
    TSG.C=NaN.*ddnew;  
    TSG.soundsp=NaN.*ddnew;

    for k=1:length(ddnew)
        ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
        if ~isempty(ii)
            TSG.T(k)=nanmean(T(ii));
            TSG.S(k)=nanmean(S(ii));
            TSG.C(k)=nanmean(C(ii));
            TSG.soundsp(k) = nanmean(sound_sp(ii));
        end
    end

catch

    TSG.status = 1; % Data file doesn't exist

end

end
