function CheckersOnCheckers(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    
    global vbl screen objRect pd
    if isempty(vbl)
        vbl=0;
    end

    if isempty(pdStim)
        pdStim=1;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSeed  = p.Results.objSeed;
    backContrast = p.Results.backContrast;
    backSeed = p.Results.backSeed;
    
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    debugging = p.Results.debugging;
    checkerSize = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    

try
    InitScreen(0);
    Add2StimLogList();

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    backRect = SetRect(0,0,240,240);
    backRect = CenterRect(backRect, screen.rect);
    
    backRect2 = SetREct(0,0,checkerSize,checkerSize);
    backRect2 = CenterREct(backRect2, screen.rect);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = uint32(movieDurationSecs*screen.rate);

    % init random generator
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    objStream = RandStream('mcg16807', 'Seed', objSeed);
    
    
    % Animationloop:
    frame = 0;
    while (frame < framesN) & ~KbCheck %#ok<AND2>
        
        % CENTER REGION
        % ------ ------
        % Make and display obj texture
        objColor = (rand(objStream, checkersN_H, checkersN_V)>.5)*2*screen.gray*objContrast...
            + screen.gray*(1-objContrast);
        objTex  = Screen('MakeTexture', screen.w, objColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', objTex);

        backColor = ones(15,15)*screen.gray;
        randBackChecker = randi(backStream, 224);
        raw = floor(randBackChecker/15)+1;
        col = mod(randBackChecker, 15)+1;

        dispRect = OffsetRect(backRect2, raw*checkerSize-15/2*checkerSize, col*checkerSize-15/2*checkerSize);
        Screen('FillRect', screen.w, screen.black, dispRect);
        

        % PD
        % --
        % Draw the PD box
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;
    
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end




