function BOWMET = read_met_BOWMET(metdir,tmin,tmax)

%parameters
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([metdir 'BOW-MET-RAW_' loaddate '-*.Raw'],''));
loadname = [metdir loadname.name];
BOWMET = struct();

%read .RAW file
format = '%s %s %s %f %f %f %f %f';
fileID = fopen(loadname,'r');
data = textscan(fileID,format,'Delimiter',',');
fclose(fileID);

%index for specified time chunk
time = join([data{1} data{2}]);
dd = days(datetime(time,"InputFormat",'MM/dd/uuuu HH:mm:ss.SSS') - datetime(2024,1,1)); %decimal days
itt = find(dd >= ddmin & dd < ddmax);

% Check if processing was done before data file was updated
if max(dd)<ddmax & round(ddmax)~=ddmax
    BOWMET.status = 1;
else
    BOWMET.status = 0;
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
RWS = data{4};
RWD = data{5};
AT = data{6};
RH = data{7};
P = data{8};

%conversions
RWS = RWS*0.514444; %knots to m/s

%bin
ddint = 1/1440;
ddnew = [ddmin:ddint:ddmax-ddint]';
dtnew = datetime(2024,1,1) + days(ddnew);
BOWMET.dd = ddnew + 30/(60*1440);
BOWMET.RWS=NaN.*ddnew;
BOWMET.RWD=NaN.*ddnew; 
BOWMET.AT=NaN.*ddnew;
BOWMET.RH=NaN.*ddnew;
BOWMET.P=NaN.*ddnew;

for k=1:length(ddnew)
    ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
    if ~isempty(ii)
        BOWMET.RWS(k)=nanmean(RWS(ii));
        BOWMET.RWD(k)=nanmean(RWD(ii));
        BOWMET.AT(k)=nanmean(AT(ii));
        BOWMET.RH(k)=nanmean(RH(ii));
        BOWMET.P(k)=nanmean(P(ii));
    end
end

end