function run010611()
CreateStimuliLogStart();

global pdStim;

% Define the rectangles
[width, height]=Screen('WindowSize', 0);
length = 192;
deltaX = length*0;         % changing the sign of delta reverses the boxes
deltaY = length/4;
objRects = SetRect(0,0,length, length/2);
objRects = CenterRect(objRects,  [0 0 width height]);
objRects = OffsetRect(objRects, deltaX, deltaY);
objRects(2,:) = OffsetRect(objRects, -2*deltaX, -2*deltaY);

Wait2Start()
% record for 1000*9 = 9000 seconds

pdStim = 0;

RF( ...
    'movieDurationSecs', 1000, ...
    'barsWidth',16, ...
    'objContrast',1, ...
    'waitFrames', 1 ...
    );

%{
for i=1:size(objRects,1)
    %pause(1)
    pdStim = pdStim+1;

    OMS_identifier2( ...
        'movieDurationSecs', 200, ...
        'barsWidth', 16, ...
        'waitFrames', 1, ...
        'rects', objRects(i,:), ...
        'backReverseFreq', .5, ...
        'presentationLength', 10 ...
        )
end
%}
    
%pause(1)
pdStim = pdStim+1;
RandUFlickerObj_xSx( ...
    'objContrast', [1 .24 .06 .03 .12], ...     % I put the contrasts in this order so that they will be shown (after randommization) in order of increasing contrast.
    'backReverseFreq', 1, ...
    'barsWidth', 8, ...
    'presentationLength', 400, ...
    'objJitterPeriod', 400, ...
    'movieDurationSecs', 2000 ...
    );


%pause(1)
pdStim = pdStim+1;
RandContrastCheckers_SSx( ...
    'movieDurationSecs', 6000, ...
    'presentationLength',10, ...
    'rects', objRects, ...         checker 2
    'cell', {   [.03 .06 .12 .24 1] , ...     Contrasts for checker1
                .12                 } ...     Contrasts for checker2
    )

CreateStimuliLogWrite();

end

function OMS_identifier2(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

CreateStimuliLogStart()
global vbl screen backRect backSource objRect objSource pd pdStim
if isempty(vbl)
    vbl=0;
end
if isempty(pdStim)
    pdStim=0;
end

p=ParseInput(varargin{:});

objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backContrast = p.Results.backContrast;
backReverseFreq = p.Results.backReverseFreq
barsWidth = p.Results.barsWidth;

presentationLength = p.Results.presentationLength;
stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;
debugging = p.Results.debugging;
waitframes = p.Results.waitframes;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize+1;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the back source rectangle
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the obj source rectangle
    objSource = SetRect(0,0, objSizeH, objSizeV);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % make the jitterSeq corresponding to saccades
    jumpsPerPeriod = 60/backReverseFreq/waitframes;
    backSeq = zeros(1, jumpsPerPeriod);
    backSeq(1) = barsWidth;
    backSeq(jumpsPerPeriod/2+1) = -barsWidth;
    backSeq(2,:) = circshift(backSeq, [0 jumpsPerPeriod/4]);
    
    % make the objectSeq
    objSeq = backSeq(1,:);
        
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);

    % Animationloop:
    for presentation = 0:presentationsN-1
        GlobalDifferential = mod(presentation, 2)+1;
        
        JitterBackTex_JitterObjTex(backSeq(GlobalDifferential, :), objSeq, ...
            waitframes, framesN, backTex, backTex)

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function RandUFlickerObj_xSx(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backReverseFreq, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
%    vbl = p.Results.vbl;
    
% debugging     = 0 or 1
% stimSize      = 600    in pixels
% objSizeH/V    = 16*12  in pixels (16 = 100um)
% objCenterXY   = [0 0] for centered object. Is in pixels
% barsWidth     = in pixels, each bar. Period is 2*barsWidth
% backContrast  = between 0 and 1
% objContrast   = between 0 and 1
% vbl           = time of last flip, 0 if none happened yet
% backReverseFreq = number of seconds the back sequence has to jitter around
% objJitterPeriod  = number of seconds the object sequence has to jitter around
% presentationLength    = number of seconds for each presentation
% objSeed
% waitframes    = probably 1 or 2. How often do you want to 'Flip'?
% movieDurationSecs     = Approximate length of the experiment, will be changed in the code
% varargin      = {screen}
%
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of gaussian random intensity and a given
% contrast
% Back will be a grating of a giving contrast and spatial frequency.
% Back grating will be reversing at a given frequency
%
% The experiment is divided in presentations. Each presentation is defined
% by the length of the presentation, the background sequence and the object
% sequence. Background and object sequences have independent durations.
% If the presentation lasts longer than either background or object sequence
% then they start over.
% In this way I can:
%   1) make repeats of a given object and background.
%   2) make repeats of a given background with several different objects.
%   3) make repeats of a given object with several different background.
%   4) make repeats where the object and background get out of phase.
%{
debugging=0

stimSize = 600;         % in pixels
objSizeH = 16*12;           % HD is 24;              % in pixels
objSizeV = 16*12;           % HD is 20;              % in pixels
objCenterXY=[0 0];
barsWidth = 7;          % in pixels

objContrast =.2;
vbl =0;
backContrast = 100/100;       %mean is 127

backReverseFreq = 1;           % how long should each one of the jitterN seq be (in seconds)?
objJitterPeriod = 11;            % how long should each one of the jitterN seq be (in seconds)?
presentationLength = 11*backReverseFreq;

% Probably you do not want to mess with these
objSeed = 1;
waitframes = 1;
movieDurationSecs=20;  % in seconds
%}

% Redefine exp time to have an even number of jitters
contrastsN = size(objContrast,2);
movieDurationSecs = presentationLength*contrastsN* ...
    floor( movieDurationSecs/presentationLength/contrastsN);

% Redefine the stimSize to incorporate an integer number of bars
stimSize = ceil(stimSize/barsWidth)*barsWidth;

%LoadHelperFunctions();
try    
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3*stimSize/2,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(framesPerSec/backReverseFreq);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);
    
    % make the Saccading like background sequence
    jitterSeq(1,:)=zeros(1, backJumpsPerPeriod);
    jitterSeq(1,0*backJumpsPerPeriod/2+1)=   barsWidth;
    jitterSeq(1,1*backJumpsPerPeriod/2+1)=  -barsWidth;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*60);

    % make a random sequence of intensities
    randStream = RandStream('mcg16807', 'Seed', objSeed);
    contrastSeq = randperm(randStream, presentationsN) - 1;         % numbers go between 0 and presentationsN -1
    contrastSeq = mod(contrastSeq, contrastsN) + 1;                 % number go between 1 and contrastsN
    clear randStream
    
    % Open all the random streams (1 per contrast). If there is a contrast
    % of '1', that random strim is binary, not gaussian
    for i=1:size(objContrast, 2)
        randStream{i} = RandStream('mcg16807', 'Seed', objSeed);
    end
    
    % Animationloop:
    for presentation = 1:presentationsN
        i = contrastSeq(presentation);

        contrast = objContrast(i);
contrast
        objSeq = uint8(randn(randStream{i}, 1, objJumpsPerPeriod)*screen.gray*contrast+screen.gray);

        if (contrast==1)
            % Convert noise to binary
            objSeq = (objSeq>screen.gray)*255;
        end
        
        JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, ...
            waitframes, framesN, backTex)

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];

        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    else
        FinishExperiment();
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function JitteringBackTex_UniformFieldObj(jitterSeq, objSeq, ...
    waitframes, framesN, backTex)
    % Screen is divided in background and object.
    % background will display the given texture and will jitter it around
    % as specified by jitterSeq.
    % Object will follow the intensities in objSeq
    % The time of the presentation comes in through framesN and if it is
    % longer than either jitterSeq or objSeq, then the jitter or the objSeq
    % sequences are repeated as many times as needed. In this way you can
    % have either:
    %   one background and one object
    %   one background with different objects
    %   different backgrounds with one object
    %
    % This procedure can also be used for reverse grating backgrounds, just
    % define the background to be the grating texture and define jitterSeq
    % to something like jitterSeq = [J 0 0 0 0 0 0 0 0 -J 0 0 0 0 0 0 0 0]
    % were the J is the size of the jump and the 0s are the frames where
    % the background is still
    % jitterSeq:    an array describing how many pixels to jump
    %               at each frame (+ to the right, - to the left)
    % objSeq:       the intensities to display in the Uniform Field obj
    % screen:       the usual screen struct.
    % waitFrames:   how often is the Flip going to be called?
    %               in general this will be either 1 or 2
    % framesN:      framesN/60 = totalLength of the presentation
    % backTex:      the texture to show in the background.
    % backRect:     where to display the background
    % backSource:   what part of the texture to display
    % objRect:      where to display the object
    % vbl:          time of last flip call
    % pd:           PD box definition

    global vbl screen backRect backSource objRect pd pdStim
    
    if (isempty(pdStim))
        pdStim=1;
    end

    % init the frame counter
    frame = 0;
    
    jumpsN = size(jitterSeq,2);
    objSeqN = size(objSeq, 2);
    
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        
        backIndex = mod(frame/waitframes, jumpsN)+1;
        backSource = backSource + jitterSeq(backIndex)*[1 0 1 0];

        Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0)

        % Object Drawing
        % --------------
        
        objIndex = mod(frame/waitframes, objSeqN)+1;
        objColor = objSeq(objIndex);
        Screen('FillRect', screen.w, objColor, objRect);


        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;

    end
end

function im = LoadIm(file, newMean, newContrast)
    % load the image in file and changes it so that it will have the given
    % mean and contrast
    
    % load file
    if (exist(file)==2)
        im0 = imread(file);
    else
        error ["file ", file, " does not exist or is not in the path"];
    end
    
    % convert it to 1D
    im1 = mean(im0, 3);
    im2 = reshape(im1, 1, size(im1,1)*size(im1,2));
    
    % change pixel intensity to have zero mean and sigma = 1
    oldMean = mean(im2);
    oldSigma = std(im2);
    im2 = im2 - oldMean;
    im2 = im2/oldSigma;
    
    % change pixel intensities to have meanIntensity and contrast
    if (newContrast >1)
        newContrast = newContrast/100;
    end
    
    newSigma = newMean*newContrast;
    im2 = im2*newSigma + newMean;

    % Change back to 2D array
    im = uint8(reshape(im2, size(im1,1), size(im1,2)));
end
function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
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
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

    p  = inputParser;   % Create an instance of the inputParser class.

    
        
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('objContrast', .05, @(x) all(x>=0) && all(x<=1));
    p.addParamValue('objJitterPeriod', 11, @(x)x>0 );
    p.addParamValue('objSizeH', 16*12, @(x)x>0);
    p.addParamValue('objSizeV', 16*12, @(x)x>0);
    p.addParamValue('objCenterXY', [0 0], @(x)size(x,2)==2);
    p.addParamValue('repeatObjSeq',0,@(x) x==0 || x==1);
    p.addParamValue('checkersN', 12, @(x)all(x>0) && all(x<=100));
    p.addParamValue('checkersSize', [16 16], @(x) all(x>0));
    
    % Background related
    p.addParamValue('backSeed', 2, @(x)isnumeric(x));
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backJitterPeriod', 11, @(x)x>0);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('repeatBackSeq',0,@(x) x==0 || x==1);
    
    % General
    p.addParamValue('stimSize', 16*32, @(x)x>0);
    p.addParamValue('presentationLength', 11, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', 8, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);
    
    
    p.addParamValue('color', 0, @(x)x>=0 && x<=255);
    p.addParamValue('array', [], @(x) 1);
    p.addParamValue('sizeV', 0, @(x)x>=0 );
    p.addParamValue('sizeH', 0, @(x)x>=0 );
    
    p.addParamValue('distance', [5], @(x) x>0);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end


