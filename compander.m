function [y gain env]=compander(x,fs,ig,threshold,ratio,og,tatt,trel,tla,twnd,isExpander)
%y=compander(x,fs,ig,threshold,ratio,og,tatt,trel,tla,twnd,isExpander)
%
%x = [M x N] N-Channel signals
%fs = sampling frequency (samples/sec)
%ig = input gain in dB (0.0 := no change)
%threshold = threshold in dB
%ratio = the ratio (i.e. 10 for a 10:1 compressor or expander)
%og = output gain in dB (0.0 := no change)
%tatt = attack time (in ms)
%trel = release time(in ms)
%tla = lookahead / lookback time (in ms)
%twnd = size of window (in ms) for computing rms(x) if zero or 1
%       peak value used.
if nargin<1 || isempty(x)
    x = sin(2*pi*440/44100*(1:500))';    
end
if nargin < 2 || isempty(fs)
    fs = 44100;
end
if nargin < 3 || isempty(ig)
    ig = 0;
end
if nargin < 4 || isempty(threshold)
    threshold = -10;
end
threshold = 10^(threshold/20);
if nargin < 5 || isempty(ratio)
    ratio = 2;
end
if(isfinite(ratio))
    slope = 1/ratio;
else
    slope = 0;
end

if nargin < 6 || isempty(og)
    og = 0;
end
if nargin < 7 || isempty(tatt)
    tatt = 0;
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
if nargin < 11 || isempty(isExpander)
    isExpander = 0;
end

x = x*10^(ig/20);

tla = tla - twnd / 2;
tla = tla * .001;                %lookahead time to seconds
twnd = twnd * .001;              % window time to seconds
tatt =tatt * .001;               % attack time to seconds
trel =trel * .001;               % release time to seconds

% attack and release "per sample decay"
if tatt==0
    att=0;
else
    att = exp(-1.0/(fs*tatt));
end
if trel==0
    rel=0;
else
    rel = exp(-1.0/(fs*trel));
end

% sample offset to lookahead wnd start
lhsmp = fix( (fs * tla) );

%samples count in lookahead window
nrms = max(1,fix( (fs * twnd) ));

%calculate rms in lookahead window...
n = size(x,1);
mono = mean(x,2);

%apply lokahead / lookback...
monos = circshift(mono,-lhsmp);

if nrms > 1
    %using cumsum() instead of conv() for efficiency
    mono2 = monos.^2;
    mono2c = cumsum(mono2);
    a = zeros(size(mono2c));
    b = ones(size(mono2c))*mono2c(end);
    i = 1:n;
    ai = i-fix(nrms/2)-1; 
    bi = i+fix(nrms/2); 
    a(ai>0) = mono2c(ai(ai>0));
    b(bi<=n) = mono2c(bi(bi<=n));
    rms = sqrt((b-a)/nrms);
else
    rms = abs(monos);
end
%rms = sqrt(conv(mono2,ones(nrms,1)/nrms,'same'));

%Envelope params...
gain = ones(size(mono));

%Compute the envelope activation function
env = rms;
for i=2:length(rms)
    if (isExpander)
        if(rms(i)<threshold)
            a = att;
        else
            a = rel;
        end
    else
        if(rms(i)>threshold)
            a = att;
        else
            a = rel;
        end
    end
    env(i) = (1-a)*rms(i)+a*env(i-1);
end

%yi=t-st
%y=sx+t-st

%now compute gain
if (isExpander)
    gain(env<threshold) = max(0,1/slope + threshold*(1-1/slope)./env(env<threshold));
else
    gain(env>threshold) = max(0,slope+(1-slope)*threshold./env(env>threshold));
end
%apply to all channels 
y = bsxfun(@times,x,gain);

%Apply output gain
y = y*10^(og/20);

if nargout == 0
    figure(1)
    plot(x);
    hold on;
    plot(y);
    hold off;
    drawnow;
    
    
    [sx ix] = sort(x(y~=0));
    yt = y(y~=0);
    
    figure(2)
    plot(sx,yt(ix),'.');
    drawnow;
end

