function rms = getRMS(in,N,fs)
if nargin < 2
    N = 44100*.1;
end
if nargin >= 3
    N = 44100*fs;
end

rms = sqrt(ema(in.^2,N));