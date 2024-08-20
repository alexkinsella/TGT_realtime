function plot_timeseries(time,var,varname,unit)
ylab = {varname, ['[',unit,']']};
plot(time,var,"Color",'k','LineWidth',2)
ylabel(ylab)
xlim([min(time),max(time)])
end