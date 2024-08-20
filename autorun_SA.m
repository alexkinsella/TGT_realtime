% Run script to process and upload SA with a specified period 

function autorun_SA(per,sharedrive,datadrive)

while true
    situational_awareness_main(sharedrive,datadrive)
    disp(['Compiling files...'])
    compile_main(sharedrive)
    disp(['Done at ',datestr(now),'. Waiting for next run...'])
    pause(60*per)
end