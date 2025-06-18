function situational_awareness_reset(start,stop,sharedrive,datadrive)
% Situational awareness processing code for ASTRAL 2024 IOP1
% Ankitha Kannad and Alex Kinsella

%refresh for each run
%clear;

%initialize
datadir = [sharedrive,':\For_Science\Situational_Awareness_Processing\data\'];

%generate files to loop over
today = datetime("now",'TimeZone','UTC'); 
disp(join(['Run time:' string(today)]))

%cruisestart = datetime(2024,4,27,22,50,00); %start of cruise
% cruisestart = datetime(2024,5,17,00,00,00); %start of leg 2
% yr = year(today); mn = month(today); dy = day(today); hr = hour(today); mm = minute(today) - mod(minute(today),10);
% cruisetemp = datetime(yr,mn,dy,hr,mm,0); %temporary end time

loopint = minutes(10);
looptime = start:loopint:stop;
loopfile = string(looptime,'yyyyMMdd_HHmm');

% %check if file exists and generate GPS file
% for il = 1:length(loopfile)-1
%     filename = join([datadir 'gps\' 'GPS_', loopfile(il),'.nc'],'');
%     if ~isfile(filename)
%         logstart = loopfile(il); logend = loopfile(il+1);
%         read_gps(logstart,logend,sharedrive,datadrive)
%         pause(0.01)
%     end
% end
% 
% %check if file exists and generate TSG file
% for il = 1:length(loopfile)-1
%     filename = join([datadir 'tsg\' 'TSG_', loopfile(il),'.nc'],'');
%     if ~isfile(filename)
%         logstart = loopfile(il); logend = loopfile(il+1);
%         read_tsg(logstart,logend,sharedrive,datadrive)
%         pause(0.01)
%     end
% end

%check if file exists and generate MET file
for il = 1:length(loopfile)-1
    filename = join([datadir 'met\' 'MET_', loopfile(il),'.nc'],'');
%     if ~isfile(filename)
        logstart = loopfile(il); logend = loopfile(il+1);
        read_met(logstart,logend,sharedrive,datadrive)
        pause(0.01)
%     end
end

% %check if file exists and generate WAMOS file
% for il = 1:length(loopfile)-1
%     filename = join([datadir 'wamos\' 'WAMOS_', loopfile(il),'.nc'],'');
%     if ~isfile(filename)
%         logstart = loopfile(il); logend = loopfile(il+1);
%         read_wamos(logstart,logend,sharedrive,datadrive)
%         pause(0.01)
%     end
% end
% 
% % Generate new ADCP files
% chunk_ADCP(sharedrive,datadrive)

%check if file exists and generate FLUX file
for il = 1:length(loopfile)-1
    filename = join([datadir 'flux\' 'FLUX_', loopfile(il),'.nc'],'');
%     if ~isfile(filename) && isfile(join([datadir 'met\' 'MET_', loopfile(il),'.nc'],'')) && isfile(join([datadir 'tsg\' 'TSG_', loopfile(il),'.nc'],''))
    if isfile(join([datadir 'met\' 'MET_', loopfile(il),'.nc'],'')) && isfile(join([datadir 'tsg\' 'TSG_', loopfile(il),'.nc'],''))
        logstart = loopfile(il);
        make_flux(logstart{1},sharedrive)
        pause(0.01)
    end
end
