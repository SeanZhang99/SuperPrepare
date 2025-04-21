function save_pickle(pickle_pkg,path,ojb)
%SAVE Summary of this function goes here
%   Detailed explanation goes here
fid = py.open(path,"wb");
pickle_pkg.dump(ojb,fid);
fid.close;
end

