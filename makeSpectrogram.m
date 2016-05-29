function [Y t f] = makeSpectrogram(x,fs,nsec,nfft,H)
%Compute the spectrogram image of the input audio data.
%
% [Y t f] = makeSpectrogram(x,fs,sec,nfft)
% [Y t f] = makeSpectrogram(x,fs,sec,nfft,H)
%
% Y := output image equal to 20*log10(abs(FFT(xf,nfft)+eps)), where xf is
% the framed audio data with frames of length nsec.
%
% x := is the input signal vector.  If ncols(x) > 1, x will be averaged
% across the columns.
%
% fs := the sampling frequency of x
%
% nsec := length of the window to use for each spectrum computation
% (default .030 sec)
%
% nfft := size of the FFT to use when computing the spectrum in each
% window. Default is 256.
%  
% H := the anti-aliasing vector to apply to each window frame. Default =
% hann(NFFT).

if nargin < 3
    ms = .030;
else
    ms = nsec / 1000;
end

if nargin < 4
    NFFT = 256;
else
    NFFT = nfft;
end

if nargin <  5
    H = hann(NFFT);
end

if size(x,2) > 1
    %turn into mono
    x = mean(x,2);
end

NOVERLAP = floor(fs*ms/2);
NWIN = NOVERLAP * 2 + 1;
X = framedata(x(:),NWIN,NOVERLAP);
X = bsxfun(@times,X,H);
Y = 20*log10(abs(fftshift(fft(X,NFFT)))+eps);

t = 1:size(Y,2);
t = t/fs;

f = 1:size(Y,1);
f = ((f/size(Y,1)*2-1)*fs/2);