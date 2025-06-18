function [ADCP_c] = compile_all_adcp(adcpdir,compiledir)

%loop through files
ADCP_c = struct();
dims = ones(7,1); dims(4:end) = 2;
flist = dir([adcpdir 'ADCP*.nc']);
for ifl = 1:length(flist)
    ADCP = struct();
    path = [adcpdir flist(ifl).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    ADCP.(vname) = ncread(path,vname);
    end
    if ifl == 1
        ADCP_c = ADCP;
    else
        ADCP_c = compile_struct(ADCP,ADCP_c,dims);
    end
end

%create netcdf file
sname = 'adcp_compiled.nc';
savename = join([compiledir sname],'');

%delete the existing file
if isfile(savename)
delete(savename)
end

%save variables in netcdf file
dims1 = {'dday',length(ADCP_c.dday)};
dims2 = {'depth_cell',size(ADCP_c.depth,1),'dday',length(ADCP_c.dday)};
create_nc_file(savename_new,ADCP_c.dday,'dday',dims1,'decimal day (UTC)','days since Jan 01, 2024')
create_nc_file(savename_new,ADCP_c.lat,'lat',dims1,'latitude','deg')
create_nc_file(savename_new,ADCP_c.lon,'lon',dims1,'longitude','deg')
create_nc_file(savename_new,ADCP_c.u,'u',dims2,'eastward velocity','m/s')
create_nc_file(savename_new,ADCP_c.v,'v',dims2,'northward velocity','m/s')
create_nc_file(savename_new,ADCP_c.depth,'depth',dims2,'depth','m')
create_nc_file(savename_new,ADCP_c.amp,'amp',dims2,'received signal strength','')

end