function x = to_column_vector(x)
%TO_COLUMN_VECTOR Summary of this function goes here
%   Detailed explanation goes here
if size(x,2) > size(x,1) 
    x = permute(x,[2,1]);
end
end

