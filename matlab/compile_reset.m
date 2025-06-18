function compile_reset(sharedrive)
% Compile situational awareness data

%initialize
% sharedrive = 'Y'; datadrive = 'Z'; %for testing
compiledir = [sharedrive,':\For_Science\Situational_Awareness_ShipboardData\'];

%compile GPS data
gpsdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\gps\'];
% [~] = compile_all_gps(gpsdir,compiledir);
% [~] = compile_new_gps(gpsdir,compiledir);

%compile TSG data
tsgdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\tsg\'];
% [~] = compile_all_tsg(tsgdir,compiledir);
% [~] = compile_new_tsg(tsgdir,compiledir);

%compile MET data
metdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\met\'];
[~] = compile_all_met(metdir,compiledir);
% [~] = compile_new_met(metdir,compiledir);

%compile WAMOS data
wamosdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\wamos\'];
% [~] = compile_all_wamos(wamosdir,compiledir);
% [~] = compile_new_wamos(wamosdir,compiledir);

%compile flux data
fluxdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\flux\'];
[~] = compile_all_flux(fluxdir,compiledir);
% [~] = compile_new_flux(fluxdir,compiledir);

%compile ADCP data
adcpdir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\adcp\'];
% [~] = compile_all_adcp(adcpdir,compiledir);
% [~] = compile_new_adcp(adcpdir,compiledir);

end