function RF(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    CreateStimuliLogStart()
    global vbl screen objRect pd
    if isempty(vbl)
        vbl=0;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    seed  = p.Results.objSeed;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    debugging = p.Results.debugging;
    checkerSize = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    

try
    InitScreen(debugging);

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = uint32(movieDurationSecs*60);

    % init random seed generator
    rand('seed', seed);
    
    % Define some needed variables
    
    % Animationloop:
    BinaryCheckers(framesN, waitframes, checkersN_V, checkersN_H, objContrast);
    
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