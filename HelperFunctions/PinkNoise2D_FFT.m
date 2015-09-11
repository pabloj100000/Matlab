function y = PinkNoise2D_FFT(size, varargin)
% The function generates a 2D sequence of pink noise samples. 
% INPUT:
% size - (x,y) or (x,time) for example (10,10)
% OUTPUT:
% 2D array of pink noise samples
%
% Note:
% Use at your own risk.

    p = ParseInput(varargin{:});
    seed = p.Results.seed;
    previous = p.Results.previous;

    S1 = RandStream('mcg16807', 'seed',seed);

    if ~isempty(previous);
        prev_size = size(previous);
    else
        prev_size = [0 0];
    end
    %calculate the size for fft. The size should be a power of 2.
    % If given size is not a power of 2, it is expanded to be
    size2 = ceil( log2( size ));
    size2 = 2.^size2;
    
    needed_size = size2 - prev_size;
    x = [previous randn(S1, needed_size(1), needed_size(2))];

    % calculate fft and then perform 1/f multiplication
    f = fft2( x );

    % prepare an array of freq for 1/f multiplication
    [freq_x, freq_y] = meshgrid(1:size2(1), 1:size2(2));
    freq = sqrt(freq_x.^2 + freq_y.^2);

    % divide left half of the fft by sqrt of freq
    f = f ./ sqrt(freq);

    y = ifft2( f , 'symmetric');
    y = y(1:size(1), 1:size(2));
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('seed', 1, @(x) isnumeric(x));         
    p.addParamValue('previous', [], @(x) isnumeric(x));
    p.parse(varargin{:});
    
end

