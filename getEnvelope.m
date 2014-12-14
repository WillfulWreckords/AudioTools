function y = getEnvelope(in,N,fs)
%Gets the exponential moving average envelope
%y = getEnvelope(in,s,fs)
%y = getEnvelope(in,N)
if nargin < 2
    N = 44100*.1;
end
if nargin >= 3
    N = 44100*fs;
end
y = ema(abs(in),N);