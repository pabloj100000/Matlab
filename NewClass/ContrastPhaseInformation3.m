function contrastSeed = ContrastPhaseInformation3(repeatsPerStim)
    global screen
    
    InitScreen(0);
    Add2StimLogList();

    period = .1;
    contrastsN = 4;
    presentationLength = repeatsPerStim*2^4*period;
    duration = presentationLength*contrastsN;
    
    OnePresentation('movieDurationSecs', duration, ...
        'presentationLength', presentationLength, ...
        'backReverseFreq', 0);

    period = .5;
    duration = repeatsPerStim*2^4*period*contrastsN;
    contrastSeed = OnePresentation('movieDurationSecs', duration, ...
        'presentationLength', presentationLength);
end

function contrastSeed = OnePresentation(varargin)
%   Object is changing at 10Hz and background is reversing at 1Hz.
%   Object is changing contrast randomly. From ObjContrasts a sequence
%   of contrasts is chosen, all contrasts are presented once. Then the
%   sequence is randomzied again until presentationsN
%   independently of contrast and background, the color in teh center is
%   changing at 10Hz following LuminanceSequence, when the contrast
%   changes, the luminance continues to loop
global screen pd

p=ParseInput(varargin{:});

% object
contrastSeed = p.Results.contrastSeed;
objContrasts = p.Results.objContrasts;
objRect = p.Results.objRect;
objFreq = p.Results.objFreq;

% background
backContrast = p.Results.backContrast;
backReverseFreq = p.Results.backReverseFreq;
backCheckerSize = p.Results.backCheckerSize;
backAngle = p.Results.angle;
backPattern = p.Results.backPattern;

% general
stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;
presentationLength = p.Results.presentationLength;

try
    
    % each presentation will have all possible contrasts.
    contrastsN = length(objContrasts);
    presentationsN = floor(movieDurationSecs/presentationLength/contrastsN);
    
    % Init all random streams
    randomContrastStream = RandStream('mcg16807', 'Seed', contrastSeed);
    
    % make the background texture, each checker takes only 1 pixel
    backCheckersN = round(stimSize/backCheckerSize);
    backCheckersN = 2*ceil(backCheckersN/2);
    if (backPattern)
        backTex = GetCheckersTex(backCheckersN+1, 1, backContrast);
    else
        backTex = GetBarsTex(backCheckersN+1, 1, backContrast);
    end
    backSource = SetRect(0, 0, backCheckersN, backCheckersN);
    backDest1 = SetRect(0,0,backCheckersN*backCheckerSize, backCheckersN*backCheckerSize);
    backDest1 = CenterRect(backDest1, screen.rect);%-floor(backCheckerSize*[1/2 1/2 1/2 1/2]));
    backDest2 = CenterRect(backDest1, screen.rect+backCheckerSize*[0 1 0 1]);%+floor(backCheckerSize*[1/2 -1/2 1/2 -1/2]));
    objRect = CenterRect(objRect, screen.rect);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    % make the saccade sequence
    framesN = ceil(presentationLength*screen.rate/objFreq);
    backFramesPeriod = round(objFreq/backReverseFreq);
    if isinf(backFramesPeriod)
        backFramesPeriod=framesN+1;
    end
    waitTime = 1/objFreq - 1/screen.rate/2;
    
    % make a pseudo random sequence of contrasts such that 4 consecutive
    % bits make a # and all 16 numbers between 0 and 15 happen once when
    % sliding the 4 bit coding window by 1.
    if (objFreq==10)
        luminanceSeq = [ 0 1 0 0 1 1 1 1 0 1 0 1 1 0 0 0 0 0 1 0 0 1 1 1 1 0 1 0 1 1 0 0];
%        luminanceSeq = [0 1 0 1 1 0 0 2 2 1 2 1 1 1 2 2 2 0 2 1 0 2 0 1 2 0 0];        
    end
    luminanceSeq = round(luminanceSeq-mean(luminanceSeq));
    
    luminanceIndex = 0;
    
    for presentation=1:presentationsN
        
        contrastSeq = randperm(randomContrastStream, contrastsN);
        
        for i = 1:contrastsN
            contrast = objContrasts(contrastSeq(i));
            for frame=0:framesN-1
                
                luminanceIndex = mod(luminanceIndex, length(luminanceSeq))+1;
                color = screen.gray * (1 + luminanceSeq(luminanceIndex)*contrast);
                
                % is it time to reverse the background?
                if (mod(frame, backFramesPeriod)==0)
                    backDest = backDest1;
                    backFlag=1;
                elseif (mod(frame, backFramesPeriod/2)==0)
                    backDest = backDest2;
                    backFlag=1;
                end
                % {
                Screen('FillRect', screen.w, screen.gray);
                
                % Disable alpha-blending, restrict following drawing to alpha channel:
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                
                % Clear 'dstRect' region of framebuffers alpha channel to zero:
                %    Screen('FillRect', screen.w, [0 0 0 0], backRect);
                Screen('FillRect', screen.w, [0 0 0 0]);
                
                % Fill circular 'dstRect' region with an alpha value of 255:
                Screen('FillOval', screen.w, [0 0 0 255], backDest);
                
                % Enable DeSTination alpha blending and reenalbe drawing to all
                % color channels. Following drawing commands will only draw there
                % the alpha value in the framebuffer is greater than zero, ie., in
                % our case, inside the circular 'dst2Rect' aperture where alpha has
                % been set to 255 by our 'FillOval' command:
                Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                
                % display background texture
                Screen('DrawTexture', screen.w, backTex{1},backSource,backDest, backAngle, 0);
                
                % Restore alpha blending mode for next draw iteration:
                Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                
                % Draw object
                Screen('FillRect', screen.w, color, objRect);
                
                
                
                % Photodiode box
                % --------------
                if (backFlag)
                    Screen('FillOval', screen.w, screen.white, pd);
                    backFlag=0;
                else
                    color = screen.gray * (1 + 2*luminanceSeq(luminanceIndex)*contrast);
                    Screen('FillOval', screen.w, color, pd);
                end
                
                screen.vbl = Screen('Flip', screen.w, screen.vbl + waitTime, 1);
                %}
                if (KbCheck)
                    break
                end
                
            end
            
            if (KbCheck)
                break
            end
        end
        %}
        if (KbCheck)
            break
        end
        
    end
    
    contrastSeed = randomContrastStream.State;
    
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex{1});
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function p =  ParseInput(varargin)
% Generates a structure with all the parameters
% Allowed parameters are:
%
% objContrast, objJitterPeriod, contrastSeed, stimSize, objSizeH, objSizeV,
% objCenterXY, backContrast, backJitterPeriod, presentationLength,
% movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

% In order to get a parameter back just use
%   p.Resulst.parameter
% In order to display all the parameters use
%   disp 'List of all arguments:'
%   disp(p.Results)
%
% General format to add inputs is...
% p.addRequired('script', @ischar);
% p.addOptional('format', 'html', ...
% @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
% p.addParamValue('outputDir', pwd, @ischar);
% p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

p  = inputParser;   % Create an instance of the inputParser class.

[screenX, screenY] = SCREEN_SIZE;
rate = Screen('NominalFrameRate', max(Screen('Screens')));

% General
p.addParamValue('stimSize', screenY, @(x)x>0);
p.addParamValue('presentationLength', 100, @(x)x>0);
p.addParamValue('movieDurationSecs', 16000, @(x)x>0);
p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));

% Object related
p.addParamValue('contrastSeed', 1, @(x) isnumeric(x));
p.addParamValue('objContrasts', [.03 .06 .12 .24], @(x) all(all(x>=0)) && all(all(x<=1)));
p.addParamValue('objTexture', [], @(x) iscell(x));
p.addParamValue('objRect', GetRects(12*PIXELS_PER_100_MICRONS, [screenX screenY]/2), @(x) size(x,2)==4);
p.addParamValue('objFreq', 10, @(x) x>0);
p.addParamValue('objCheckerSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('luminanceSeq', [], @(x) isnumeric(x));

% Background related
p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
p.addParamValue('backReverseFreq', 1, @(x) x>=0);
p.addParamValue('backTexture', [], @(x) iscell(x));
p.addParamValue('backRect', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
p.addParamValue('backCheckerSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
p.addParamValue('angle', 0, @(x) x>=0);
p.addParamValue('backPattern', 1, @(x) x==0 || x==1);

% Call the parse method of the object to read and validate each argument in the schema:
p.parse(varargin{:});

end



