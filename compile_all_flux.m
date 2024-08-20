function [FLUX_c] = compile_all_flux(fluxdir,compiledir)

%loop through files
FLUX_c = struct();
dims = ones(9,1);
flist = dir([fluxdir 'FLUX*.nc']);
for ifl = 1:length(flist)
    FLUX = struct();
    path = [fluxdir flist(ifl).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    FLUX.(vname) = ncread(path,vname);
    end
    if ifl == 1
        FLUX_c = FLUX;
    else
        FLUX_c = compile_struct(FLUX,FLUX_c,dims);
    end
end

%create netcdf file
sname = 'flux_compiled.nc';
savename = join([compiledir sname],'');

%delete the existing file
if isfile(savename)
delete(savename)
end

%save variables in netcdf file
dims = {'dday',length(FLUX_c.dday)};
create_nc_file(savename,FLUX_c.dday,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
create_nc_file(savename,FLUX_c.lat,'lat',dims,'latitude','deg')
create_nc_file(savename,FLUX_c.lon,'lon',dims,'longitude','deg')
create_nc_file(savename,FLUX_c.tau,'tau',dims,'windstress','Pa')
create_nc_file(savename,FLUX_c.shf,'shf',dims,'sensible heat flux','w/m2')
create_nc_file(savename,FLUX_c.lhf,'lhf',dims,'latent heat flux','w/m2')
create_nc_file(savename,FLUX_c.lwdwn,'lwdwn',dims,'longwave down','w/m2')
create_nc_file(savename,FLUX_c.swdwn,'swdwn',dims,'shortwave down','w/m2')
create_nc_file(savename,FLUX_c.nhf,'nhf',dims,'net heat flux','w/m2')


end