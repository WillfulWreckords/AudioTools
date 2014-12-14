function ret = getFrameData(in,channel,frameNumber,NWIN,NOVERLAP)

NCOL = (size(in,1) - NWIN) / (NWIN - NOVERLAP) + 2;

n = 1;
j1 = frameSub2Idx(1, frameNumber, NWIN, NOVERLAP);
r = (1:NWIN)'-1;
J = bsxfun(@plus,r(:,ones(1,size(j1,2))),j1);
in = in(:,channel);
in(max(J(:))) = 0;
ret = in(J);