function WD_avg = average_WD(WD)
x = cos(pi/180 * (90 - WD));
y = sin(pi/180 * (90 - WD));
WD_avg = mod(90 - 180/pi * atan2(nanmean(y),nanmean(x)),360);
end