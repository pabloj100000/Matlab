function run072111()
global screen

%  Record for 402s three times, then
% Record for 5000  +   2120
try
    
    Wait2Start()

    % Define the rectangles
    objRect = GetRects(192, screen.center);
    stimSize = 768;
    barsWidth = 8;


    % 1000s
    RF()

    % 2000s
    pause(.2)
    Reproduce092810()
    
    %%%%%%%%%%%%%%%%%%%%%% Changing contrast every 100s %%%%%%%%%%%%%%%%%%%
    % traditional Gatting Experiment switching contrast every 100s
    % 500s
    pause(.2)
    UflickerObj( ...
        'objContrast', [.12 .35 .24 .06 .03], ...
        'rects', objRect, ...
        'backMode', [0 0 1 0], ...
        'backPattern', 0, ...
        'barsWidth', barsWidth, ...
        'stimSize', stimSize, ...
        'backReverseFreq', 1, ...
        'backJitterPeriod', 100, ...
        'objJitterPeriod', 100, ...
        'presentationLength', 100, ...
        'movieDurationSecs', 500 ...
        );
    
    pause(.2)
    UflickerObj( ...
        'objContrast', [.12 .35 .24 .06 .03], ...
        'rects', objRect, ...
        'backMode', [0 0 1 0], ...
        'backPattern', 0, ...
        'barsWidth', barsWidth, ...
        'stimSize', stimSize, ...
        'pdStim', 106, ...
        'backReverseFreq', .5, ...
        'backJitterPeriod', 100, ...
        'objJitterPeriod', 100, ...
        'presentationLength', 500, ...
        'movieDurationSecs', 2500 ...
        );
    
    % 500s
    pause(.2)
    Sensitization();

    FinishExperiment();

catch 
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end

function Reproduce092810()
        % this is not identical to what was run on 092810.
        % Major differences are:
        %   1)  All times have been cut from 1600 to 1000s
        %   2)  On 092810 I run UFlickerObj_xSx twice, first with seed = 1
        %       and then with seed = 2 for a total of 3200s
        %       I'm only running the 1st 1000s of seed = 1
    global pdStim;


    % 1600 * 9 = 14400

    objContrast = [3 6 12 24]/100;
    for i=1:length(objContrast)

        pdStim=i;                                   %#ok<NASGU>
        UFlickerObj_xSx( ...
            'objContrast', objContrast(i), ...
            'backContrast', 1, ...
            'movieDurationSecs', 500, ...   
            'objSeed',1 ...
            );
    end
end

function UFlickerObj_xSx(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backReverseFreq, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    
    global vbl screen backRect backSource objRect pd
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
% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

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
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backReverseFreq*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);
    
    % make the Saccading like background sequence
    jitterSeq(1,:)=zeros(1, backJumpsPerPeriod);
    jitterSeq(1,0*backJumpsPerPeriod/2+1)=   barsWidth;
    jitterSeq(1,1*backJumpsPerPeriod/2+1)=  -barsWidth;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*60);
    randn('seed',objSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        objSeq = uint8(randn(1, objJumpsPerPeriod)*screen.gray*objContrast+screen.gray);
        
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
    p.addParamValue('objContrast', .05, @(x)x>=0 && x<=1);
    p.addParamValue('objJitterPeriod', 11, @(x)x>0 );
    p.addParamValue('objSeed', 1, @(x)isnumeric(x));
    p.addParamValue('objSizeH', 16*12, @(x)x>0);
    p.addParamValue('objSizeV', 16*12, @(x)x>0);
    p.addParamValue('objCenterXY', [0 0], @(x)size(x,2)==2);
    
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
%    p.addParamValue('pdStim', 1, @(x)x>=0 && x<256);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', 8, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);

    

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end







