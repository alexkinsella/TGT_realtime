function WAMOS = read_wamos_WAMOS(wamosdir,tmin,tmax)
%convert to datetime format
dateFormat = 'yyyyMMdd_HHmm';
ddmin = days(tmin - datetime(2024,1,1));
ddmax = days(tmax - datetime(2024,1,1));

%loop parameters
loaddate = string(tmin,'yyyyMMdd');
loadname = dir(join([wamosdir 'WAMOS-RAW_' loaddate '-*.Raw'],''));
loadname = [wamosdir loadname.name];

%read .RAW file
format = '%s %s %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s';
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
        WAMOS.status = 1;
    else
        WAMOS.status = 0;
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
    
    sig_wave_h = data{4};
    mean_period = data{5};
    peak_wavedir = data{6};
    peak_waveperiod = data{7};
    peak_wavelength = data{8};
    swell_wavedir = data{9};
    swell_waveperiod = data{10};
    swell_wavelength = data{11};
    wind_seawave_dir = data{12};
    wind_seawave_waveperiod = data{13};
    wind_seawave_currentdir = data{14};
    currentdir = data{15};
    currentspeed = data{16};
    
    % Change fill values to nan
    sig_wave_h(sig_wave_h<-5) = nan;
    mean_period(mean_period<-5) = nan;
    peak_wavedir(peak_wavedir<-5) = nan;
    peak_waveperiod(peak_waveperiod<-5) = nan;
    peak_wavelength(peak_wavelength<-5) = nan;
    swell_wavedir(swell_wavedir<-5) = nan;
    swell_waveperiod(swell_waveperiod<-5) = nan;
    swell_wavelength(swell_wavelength<-5) = nan;
    wind_seawave_dir(wind_seawave_dir<-5) = nan;
    wind_seawave_currentdir(wind_seawave_currentdir<-5) = nan;
    
    timecheck = dd>=ddmin & dd<ddmax;
    WAMOS.dd = dd(timecheck);
    WAMOS.sig_wave_h= sig_wave_h(timecheck); 
    WAMOS.mean_period=mean_period(timecheck); 
    WAMOS.peak_wavedir=peak_wavedir(timecheck); 
    WAMOS.peak_waveperiod=peak_waveperiod(timecheck); 
    WAMOS.peak_wavelength=peak_wavelength(timecheck); 
    WAMOS.swell_wavedir=swell_wavedir(timecheck);
    WAMOS.swell_waveperiod=swell_waveperiod(timecheck); 
    WAMOS.swell_wavelength=swell_wavelength(timecheck);
    WAMOS.wind_seawave_dir=wind_seawave_dir(timecheck);
    WAMOS.wind_seawave_waveperiod=wind_seawave_waveperiod(timecheck);
    WAMOS.wind_seawave_currentdir=wind_seawave_currentdir(timecheck);
    WAMOS.currentdir=currentdir(timecheck);
    WAMOS.currentspeed=currentspeed(timecheck);
catch
    WAMOS.status = 1; % Data not ready yet
end

%{
%bin
ddint = 1.5/1440;
ddnew = [ddmin:ddint:ddmax-ddint]';
dtnew = datetime(2024,1,1) + days(ddnew);
WAMOS.dd = ddnew + 45/(60*1440);
WAMOS.sig_wave_h=NaN.*ddnew; 
WAMOS.mean_period=NaN.*ddnew; 
WAMOS.peak_wavedir=NaN.*ddnew; 
WAMOS.peak_waveperiod=NaN.*ddnew; 
WAMOS.peak_wavelength=NaN.*ddnew; 
WAMOS.swell_wavedir=NaN.*ddnew;
WAMOS.swell_waveperiod=NaN.*ddnew; 
WAMOS.swell_wavelength=NaN.*ddnew;
WAMOS.wind_seawave_dir=NaN.*ddnew;
WAMOS.wind_seawave_waveperiod=NaN.*ddnew;
WAMOS.wind_seawave_currentdir=NaN.*ddnew;
WAMOS.currentdir=NaN.*ddnew;
WAMOS.currentspeed=NaN.*ddnew;

for k=1:length(ddnew)
    ii = find(dd>=ddnew(k) & dd<ddnew(k)+ddint);
%     datetime(2024,1,1) + days(dd(ii)) %testing
    if ~isempty(ii)
        WAMOS.sig_wave_h(k)=nanmean(sig_wave_h(ii)); 
        WAMOS.mean_period(k)=nanmean(mean_period(ii)); 
        WAMOS.peak_wavedir(k)=nanmean(peak_wavedir(ii)); 
        WAMOS.peak_waveperiod(k)=nanmean(peak_waveperiod(ii)); 
        WAMOS.peak_wavelength(k)=nanmean(peak_wavelength(ii)); 
        WAMOS.swell_wavedir(k)=nanmean(swell_wavedir(ii));
        WAMOS.swell_waveperiod(k)=nanmean(swell_waveperiod(ii)); 
        WAMOS.swell_wavelength(k)=nanmean(swell_wavelength(ii));
        WAMOS.wind_seawave_dir(k)=nanmean(wind_seawave_dir(ii));
        WAMOS.wind_seawave_waveperiod(k)=nanmean(wind_seawave_waveperiod(ii));
        WAMOS.wind_seawave_currentdir(k)=nanmean(wind_seawave_currentdir(ii));
        WAMOS.currentdir(k)=nanmean(currentdir(ii));
        WAMOS.currentspeed(k)=nanmean(currentspeed(ii));
    end
end
%}

end