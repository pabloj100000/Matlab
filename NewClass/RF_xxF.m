function RF_xxF(varargin)
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
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    checkersN = p.Results.checkersN;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    repeatObjSeq = p.Results.repeatObjSeq;
    backSeed = p.Results.backSeed;
    repeatBackSeq = p.Results.repeatBackSeq;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
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
    
    framesPerSec = screen.rate;
    backFramesN = round(backJitterPeriod*framesPerSec);

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*screen.rate);

    % start the random generator streams
    objStream = RandStream('mcg16807', 'Seed',objSeed);
    RandStream.setDefaultStream(objStream);
    backStream = RandStream('mcg16807', 'Seed',backSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        % make the FEM like background sequence. Set up the random seed
        % before creating the random sequence and update it after you are
        % done
        if (~repeatBackSeq || presentation == 1)
            jitterSeq = randi(backStream, 3, 1, backFramesN)-2;
        end
            
        % JitteringBackTex_RFObj will use the random generator for the
        % checkers. Set the object seed right before using it. If you are
        % using different obj sequences update the seed after you are done.
        JitteringBackTex_RFObj(jitterSeq, checkersN, ...
            waitframes, framesN, objContrast, backTex)

        if (repeatObjSeq)
            objStream = RandStream('mcg16807', 'Seed',objSeed);
            RandStream.setDefaultStream(objStream);            
        end
        
        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
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
