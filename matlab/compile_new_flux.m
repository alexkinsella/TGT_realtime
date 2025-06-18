function [FLUX_c] = compile_new_flux(fluxdir,compiledir)

%initialize
FLUX_c = struct();
dims_c = ones(9,1);

%read in compiled data
path = [compiledir 'flux_compiled.nc'];
info = ncinfo(path);
nv = length(info.Variables);
for iv = 1:nv
vname = info.Variables(iv).Name;
FLUX_c.(vname) = ncread(path,vname);
end

%read in missing files
flist = dir([fluxdir 'FLUX*.nc']);
fname = {}; for ifl = 1:length(flist); fname{ifl} = flist(ifl).name(6:end-3); end
fname_dd = days(datetime(fname,"InputFormat",'yyyyMMdd_HHmm') - datetime(2024,1,1));
imissing = find(fname_dd >= FLUX_c.dday(end));
for im = 1:length(imissing)
    FLUX = struct();
    disp(['Adding ', flist(imissing(im)).name])
    path = [fluxdir flist(imissing(im)).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    FLUX.(vname) = ncread(path,vname);
    end
    FLUX_c = compile_struct(FLUX,FLUX_c,dims_c);
end

%compile if there are missing files
if ~isempty(imissing)

    %compile into mat file
    sname_mat = 'flux_compiled.mat';
    savename_mat = join([compiledir sname_mat],'');
    save(savename_mat,"FLUX_c");

    %compile into netcdf file
    sname = 'flux_compiled.nc';
    savename = join([compiledir sname],'');
    savename_new = [savename(1:end-3),'_new.nc'];
    
    %delete the existing file
    %if isfile(savename)
    %delete(savename)
    %end

    %pause(5)
    
    %save variables in netcdf file
    dims = {'dday',length(FLUX_c.dday)};
    create_nc_file(savename_new,FLUX_c.dday,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
    create_nc_file(savename_new,FLUX_c.lat,'lat',dims,'latitude','deg')
    create_nc_file(savename_new,FLUX_c.lon,'lon',dims,'longitude','deg')
    create_nc_file(savename_new,FLUX_c.tau,'tau',dims,'windstress','Pa')
    create_nc_file(savename_new,FLUX_c.shf,'shf',dims,'sensible heat flux','w/m2')
    create_nc_file(savename_new,FLUX_c.lhf,'lhf',dims,'latent heat flux','w/m2')
    create_nc_file(savename_new,FLUX_c.lwdwn,'lwdwn',dims,'longwave down','w/m2')
    create_nc_file(savename_new,FLUX_c.swdwn,'swdwn',dims,'shortwave down','w/m2')
    create_nc_file(savename_new,FLUX_c.nhf,'nhf',dims,'net heat flux','w/m2')

    system(['move /y ',savename_new,' ',savename]);

end

end