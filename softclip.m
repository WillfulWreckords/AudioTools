function [y idxf idxl]= softclip(x,k)
% Performs soft clipping on input data
%  [y idxf idxl]= softclip(x,k)

if nargin <2
    k = 1;
end
if k < 0
    k = 10^(k/20);
end
sx = sign(x);
xa = abs(x);
y = xa;
for i = 1:size(x,2)
    xmx = (xa(:,i) > xa([2:end,end],i)) & ...
        (xa(:,i) > xa([1,1:end-1],i)) & ...
        (xa(:,i) > k);
    idx = find(xmx)';
    
    if isempty(idx)
        continue;
    end
    
    idxf = idx;
    idxl = idx;
    for j = 1:length(idx)
        while idxf(j) > 1 && xa(idxf(j),i) > k
            idxf(j) = idxf(j) - 1;
        end
        while idxf(j) > 1 && ...
                xa(idxf(j),i) >= xa(idxf(j)-1,i)
            idxf(j) = idxf(j) - 1;
        end
        
        while idxl(j) < size(x,1)-1 && xa(idxl(j),i) > k
            idxl(j) = idxl(j) + 1;
        end
        while idxl(j) < size(x,1)-1 && ...
                xa(idxl(j),i) >= xa(idxl(j)+1,i)
            idxl(j) = idxl(j) + 1;
        end
        t1 = xa(idxf(j):idx(j),i);
        mx1 = max(t1);
        mn1 = min(t1);
        t2 = xa(idx(j):idxl(j),i);
        mx2 = max(t2);
        mn2 = min(t2);
        y(idxf(j):idx(j),i) = (t1-mn1)*(k-mn1)/(mx1-mn1)+mn1;
        y(idx(j):idxl(j),i) = (t2-mn2)*(k-mn2)/(mx2-mn2)+mn2;
    end
end
y = sx.*y;