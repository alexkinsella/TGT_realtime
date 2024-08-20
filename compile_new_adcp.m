function [ADCP_c] = compile_new_adcp(adcpdir,compiledir)

%initialize
ADCP_c = struct();
dims_c = ones(7,1); dims_c(4:end) = 2;

%read in compiled data
path = [compiledir 'adcp_compiled.nc'];
info = ncinfo(path);
nv = length(info.Variables);
for iv = 1:nv
vname = info.Variables(iv).Name;
ADCP_c.(vname) = ncread(path,vname);
end

%read in missing files
flist = dir([adcpdir 'ADCP*.nc']);
fname = {}; for ifl = 1:length(flist); fname{ifl} = flist(ifl).name(6:end-3); end
fname_dd = days(datetime(fname,"InputFormat",'yyyyMMdd_HHmm') - datetime(2024,1,1));
imissing = find(fname_dd >= ADCP_c.dday(end));
for im = 1:length(imissing)
    ADCP = struct();
    disp(['Adding ', flist(imissing(im)).name])
    path = [adcpdir flist(imissing(im)).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    ADCP.(vname) = ncread(path,vname);
    end
    ADCP_c = compile_struct(ADCP,ADCP_c,dims_c);
end

%compile if there are missing files
if ~isempty(imissing)
    
    %compile into mat file
    sname_mat = 'adcp_compiled.mat';
    savename_mat = join([compiledir sname_mat],'');
    save(savename_mat,"ADCP_c");

    %compile into netcdf file
    sname = 'adcp_compiled.nc';
    savename = join([compiledir sname],'');
    savename_new = [savename(1:end-3),'_new.nc'];
    
    %delete the existing file
    %if isfile(savename)
    %delete(savename)
    %end

    %pause(5)
    
    %save variables in netcdf files
    dims1 = {'dday',length(ADCP_c.dday)};
    dims2 = {'depth_cell',size(ADCP_c.depth,1),'dday',length(ADCP_c.dday)};
    create_nc_file(savename_new,ADCP_c.dday,'dday',dims1,'decimal day (UTC)','days since Jan 01, 2024')
    create_nc_file(savename_new,ADCP_c.lat,'lat',dims1,'latitude','deg')
    create_nc_file(savename_new,ADCP_c.lon,'lon',dims1,'longitude','deg')
    create_nc_file(savename_new,ADCP_c.u,'u',dims2,'eastward velocity','m/s')
    create_nc_file(savename_new,ADCP_c.v,'v',dims2,'northward velocity','m/s')
    create_nc_file(savename_new,ADCP_c.depth,'depth',dims2,'depth','m')
    create_nc_file(savename_new,ADCP_c.amp,'amp',dims2,'received signal strength','')

    system(['move /y ',savename_new,' ',savename]);

end

end