% Rebuild flux

files = dir('U:For_Science\Situational_Awareness_Processing\data\flux\*.nc');

for ff = 1:numel(files)
    shf = ncread([files(ff).folder,'/',files(ff).name],'shf');
    logstart = files(ff).name(6:18);
    if max(isnan(shf))==1
        logend = datestr(datetime(logstart,'inputformat','yyyyMMdd_HHmm')+minutes(10),'yyyymmdd_HHMM');
        make_flux(logstart,'U')
    end
    disp(['Done with ',logstart])
end