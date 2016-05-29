function [y gain env]=compressor(x,fs,ig,threshold,ratio,og,tatt,trel,tla,twnd)
%y=compressor(x,fs,ig,threshold,ratio,og)
%y=compressor(x,fs,ig,threshold,ratio,og,tatt)
%y=compressor(x,fs,ig,threshold,ratio,og,tatt,trel)
%y=compressor(x,fs,ig,threshold,ratio,og,tatt,trel,tla,twnd)
%
%adapted from http://www.musicdsp.org/archive.php?classid=4#169
%
%x = [M x N] N-Channel signals
%fs = sampling frequency (samples/sec)
%ig = input gain in dB (0.0 := no change)
%threshold = in dB
%ratio = the compression ratio (i.e. 10 for a 10:1 compressor)
%og = output gain in dB (0.0 := no change)
%tatt = attack time (in ms)
%trel = release time(in ms)
%tla = lookahead / lookback time (in ms)
%twnd = size of lookahead window (in ms) for computing rms(x) if zero or 1
%       peak value used.


if nargin < 3 || isempty(ig)
    ig = 0;
end
if nargin < 4 || isempty(threshold)
    threshold = -10;
end
if nargin < 5 || isempty(ratio)
    ratio = 10;
end 
if nargin < 6 || isempty(og)
    og = 0;
end
if nargin < 7 || isempty(tatt)
    tatt = 1;
end
if nargin < 8 || isempty(trel)
    trel = tatt;
end
if nargin < 9 || isempty(tla)
    tla = tatt; 
end
if nargin < 10 || isempty(twnd)
    twnd = 0;
end

[y gain env]=compander(x,fs,ig,threshold,ratio,og,tatt,trel,tla,twnd,0);
