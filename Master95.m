function [ output_args ] = Master95( varargin )
%MASTER95 performs an 95% mastering solution to a set of input files or
%directories.  It normalizes the volume of all input files, applies an
%accross the board fequency matching eq if a "template.wav" file exists in
%the directory, then performs a basic dual-band compression followed by a
%brick wall limiter.
%
%Master95(<args>, dir)
%Master95(<args>, file1,file2,file3,...)
%
%Where <args> is string value pairs with the following options
% -'tempate' <template_filename>  template file for frequency EQ
% -'blending' <value> blending value for matching EQ profiles (0<value<1)
% -'smoothing' <value> Frequency spectrum smoothing param (0<value<1)
% -'min_v' <value> digital value to use as silence threshold 
% -'min_db' <value> db value to use as silence threshold
% -'rms_v' <value> digital value to use as rms target (before compression)
% -'rms_db' <value> db value to use as rms target (before compression)


warning off all
FS = 44100;
NWINms = 30;
Nsec = .001;
NOVERLAP = floor(NWINms*Nsec/2*FS);
NWIN = NOVERLAP*2;
NFFT = NWIN;
SMOOTHING = .1;
BLENDING = .5;
CLIP_SILENCE = 1;
MIN_V = 10^(-80/20);
MAX_V = 10^(-0.1/20);
RMSa = 10^(-15/20);
Nstd = -2;

%Filterbank params...
FORDER=3;                   %Filter order
FC = 250;                   %Cutoff Frequescy

%Compression Params Brickwall...
THRESHOLD=-10;                %-10dB threshold
RATIO=100;                  %100:1 ratio
LOOKAHEAD=0;                %lookahead time (ms)
LOOKSIZE=10;                %RMS computation window size (ms)
ATTACK=.05;                 %attack time (ms)
RELEASE=10;                 %release time (ms)
IGAIN = 3.5;                  %output gain (dB)
OGAIN = 0;                  %input gain (dB)

%Compression Params Low...
TLow=-8.7;                  %Threshold
RLow=2.34;                  %Compression Ratio
LLow=0;                     %lookahead time (ms)
LSLow=10;                   %RMS computation window size (ms)
ATTLow=1;                   %attack time (ms)
RELLow=62;                  %release time (ms)
GLow = 5.6;                 %output gain (dB)
ILow = 0.0;                 %input gain (dB)

%Compression Params High...
THigh=-6.6;                 %threshold
RHigh=2.86;                 %ratio
LHigh=0;                    %lookahead time (ms)
LSHigh=10;                  %RMS computation window size (ms)
ATTHigh=5.08;               %attack time (ms)
RELHigh=114;                %release time (ms)
GHigh = 4.0;                %output gain (dB)
IHigh = 0.0;                %input gain (dB)

%Metadata
artist = 'Unknown Artist';
album = 'Unknown Album';
copyright = [char(169),' ', datestr(now,'YYYY'), ' Willful Wreckords, LLC'];

%Variable init
template = [];
fileList = {};
i = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Process Arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while i<=nargin
    var = varargin{i};
    if (var(1) == '-')
        %Is start of a string value flag set...
        if strcmpi(var,'-artist')
            %Unused for now
            artist = varargin{i+1};
        elseif strcmpi(var,'-album')
            %Unused for now
            album = varargin{i+1};
        elseif strcmpi(var,'-copy')
            %Unused for now
            copyright = varargin{i+1};
        elseif strcmpi(var,'-template')
            template = varargin{i+1};
        elseif strcmpi(var,'-min_v') || strcmpi(var,'-min_db')
            if ischar(varargin{i+1})
                MIN_V = str2double(varargin{i+1});
            else
                MIN_V = varargin{i+1};
            end
            if MIN_V < 0
                MIN_V = 10^(MIN_V/20);
            end
        elseif strcmpi(var,'-max_v') || strcmpi(var,'-max_db')
            if ischar(varargin{i+1})
                MAX_V = str2double(varargin{i+1});
            else
                MAX_V = varagin{i+1};
            end
            if MAX_V <= 0
                MAX_V = 10^(MAX_V/20);
            end
        elseif strcmpi(var,'-rms_v') || strcmpi(var,'-rms_db')
            if ischar(varargin{i+1})
                RMSa = str2double(varargin{i+1});
            else
                RMSa = varargin{i+1};
            end
            if RMSa <= 0
                RMSa = 10^(RMSa/20);
            end
        elseif (strcmpi(var,'-blending'))
            if ischar(varargin{i+1})
                BLENDING = str2double(varargin{i+1});
            else
                BLENDING = varargin{i+1};
            end
        elseif (strcmpi(var,'-smoothing'))
            
            if ischar(varargin{i+1})
                SMOOTHING = str2double(varargin{i+1})/2;
            else
                SMOOTHING = varargin{i+1}/2;
            end
        end
        i = i+1;
    else
        %starting the file/dir list
        if (isdir(var))
            if (var(end)~=filesep)
                var(end+1) = filesep;
            end
            D = dir([var,'*.wav']);
            for k=1:length(D)
                fileList{end+1} = [var,D(k).name];
            end
            D = dir([var,'*.wav.template']);
            for k=1:length(D)
                template = [var,D(k).name];
            end
        else
            fileList{end+1} = var;
        end
    end
    i = i+1;
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RMS normalization.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
names = cell(size(fileList));
for i=1:length(fileList)
    file = fileList{i};
    
    found = strfind(file,filesep);
    if (isempty(found))
        found = 1;
        fn = file;
        d = '';
    else
        d = file(1:found(end));
        fn = file(found(end)+1:end);
    end
    
    if strcmpi(fn,'template.wav')
        template = file;
    end
    
    found = strfind(file,filesep);
    if (isempty(found))
        found = 1;
    end
    name = file(found(end)+1:end);
    names{i} = name;
end

%FORDER = 3
%b_low =  1.0e-04 * [0.0545    0.1636    0.1636    0.0545]
%a_low =  [1.0000   -2.9288    2.8600   -0.9312]
%b_high = [0.9650   -2.8950    2.8950   -0.9650]
%a_high = [1.0000   -2.9288    2.8600   -0.9312]
[b_low a_low] = butter(FORDER,FC/FS*2,'low');
[b_high a_high] = butter(FORDER,FC/FS*2,'high');
if SMOOTHING > 0 && SMOOTHING < 1
    [b_smooth a_smooth] = butter(FORDER,SMOOTHING,'low');
    %[b_smooth a_smooth] = ema(SMOOTHING,FS);
else
    b_smooth = 1;
    a_smooth = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get Template Frequesncy Response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(template)
    file = template;
    
    [wavo fs nbits] = wavread(file);
    wav = wavo / max(max(abs(wavo)))*.5; %normalize peaks
    
    %Remove silence from template
    xrms = getRMS(wav);
    sil = max(xrms > MIN_V,[],2);
    start = find(sil, 1, 'first');
    stop = find(sil, 1, 'last');
    if isempty(start)
        start = 1;
    end
    if isempty(stop)
        stop = size(wav,1);
    end
    wav = wav(start:stop,:);
    
    %Compute the FFT
    frames = framedata(mean(wav,2),NWIN,NOVERLAP);
    w = hamming(size(frames,1));
    x = bsxfun(@times,frames,w);
    F = fft(x);
    Pw = sqrt(sum(F.*F));
    Fmean = abs(mean(F(:,Pw>(mean(Pw)+Nstd*std(Pw))),2));
    
    template = Fmean;
    templateAudio = wav;
    Ftemplate = F;
    
    %Smooth if necessary
    if SMOOTHING>0 && SMOOTHING<1
        template = ifftshift(filtfilt(b_smooth,a_smooth,fftshift(template,1)),1);
    end
    template(template<0) = 0;
end

for i=1:length(fileList)
    
    file = fileList{i};
    found = strfind(file,filesep);
    if (isempty(found))
        found = 1;
        fn = file;
        d = '';
    else
        d = file(1:found(end));
        fn = file(found(end)+1:end);
    end
    
    if strcmpi(fn,'template.wav')
        continue;
    end
    
    [status,message,messageid] =  mkdir([d,'Master95Outputs',filesep]);
    
    %[wavo fs nbits] = wavread(file);
    [wavo fs] = audioread(file);
    
    %wavwrite(wavo,fs,[d,'Master95Outputs',filesep,'in_',fn]);
    audiowrite([d,'Master95Outputs',filesep,'in_',fn],wavo,fs);
    
    wav = wavo / max(max(abs(wavo)))*.5;
    
    %wavwrite(wav,fs,[d,'Master95Outputs',filesep,'n_',fn]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Trim the input clip so we don't have silence at the beginning and the
    %end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if CLIP_SILENCE
        xrms = getRMS(wav);
        sil = max(xrms > MIN_V,[],2);
        start = find(sil, 1, 'first');
        stop = find(sil, 1, 'last');
        if isempty(start)
            start = 1;
        end
        if isempty(stop)
            stop = size(wav,1);
        end
        wav = wav(start:stop,:);
    end
    
    %wavwrite(wav,fs,[d,'Master95Outputs',filesep,'r_',fn]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Frequency Envelope Matching
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(template)
        x = framedata(mean(wav,2),NWIN,NOVERLAP);
        w = hamming(size(x,1));
        x = bsxfun(@times,x,w);
        Fm = fft(x);
        Pw = sqrt(sum(Fm.*Fm));
        Fmean = abs(mean(Fm(:,Pw>(mean(Pw)+Nstd*std(Pw))),2));
        fmin = min(Fmean);
        
        if SMOOTHING>0 && SMOOTHING<1
            Fmean = ifftshift(filtfilt(b_smooth,a_smooth,fftshift(Fmean,1)),1);
        end
        c = template./Fmean;
        c(Fmean < .00005) = 1;
        
        if ~all(c==1)
            %c = c/sum(abs(c));
            for ci=1:size(wav,2)
                x = framedata(mean(wav(:,ci),2),NWIN,NOVERLAP);
                w = hamming(size(x,1));
                x = bsxfun(@times,x,w);
                F = fft(x);
                
                Fc = bsxfun(@times,F,c*BLENDING)+(1-BLENDING).*F;
                
                Y = real(ifft(Fc));
                y = iframedata(Y,NOVERLAP,NWIN);
                
                %subplot(2,1,1)
                %plot(wav(:,ci),'b')
                %hold on;
                %plot(y,'r');
                %hold off;
                
                %subplot(2,1,2)
                %plot(fftshift(template/max(template)),'b')
                %hold on;
                %plot(fftshift(Fmean/max(Fmean)),'r')
                %plot(fftshift(c.*Fmean/max(c.*Fmean)),'g')
                %%plot(fftshift(c/max(c)),'go-')
                %%plot(fftshift((template./Fmean)/max((template./Fmean))),'ko-')
                %hold off;
                %drawnow;
                
                wav(:,ci) = y(1:size(wav,1));
            end
        end
        %wavwrite(.5*wav/max(abs(wav(:))),fs,[d,'Master95Outputs',filesep,'f_',fn]);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Scale to match max RMS level for all files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    RMS = getRMS(mean(wav,2));
    RMSm = mean(RMS);
    wav = wav * RMSa / RMSm;
    
    if isempty(template)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Dual Band Processing - Linear phase butterworth filters - 6dB down at
        %FC
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        L_low = filtfilt(b_low,a_low,wav(:,1));
        R_low = filtfilt(b_low,a_low,wav(:,2));
        L_high = filtfilt(b_high,a_high,wav(:,1));
        R_high = filtfilt(b_high,a_high,wav(:,2));
        
        low = [L_low, R_low];
        high = [L_high, R_high];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Compression
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %y=compressor(x,fs,ig,threshold,ratio,og,tatt,trel,tla,twnd)
        lc = compressor(low,fs,ILow,TLow,RLow,GLow,ATTLow,RELLow,LLow,LSLow);
        hc = compressor(high,fs,IHigh,THigh,RHigh,GHigh,ATTHigh,RELHigh,LHigh,LSHigh);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Combine
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        c = lc+hc;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Brick Wall Limiter
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        y = compressor(c,fs,THRESHOLD,RATIO,IGAIN,ATTACK,RELEASE,OGAIN,LOOKAHEAD,LOOKSIZE);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Soft Clipping
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        yc = softclip(y,.5);
    else
        yc = softclip(wav,.5);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Write outputs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wavwrite(yc,fs,[d,'Master95Outputs',filesep,'out_',fn]);
    disp(['wrote ' 'out_' fn])
end

%sound(y(1:fs*3),fs);
%sound(wavo(1:fs*3),fs);
