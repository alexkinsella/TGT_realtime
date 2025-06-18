function [TSG_c] = compile_new_tsg(tsgdir,compiledir)

%initialize
TSG_c = struct();
dims_c = ones(8,1);

%read in compiled data
path = [compiledir 'tsg_compiled.nc'];
info = ncinfo(path);
nv = length(info.Variables);
for iv = 1:nv
vname = info.Variables(iv).Name;
TSG_c.(vname) = ncread(path,vname);
end

%read in missing files
flist = dir([tsgdir 'TSG*.nc']);
fname = {}; for ifl = 1:length(flist); fname{ifl} = flist(ifl).name(5:end-3); end
fname_dd = days(datetime(fname,"InputFormat",'yyyyMMdd_HHmm') - datetime(2024,1,1));
imissing = find(fname_dd >= TSG_c.dday(end));
for im = 1:length(imissing)
    TSG = struct();
    disp(['Adding ', flist(imissing(im)).name])
    path = [tsgdir flist(imissing(im)).name];
    info = ncinfo(path);
    nv = length(info.Variables);
    for iv = 1:nv
    vname = info.Variables(iv).Name;
    TSG.(vname) = ncread(path,vname);
    end
    TSG_c = compile_struct(TSG,TSG_c,dims_c);
end

%compile if there are missing files
if ~isempty(imissing)

    %compile into mat file
    sname_mat = 'tsg_compiled.mat';
    savename_mat = join([compiledir sname_mat],'');
    save(savename_mat,"TSG_c");

    %compile into netcdf file
    sname = 'tsg_compiled.nc';
    savename = join([compiledir sname],'');
    savename_new = [savename(1:end-3),'_new.nc'];
    
    %delete the existing file
    %if isfile(savename)
    %delete(savename)
    %end

    %pause(5) 
    
    %save variables in netcdf file
    dims = {'dday',length(TSG_c.dday)};
    create_nc_file(savename_new,TSG_c.dday,'dday',dims,'decimal day','days since Jan 01, 2024')
    create_nc_file(savename_new,TSG_c.lat,'lat',dims,'latitude','deg')
    create_nc_file(savename_new,TSG_c.lon,'lon',dims,'longitude','deg')
    create_nc_file(savename_new,TSG_c.T,'T',dims,'temperature','deg C')
    create_nc_file(savename_new,TSG_c.intakeT,'intakeT',dims,'intake temperature','deg C')
    create_nc_file(savename_new,TSG_c.S,'S',dims,'salinity','psu')
    create_nc_file(savename_new,TSG_c.C,'C',dims,'conductivity','V')
    create_nc_file(savename_new,TSG_c.sound_speed,'sound_speed',dims,'sound speed','m/s')

    %system(['wsl mv ','"',savename_new,'" "',savename,'"'])
    %system(['wsl mv ','"',['/mnt/ekamsat24_share/For_Science/Situational_Awareness_ShipboardData/',sname(1:end-3),'_new.nc'],'" "',['/mnt/ekamsat24_share/For_Science/Situational_Awareness_ShipboardData/',sname],'"'])
    system(['move /y ',savename_new,' ',savename]);

end

end