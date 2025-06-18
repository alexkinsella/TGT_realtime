function [data_c] = compile_struct(data,data_c,dim)
%Compile 1D structure
varnames = fieldnames(data);
for iv = 1:length(varnames)
    data_c.(varnames{iv}) = cat(dim(iv),data_c.(varnames{iv}),data.(varnames{iv}));
end
end