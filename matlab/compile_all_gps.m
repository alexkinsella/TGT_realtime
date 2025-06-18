function [GPS_c] = compile_all_gps(gpsdir,compiledir)
% create netcdf file with GPS data for specified start and end time

%loop through files
GPS_c = struct();
dims = [1,1,1,1,1,1,1,1,1];
flist = dir([gpsdir 'GPS*.nc']);
for ifl = 1:length(flist)
    GPS = struct();
    path = [gpsdir flist(ifl).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    GPS.(vname) = ncread(path,vname);
    end
    if ifl == 1
        GPS_c = GPS;
    else
        GPS_c = compile_struct(GPS,GPS_c,dims);
    end
end

%create netcdf file
sname = 'gps_compiled.nc';
savename = join([compiledir sname],'');

%delete the existing file
if isfile(savename)
delete(savename)
end

%save variables in netcdf file
dims = {'dday',length(GPS_c.dday)};
create_nc_file(savename,GPS_c.dday,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
create_nc_file(savename,GPS_c.lat,'lat',dims,'latitude','deg')
create_nc_file(savename,GPS_c.lon,'lon',dims,'longitude','deg')
create_nc_file(savename,GPS_c.cog,'cog',dims,'course over ground','deg')
create_nc_file(savename,GPS_c.sog,'sog',dims,'speed over ground','m/s')
create_nc_file(savename,GPS_c.hdg,'hdg',dims,'heading','deg')
create_nc_file(savename,GPS_c.roll,'roll',dims,'roll','deg')
create_nc_file(savename,GPS_c.pitch,'pitch',dims,'pitch','deg')
create_nc_file(savename,GPS_c.heave,'heave',dims,'heave','deg')

end