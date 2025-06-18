function [WAMOS_c] = compile_new_wamos(wamosdir,compiledir)

%initialize
WAMOS_c = struct();
dims_c = ones(16,1);

%read in compiled data
path = [compiledir 'wamos_compiled.nc'];
info = ncinfo(path);
nv = length(info.Variables);
for iv = 1:nv
vname = info.Variables(iv).Name;
WAMOS_c.(vname) = ncread(path,vname);
end

%read in missing files
flist = dir([wamosdir 'WAMOS*.nc']);
fname = {}; for ifl = 1:length(flist); fname{ifl} = flist(ifl).name(7:end-3); end
fname_dd = days(datetime(fname,"InputFormat",'yyyyMMdd_HHmm') - datetime(2024,1,1));
imissing = find(fname_dd >= WAMOS_c.dday(end));
for im = 1:length(imissing)
    WAMOS = struct();
    disp(['Adding ', flist(imissing(im)).name])
    path = [wamosdir flist(imissing(im)).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    WAMOS.(vname) = ncread(path,vname);
    end
    WAMOS_c = compile_struct(WAMOS,WAMOS_c,dims_c);
end

%compile if there are missing files
if ~isempty(imissing)

    %compile into mat file
    sname_mat = 'wamos_compiled.mat';
    savename_mat = join([compiledir sname_mat],'');
    save(savename_mat,"WAMOS_c");

    %compile into netcdf file
    sname = 'wamos_compiled.nc';
    savename = join([compiledir sname],'');
    savename_new = [savename(1:end-3),'_new.nc'];
    
    %delete the existing file
    %if isfile(savename)
    %delete(savename)
    %end

    pause(5)
    
    %save variables in netcdf file
    dims = {'dday',length(WAMOS_c.dday)};
    create_nc_file(savename_new,WAMOS_c.dday,'dday',dims,'decimal day','days since Jan 01, 2024')
    create_nc_file(savename_new,WAMOS_c.lat,'lat',dims,'latitude','deg')
    create_nc_file(savename_new,WAMOS_c.lon,'lon',dims,'longitude','deg')
    create_nc_file(savename_new,WAMOS_c.sig_wave_h,'sig_wave_h',dims,'significant wave height','m')
    create_nc_file(savename_new,WAMOS_c.mean_period,'mean_period',dims,'mean period','s')
    create_nc_file(savename_new,WAMOS_c.peak_wavedir,'peak_wavedir',dims,'peak wave direction','deg (coming from)')
    create_nc_file(savename_new,WAMOS_c.peak_waveperiod,'peak_waveperiod',dims,'peak wave period','s')
    create_nc_file(savename_new,WAMOS_c.peak_wavelength,'peak_wavelength',dims,'peak wavelength','m')
    create_nc_file(savename_new,WAMOS_c.swell_wavedir,'swell_wavedir',dims,'swell wave direction','deg (coming from)')
    create_nc_file(savename_new,WAMOS_c.swell_waveperiod,'swell_waveperiod',dims,'swell wave period','s')
    create_nc_file(savename_new,WAMOS_c.swell_wavelength,'swell_wavelength',dims,'swell wavelength','m')
    create_nc_file(savename_new,WAMOS_c.wind_seawave_dir,'wind_seawave_dir',dims,'wind sea wave direction','deg (coming from)')
    create_nc_file(savename_new,WAMOS_c.wind_seawave_waveperiod,'wind_seawave_waveperiod',dims,'wind sea wave period','s')
    create_nc_file(savename_new,WAMOS_c.wind_seawave_currentdir,'wind_seawave_currentdir',dims,'wind sea wave current direction','deg')
    create_nc_file(savename_new,WAMOS_c.currentdir,'currentdir',dims,'current direction','deg')
    create_nc_file(savename_new,WAMOS_c.currentspeed,'currentspeed',dims,'current speed','m/s')

    system(['move /y ',savename_new,' ',savename]);


end

end