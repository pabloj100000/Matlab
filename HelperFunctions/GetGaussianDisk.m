function [tex]= GetGaussianDisk(imSize, luminance, varargin)
global screen
Add2StimLogList();

p  = inputParser;   % Create an instance of the inputParser class.

% Gabor parameters
p.addParamValue('decay', 5, @(x) x>0);      % dimension of the two patches to discriminate

p.parse(varargin{:});

% gabor parameters
decay = p.Results.decay;

if size(imSize,2)==1
    imSize = [imSize imSize];
end

%imSize = 100;                           % image size: n X n
%lambda = 10;                            % wavelength (number of pixels per cycle)
%sigma = 10;                             % gaussian standard deviation in pixels
%phase = .0;                             % phase (0 -> 1)
%contrast=1;

%make linear ramp
X = (-imSize(1)/2:imSize(1)/2)';                           % X is a vector from 1 to imageSize
Y = -imSize(2)/2:imSize(2)/2;


%Make a gaussian mask
%Make 2D gaussian blob
gaussX = normpdf(X,0, 100/decay);%/imSize);
gaussX = gaussX/max(gaussX);
gaussY = normpdf(Y, 0, 100/decay);
gaussY = gaussY/max(gaussY);

% make the grating for the texture
grating = ones(imSize(1)+1, imSize(2)+1, 2)*luminance;
grating(:,:,2) = 255-round(255*(gaussX*gaussY));

if (isfield(screen, 'w'))
    tex = Screen('MakeTexture', screen.w, grating);
else
    tex = [];
    
end
