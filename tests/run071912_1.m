% Experiment finished running on: 19-Jul-2012 13:28:54
%%%%%%%%%%%%%%%%%%
% Following is the content of file:
%/Users/baccuslab/Desktop/stimuli/Pablo/NewClass/Sensitization.m
 function Sensitization(varargin)
%   obj and background will both be either bars or checkers of a given
%   size. The phase and contrast will change over some values.
% 
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

global screen pd

if isempty(screen)
    screen.rate = max(Screen('NominalFrameRate', max(Screen('Screens'))),60);
end

    p  = inputParser;   % Create an instance of the inputParser class.

    [screenWidth screenHeight] = SCREEN_SIZE;
    p.addParamValue('lowLength', 16, @(x)x>0);
    p.addParamValue('hiLength', 4, @(x) x>0);
    p.addParamValue('repeats', 25, @(x) x>0);
    p.addParamValue('pdStim', 2, @(x) x>0);
    p.addParamValue('stimSize', screenHeight, @(x) x>0);
    p.addParamValue('waitframes', round(screen.rate/30), @(x) x>0);
    
    p.parse(varargin{:});
    

    lowLength = p.Results.lowLength;
    hiLength = p.Results.hiLength;
    repeatsN = p.Results.repeats;
    pdStim = p.Results.pdStim;
    stimSize = p.Results.stimSize;
    waitframes = p.Results.waitframes;
    
try
    InitScreen(0);
    Add2StimLogList();

    % each presentation will have all possible contrasts.

    % Init all random streams
    stream1 = RandStream('mcg16807', 'Seed', 1);

    rect = GetRects(stimSize, screen.center);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    PDFrames = round(screen.rate/waitframes);
    
    framesLo = round(screen.rate*lowLength/waitframes);
    framesHi = round(screen.rate*hiLength/waitframes);
    % get framesLO/HI to be integer multiples of PDFrames
    framesLo = PDFrames*round(framesLo/PDFrames);
    framesHi = PDFrames*round(framesHi/PDFrames);
    
    contrastHi = .35;
    contrastLo = .05;
    
    sigmaHi = contrastHi*screen.gray;
    sigmaLo = contrastLo*screen.gray;
    
    updateTime = waitframes/screen.rate;
    
    for repeat=1:repeatsN
        for frame=0:framesHi+framesLo-1
            if (frame<framesHi)
                % Hi contrast
                color = sigmaHi*randn(stream1)+screen.gray;
            else
                color = sigmaLo*randn(stream1)+screen.gray;
            end
            Screen('FillRect', screen.w, screen.gray)
            Screen('FillOval', screen.w, color, rect)
            
            % Photodiode box
            % --------------
            if (mod(frame, PDFrames)==0)
                Screen('FillOval', screen.w, screen.white, pd);
            else
                Screen('FillOval', screen.w, color/2, pd);
            end
            
            screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime , 1);
            if (KbCheck)
                break
            end

        end
        if (KbCheck)
            break
        end
    end
    
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end


%%%%%%%%%%%%%%%%%%
% Following is the content of file:
%/Users/baccuslab/Desktop/stimuli/Pablo/NewClass/OMS_identifier_LD.m
 function OMS_identifier_LD(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.
global screen pd

p=ParseInput(varargin{:});

backContrast = p.Results.backContrast;
barsWidth = p.Results.barsWidth;

presentationLength = p.Results.presentationLength;
stimSize = p.Results.stimSize;
waitframes = p.Results.waitframes;

try
    InitScreen(0);
    Add2StimLogList();
    
    %centerX = screen.rect(3)/2;
  
    % make the background texture
    barsN = floor(stimSize/barsWidth)+1;
    stimSize = barsWidth * (barsN-1);
    
    x= 0:barsN;
    bars = ceil(mod(x,2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % Define the background Destination Rectangle, length is
    % (barsN-1)*barsWIdth
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the back source rectangle
    backSource1 = SetRect(0,0,barsN-1,1);
    backSource2 = SetRect(1,0,barsN, 1);
    
    
    %stimSize    % in pixels
    objSize = 8*PIXELS_PER_100_MICRONS; % in pixels
    %cetnerX     % in pixels
        
    % define the obj rect. Center of the rect is in the upper left corner of the array
    objRect = SetRect(0, 0, 8*PIXELS_PER_100_MICRONS, 8*PIXELS_PER_100_MICRONS);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, -2*PIXELS_PER_100_MICRONS, -2*PIXELS_PER_100_MICRONS);
    
    % obj source
    objSource = SetRect(-1, -1, 1, 1)* (barsN-1)*objSize/stimSize/2;%*PIXELS_PER_100_MICRONS, 8*PIXELS_PER_100_MICRONS)*(barsN-1)/stimSize;
    objSource1(1, :) = CenterRect(objSource, (barsN-1)/2-2*PIXELS_PER_100_MICRONS*(barsN-1)/stimSize*[1 0 1 0]);     %objSource + [1 0 1 0]*(1/2 - .75*objSize/stimSize);
    objSource1(2, :) = objSource1(1,:)+4*PIXELS_PER_100_MICRONS*(barsN-1)/stimSize*[1 0 1 0];
    objSource = objSource1(1, :);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    framesN = uint32(presentationLength*screen.rate/waitframes);
    jumpFrames = 2*round(screen.rate/waitframes/2);     % every 0.5s
    framesN = jumpFrames*floor(framesN/jumpFrames);
%    k=0;
%    lastK=0;
    % Animationloop:
    for trial=1:2
        for i=0:4        % i=0 Global Motion, i=1:4 DIfferential
            for frame=0:framesN-1
                % Background Drawing
                % ---------- -------
                if mod(frame, 2*jumpFrames)==0
                    backSource = backSource1;
                elseif mod(frame, jumpFrames)==0
                    backSource = backSource2;
                end
                Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0);
                
                
                
                % Object Drawing
                % --------------
                if (i>0)
                    if mod(frame+jumpFrames/2, 2*jumpFrames)==0
                        index = mod(i, 2);
                        if index==0
                            index=2;
                        end
                        objSource = objSource1(index, :);
                    elseif mod(frame+jumpFrames/2, jumpFrames)==0
                        objSource = objSource + [1 0 1 0];
                    end
                    Screen('DrawTexture', screen.w, backTex, objSource, objRect, 0,0);
                        
                    %        Screen('DrawTexture', screen.w, objTex, objSource + objShiftRect, objRect, 0,0);
                end
%}                
                % Photodiode box
                % --------------
                if (mod(frame, jumpFrames)==0 || (i>0 && mod(frame, jumpFrames/2)==0))
                    Screen('FillOval', screen.w, screen.white, pd);
%                    k-lastK
%                    lastK=k;
                end
                
                % Flip 'waitframes' monitor refresh intervals after last redraw.
                screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
%k=k+1;
                if KbCheck
                    break
                end
            end
            if KbCheck
                break
            end
            
% {
            if (i==0)
                % do nothing
            elseif (i==2)
            % move object down and left
                objRect = OffsetRect(objRect, -4*PIXELS_PER_100_MICRONS, 4*PIXELS_PER_100_MICRONS);
            elseif (i==4)
                % move object up and left
                objRect = OffsetRect(objRect, -4*PIXELS_PER_100_MICRONS, -4*PIXELS_PER_100_MICRONS);
            else
                % move object to the right
                objRect = OffsetRect(objRect, 4*PIXELS_PER_100_MICRONS, 0);
            end
%}            
        end
    end
    
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex);

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
%    psychrethrow(psychlasterror);
end %try..catch..
end

function p =  ParseInput2(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    p  = inputParser;   % Create an instance of the inputParser class.
    
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=60;
    end

    % General
    p.addParamValue('presentationLength', 10, @(x)x>0);
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('waitframes', round(rate/30), @(x)x>0);
    p.addParamValue('pdStim', 1, @(x) isnumeric(x));
    
    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS, @(x) x>0);

    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end



%%%%%%%%%%%%%%%%%%
% Following is the content of file:
%/Users/baccuslab/Desktop/stimuli/Pablo/NewClass/GrayScreen.m
function GrayScreen(color, time)
% present a screen of "color" for "time" seconds
global screen

InitScreen(0);
Add2StimLogList();

Screen('FillRect', screen.w, color);
Screen('Flip', screen.w);
pause(time);

FinishExperiment();

end
%%%%%%%%%%%%%%%%%%
% Following is the content of file:
%/Users/baccuslab/Desktop/stimuli/Pablo/NewClass/ContrastPhaseInformation3.m
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

function p =  ParseInput3(varargin)
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




%%%%%%%%%%%%%%%%%%
% Following is the content of file:
%/Users/baccuslab/Desktop/stimuli/Pablo/HelperFunctions/GetCheckersTex.m
 function Tex = GetCheckersTex(stimSize, barsWidth, Contrast)
% Usage: Tex = GetCheckersTex(stimSize, barsWidth, screen, Contrast)
    global screen
    Add2StimLogList();
    
    InitScreen(0);
    if size(stimSize,2)==1
        [x, y]  = meshgrid(0:stimSize-1);
    else
        [x, y] = meshgrid(0:stimSize(1)-1, 0:stimSize(2)-1);
    end
    x = mod(floor(x/barsWidth),2);
    y = mod(floor(y/barsWidth),2);
    bars = x.*y + ~x.*~y;
    bars = bars*2*screen.gray*Contrast...
        + screen.gray*(1-Contrast);
    Tex{1} = Screen('MakeTexture', screen.w, bars);
end


%%%%%%%%%%%%%%%%%%
% Following is the content of file:
%/Users/baccuslab/Desktop/stimuli/Pablo/NewClass/ContrastPhaseInformation4.m
 function ContrastPhaseInformation4(repeats)
%   Object is changing at 10Hz and background is reversing at 1Hz.
%   Object luminance is read from file and adjusted according to 
%   luminance = valueFromFile - base/2
%   luminance = gray + gray*luminance*contrast
global screen
    InitScreen(0);
    Add2StimLogList();

    period = .1;
    length = 4^4*period*repeats;
    OnePresentation('MSequence_4_4.txt', 'objContrast', .24,...
        'backReverseFreq', 0, 'movieDurationSecs', length);

    period = .5;
    length = 4^4*period*repeats;
    OnePresentation('MSequence_4_4.txt', 'objContrast', .24,...
        'movieDurationSecs', length);
    
end

function OnePresentation1(file, varargin)
global screen

p=ParseInput(varargin{:});

% object
objContrast = p.Results.objContrast;
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

try
            
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
    framesN = ceil(movieDurationSecs*objFreq);
    backFramesPeriod = round(objFreq/backReverseFreq);
    if isinf(backFramesPeriod)
        backFramesPeriod=framesN+1;
    end
    waitTime = 1/objFreq-1/screen.rate/2;%waitframes/screen.rate;
    
    % Read a pseudo random sequence of luminance levels such that 'codeLength'
    % consecutive bits make a stimulus in base 'base'. The name of the file
    % is of the form 'MSequence_base_codeLength.txt'
    fid = fopen(file, 'r');
    findDash = strfind(file, '_');
    base = str2double(file(findDash(1)+1:findDash(2)-1));
    seqMean = (base-1)/2;

    for frame=0:framesN-1
        if feof(fid)
            frewind(fid)
        end
        luminance = fscanf(fid, '%u', 1)-seqMean;
        color = screen.gray * (1 + luminance*objContrast);

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
            color = screen.white;
            backFlag=0;
        else
            color = screen.gray * (1 + 2*luminance*objContrast);
        end
        Screen('FillOval', screen.w, color, pd);
        screen.vbl = Screen('Flip', screen.w, screen.vbl + waitTime, 1);
        %}
        if (KbCheck)
            break
        end
        
    end
    
        
    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', backTex{1});
    
    fclose(fid);
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.

    if exist('fid', 'var')
        fclose(fid);
    end
    
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function p =  ParseInput5(varargin)
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
p.addParamValue('movieDurationSecs', 16000, @(x)x>0);
p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));
p.addParamValue('file', [], @(x)ischar(x));

% Object related
p.addParamValue('objContrast', .12, @(x) all(all(x>=0)) && all(all(x<=1)));
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




%%%%%%%%%%%%%%%%%%
