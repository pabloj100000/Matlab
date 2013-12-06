function gabor = GaborTest()

imSize = 100;                           % image size: n X n
lamda = 10;                             % wavelength (number of pixels per cycle)
theta = 0;                              % grating orientation
sigma = 20;                             % gaussian standard deviation in pixels
phase = .0;                             % phase (0 -> 1)
%trim = .005;                            % trim off gaussian values smaller than this


%make linear ramp
X = 1:imSize;                           % X is a vector from 1 to imageSize
X0 = (X / imSize) - .5;                 % rescale X -> -.5 to .5

%mess about with wavelength and phase
freq = imSize/lamda;                    % compute frequency from wavelength
phaseRad = (phase * 2* pi);             % convert to radians: 0 -> 2*pi

%Now make a 2D grating
%Start with a 2D ramp use meshgrid to make 2 matrices with ramp values across columns (Xm) or across rows (Ym) respectively
[Xm Ym] = meshgrid(X0, X0);             % 2D matrices

%Put 2D ramps through sine
Xf = Xm * freq * 2*pi;
grating = sin( Xf + phaseRad);          % make 2D sinewave

%Change orientation by adding Xm and Ym together in different proportions
if theta~=0
    thetaRad = (theta / 360) * 2*pi;        % convert theta (orientation) to radians
    Xt = Xm * cos(thetaRad);                % compute proportion of Xm for given orientation
    Yt = Ym * sin(thetaRad);                % compute proportion of Ym for given orientation
    XYt =  Xt + Yt ;                      % sum X and Y components
    XYf = XYt * freq * 2*pi;                % convert to radians and scale by frequency
    grating = sin( XYf + phaseRad);                   % make 2D sinewave
end

%Make a gaussian mask
%Make 2D gaussian blob
s = sigma / imSize;                     % gaussian width as fraction of imageSize
gauss = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) ); % formula for 2D gaussian

%Now multply grating and gaussian to get a GABOR
%gauss(gauss < trim) = 0;                 % trim around edges (for 8-bit colour displays)
gabor = grating .* gauss;                % use .* dot-product
