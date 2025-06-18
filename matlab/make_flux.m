% Make fluxes for a given time

function make_flux(logstart,sharedrive)

% Fixed parameters
zu = 22.6;
zt = 15;
zq = 15;
alb = 0.1;
em = 0.97;
sb = 5.67e-8;

%% Read in netcdfs
metfile = join([sharedrive,':\For_Science\Situational_Awareness_Processing\data\met\MET_',logstart,'.nc'],'');

tsgfile = join([sharedrive,':\For_Science\Situational_Awareness_Processing\data\tsg\TSG_',logstart,'.nc'],'');

if isfile(metfile) & isfile(tsgfile)

    TWS = ncread(metfile,'TWS');
    AT = ncread(metfile,'AT');
    RH = ncread(metfile,'RH');
    P = ncread(metfile,'P');
    SST = ncread(tsgfile,'T');
    SWdwn = ncread(metfile,'SW');
    LWdwn = ncread(metfile,'LW');
    lat = ncread(metfile,'lat');
    lon = ncread(metfile,'lon');
    dday = ncread(metfile,'dday');
    
    %% Compute
    A = coare35vn(TWS,zu,AT,zt,...
        RH,zq,P,SST,...
        SWdwn,LWdwn,lat,NaN,NaN,NaN,NaN);
    
    tau = A(:,2);
    shf = A(:,3);
    lhf = A(:,4);
    LWnet = em*(LWdwn-sb*((SST+273.15).^4));
    
    nhf = (1-alb)*SWdwn + LWnet - shf - lhf;
    
    %% Write netcdf
    savename = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\flux\FLUX_',logstart,'.nc'];
    
    %delete the existing file
    if isfile(savename)
    delete(savename)
    end
    
    dims = {'dday',length(dday)};
    create_nc_file(savename,dday,'dday',dims,'decimal day (UTC)','days since Jan 01, 2024')
    create_nc_file(savename,lat,'lat',dims,'latitude','deg')
    create_nc_file(savename,lon,'lon',dims,'longitude','deg')
    create_nc_file(savename,tau,'tau',dims,'windstress','Pa')
    create_nc_file(savename,shf,'shf',dims,'sensible heat flux','w/m2')
    create_nc_file(savename,lhf,'lhf',dims,'latent heat flux','w/m2')
    create_nc_file(savename,LWdwn,'lwdwn',dims,'longwave down','w/m2')
    create_nc_file(savename,SWdwn,'swdwn',dims,'shortwave down','w/m2')
    create_nc_file(savename,nhf,'nhf',dims,'net heat flux','w/m2')

    disp(["Created FLUX file for ",logstart])

else
    disp(['No met and/or TSG for ',logstart])

end

