function ret = getFrameData(in,channel,frameNumber,NWIN,NOVERLAP)
%ret = getFrameData(in,channel,frameNumber,NWIN,NOVERLAP)
%
%Extracts a specific frame of data
i = frameSub2Idx(1:NWIN, frameNumber, NWIN, NOVERLAP);
ret=in(i,channel);
