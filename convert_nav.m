function y=convert_nav(x)
xdeg=fix(x/100);
xmin=x-(xdeg*100);
y=xdeg+(xmin/60);
end