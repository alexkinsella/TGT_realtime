function [GPS_c] = compile_new_gps(gpsdir,compiledir)

%initialize
GPS_c = struct();
dims_c = [1,1,1,1,1,1,1,1,1];

%read in compiled data
path = [compiledir 'gps_compiled.nc'];
info = ncinfo(path);
nv = length(info.Variables);
for iv = 1:nv
vname = info.Variables(iv).Name;
GPS_c.(vname) = ncread(path,vname);
end

%read in missing files
flist = dir([gpsdir 'GPS*.nc']);
fname = {}; for ifl = 1:length(flist); fname{ifl} = flist(ifl).name(5:end-3); end
fname_dd = days(datetime(fname,"InputFormat",'yyyyMMdd_HHmm') - datetime(2024,1,1));
imissing = find(fname_dd >= GPS_c.dday(end));
for im = 1:length(imissing)
    GPS = struct();
    disp(['Adding ', flist(imissing(im)).name])
    path = [gpsdir flist(imissing(im)).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    GPS.(vname) = ncread(path,vname);
    end
    GPS_c = compile_struct(GPS,GPS_c,dims_c);
end

%compile if there are missing files
if ~isempty(imissing)
    
    %compile into mat file
    sname_mat = 'gps_compiled.mat';
    savename_mat = join([compiledir sname_mat],'');
    save(savename_mat,"GPS_c");

    %compile into netcdf file
    sname = 'gps_compiled.nc';
    sname_new = [sname(1:end-3),'_new.nc'];
    savename = join([compiledir sname],'');
    savename_new = [savename(1:end-3),'_new.nc'];
    
    %delete the existing file
    %if isfile(savename)
    %delete(savename)
    %end

    %pause(5)
    
    %save variables in netcdf file
    dims = {'dday',length(GPS_c.dday)};
    create_nc_file(savename_new,GPS_c.dday,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
    create_nc_file(savename_new,GPS_c.lat,'lat',dims,'latitude','deg')
    create_nc_file(savename_new,GPS_c.lon,'lon',dims,'longitude','deg')
    create_nc_file(savename_new,GPS_c.cog,'cog',dims,'course over ground','deg')
    create_nc_file(savename_new,GPS_c.sog,'sog',dims,'speed over ground','m/s')
    create_nc_file(savename_new,GPS_c.hdg,'hdg',dims,'heading','deg')
    create_nc_file(savename_new,GPS_c.roll,'roll',dims,'roll','deg')
    create_nc_file(savename_new,GPS_c.pitch,'pitch',dims,'pitch','deg')
    create_nc_file(savename_new,GPS_c.heave,'heave',dims,'heave','deg')

    %system(['wsl mv ',savename_new,' ',savename])
    system(['move /y ',savename_new,' ',savename]);

end

end