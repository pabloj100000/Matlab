function RF_xSx(varargin)
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

    p  = inputParser;   % Create an instance of the inputParser class.

    [screenW screenH] = SCREEN_SIZE;
    
    p.addParamValue('objContrast', .35, @(x)x>0);
    p.addParamValue('objSeed', 1, @(x) x>0);
    p.addParamValue('stimSize', screenH, @(x) x>0);
    p.addParamValue('objSizeH', 12*PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('objSizeV', 12*PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('objCenterXY', [0 0], @(x)size(x)==[1 2]);
    p.addParamValue('backContrast', 1, @(x) x>0);
    p.addParamValue('backReverseFreq', .5, @(x) x>0);
    p.addParamValue('presentationLength', 2, @(x) x>0);
    p.addParamValue('movieDurationSecs', 1000, @(x) x>0);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    p.addParamValue('checkersN', 1, @(x) x>0);
    p.addParamValue('waitframes', 1, @(x) x>0);
    p.addParamValue('pdStim', 0, @(x) x>=0);

    p.parse(varargin{:});
    


    objContrast = p.Results.objContrast;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    barsWidth = p.Results.barsWidth;
    checkersN = p.Results.checkersN;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;
    
%    vbl = p.Results.vbl;
    

% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/presentationLength);

% Redefine the stimSize to incorporate an integer number of bars
stimSize = ceil(stimSize/barsWidth)*barsWidth;

%LoadHelperFunctions();
try    
    InitScreen(0);
    Add2StimLogList();
    
    % make the background texture
    backTex = GetCheckersTex(stimSize/barsWidth+1, 1, backContrast);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize/barsWidth,stimSize/barsWidth);
    backSourceOri = backSource;
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    framesPerSec = screen.rate;
    backJumpsPerPeriod = round(framesPerSec/backReverseFreq);
    
    % make the Saccading like background sequence
    jitterSeq(1,:)=zeros(1, backJumpsPerPeriod);
    jitterSeq(1,0*backJumpsPerPeriod/2+1)=   1;
    jitterSeq(1,1*backJumpsPerPeriod/2+1)=  -1;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*screen.rate);
    rand('seed',objSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        
        JitteringBackTex_RFObj(jitterSeq, checkersN, ...
            waitframes, framesN, objContrast, backTex{1}, pdStim)


        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
%        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];

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
