function q = ContrastDiscriminationTask2(varargin)
    % Quest test.
    % You'll be presented to patches and have to identify the highest
    % contrast one. Press left/right arrow to identify the highest contrast
    % one or "Esc" to quit
global screen

try
    [objSize lambda sigma phase pedestal deltaX trialsPerDelay] = GetParameters(varargin{:});

    % *************** Constants ******************
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    RIGHT_BTN = KbName('RightArrow');
    LEFT_BTN = KbName('LeftArrow');
    RIGHT = 2;
    LEFT = 1;
    maxPhysicalContrast = .4;
    % *************** End of Constants ******************
    % *************** Variables that need to be init ***********
    InitScreen(0);
    
    vbl = 0;
    abortFlag=0;
    
    % Get object texture
    pedestalTex = GetGaborText2(objSize, lambda, sigma, phase, pedestal);
    
    % Make all necessary rectangles
    objDest = GetRects(objSize, screen.center-[deltaX 0])';
    objDest(:,2) = GetRects(objSize, screen.center+[deltaX 0])';
    objSource = Screen('Rect', pedestalTex);

    % Get 2 rectangles for the fixation point
    fixationLength = 11;
    fixationRect(:,1) = CenterRectOnPoint(SetRect(0,0, fixationLength, 1), screen.center(1), screen.center(2))';
    fixationRect(:,2) = CenterRectOnPoint(SetRect(0, 0, 1, fixationLength), screen.center(1), screen.center(2));
    
    % start Quest structure
    tGuess = log(pedestal);
    tGuessSd = 2;
    pThreshold=0.82;
    beta=3.5;delta=0.01;gamma=0.5;
    q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
    q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
    
    for i=1:trialsPerDelay
                
        % Get recommended level.  Choose your favorite algorithm.
        tTest=QuestQuantile(q);	% Recommended by Pelli (1987), and still our favorite.
        tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
        tTest = min(log(maxPhysicalContrast),tTest);
        pedestalPatch = randi(2, 1, 1);      % pedestalPatch = 1=> left
        %                                                      2=> right
        
        fprintf('tTest=%f, 10^tTest=%f\n',tTest, exp(tTest))

        % grab a gabor patch of the suggested contrast
        testTex = GetGaborText2(objSize, lambda, sigma, phase, exp(tTest));
        
        % order the two patches randomly
        if pedestalPatch==LEFT
            objTextures = [pedestalTex testTex];
        else
            objTextures = [testTex pedestalTex];
        end
        
        % show the fixation spot
        Screen('FillRect', screen.w, 0, fixationRect);

        Screen('DrawTextures', screen.w, objTextures, objSource, objDest);
        Screen('Close', testTex);
      
        vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                    
        % figure out which patch had the higest contrast
        % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
        if (pedestal>exp(tTest))
            higestPatch = pedestalPatch;
        else
            higestPatch = 3 - pedestalPatch;
        end
        
        while 1
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if (keyIsDown)
                if keyCode(ESCAPE)
                    % finish experiment
                    abortFlag=1;
                    break
                elseif (keyCode(RIGHT_BTN) && higestPatch==RIGHT) || ...
                        (keyCode(LEFT_BTN) && higestPatch==LEFT)
                    % got the contrast right
                    % Update the pdf
                    q=QuestUpdate(q,tTest, true); % Add the new datum (actual test intensity and observer response) to the database.
                    break
                elseif (keyCode(RIGHT_BTN) && higestPatch==LEFT) || ...
                        (keyCode(LEFT_BTN) && higestPatch==RIGHT)
                    % got the contrast wrong
                    % Update the pdf
                    q=QuestUpdate(q,tTest, false); % Add the new datum (actual test intensity and observer response) to the database.
                    break
                end
            end
        end
        pause(.2)
        %}
        if (abortFlag)
            break
        end

    end
    
    % Ask Quest for the final estimate of threshold.
    t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
    sd=QuestSd(q);
    fprintf('Final threshold estimate (mean�sd) is %.2f � %.2f\n',t,sd);
    fprintf('corresponding contrast is %.2f\n', exp(t));
        
    Screen('CloseAll')
    clear global screen
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    fprintf('Error');
end %try..catch..
end

function [objSize lambda sigma phase pedestal deltaX trialsPerDelay] = GetParameters(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('objSize', 100, @(x) x>0);
    p.addParamValue('lambda', 10, @(x) x>0);        % # of pixels per cycle
    p.addParamValue('sigma', 10, @(x) x>0);         % gaussian standard deviation in pixels
    p.addParamValue('phase', 0, @(x) x>0);          % phase, 0->1
    p.addParamValue('pedestal', .05, @(x) all(x>=0 & x<=1)); % contrast of the reference patch
    p.addParamValue('deltaX', 128, @(x) x>0);       % Distance of each patch to the fixation point (pixels)
    p.addParamValue('trialsPerDelay', 20, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    
    p.parse(varargin{:});
    
    % gabor parameters
    objSize = p.Results.objSize;
    lambda = p.Results.lambda;
    sigma = p.Results.sigma;
    phase = p.Results.phase;
    pedestal = p.Results.pedestal;
    deltaX = p.Results.deltaX;
    trialsPerDelay = p.Results.trialsPerDelay;
end

function InitScreen(debugging)
    % Initializes the Screen.
    % The idea here is that you can call this function from within a given
    % stimulus where the 2nd parameter might or might no be defined. If it
    % is defined this function does nothing but if it is not defined then
    % this function initializes the screen.
    
    global screen
    if (isfield(screen, 'w'))
        return
    end
    
    % write which function initialized the screen. So that we know when to
    % close it.
    s = dbstack('-completenames');
    screen.callingFunction = s(length(s)).file;

    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to white and black.
    screen.white=WhiteIndex(screenNumber);
    screen.black=BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	screen.gray=floor((screen.white+screen.black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if screen.gray == screen.white
		screen.gray=screen.white / 2;
    end

    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    screen.center=[screenX screenY]/2;
    
    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
        if (debugging)
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray, [10 10 400 400]);
        else
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
            HideCursor();
        end
        Priority(1);
    else
        [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
    end
    
        % Query duration of monitor refresh interval:
    screen.ifi=Screen('GetFlipInterval', screen.w);

end

function [tex]= GetGaborText2(imSize, lambda, sigma, phase, contrast)
global screen


%imSize = 100;                           % image size: n X n
%lambda = 10;                            % wavelength (number of pixels per cycle)
%sigma = 10;                             % gaussian standard deviation in pixels
%phase = .0;                             % phase (0 -> 1)
%contrast=1;

if (contrast>1)
    error('contrast has to be between 0 and 1');
end
   
%make linear ramp
X = 0:imSize;                           % X is a vector from 1 to imageSize
X0 = (X / imSize) - .5;                 % rescale X -> -.5 to .5

%mess about with wavelength and phase
freq = imSize/lambda;                    % compute frequency from wavelength
phaseRad = (phase * 2* pi);             % convert to radians: 0 -> 2*pi

%Put 2D ramps through sine
Xf = X0 * freq * 2*pi;
sinusoidal = sin( Xf + phaseRad);          % make 2D sinewave

%Make a gaussian mask
%Make 2D gaussian blob
gauss1D = normpdf(Xf,0,sigma);%/imSize);
gauss1D = gauss1D/max(gauss1D);

grating = gauss1D'*(sinusoidal.*gauss1D);

grating = 127+contrast*127*grating;
InitScreen(0);

tex = Screen('MakeTexture', screen.w, grating);
end

function rects = GetRects(diameters, centers)
    if (length(diameters) ~= size(centers,1))
        error('# of diameters and # of centers do not match');
    end
    
    rects = ones(length(diameters), 4);
    for i=1:length(diameters)
        rects(i,:) = SetRect(0,0,diameters(i), diameters(i));
        rects(i,:) = CenterRectOnPoint(rects(i,:), centers(i,1), centers(i,2));
    end
    
end
