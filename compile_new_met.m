function [MET_c] = compile_new_met(metdir,compiledir)

%initialize
MET_c = struct();
dims_c = ones(18,1);

%read in compiled data
path = [compiledir 'met_compiled.nc'];
info = ncinfo(path);
nv = length(info.Variables);
for iv = 1:nv
vname = info.Variables(iv).Name;
MET_c.(vname) = ncread(path,vname);
end

%read in missing files
flist = dir([metdir 'MET*.nc']);
fname = {}; for ifl = 1:length(flist); fname{ifl} = flist(ifl).name(5:end-3); end
fname_dd = days(datetime(fname,"InputFormat",'yyyyMMdd_HHmm') - datetime(2024,1,1));
imissing = find(fname_dd >= MET_c.dday(end));
for im = 1:length(imissing)
    MET = struct();
    disp(['Adding ', flist(imissing(im)).name])
    path = [metdir flist(imissing(im)).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    MET.(vname) = ncread(path,vname);
    end
    MET_c = compile_struct(MET,MET_c,dims_c);
end

%compile if there are missing files
if ~isempty(imissing)

    %compile into mat file
    sname_mat = 'met_compiled.mat';
    savename_mat = join([compiledir sname_mat],'');
    save(savename_mat,"MET_c");

    %compile into netcdf file
    sname = 'met_compiled.nc';
    savename = join([compiledir sname],'');
    savename_new = [savename(1:end-3),'_new.nc'];
    
%     %delete the existing file
%     if isfile(savename)
%     delete(savename)
%     end

    %save variables in netcdf file
    dims = {'dday',length(MET_c.dday)};
    create_nc_file(savename_new,MET_c.dday,'dday',dims,'decimal day','days since Jan 01, 2024')
    create_nc_file(savename_new,MET_c.lat,'lat',dims,'latitude','deg')
    create_nc_file(savename_new,MET_c.lon,'lon',dims,'longitude','deg')
    create_nc_file(savename_new,MET_c.TWS,'TWS',dims,'median true wind speed','m/s')
    create_nc_file(savename_new,MET_c.TWD,'TWD',dims,'median true wind  direction','deg')
    create_nc_file(savename_new,MET_c.TWS_SONIC,'TWS_SONIC',dims,'SONIC true wind speed','m/s')
    create_nc_file(savename_new,MET_c.TWD_SONIC,'TWD_SONIC',dims,'SONIC true wind  direction','deg')
    create_nc_file(savename_new,MET_c.TWS_port,'TWS_port',dims,'port true wind speed','m/s')
    create_nc_file(savename_new,MET_c.TWD_port,'TWD_port',dims,'port true wind  direction','deg')
    create_nc_file(savename_new,MET_c.TWS_stbd,'TWS_stbd',dims,'starboard true wind speed','m/s')
    create_nc_file(savename_new,MET_c.TWS_stbd,'TWD_stbd',dims,'starboard true wind  direction','deg')
    create_nc_file(savename_new,MET_c.RWS,'RWS',dims,'relative wind speed','m/s')
    create_nc_file(savename_new,MET_c.RWD,'RWD',dims,'relative wind direction','deg')
    create_nc_file(savename_new,MET_c.AT,'AT',dims,'atmospheric temperature','deg C')
    create_nc_file(savename_new,MET_c.RH,'RH',dims,'relative humidity','%')
    create_nc_file(savename_new,MET_c.P,'P',dims,'barometric pressure','mbar')
    create_nc_file(savename_new,MET_c.LW,'LW',dims,'longwave radiation','W/m^2')
    create_nc_file(savename_new,MET_c.SW,'SW',dims,'shortwave radiation','W/m^2')

    system(['move /y ',savename_new,' ',savename]);

end

end