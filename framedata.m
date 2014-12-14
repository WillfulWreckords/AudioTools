function xin = framedata(in,NWIN,NOVERLAP)
%[X] = framedata(x,NWIN,NOVERLAP)
%
%Outputs matrix of framed input data

%Turn into column vector
in = in(:);

%Compute the number of columns in output
ncol = ceil((length(in)-NWIN) / (NWIN-NOVERLAP))+1; 

%pad out with zeros as needed..
in(ncol*(NWIN-NOVERLAP)+NWIN) = 0; 

%initialize indices...
colindex = (0:(ncol-1))*(NWIN-NOVERLAP);
rowindex = (1:NWIN)';

%Initialize output
xin = zeros(NWIN,ncol);

%Create the framed output data
xin(:) = in(rowindex(:,ones(1,ncol))+colindex(ones(NWIN,1),:));