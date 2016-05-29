[x fs] = audioread('pray.wav');

levels = 12;

n = 2^(levels); %also number of subbands
ks = fs*4*60;
x = x(ks:end);
%ke = fs*5*60;
%x = x(ks:ke);

xn=x;
N = 2^levels;
k = ceil(length(x)/N)*N;
xn(k)=0;

% Default asymmetric structure with
% Daubechies order 3 extremal phase wavelet
Ha = dsp.DyadicAnalysisFilterBank('NumLevels',levels,'TreeStructure','Symmetric');
Hs = dsp.DyadicSynthesisFilterBank('NumLevels',levels,'TreeStructure','Symmetric');
Y = step(Ha,xn);
Yr=reshape(Y,size(xn,1)/n,n);
%Yr(:,1:end/2)=0;
xden = step(Hs, Yr(:));

ms = .030;
NFFT = 512;
NOVERLAP = floor(fs*ms/2);
NWIN = NOVERLAP * 2 + 1;
X = framedata(x,NWIN,NOVERLAP);
Xden = framedata(xden(:),NWIN,NOVERLAP);
Y = fftshift(fft(X,NFFT));

CEP = fftshift(fft(20*log10(abs(Y)+eps),NFFT));
CEPf = conv2(CEP,[1;1;1]/3,'same');
Yw = ifft(ifftshift(CEPf,NFFT));
Yw = abs(Yw);
Yw = Yw / max(Yw(:));
Yden = Y.*Yw;
Xden = ifft(ifftshift(Yden,NFFT),NFFT);
xden = iframedata(Xden,NOVERLAP,NWIN);

Yden = fftshift(fft(Xden,NFFT));

%p = audioplayer(xn,fs);
%p0 = audioplayer(x,fs);
%play(p);

xl = 1:size(Y,2);
xl = xl/fs;

yl = 1:size(Y,1);
yl = ((yl/size(Y,1)*2-1)*fs/2);

figure(1), imagesc(xl,yl,20*log10(abs(Y)+eps));
colorbar;
xlabel('time');
ylabel('frequency');

figure(2), imagesc(xl,yl,20*log10(abs(Yden)+eps));
colorbar;
axis xy;
xlabel('time');
ylabel('frequency');

figure(3), imagesc(xl,yl,Yf);
colorbar;
axis xy;
xlabel('time');
ylabel('frequency');

drawnow;