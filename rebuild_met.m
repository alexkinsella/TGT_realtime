% Rebuild met

files = dir('U:For_Science\Situational_Awareness_Processing\data\met\*.nc');

for ff = 1:numel(files)
    %AT = ncread([files(ff).folder,'/',files(ff).name],'AT');
    logstart = files(end-ff).name(5:17);
    %if max(isnan(AT))==1
        logend = datestr(datetime(logstart,'inputformat','yyyyMMdd_HHmm')+minutes(10),'yyyymmdd_HHMM');
        read_met(logstart,logend,'U','W')
    %end
    disp(['Done with ',logstart])
end