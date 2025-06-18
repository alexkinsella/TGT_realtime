function RAD = read_met_RAD(metdir,tmin,tmax)

%parameters
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([metdir 'Campbell-RAD_' loaddate '-*.Raw'],''));
loadname = [metdir loadname.name];
RAD = struct();

%read .RAW file
format = '%s %s %s %f %f %f %f';
fileID = fopen(loadname,'r');
data = textscan(fileID,format,'Delimiter',',');
fclose(fileID);

%index for specified time chunk
time = join([data{1} data{2}]);
dd = days(datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
itt = find(dd >= ddmin & dd < ddmax);

% Check if processing was done before data file was updated
if max(dd)<ddmax & round(ddmax)~=ddmax
    RAD.status = 1;
else
    RAD.status = 0;
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
LW = data{5};
SW = data{7};

%bin
ddint = 1/1440;
ddnew = [ddmin:ddint:ddmax-ddint]';
dtnew = datetime(2024,1,1) + days(ddnew);
RAD.dd = ddnew + 30/(60*1440);
RAD.LW=NaN.*ddnew; 
RAD.SW=NaN.*ddnew;

for k=1:length(ddnew)
    ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
    if ~isempty(ii)
        RAD.LW(k)=nanmean(LW(ii));
        RAD.SW(k)=nanmean(SW(ii));
    end
end

end