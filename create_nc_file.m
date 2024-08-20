function create_nc_file(fname,var,vname,dims,long_name,units)
nccreate(fname,vname,'Dimensions',dims); 
ncwrite(fname,vname,var); 
ncwriteatt(fname,vname,'long_name',long_name)
ncwriteatt(fname,vname,'units',units)
end