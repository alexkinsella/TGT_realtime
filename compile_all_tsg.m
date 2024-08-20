function [TSG_c] = compile_all_tsg(tsgdir,compiledir)
% create netcdf file with GPS data for specified start and end time

%loop through files
TSG_c = struct();
dims = ones(8,1);
flist = dir([tsgdir 'TSG*.nc']);
for ifl = 1:length(flist)
    TSG = struct();
    path = [tsgdir flist(ifl).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    TSG.(vname) = ncread(path,vname);
    end
    if ifl == 1
        TSG_c = TSG;
    else
        TSG_c = compile_struct(TSG,TSG_c,dims);
    end
end

%create netcdf file
sname = 'tsg_compiled.nc';
savename = join([compiledir sname],'');

%delete the existing file
if isfile(savename)
delete(savename)
end

%save variables in netcdf file
dims = {'dday',length(TSG_c.dday)};
create_nc_file(savename,TSG_c.dday,'dday',dims,'decimal day','days since Jan 01, 2024')
create_nc_file(savename,TSG_c.lat,'lat',dims,'latitude','deg')
create_nc_file(savename,TSG_c.lon,'lon',dims,'longitude','deg')
create_nc_file(savename,TSG_c.T,'T',dims,'temperature','deg C')
create_nc_file(savename,TSG_c.intakeT,'intakeT',dims,'intake temperature','deg C')
create_nc_file(savename,TSG_c.S,'S',dims,'salinity','psu')
create_nc_file(savename,TSG_c.C,'C',dims,'conductivity','V')
create_nc_file(savename,TSG_c.sound_speed,'sound_speed',dims,'sound speed','m/s')

end