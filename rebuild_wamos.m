% Rebuild wamos

function rebuild_wamos(nanonly)

files = dir('U:For_Science\Situational_Awareness_Processing\data\wamos\*.nc');

for ff = 1:numel(files)
    if nanonly==1
        swh = ncread([files(ff).folder,'/',files(ff).name],'sig_wave_h');
        logstart = files(ff).name(7:19);
        if max(isnan(swh))==1
            logend = datestr(datetime(logstart,'inputformat','yyyyMMdd_HHmm')+minutes(10),'yyyymmdd_HHMM');
            read_wamos(logstart,logend,'U','W')
        end
    else
        logstart = files(ff).name(7:19);
        logend = datestr(datetime(logstart,'inputformat','yyyyMMdd_HHmm')+minutes(10),'yyyymmdd_HHMM');
        read_wamos(logstart,logend,'U','W')
    end
    disp(['Done with ',logstart])
end