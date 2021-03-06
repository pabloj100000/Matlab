function objSeed = TemporalNaturalFlicker_Sxx(objContrast, trialsN, ...
    repeatCenterFlag, varargin)
global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});

    waitframes = p.Results.waitframes;
    objSeed = p.Results.objSeed;
    presentationLength = p.Results.presentationLength;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    backTex = p.Results.backTexture;
    stimSize = p.Results.stimSize;
    
    
    % start the stimulus
    InitScreen(0)
    Add2StimLogList();

    % get the background texture
    stimSize = barsWidth*floor(stimSize/barsWidth);
    if (isempty(backTex))
        clearBackTexFlag = 1;
        backTex = GetCheckersTex(stimSize/barsWidth, 1, backContrast);
    else
        clearBackTexFlag = 0;
    end

    % I want framesN to have an integer number of background reversals
    % 
    backFrames = fix(screen.rate/waitframes/backReverseFreq/2);
    seqLength = 100;    % I want to generate sequences that last 100s every
                         % time, because of the way GetNaturalStim works,
                         % with the fft, changing the time changes the
                         % sequence and I do not want that.
    % FramesN will be used to generate the obj sequence 
    framesN = fix(seqLength*screen.rate/waitframes);
    framesN = backFrames*fix(framesN/backFrames);
    
    % presentedFrames might be shorter than framesN
    presentedFrames = fix(presentationLength*screen.rate/waitframes);
    presentedFrames = backFrames*fix(presentedFrames/backFrames);
    
    if (presentedFrames>framesN)
        error('Problem in TemporalNaturalFlicker.\nPresentedFrames can not be bigger than framesN');
    end
    
    for trial = 0:trialsN-1
        if (trial==0 || ~repeatCenterFlag)
            % grab the natural stimulus
            [objSeq objSeed] = GetNaturalStim(framesN, objSeed);
            v_std = std(objSeq);
            objSeq = objSeq*screen.gray*objContrast/v_std + screen.gray;
            objSeq(presentedFrames+1:end)=[];
            fprintf('effective contrast is %g\r', std(objSeq)/mean(objSeq));
        end
        
        TemporalNaturalFLicker(objSeq, 0, waitframes, ...
            'backTexture', backTex);
        if (KbCheck)
            break
        end

    end
    FinishExperiment();

    if (clearBackTexFlag)
        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', backTex{1});
    end

    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = SCREEN_SIZE;
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x) && size(x,1)==1 );
        p.addParamValue('objContrast', [.03 .06 .12 .24 1], @(x) all(all(x>=0)) && all(all(x<=1)));
        p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);

        % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
        p.addParamValue('backDest', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
        p.addParamValue('angle', 0, @(x) isnumeric(x));

        % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('presentationLength', 100, @(x)x>0);
        p.addParamValue('movieDurationSecs', 10000, @(x)x>0);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
