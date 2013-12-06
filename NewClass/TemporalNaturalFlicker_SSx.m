function objSeed = TemporalNaturalFlicker_SSx(objContrast, trialsN, ...
    repeatCenterFlag, varargin)
%   
global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});

    waitframes = p.Results.waitframes;
    objSeed = p.Results.objSeed;
    objRect = p.Results.objRect;
    presentationLength = p.Results.presentationLength;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    backTex = p.Results.backTexture;
    stimSize = p.Results.stimSize;
    
    % start the stimulus
%    InitScreen(0)
    Add2StimLogList();

    % get the background texture
    stimSize = barsWidth*floor(stimSize/barsWidth);
    if (isempty(backTex))
        clearBackTexFlag = 1;
        backTex = GetCheckersTex(stimSize/barsWidth+1, 1, backContrast);
    else
        clearBackTexFlag = 0;
    end

    % I want framesN to have an even number of background reversals
    % 
    backFrames = fix(screen.rate/waitframes/backReverseFreq/2);
    framesN = fix(presentationLength*screen.rate/waitframes);
    framesN = backFrames*fix(framesN/backFrames);

    for trial = 0:trialsN-1
        if (trial==0 || ~repeatCenterFlag)
            % grab the natural stimulus
            objSeq = GetPinkNoise(0,framesN-1, objContrast, screen.gray, 0);
        end
        
        for i=0:1
            % i=0:  backFreq  = 0, still background
            % i=1:  backFreq != 0, saccading background
            backFreq = i*backReverseFreq;
            TemporalNaturalFLicker(objSeq, backFreq, waitframes, ...
                'backTexture', backTex, ...
                'barsWidth', barsWidth, ...
                'backContrast', backContrast, ...
                'backPhase', mod(trial,2), ...
                'objRect', objRect);
        end
        
        if (KbCheck)
            break
        end
    end

    if (clearBackTexFlag)
        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', backTex{1});
    end

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objRect', rect, @(x) size(x,1)==4 || size(x,2)==4);
%        p.addParamValue('objContrast', [.03 .06 .12 .24 1], @(x) all(all(x>=0)) && all(all(x<=1)));
%        p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);

        % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
%        p.addParamValue('backDest', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
%        p.addParamValue('angle', 0, @(x) isnumeric(x));

        % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('presentationLength', 200, @(x)x>0);
%        p.addParamValue('movieDurationSecs', 10000, @(x)x>0);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
