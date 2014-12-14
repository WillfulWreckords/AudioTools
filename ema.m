function varargout = ema(x,N,fs)
%Exponential moving average of N data points
%
%[b a] = ema(Nsamples)
%[b a] = ema(Nseconds,samplingFrequesncy)
%
%y = ema(x,Nsamples)
%y = ema(x,Nseconds,samplingFrequesncy)

if isscalar(x)
    if nargin >=2
        x = x * N;
    end
    N = x;
    alpha = exp(-1.0/N);
    varargout{1} = 1-alpha;
    varargout{2} = [ 1  -alpha]; 
else
    x = double(x);
    x(~isfinite(x)) = 0;
    if nargin >=3
        N = N*fs;
    end
    if N ~= 0
        alpha = exp(-1.0/N);
        y = filter(1-alpha,[1 -alpha],x);
    else
        y = x;
    end
    varargout{1} = y;
    varargout{2} = 1-alpha;
    varargout{3} = [1  -alpha];
end
