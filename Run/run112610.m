function run112610()
CreateStimuliLogStart();

global pdStim;

Wait2Start()
% record for 800*9*.016673*60 = 7228 seconds

% ***********   Can we switch contrast every second ***************** 
pdStim = 0;
RF( ...
    'movieDurationSecs', 800, ...
    'barsWidth',16, ...
    'objContrast',1, ...
    'waitFrames', 1 ...
    );

%pause(1)
pdStim = 1;
RandUflickerObj_xSx( ...
    'objContrast', [.03 .06 .12 .24 1], ...
    'backReverseFreq', 1, ...
    'barsWidth', 8, ...
    'presentationLength', 1, ...   switch contrast every second
    'objJitterPeriod', 1, ...
    'movieDurationSecs', 1600 ...
    );

% *********** For cells under different contrasts. How much simultaneous
%           amplification do we see?            ***************** 
pdStim = 0;
RF( ...
    'movieDurationSecs', 800, ...
    'barsWidth',16, ...
    'objContrast',1, ...
    'waitFrames', 1 ...
    );

%pause(1)
pdStim = 2;
RandContrastCheckers_xSx(...
    'checkersSize', [192/2 192/2], ...
    'debugging',0, ...
    'objContrast', [ .12 1], ...
    'movieDurationSecs', 1600, ...
    'presentationLength', 5,...
    'objJitterPeriod', 5 ...
    )

% ***************** Do signales get amplified until contrast matches
%           background or can they be amplified even if contrast
%           is higher than in the background.
pdStim = 0;
RF( ...
    'movieDurationSecs', 800, ...
    'barsWidth',16, ...
    'objContrast',1, ...
    'waitFrames', 1 ...
    );

%%pause(1)
pdStim = 3;
RandUflickerObj_xSx( ...
    'objContrast', [.03 .06 .12 .24 1], ...
    'backReverseFreq', 1, ...
    'barsWidth', 8, ...
    'backContrast', .12, ...
    'presentationLength', 10, ...   switch contrast every second
    'objJitterPeriod', 10, ...
    'movieDurationSecs', 800 ...
    );

%%pause(1)
pdStim = 4;
RandUflickerObj_xSx( ...
    'objContrast', [.03 .06 .12 .24 1], ...
    'backReverseFreq', 1, ...
    'barsWidth', 8, ...
    'backContrast', .24, ...
    'presentationLength', 10, ...   switch contrast every second
    'objJitterPeriod', 10, ...
    'movieDurationSecs', 800 ...
    );
CreateStimuliLogWrite();

end

function RandUflickerObj_xSx(varargin)
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

function RandContrastCheckers_xSx(varargin)
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
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    checkersSize = p.Results.checkersSize;
    objCenterXY = p.Results.objCenterXY;

    stimSize = p.Results.stimSize;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    


    % Redefine exp time to have an even number of jitters
    contrastsN = size(objContrast,2);
    movieDurationSecs = presentationLength*contrastsN* ...
        floor( movieDurationSecs/presentationLength/contrastsN);

    % Redefine the stimSize to incorporate an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

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

    % Define the random array for checkers
    checkersN = round([objSizeH/checkersSize(1) objSizeV/checkersSize(2)]);
    checkers = zeros(checkersN);
    
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

    % make a random sequence of Contrasts
    randStream = RandStream('mcg16807', 'Seed', objSeed);
    contrastSeq = randperm(randStream, presentationsN*checkersN(1)*checkersN(2)) - 1;       % numbers go between 0 and presentationsN -1
    contrastSeq = mod(contrastSeq, contrastsN) + 1;                         % number go between 1 and contrastsN
    contrastSeq = reshape(contrastSeq, checkersN(1), checkersN(2), presentationsN);
    clear randStream
    
    %Restart a random stream per checker per contrast, all with the same
    %seed
    for i=1:checkersN(1)
        for j=1:checkersN(2)
            for k=1:contrastsN;
                randStream{i,j,k} = RandStream('mcg16807', 'Seed', objSeed);
            end
        end
    end
    
    % preallocate objSeq for speed
    objSeq = zeros(checkers(1), checkers(2), objJumpsPerPeriod);
    
    % Animationloop:
    for presentation = 1:presentationsN
        % grab the contrast for each checker over the current presentation
        contrastIndex = contrastSeq(:,:,presentation);
        contrast = objContrast(contrastIndex);
        
        % for each checker, grab the sequence of random numbers that
        % correspond to the contrast
        for i=1:checkersN(1)
            for j=1:checkersN(2)
                objSeq(i,j,:) = uint8(randn(randStream{i,j,contrastIndex(i,j)}, 1, objJumpsPerPeriod)*screen.gray*contrast(i,j)+screen.gray);
                if (contrast(i, j)==1)
                    % Convert noise to binary
                    objSeq(i,j,:) = (objSeq(i,j,:)>screen.gray)*255;
                end
            end
        end
        
        JitteringBackTex_RandContrRF(framesN, jitterSeq, objSeq, ...
            waitframes, backTex);
        
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
