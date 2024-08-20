function y=convert_tom(x)

flag=-8888.;

i=find(x==flag);

xdeg=fix(x/100);
xmin=x-(xdeg*100);
y=xdeg+(xmin/60);

y(i)=flag;
