function xr = iframedata(X,NOVERLAP,WIN)
%xr = iframedata(X)
%   Uses NWIN = NCOLS(X)
%   Uses NOVELAP = NROWS(X) / 2
%xr = iframedata(X,NOVERLAP)
%xr = iframedata(X,NOVERLAP,WIN)
%   WIN is windowing vector (i.e. hamming, etc) used on data.
%
%Outputs matrix of framed input data

%Compute the number of columns
NCOL = size(X,2);

%Compute the number of windows
NWIN = size(X,1);

if nargin < 2 || isempty(NOVERLAP)
    NOVERLAP = NWIN / 2;
end

%initialize indices...
colindex = (0:(NCOL-1))*(NWIN-NOVERLAP);
rowindex = (1:NWIN)';

I = rowindex(:,ones(1,NCOL))+colindex(ones(NWIN,1),:);

xr = accumarray(I(:),X(:));

%We've been provided the window information for accurate reconstruction...
if nargin >= 3 && ~isempty(WIN)
    if (numel(WIN)==numel(X))
    
    elseif (size(WIN,1) == size(X,1))
        WIN = WIN(:,ones(1,size(X,2)));
    elseif numel(WIN)==1
        WIN = X;
        WIN(:) = 1;
    end
    counts = accumarray(I(:),WIN(:));
    counts(counts==0) = 1;
    xr = xr ./ counts;
end


