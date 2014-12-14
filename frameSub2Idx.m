function i = frameSub2Idx(r,c,NWIN,NOVERLAP)

if (numel(r)>1 && numel(c)>0)
    i = r(:,ones(1,size(c,2))) + (c(ones(size(r,1),1),:)-1).*(NWIN-NOVERLAP);
else
    i = r + (c-1) .* (NWIN - NOVERLAP);
end