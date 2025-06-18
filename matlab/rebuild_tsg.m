% Rebuild TSG

files = dir('U:For_Science\Situational_Awareness_Processing\data\tsg\*.nc');

for ff = 1:numel(files)
    T = ncread([files(ff).folder,'/',files(ff).name],'T');
    logstart = files(ff).name(5:17);
    if max(isnan(T))==1
        logend = datestr(datetime(logstart,'inputformat','yyyyMMdd_HHmm')+minutes(10),'yyyymmdd_HHMM');
        read_tsg(logstart,logend,'U','W')
    end
    disp(['Done with ',logstart])
end