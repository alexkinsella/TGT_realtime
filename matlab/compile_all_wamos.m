function [WAMOS_c] = compile_all_wamos(wamosdir,compiledir)

% %for testing
% wamosdir = 'U:\For_Science\Situational_Awareness_Processing\data\wamos\';
% compiledir = 'U:\For_Science\Situational_Awareness_ShipboardData\';

%loop through files
count = 0;
WAMOS_c = struct();
dims = ones(16,1);
flist = dir([wamosdir 'WAMOS*.nc']);
for ifl = 1:length(flist)
    WAMOS = struct();
    path = [wamosdir flist(ifl).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    WAMOS.(vname) = ncread(path,vname);
    end
    if ~isempty(WAMOS.dday)
        count = count + 1;
    end
    if count == 1
        WAMOS_c = WAMOS;
    elseif count > 1
        WAMOS_c = compile_struct(WAMOS,WAMOS_c,dims);
    end
end

%create netcdf file
sname = 'wamos_compiled.nc';
savename = join([compiledir sname],'');

%delete the existing file
if isfile(savename)
delete(savename)
end

%save variables in netcdf file
dims = {'dday',length(WAMOS_c.dday)};
create_nc_file(savename,WAMOS_c.dday,'dday',dims,'decimal day','days since Jan 01, 2024')
create_nc_file(savename,WAMOS_c.lat,'lat',dims,'latitude','deg')
create_nc_file(savename,WAMOS_c.lon,'lon',dims,'longitude','deg')
create_nc_file(savename,WAMOS_c.sig_wave_h,'sig_wave_h',dims,'significant wave height','m')
create_nc_file(savename,WAMOS_c.mean_period,'mean_period',dims,'mean period','s')
create_nc_file(savename,WAMOS_c.peak_wavedir,'peak_wavedir',dims,'peak wave direction','deg (coming from)')
create_nc_file(savename,WAMOS_c.peak_waveperiod,'peak_waveperiod',dims,'peak wave period','s')
create_nc_file(savename,WAMOS_c.peak_wavelength,'peak_wavelength',dims,'peak wavelength','m')
create_nc_file(savename,WAMOS_c.swell_wavedir,'swell_wavedir',dims,'swell wave direction','deg (coming from)')
create_nc_file(savename,WAMOS_c.swell_waveperiod,'swell_waveperiod',dims,'swell wave period','s')
create_nc_file(savename,WAMOS_c.swell_wavelength,'swell_wavelength',dims,'swell wavelength','m')
create_nc_file(savename,WAMOS_c.wind_seawave_dir,'wind_seawave_dir',dims,'wind sea wave direction','deg (coming from)')
create_nc_file(savename,WAMOS_c.wind_seawave_waveperiod,'wind_seawave_waveperiod',dims,'wind sea wave period','s')
create_nc_file(savename,WAMOS_c.wind_seawave_currentdir,'wind_seawave_currentdir',dims,'wind sea wave current direction','deg')
create_nc_file(savename,WAMOS_c.currentdir,'currentdir',dims,'current direction','deg')
create_nc_file(savename,WAMOS_c.currentspeed,'currentspeed',dims,'current speed','m/s')

end