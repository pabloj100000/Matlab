function BackgroundRF(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % checkersContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    CreateStimuliLogStart()
    global vbl screen pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    
    if isempty(pdStim)
        pdStim=1;
    end

    p=ParseInput(varargin{:});

    seed  = p.Results.objSeed;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    debugging = p.Results.debugging;
    checkerSize = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objColor = p.Results.color;
    checkersContrast = p.Results.backContrast;

try
     InitScreen(debugging);

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the back Destination Rectangle
    backRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    backRect = CenterRect(backRect, screen.rect);

    % Define the object Rectangle
    objRect = SetRect(0,0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = uint32(movieDurationSecs*60);
    frame = 0;
    
    % init random seed generator
    S1 = RandStream('mcg16807', 'Seed',seed);
    
    % Animationloop:
    while (frame < framesN) & ~KbCheck %#ok<AND2>


        
        % CENTER REGION
        % ------ ------
        % Make and display obj texture
        backColor = (rand(S1, checkersN_H, checkersN_V)>.5)*2*screen.gray*checkersContrast...
            + screen.gray*(1-checkersContrast);
        backTex  = Screen('MakeTexture', screen.w, backColor);
        Screen('DrawTexture', screen.w, backTex, [], backRect, 0, 0);

        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', backTex);

        % Display the uniform constant box in the object region
        Screen('FillRect', screen.w, objColor, objRect);
        
        % PD
        % --
        % Draw the PD box
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)

        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;
    
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



function BiMonoPhasicInformation(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can have different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done

    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    
    if isempty(pdStim)
        pdStim=0;
    end
    
    p=ParseInput(varargin{:});

    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    objContrast = p.Results.objContrast;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backSeed = p.Results.backSeed;
    backTex = p.Results.backTexture;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;

    backN = sum(backMode);
    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = backN*presentationLength* ...
        floor(movieDurationSecs/(backN*presentationLength));

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    
try
    InitScreen(debugging);
    
    % make the background texture
    if (isempty(backTex))
        backTex = GetCheckersTex(stimSize, barsWidth, screen, backContrast);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,stimSize);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = 1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % make all 7 objects that I want to use in the information calculation.
    % 1st 4 objects are constant intensities, last 3 are biphasic at
    % different periods
    frame1 = 1;
    frame2 = 3;
    frame3 = 5;
    objSeq = zeros(7, backJumpsPerPeriod);
    objSeq(1,:) = 0;
    objSeq(2,:) = 63;
    objSeq(3,:) = 127;
    objSeq(4,:) = 255;
    objSeq(5,:) = round(screen.gray*(1 - objContrast/2 + mod(floor((0:backJumpsPerPeriod-1)/frame1),2)*objContrast ));
    objSeq(6,:) = round(screen.gray*(1 - objContrast/2 + mod(floor((0:backJumpsPerPeriod-1)/frame2),2)*objContrast ));
    objSeq(7,:) = round(screen.gray*(1 - objContrast/2 + mod(floor((0:backJumpsPerPeriod-1)/frame3),2)*objContrast ));
    
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of objects to display.
    S1 = RandStream('mcg16807', 'Seed', objSeed);
    objStimSeq = randperm(S1, presentationsN);
    objStimSeq = mod(objStimSeq(:), 7) + 1;
    clear S1;
    

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % get a random order of all selected backgrounds
        backOrder = randperm(backStream, 4);
%backOrder
%backOrderArray(presentation, :)=backOrder;
        for back=1:4            
            if (back==1)
                object = objSeq(objStimSeq(presentation), :);
            end
            
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
            frame = 0;
            while (frame < framesN) && ~KbCheck
                frameIndex = floor(frame/waitframes)+1;
                % Background Drawing
                % ---------- -------
                backSource = backSource + backSeq(frameIndex)*[1 0 1 0];

                % Disable alpha-blending, restrict following drawing to alpha channel:
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                
                % Clear 'dstRect' region of framebuffers alpha channel to zero:
                %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
                Screen('FillRect', screen.w, [0 0 0 0], [0 0 10000 10000]);
                
                % Fill circular 'dstRect' region with an alpha value of 255:
                Screen('FillOval', screen.w, [0 0 0 255], backRect);
                
                % Enable DeSTination alpha blending and reenalbe drawing to all
                % color channels. Following drawing commands will only draw there
                % the alpha value in the framebuffer is greater than zero, ie., in
                % our case, inside the circular 'dst2Rect' aperture where alpha has
                % been set to 255 by our 'FillOval' command:
                Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                
                % Draw 2nd grating texture, but only inside alpha == 255 circular
                % aperture, and at an angle of 90 degrees:
                Screen('DrawTexture', screen.w, backTex, backSource, backRect, backAngle,0);
                
                % Restore alpha blending mode for next draw iteration:
                Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

                
                % Object Drawing
                % --------------
                Screen('FillRect', screen.w, object(frameIndex), objRect);
                
                % Photodiode box
                % --------------
                DisplayStimInPD2(pdStim, pd, frame, 60, screen)
                
                % Flip 'waitframes' monitor refresh intervals after last redraw.
                vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
                frame = frame + waitframes;
            end
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 1 1 1];
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function CheckersOnCheckers(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    CreateStimuliLogStart()
    global vbl screen objRect pd pdStim
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
    InitScreen(debugging);

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
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = uint32(movieDurationSecs*60);

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
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;
    
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




function CheckersOnCheckers(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    CreateStimuliLogStart()
    global vbl screen objRect pd pdStim
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
    InitScreen(debugging);

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
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = uint32(movieDurationSecs*60);

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
        DisplayStimInPD2(pdStim, pd, frame, 60, screen)
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;
    
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




function ContrastInformation(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can have different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done

    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    
    if isempty(pdStim)
        pdStim=0;
    end
    
    p=ParseInput(varargin{:});

    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backSeed = p.Results.backSeed;
    backTex = p.Results.backTexture;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;

    backN = sum(backMode);
    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = backN*presentationLength* ...
        floor(movieDurationSecs/(backN*presentationLength));

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    
try
    InitScreen(debugging);
    
    % make the background texture
    if (isempty(backTex))
        backTex = GetCheckersTex(stimSize, barsWidth, screen, backContrast);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,stimSize);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = 1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % make all 7 objects that I want to use in the information calculation.
    % 1st 4 objects are constant time period, different conrasts.
    % Last 3 are at different time period, same contrast as stim 3
    % I am going to change the intensity in the object every frames1/4 frames.
    % The idea is that 2*frames1 matches the temporal extent of the kernel
    % as close as possible.
    frame1 = 3;
    frame2 = 2;
    frame3 = 4;
    frame4 = 5;
    objSeq = zeros(7, backJumpsPerPeriod);
    objSeq(1,:) = mod(floor((0:backJumpsPerPeriod-1)/frame1),2)*32  + 112;
    objSeq(2,:) = mod(floor((0:backJumpsPerPeriod-1)/frame1),2)*16  + 119;
    objSeq(3,:) = mod(floor((0:backJumpsPerPeriod-1)/frame1),2)*8  + 123;
    objSeq(4,:) = mod(floor((0:backJumpsPerPeriod-1)/frame1),2)*4  + 125;
    objSeq(5,:) = mod(floor((0:backJumpsPerPeriod-1)/frame2),2)*8  + 123;
    objSeq(6,:) = mod(floor((0:backJumpsPerPeriod-1)/frame3),2)*8  + 123;
    objSeq(7,:) = mod(floor((0:backJumpsPerPeriod-1)/frame4),2)*8  + 123;
    
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of objects to display.
    S1 = RandStream('mcg16807', 'Seed', objSeed);
    objStimSeq = randperm(S1, presentationsN);
    objStimSeq = mod(objStimSeq(:), 7) + 1;
    clear S1;
    

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % get a random order of all selected backgrounds
        backOrder = randperm(backStream, 4);
%backOrder
%backOrderArray(presentation, :)=backOrder;
        for back=1:4            
            if (back==1)
                object = objSeq(objStimSeq(presentation), :);
            end
            
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
            frame = 0;
            while (frame < framesN) & ~KbCheck %#ok<AND2>
                frameIndex = frame/waitframes+1;
                
                % Background Drawing
                % ---------- -------
                backSource = backSource + backSeq(frameIndex)*[1 0 1 0];

                % Disable alpha-blending, restrict following drawing to alpha channel:
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                
                % Clear 'dstRect' region of framebuffers alpha channel to zero:
                %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
                Screen('FillRect', screen.w, [0 0 0 0], [0 0 10000 10000]);
                
                % Fill circular 'dstRect' region with an alpha value of 255:
                Screen('FillOval', screen.w, [0 0 0 255], backRect);
                
                % Enable DeSTination alpha blending and reenalbe drawing to all
                % color channels. Following drawing commands will only draw there
                % the alpha value in the framebuffer is greater than zero, ie., in
                % our case, inside the circular 'dst2Rect' aperture where alpha has
                % been set to 255 by our 'FillOval' command:
                Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                
                % Draw 2nd grating texture, but only inside alpha == 255 circular
                % aperture, and at an angle of 90 degrees:
                Screen('DrawTexture', screen.w, backTex, backSource, backRect, backAngle,0);
                
                % Restore alpha blending mode for next draw iteration:
                Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

                
                % Object Drawing
                % --------------
                Screen('FillRect', screen.w, object(frameIndex), objRect);
                
                % Photodiode box
                % --------------
                DisplayStimInPD2(pdStim, pd, frame, 60, screen)
                
                % Flip 'waitframes' monitor refresh intervals after last redraw.
                vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
                frame = frame + waitframes;
            end
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 1 1 1];
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function FixedObjPhases_SSx(varargin)
%   Stimulus is divided in object and background. Each one with its own
%   contrast. Spatialy, both are going to be gratings of a given barsWidth.
%   Temporally, background can either be still or reversing at
%   backReverseFreq. The object will be changing between 4 different phases
%   at backReverseFreq. All possible combinations of 4 phases are
%   considering giving a total of 16 different jumps. There is nothing
%   random in this experiment.

   global vbl screen backRect backSource objRect objSource pd
 


    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    debugging = p.Results.debugging;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backReverseFreq = p.Results.backReverseFreq;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    
    CreateStimuliLogStart()
    if isempty(vbl)
        vbl=0;
    end

    phasesN = 4;
    oneSecStimN = (phasesN^2)/2;
    presentationLength = 1/backReverseFreq;
    repeats = 11;
    globalRepeats = 4;
    movieDurationSecs = globalRepeats*repeats*presentationLength*oneSecStimN;
try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % make the object texture
    x= 1:2*objSizeH;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*objContrast...
        + screen.gray*(1-objContrast));
    objTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);
    backSourceOri = backSource;
    objSourceOri = objSource;

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objSeqFramesN = presentationLength*framesPerSec;
    
    % make the back sequences (one still, one saccade like)
    backSeq(1,:) = zeros(1, objSeqFramesN);
    jumpingFrames = 1:objSeqFramesN/2:objSeqFramesN;
    backSeq(2,jumpingFrames) = barsWidth/2;

    % make the object sequence of jumps. Jumps are separeted every
    % saccadeFrames.
    %phaseSequence = [0 1 1 2 3 0 0 2 1 0 3 3 1 3 2 2];
    allObjSeq = zeros(8, objSeqFramesN);
    allObjSeq(:,jumpingFrames) = [2 1; 0 1; 1 1; 0 2; -1 -1; -1 0; 2 2; -1 0]*barsWidth/2;
%    objJumpsSeq=[2 1 0 1 1 1 0 2 -1 -1 -1 0 2 2 -1 0]*barsWidth/2;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % Define some needed variables
    framesN = uint32(presentationLength*60);
    
    % Animationloop:
    for presentation = 0:presentationsN-1
        background = mod(floor(presentation/oneSecStimN/repeats), 2)+1;
        objSeq = allObjSeq(mod(presentation, oneSecStimN)+1, :);
        
        JitterBackTex_JitterObjTex(backSeq(background,:), objSeq, ...
            waitframes, framesN, backTex, objTex);

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = mod(objSource, 2*barsWidth)+objSourceOri.*[1 0 1 0];

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

function GatingFinder(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % v.contrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % v.objCenterXY, backContrast, backReverseFreq, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    CreateStimuliLogStart()
    global vbl screen pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    if isempty(pdStim)
        pdStim=0;
    end

    SPACEBAR = KbName('space');
    ESCAPE = KbName('escape');
    LEFTARROW = KbName('LeftArrow');
    UPARROW = KbName('UpArrow');
    RIGHTARROW = KbName('RightArrow');
    DOWNARROW = KbName('DownArrow');
    DELAY = 1;
    NODELAY = 0;
    INCREASE = 1;
    DECREASE = -1;

    p=ParseInput(varargin{:});

    v.contrast = p.Results.objContrast;
    objSeed = p.Results.objSeed;
    v.diameter = 192;
    
    stimSize = p.Results.stimSize;
    backContrast = p.Results.backContrast;
    
    presentationLength = 1;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
        
    % Redefine the stimSize to incorporate an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

try    
    InitScreen(debugging);
    
    % make the background texture
    backTex{1} = GetCheckersTex(stimSize, 4, screen, backContrast);
    backTex{2} = GetCheckersTex(stimSize, 8, screen, backContrast);
    backTex{3} = GetCheckersTex(stimSize, 16, screen, backContrast);
    backTex{4} = GetCheckersTex(stimSize, 32, screen, backContrast);
    backTex{5} = GetCheckersTex(stimSize, 100, screen, backContrast);
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,stimSize);
    backSourceOri = backSource;

    objRect = SetRect(0,0,v.diameter, v.diameter);
    objRect = CenterRect(objRect, screen.rect);
    [v.objCenter(1), v.objCenter(2)] = RectCenter(objRect);
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60;
            
    framesN = uint32(presentationLength*framesPerSec);

    % make a still and a Saccading like background sequence
    jitterSeq(:,:) = zeros(5, framesN);
    x = 0:int32(2*framesN/framesPerSec)-1;
    jitterSeq(2,x*framesPerSec/2+1)=   4*(-1).^x;
    jitterSeq(3,x*framesPerSec/2+1)=   8*(-1).^x;
    jitterSeq(4,x*framesPerSec/2+1)=   16*(-1).^x;
    jitterSeq(5,x*framesPerSec/2+1)=   32*(-1).^x;
    jitterSeq(6,x*framesPerSec/2+1)=   100*(-1).^x;
            
    %Restart a random stream per checker per contrast, all with the same
    %seed
    randStream = RandStream('mcg16807', 'Seed', objSeed);
    
    % preallocate objSeq for speed
    objSeq = zeros(1, framesN);

    exitFlag = 0;
    v.backMode = 2;
    v.meanIntensity = screen.gray;
    v.backAngle = 0;
    v.backTex = 1;
    v.break = 0;
    text = fieldnames(v);
       
    selection = 1;
    % Animationloop:
    
    ListenChar(2)       % prevent keystrokes from writing onto matlab
    while 1         
        objSeq = uint8(randn(randStream, 1, framesN)*v.meanIntensity*v.contrast+v.meanIntensity);
        
        if (v.contrast==1)
            % Convert noise to binary
            objSeq = (objSeq>v.meanIntensity)*255;
        end
        backSource = backSourceOri;
        for frame=0:waitframes:framesN-1
            Screen('FillRect', screen.w, screen.gray, [1 1 300 30]);
            Screen(screen.w,'TextSize', 18);
            Screen(screen.w, 'DrawText', [text{selection}, ' = ', num2str(v.(text{selection}))],1,1, screen.black );
            
            backSource = backSource + [1 0 1 0]*jitterSeq(v.backMode,frame+1);

            % display the background
            Screen('DrawTexture', screen.w, backTex{v.backTex}, backSource, backRect, v.backAngle,1)
            
            % display checker
            Screen('FillOval', screen.w, objSeq(1, frame+1), objRect)
            
            % Photodiode box
            % --------------
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
            
            
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if (keyIsDown)
                if keyCode(ESCAPE)
                    exitFlag = 1;
                    break
                elseif keyCode(SPACEBAR)
                    % change mode
                    pause(0.2);
                    selection = mod(selection, length(text)) + 1;
                    {selection, text{selection}}
                elseif keyCode(RIGHTARROW)
                    v = ChangeSelection(selection, v, INCREASE, NODELAY);
                elseif keyCode(LEFTARROW)
                    v = ChangeSelection(selection, v, DECREASE, NODELAY);
                elseif keyCode(UPARROW)
                    v = ChangeSelection(selection, v, INCREASE, DELAY);
                elseif keyCode(DOWNARROW)
                    v = ChangeSelection(selection, v, DECREASE, DELAY);
                end
                objRect = SetRect(0,0,v.diameter, v.diameter);
                objRect = CenterRectOnPoint(objRect,v.objCenter(1),v.objCenter(2));

                if (v.break)
                    break
                end
            end
        
%            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        end
        if exitFlag
            break;
        end
    end
    ListenChar(0)
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    ListenChar(0)
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function v = ChangeSelection(selection, v, UpDown, delayFlag)
    v.break = 0;
    switch selection
        case 1   % change Contrast
            v.contrast = v.contrast + .01*UpDown;
            if v.contrast < 0
                v.contrast = 0;
            elseif v.contrast > 1
                v.contrast = 1;
            end
        case 2   % change v.diameter
            v.diameter = v.diameter + UpDown * 1;
        case 3   % change v.objCenter
            % delayFlag is 1 if pressed Up/Down arrows and is 0 if
            % left/right arrows
            if (delayFlag)
                v.objCenter = v.objCenter + [0 1]*UpDown;
            else
                v.objCenter = v.objCenter + [1 0]*UpDown;
            end
        case 4   % change v.backMode
            if (v.backMode == 1)
                v.backMode = v.backTex+1;
            else
                v.backMode = 1;
            end
        case 5  % hange v.meanIntensity
            v.meanIntensity = v.meanIntensity + UpDown * 1;
            if (v.meanIntensity < 0)
                v.meanIntensity = 0;
            elseif (v.meanIntensity > 255)
                v.meanIntensity = 255;
            end
        case 6  % hange v.backAngle
            v.backAngle = v.backAngle + UpDown * 1;
            if (mod(v.backAngle, 360)==0 )
                v.backAngle = 0;
            end
        case 7  % bac, tex
            v.backTex = mod(v.backTex,5)+1;
            % if backMode is not still, update the background step
            if (v.backMode > 1)
                v.backMode = v.backTex+1;
            end
            v.break = 1;
    end
    if (delayFlag && selection~=3)
        pause(0.5);
    end
end
function nextSeed = JitterAllTextures(textures, objSeed, alphaIn, ...
    presentationsN, jitter, objSize, imSize, objColor, objMode)
    global screen pdStim vbl
    
    if (isempty(pdStim))
        pdStim=0;
    end
    
    if (isempty(vbl))
        vbl=0;
    end
    
    framesN = length(jitter);
  
%    textures = LoadAllTextures(debugging, '../Images/');
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);

    % Get 1sec random jitter (60 frames per sec)
%    S1 = RandStream('mcg16807', 'Seed', objSeed);
%    jitter = randi(S1, 3, 1, framesN)-2;
%    clear S1

    imSize = imSize/2;   % actuall, half the image size

    % Create a single gaussian transparency mask and store it to a texture:
    % The mask must have the same size as the visible size of the grating
    % to fully cover it. Here we must define it in 2 dimensions and can't
    % get easily away with one single row of pixels.
    %
    % We create a  two-layer texture: One unused luminance channel which we
    % just fill with the same color as the background color of the screen
    % 'gray'. The transparency (aka alpha) channel is filled with a
    % gaussian (exp()) aperture mask:
    mask=ones(2*imSize+1, 2*imSize+1, 2) * screen.gray;
    [x,y]=meshgrid(-1*imSize:1*imSize,-1*imSize:1*imSize);
    % mask == 0 is opaque, mask == 255 is transparent
    i=1;
    for alphaOut=255:255:255
%        for alphaIn=0:63:255
            mask(:, :, 2) = (abs(x)<objSize/2 & abs(y)<objSize/2)*(alphaIn-alphaOut) + alphaOut;
            maskTex{i}=Screen('MakeTexture', screen.w, mask);
            i = i+1;
%        end
    end
    clear x y mask

    % Get rect for objMode=2
    objRectOri = SetRect(0,0,objSize,objSize);
    objRectOri = CenterRect(objRectOri, screen.rect);
    
    % Get order of images and masks
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    order=randperm(S1, presentationsN);
    imOrder = mod(order, length(textures))+1;
    maskOrder = mod(order, length(maskTex))+1;
    nextSeed = S1.State;
    
%    destRectOri = [0 0 2*imSize-1 2*imSize-1];
    destRectOri = GetRects(2*imSize, [screen.rect(3) screen.rect(4)]/2);
    sourceRectOri = [0 0 2*imSize-1 2*imSize-1];
    angle = 0;
    
    Screen('TextSize', screen.w,12);

    for i=1:presentationsN
        destRect = destRectOri;
        sourceRect = sourceRectOri;
        objRect = objRectOri;
        for frame = 0:framesN-1    % for every frame
            destRect = destRect + jitter(frame+1)*[1 0 1 0];
            objRect = objRect + jitter(frame+1)*[1 0 1 0];
            
            switch objMode
                case 0
                    Screen('DrawTexture', screen.w, textures{imOrder(i)}, sourceRect, destRect, angle);
                case 1
                    % Disable alpha-blending, restrict following drawing to alpha channel:
                    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                    
                    % Clear 'dstRect' region of framebuffers alpha channel to zero:
                    Screen('FillRect', screen.w, [0 0 0 0], destRect);
                    
                    % Write value of alpha channel and RGB according to our mask
                    Screen('DrawTexture', screen.w, maskTex{maskOrder(i)},[],destRect);
                    
                    % Enable DeSTination alpha blending and reenalbe drawing to all
                    % color channels. Following drawing commands will only draw there
                    % the alpha value in the framebuffer is greater than zero, ie., in
                    % our case, inside the circular 'dst2Rect' aperture where alpha has
                    % been set to 255 by our 'FillOval' command:
                    Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                    
                    % Draw 2nd texture
                    Screen('DrawTexture', screen.w, textures{imOrder(i)}, sourceRect, destRect, angle);
                    
                    % Restore alpha blending mode for next draw iteration:
                    Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                case 2
                    Screen('DrawTexture', screen.w, textures{imOrder(i)}, sourceRect, destRect, angle);
                    Screen('FillRect', screen.w, objColor, objRect);
                    
            end
            
            Screen('DrawText', screen.w, ['i = ',num2str(i)], 20,20, screen.black);
            Screen('DrawText', screen.w, ['alpha = ', num2str(alphaIn)] , 20,40, screen.black);
            % Photodiode box
            % --------------
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)

            vbl = Screen('Flip', screen.w, vbl);
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
end


function LoadHelperFunctions()
end
function LowContrastObj_SSF(varargin)



    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect objSource pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    if isempty(pdStim)
        pdStim=1;
    end

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSeed  = p.Results.objSeed;
    debugging = p.Results.debugging;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    waitframes = p.Results.waitframes;

    backSeqN = 3;       % there are only two backgrounds, the random one and a still one.

% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
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


% Redefine exp time to have an even number of jitters
movieDurationSecs = backSeqN*presentationLength* ...
    floor(movieDurationSecs/(backSeqN*presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % make the object texture
    x= 1:3*objSizeH;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*objContrast...
        + screen.gray*(1-objContrast));
    objTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);
    backSourceOri = backSource;
    objSourceOri = objSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    %when background is reversing (jumping) how many frames is the period
    %of the reversing?
    backReverseFrames = round(framesPerSec/backReverseFreq);
    
    % make the back still and reversing sequences
    stillSeq = zeros(1, objJumpsPerPeriod);
    
    
    reverseSeq = zeros(1, objJumpsPerPeriod);
    ForwardFrames = 1:backReverseFrames:objJumpsPerPeriod;
    reverseSeq(1,ForwardFrames)=   barsWidth;
    reverseSeq(1,ForwardFrames + backReverseFrames/2)=  -barsWidth;

    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % Define some needed variables
    

    framesN = uint32(presentationLength*60);
    rand('seed', objSeed);

    % Animationloop:
    for presentation = 0:presentationsN-1
        switch (mod(presentation, 3))
            case 0
                backSeq = stillSeq;
                %objSeed = rand('seed');
                % get the random sequence of jumps for the object
                objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

            case 1
                backSeq = reverseSeq;
                %rand('seed', objSeed);
            case 2
                % somewhat anelegant coding. Setting backSeq to the
                % objSeq used in the previuos presentation. Ends up working
                % ok because the objSeq of this presentation will be
                % identical.
                backSeq = objSeq;
                %rand('seed', objSeed);
        end


        JitterBackTex_JitterObjTex(backSeq, objSeq, waitframes, framesN, ...
            backTex, objTex)

        % Previous function DID modify backSource and objSource.
        % Recenter backSource to prevent too much sliding of the texture.
        % objSource has to be reinitialize so that all 3 sequences will
        % have the same phase.
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = objSourceOri;

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

function LowContrastObj_SxF(varargin)
%   
   global vbl screen backRect backSource objRect objSource pd pdStim
 


    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSeed  = p.Results.objSeed;
    debugging = p.Results.debugging;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;
    
    
    CreateStimuliLogStart()
    if isempty(vbl)
        vbl=0;
    end

    backSeqN = 2;       % there are only two backgrounds, the random one and a still one.

% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
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


% Redefine exp time to have an even number of jitters
movieDurationSecs = backSeqN*presentationLength* ...
    floor(movieDurationSecs/(backSeqN*presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % make the object texture
    x= 1:2*objSizeH;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*objContrast...
        + screen.gray*(1-objContrast));
    objTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);
    backSourceOri = backSource;
    objSourceOri = objSource;

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    
    % make the backSeqN random sequences
    stillSeq = zeros(1, objJumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % Define some needed variables
    framesN = uint32(presentationLength*60);
    rand('seed', objSeed);
    
    % Animationloop:
    for presentation = 1:presentationsN
        % get the random sequence of jumps for the object
        objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

        if (mod(presentation, 2))
            % Global Motion
            backSeq = objSeq;
            rand('seed', objSeed);
        else            
            % Differential Motion
            backSeq = stillSeq;
           objSeed = rand('seed');
        end

        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex);

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = mod(objSource, 2*barsWidth)+objSourceOri.*[1 0 1 0];

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

function LowContrastObj_SxF(varargin)
   global vbl screen backRect backSource objRect objSource pd pdStim
 


    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSeed  = p.Results.objSeed;
    debugging = p.Results.debugging;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    waitframes = p.Results.waitframes;
    pdStim = p.Results.pdStim;
    
    
    CreateStimuliLogStart()
    if isempty(vbl)
        vbl=0;
    end

    backSeqN = 2;       % there are only two backgrounds, the random one and a still one.

% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
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


% Redefine exp time to have an even number of jitters
movieDurationSecs = backSeqN*presentationLength* ...
    floor(movieDurationSecs/(backSeqN*presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % make the object texture
    x= 1:2*objSizeH;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*objContrast...
        + screen.gray*(1-objContrast));
    objTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);
    backSourceOri = backSource;
    objSourceOri = objSource;

    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    
    % make the backSeqN random sequences
    stillSeq = zeros(1, objJumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % Define some needed variables
    framesN = uint32(presentationLength*60);
    rand('seed', objSeed);
    
    % Animationloop:
    for presentation = 1:presentationsN
        % get the random sequence of jumps for the object
        objSeq = floor(rand(1, objJumpsPerPeriod)*3)-1;

        if (mod(presentation, 2))
            % Global Motion
            backSeq = objSeq;
            rand('seed', objSeed);
        else            
            % Differential Motion
            backSeq = stillSeq;
           objSeed = rand('seed');
        end

        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex);

        % Previous function DID modify backSource. Recenter it to prevent
        % too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
        objSource = mod(objSource, 2*barsWidth)+objSourceOri.*[1 0 1 0];

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

function NaturalStim2_xSF(varargin)

    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    if isempty(pdStim)
        pdStim=1;
    end

    p=ParseInput(varargin{:});

    debugging = p.Results.debugging;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    objSeed = p.Results.objSeed;
    objSizeH = p.Results.objSizeH;      % Here obj Size and Center define
    objSizeV = p.Results.objSizeV;      % a rectangle and in each corner of the rectangle
    objCenterXY = p.Results.objCenterXY;    % the 4 flys will be positioned, each one
    objContrast = p.Results.objContrast;
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backSeed = p.Results.backSeed;
    waitframes = p.Results.waitframes;


% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
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


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(0, 0, stimSize, stimSize);
    backSource = OffsetRect(backSource, stimSize/2,0);
    backSourceOri = backSource;

    % make background textures
    x= 1:2*stimSize;
    bars = ones(stimSize,1)*ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    barsRect = SetRect(0,0,size(bars,1), size(bars,2));
    
    % Grab the images and constrain the size
    im = LoadIm('rocks.jpeg', 127, objContrast);
    if (objSizeH ~= size(im,1) || objSizeV ~= size(im,2))
        im = imresize(im, [objSizeH objSizeV]);
    end
        
    imRect = CenterRect(objRect, barsRect);
    backTex=zeros(1,4);
    for i=1:4
        bars(imRect(1):imRect(3)-1, imRect(2):imRect(4)-1)=im;
        im = rot90(im);
        
        backTex(i) = Screen('MakeTexture', screen.w, bars);
    end
    clear bars
    
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);
    
    % make the jitter sequence
    S1 = RandStream('mcg16807', 'Seed',backSeed);
    jitterSeq = randi(S1, 3, 1, framesN)-2;
    jitterSeq(1, framesN) = barsWidth;

    % make the random sequence of objects to be presented.
    S2 = RandStream('mcg16807', 'Seed', objSeed);
    object = randperm(S2, presentationsN)-1;
    object = mod(object, 4)+1;
    
    % Animationloop:
    for presentation = 0:presentationsN-1
        shift = [0 0 0 0];
        for frame=0:framesN-1
            shift = shift + jitterSeq(frame+1)*[1 0 1 0];
            Screen('DrawTexture', screen.w, backTex(object(presentation+1)), backSource-shift, backRect, 0,0);
            
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);

            
            % Previous function DID modify backSource and objSource.
            % Recenter backSource to prevent too much sliding of the texture.
            % objSource has to be reinitialize so that all 3 sequences will
            % have the same phase.
            backSource = mod(backSource.*[1 0 1 0], 2*barsWidth)+backSourceOri.*[1 1 1 1];
        
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end

catch ME
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    disp(ME)
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end

function NaturalStim_xSF(varargin)

    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect objSource pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    if isempty(pdStim)
        pdStim=1;
    end

    p=ParseInput(varargin{:});

    debugging = p.Results.debugging;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;      % Here obj Size and Center define
    objSizeV = p.Results.objSizeV;      % a rectangle and in each corner of the rectangle
    objCenterXY = p.Results.objCenterXY;    % the 4 flys will be positioned, each one
    dotRadia = p.Results.dotRadia;      % has radia dotRadia
    barsWidth = p.Results.barsWidth;
    backContrast = p.Results.backContrast;
    backSeed = p.Results.backSeed;
    backJitterPeriod = p.Results.backJitterPeriod;      % for random jittering
    repeatBackSeq = p.Results.repeatBackSeq;
    waitframes = p.Results.waitframes;


% 
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Both object and back will be a grating of a given spatial frequency.
% obj will have a low contrast and back will have a higer one.
% Either back and object follow the same random jitter
% or object alone jitters and back stays still.
% The 'randomly' jittering sequences are compossed of -1, 0, 1 pixel jumps
% per frame with equal probability
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


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

try
    InitScreen(debugging);
    
    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;

    % make background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));

    backTex = Screen('MakeTexture', screen.w, bars);
    clear bars
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = 5*SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    objSource = SetRect(objSizeH/2, 0,3/2*objSizeH,1);
    backSourceOri = backSource;
    objSourceOri = objSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % Define the object Positions
        % the square defining a circle
    flyA = SetRect(0,0,2*dotRadia, 2*dotRadia);
    flyA = CenterRect(flyA, screen.rect);
    flyRect = OffsetRect(flyA, objSizeH/2, objSizeV/2);
    flyRect(2,:) = OffsetRect(flyA, objSizeH/2, -objSizeV/2);
    flyRect(3,:) = OffsetRect(flyA, -objSizeH/2, -objSizeV/2);
    flyRect(4,:) = OffsetRect(flyA, -objSizeH/2, objSizeV/2);
    
    
    framesPerSec = 60/waitframes;
    
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);
    
    % make the jitter sequence
    S1 = RandStream('mcg16807', 'Seed',backSeed);
    jitterSeq = randi(S1, 3, 1, framesN)-2;
    jitterSeq(1, framesN) = barsWidth;

    % Animationloop:
    for presentation = 0:presentationsN-1
        shift = [0 0 0 0];
        for frame=1:framesN
            shift = shift + jitterSeq(frame)*[1 0 1 0];
            object = mod(presentation, 4)+1;
%            angle = double(mod(presentation, 2)*90);
            Screen('DrawTexture', screen.w, backTex, backSource-shift, backRect, 0,0);
%            Screen('FillRect', screen.w, screen.gray, objRect+shift);
            Screen('FillOval', screen.w, screen.black, flyRect(object, :)+shift);
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);

            
            % Previous function DID modify backSource and objSource.
            % Recenter backSource to prevent too much sliding of the texture.
            % objSource has to be reinitialize so that all 3 sequences will
            % have the same phase.
            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
            objSource = objSourceOri;
        
            if (KbCheck)
                break
            end
        end
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

function OMS_identifier_LD(varargin)
% Wrapper to call JitterBackTex_JitterObjTex
%
% Divide the screen in object and background.
% Object will be a given texture changing phases every so often.
% Back will be a grating of a giving contrast and spatial frequency
% that reverses periodically at backReverseFreq.

CreateStimuliLogStart()
global vbl screen pd pdStim
if isempty(vbl)
    vbl=0;
end
if isempty(pdStim)
    pdStim=0;
end

p=ParseInput(varargin{:});

backContrast = p.Results.backContrast;
backReverseFreq = .5;
barsWidth = p.Results.barsWidth;

presentationLength = p.Results.presentationLength;
stimSize = p.Results.stimSize;
debugging = p.Results.debugging;
waitframes = p.Results.waitframes;

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    centerX = screen.rect(3)/2;
    centerY = screen.rect(4)/2;
    
    % make the background texture
    x= 1:stimSize+1;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the back source rectangle
    backSource = SetRect(0,0,stimSize,1);
    backSourceOri = backSource;

    % define the obj rect. Center of the rect is in the upper left corner of the array
    objRect = SetRect(0, 0, 64, 64);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, -54, -54);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % make the jitterSeq corresponding to saccades
    framesPerSec = 60;
    framesN = uint32(presentationLength*60);
    backSeq = zeros(1, framesN);
    ForJumps = 1:framesPerSec/backReverseFreq/waitframes:framesN;
    BackJumps = framesPerSec/backReverseFreq/waitframes/2+1:framesPerSec/backReverseFreq/waitframes:framesN;
    backSeq(ForJumps) = barsWidth;
    backSeq(BackJumps) = -barsWidth;
    
    % make the objectSeq
    objSeq = backSeq(1,:);
        
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.

    frame = 0;
    
    % Animationloop:
    for i=0:16        % i=0 Global Motion, i=1:16 DIfferential

        % Define the obj source rectangle
        objSource = [objRect(1)-centerX+stimSize/2 0 objRect(3)-centerX+stimSize/2 1];
        %OffsetRect(objRect, -centerX, 0);
        
        while (frame < framesN) & ~KbCheck %#ok<AND2>
            % Background Drawing
            % ---------- -------
            backSource = backSource + backSeq(frame+1)*[1 0 1 0];
            
            Screen('DrawTexture', screen.w, backTex, backSource, backRect, 0,0);
            
           
            % Object Drawing
            % --------------
            if (i>0)
                objSource = objSource + objSeq(frame+1)*[1 0 1 0];
                
                %        Screen('DrawTexture', screen.w, objTex, objSource + objShiftRect, objRect, 0,0);
                Screen('DrawTexture', screen.w, backTex, objSource, objRect, 0,0);
            end
            
            % Photodiode box
            % --------------
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
            frame = frame + waitframes;
        end
        frame = 0;

        backSource = backSourceOri;

        if (i==0)
            Offset = framesPerSec/backReverseFreq/waitframes/4;
            backSeq = circshift(backSeq, [0 Offset]);
        elseif (mod(i,4)==0)
            objRect = OffsetRect(objRect, -96, 32);
        else
            objRect = OffsetRect(objRect, 32, 0);
        end
        
        if KbCheck
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



function RF_xSx(varargin)
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
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backSeed = p.Results.backSeed;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    checkersN = p.Results.checkersN;
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
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backReverseFreq*framesPerSec);
    
    % make the Saccading like background sequence
    jitterSeq(1,:)=zeros(1, backJumpsPerPeriod);
    jitterSeq(1,0*backJumpsPerPeriod/2+1)=   barsWidth;
    jitterSeq(1,1*backJumpsPerPeriod/2+1)=  -barsWidth;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*60);
    rand('seed',objSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        
        JitteringBackTex_RFObj(jitterSeq, checkersN, ...
            waitframes, framesN, objContrast, backTex)


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
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end
function RF_xxF(varargin)
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
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backFramesN = round(backJitterPeriod*framesPerSec);

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
            
    framesN = uint32(presentationLength*60);

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
function StableObject2_xSx(varargin)
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
backReverseFreq = p.Results.backReverseFreq;

stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;
presentationLength = p.Results.presentationLength;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % make the object textures
    bars = 255*[0 0 1/3 1/3 2/3 2/3 1 1]';
    for i=1:8
        objTex(i) = Screen('MakeTexture', screen.w, bars);
        bars = circshift(bars,1);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;

    % Define the obj source rectangle
    objSource = SetRect(0,0, 1, 8);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterSeq corresponding to saccades
    jumpsPerPeriod = 60/backReverseFreq;
    backSeq = zeros(1, jumpsPerPeriod);
    backSeq(1) = barsWidth;
    backSeq(jumpsPerPeriod/2+1) = -barsWidth;
    
    % make the objectSeq
    objSeq = zeros(1, jumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);

    % Animationloop:
    for presentation = 0:presentationsN-1
        phase = mod(presentation ,8)+1;
        
%backSeq(1:10)
        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex(phase))

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


function StableObject2_Sxx(varargin)
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
backReverseFreq = p.Results.backReverseFreq;

stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;
presentationLength = p.Results.presentationLength;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % make the object textures
    bars = 255*[0 0 1/3 1/3 2/3 2/3 1 1]';
    objTex = ones(1,8);
    for i=1:8
        objTex(i) = Screen('MakeTexture', screen.w, bars);
        bars = circshift(bars,1);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;

    % Define the obj source rectangle
    objSource = SetRect(0,0, 1, 8);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % make the jitterSeq corresponding to saccades
    jumpsPerPeriod = 60/backReverseFreq;
    backSeq = zeros(1, jumpsPerPeriod);
    
    % make the objectSeq
    objSeq = zeros(1, jumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);

    % Animationloop:
    for presentation = 0:presentationsN-1
        phase = mod(presentation ,8)+1;
        
        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex(phase))

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


function StableObject2_xSx(varargin)
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
backReverseFreq = p.Results.backReverseFreq;

stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;
presentationLength = p.Results.presentationLength;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % make the object textures
    bars = 255*[0 0 1/3 1/3 2/3 2/3 1 1]';
    objTex = ones(1,8);
    for i=1:8
        objTex(i) = Screen('MakeTexture', screen.w, bars);
        bars = circshift(bars,1);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;

    % Define the obj source rectangle
    objSource = SetRect(0,0, 1, 8);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % make the jitterSeq corresponding to saccades
    jumpsPerPeriod = 60/backReverseFreq;
    backSeq = zeros(1, jumpsPerPeriod);
    backSeq(1) = barsWidth;
    backSeq(jumpsPerPeriod/2+1) = -barsWidth;
    
    % make the objectSeq
    objSeq = zeros(1, jumpsPerPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);

    % Animationloop:
    for presentation = 0:presentationsN-1
        phase = mod(presentation ,8)+1;
        
        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex(phase))

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


function StableObject2_xxF(varargin)
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
backSeed = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;

stimSize = p.Results.stimSize;
movieDurationSecs = p.Results.movieDurationSecs;
presentationLength = p.Results.presentationLength;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:2*stimSize;
    bars = ceil(mod(floor(x/barsWidth),2)*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast));
    backTex = Screen('MakeTexture', screen.w, bars);

    % make the object textures
    bars = 255*[0 0 1/3 1/3 2/3 2/3 1 1]';
    objTex = ones(1,8);
    for i=1:8
        objTex(i) = Screen('MakeTexture', screen.w, bars);
        bars = circshift(bars,1);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;

    % Define the obj source rectangle
    objSource = SetRect(0,0, 1, 8);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % make the jitterSeq corresponding to FEM
    framesPerSec = 60/waitframes;
    S1 = RandStream('mcg16807', 'Seed',backSeed);
    backSeq = randi(S1, 3, 1, framesPerSec*backJitterPeriod)-2;

    % make the objectSeq
    objSeq = zeros(1, framesPerSec*backJitterPeriod);
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    framesN = uint32(presentationLength*60);

    % Animationloop:
    for presentation = 0:presentationsN-1
        phase = mod(presentation ,8)+1;
        
        JitterBackTex_JitterObjTex(backSeq, objSeq, ...
            waitframes, framesN, backTex, objTex(phase), 2*barsWidth, ...
            backSourceOri)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


function StableObject_SSF(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~5-10 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that either is still, reverses periodically at backReverseFreq of follows
% random jitter.
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be with periodic background and last N obj
% will be with still background.

CreateStimuliLogStart()
global vbl screen backRect backSource objRect pd pdStim
if isempty(vbl)
    vbl=0;
end
if isempty(pdStim)
    pdStim=0;
end

p=ParseInput(varargin{:});

objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed  = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
backReverseFreq = p.Results.backReverseFreq;
repeatBackSeq = p.Results.repeatBackSeq;

stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

objIntensities = (1:4)*64;
objIntensities = objIntensities - mean(objIntensities) + 127;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
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
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterSeq corresponding to still, saccades and FEM (the one
    % corresponding to FEM will only be used if repeatBackSeq==1)
    jumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    saccadeFrames = 1:framesPerSec/backReverseFreq/2:jumpsPerPeriod;
    jitterSeq(1:2,:) = zeros(2, jumpsPerPeriod);
    jitterSeq(2,saccadeFrames) = barsWidth;
    rand('seed', backSeed);
    jitterSeq(3,:) = floor(rand(1, jumpsPerPeriod)*3)-1;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    stimSeq = randperm(presentationsN);
    intensitiesN = size(objIntensities,2);
    stimSeq = mod(stimSeq, 3*intensitiesN);     % make stimSeq between 0 and 3*intensitiesN-1

    objSeq = mod(stimSeq, intensitiesN)+1;     % make objSeq between 1 and 3*intensitiesN
    backStimSeq = floor(stimSeq/intensitiesN)+1;
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    framesN = uint32(presentationLength*60);
    
    rand('seed', backSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        objColor = objIntensities(objSeq(presentation));
        backStim = backStimSeq(presentation);
        if (backStim == 3 && ~repeatBackSeq)
            backSeq = floor(rand(1, jumpsPerPeriod)*3)-1;
        else
            backSeq = jitterSeq(backStim, :);
        end
%backSeq(1:10)
        JitteringBackTex_UniformFieldObj(backSeq, objColor, ...
            waitframes, framesN, backTex)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


function StableObject_SSx(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~5-10 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that either is still or reverses periodically at 2Hz 
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be with periodic background and last N obj
% will be with still background.

CreateStimuliLogStart()
global vbl screen backRect backSource objRect pd pdStim
if isempty(vbl)
    vbl=0;
end

p=ParseInput(varargin{:});

objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
pdStim = p.Results.pdStim;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

objIntensities = (1:4)*64;
objIntensities = objIntensities - mean(objIntensities) + 127;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
try
    InitScreen(debugging);
    
    % make the background texture
    x= 1:stimSize;
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

    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,1);
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterN random sequences
    jumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    jitterSeq(1:2,:) = zeros(2, jumpsPerPeriod);
    jitterSeq(2,1) = barsWidth/2;
    jitterSeq(2, jumpsPerPeriod/2+1) = -barsWidth/2;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    objSeq = randperm(presentationsN);
    intensitiesN = size(objIntensities,2);
    objSeq = mod(objSeq, intensitiesN*3);     % make objSeq between 0 and 3*intensitiesN-1
    objSeq = mod(objSeq, intensitiesN*2)+1;     % make objSeq between 1 and 2*intensitiesN but
                                                        % first half has
                                                        % doulbe
                                                        % probability
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl = Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs+RFlength), ' secs']);
    framesN = uint32(presentationLength*60);
    
    % Animationloop:
    for presentation = 1:presentationsN
        stim = objSeq(presentation);
        objColor = objIntensities(mod(stim, intensitiesN)+1);
        if (stim>intensitiesN)
            % still background
            backSeq = jitterSeq(1,:);
        else
            backSeq = jitterSeq(2,:);
        end

        
        JitteringBackTex_UniformFieldObj(backSeq, objColor, ...
            waitframes, framesN, backTex)
        

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


function StableObject_SxF(varargin)

% debugging     = 0 or 1
% stimSize      = 600    in pixels
% objSizeH/V    = 16*12  in pixels (16 = 100um)
% objCenterXY   = [0 0] for centered object. Is in pixels
% barsWidth     = in pixels, each bar. Period is 2*barsWidth
% backContrast  = between 0 and  1
% objIntensities = 1D array of numbers each between 0 and 255;
% vbl           = time of last flip, 0 if none happened yet
% backJitterPeriod  = number of seconds the back sequence has to jitter around
% presentationLength    = number of seconds for each presentation
% waitframes    = probably 1 or 2. How often do you want to 'Flip'?
% movieDurationSecs     = Approximate length of the experiment, will be changed in the code
% seed
% varargin      = {screen}


%
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~11 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that either is still or random Jittering 
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be for jittering background and last N obj
% will be with still background.
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    if isempty(vbl)
        vbl=0;
    end
    if isempty(pdStim)
        pdStim=1;
    end
    LoadHelperFunctions();

    p=ParseInput(varargin{:});

    %objContrast = p.Results.objContrast;
    %objJitterPeriod = p.Results.objJitterPeriod;
    objSeed = p.Results.objSeed;
    stimSize = p.Results.stimSize;
    objSizeH = p.Results.objSizeH;
    objSizeV = p.Results.objSizeV;
    objCenterXY = p.Results.objCenterXY;
    backSeed = p.Results.backSeed;
    backContrast = p.Results.backContrast;
    backJitterPeriod = p.Results.backJitterPeriod;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    objIntensities = (1:4)*64;
    objIntensities = objIntensities - mean(objIntensities) + 127;

try
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = presentationLength* ...
        floor(movieDurationSecs/(presentationLength));


    % Redefine stimSize to have an integer number of bars
    stimSize = ceil(stimSize/barsWidth)*barsWidth;
    
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
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the background Jitter random sequences
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    jitterSeq(1,:) = zeros(1, backJumpsPerPeriod);
    rand('seed', backSeed);
    jitterSeq(2,:) = floor(rand(1, backJumpsPerPeriod)*3)-1;
 %   jitterShift = 0;
 %   jitterShiftPerPeriod = sum(jitterSeq(2,:));
    
    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    objSeq = randperm(presentationsN);
    intensitiesN = size(objIntensities,2);
    objSeq = mod(objSeq, intensitiesN*3);     % make objSeq between 0 and 3*intensitiesN-1
    objSeq = mod(objSeq, intensitiesN*2)+1;     % make objSeq between 1 and 2*intensitiesN but
                                                        % first half has
                                                        % doulbe
                                                        % probability
    % Define some needed variables
    
    framesN = uint32(presentationLength*60);
    
    % Animationloop:
    for presentation = 1:presentationsN

        stim = objSeq(presentation);
        objColor = objIntensities(mod(stim, intensitiesN)+1);
        if (stim>intensitiesN)
            % still background
            backSeq = jitterSeq(1,:);
        else
            backSeq = jitterSeq(2,:);
        end
%backSeq(1:10)        
        JitteringBackTex_UniformFieldObj(backSeq, objColor, ...
            waitframes, framesN, backTex)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


function StableObject_xxF(varargin)
% Wrapper to call JitteringBackTex_UniformFieldObj
%
% Divide the screen in object and background.
% Object will be a uniform field box of a given intensity that will
% change very slowly ~5-10 secs.
% Back will be a grating of a giving contrast and spatial frequency
% that will follow random jitter.
%
% Internally, there are N obj intensities, and I will have a seq of objects
% equal to 2N, first N objs will be with periodic background and last N obj
% will be with still background.

CreateStimuliLogStart()
global vbl screen backRect backSource objRect pd
if isempty(vbl)
    vbl=0;
end

p=ParseInput(varargin{:});

objSeed  = p.Results.objSeed;
objSizeH = p.Results.objSizeH;
objSizeV = p.Results.objSizeV;
objCenterXY = p.Results.objCenterXY;
backSeed  = p.Results.backSeed;
backContrast = p.Results.backContrast;
backJitterPeriod = p.Results.backJitterPeriod;
repeatBackSeq = p.Results.repeatBackSeq;

stimSize = p.Results.stimSize;
presentationLength = p.Results.presentationLength;
movieDurationSecs = p.Results.movieDurationSecs;
debugging = p.Results.debugging;
barsWidth = p.Results.barsWidth;
waitframes = p.Results.waitframes;

objIntensities = (1:4)*64;
objIntensities = objIntensities - mean(objIntensities) + 127;


% Redefine exp time to have an even number of jitters
movieDurationSecs = presentationLength* ...
    floor(movieDurationSecs/(presentationLength));

LoadHelperFunctions();
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
    objRect = SetRect(0,0,objSizeH, objSizeV);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    framesPerSec = 60/waitframes;
    
    % make the jitterSeq corresponding to FEM (will only be used if repeatBackSeq==1)
    jumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    rand('seed', backSeed);
    jitterSeq = floor(rand(1, jumpsPerPeriod)*3)-1;

    % We run at most 'consPresentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);

    % make the random sequence of object intensities to display
    rand('seed', objSeed);
    intensitiesN = size(objIntensities,2);
    objSeq = floor((0:presentationsN-1)/(presentationsN/intensitiesN))+1;
%    objSeq = mod(stimSeq, intensitiesN) + 1;     % make stimSeq between 1 and intensitiesN    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    framesN = uint32(presentationLength*60);
    
    rand('seed', backSeed);

    % Animationloop:
    for presentation = 1:presentationsN
        objColor = objIntensities(objSeq(presentation));
        if (~repeatBackSeq)
            jitterSeq = floor(rand(1, jumpsPerPeriod)*3)-1;
        end
        JitteringBackTex_UniformFieldObj(jitterSeq, objColor, ...
            waitframes, framesN, backTex)

        % Recenter backSource to prevent too much sliding of the texture.
        % Is not perfect and sliding will still take place but will be
        % slower and hopefully will be ok
        backSource = mod(backSource, 2*barsWidth)+backSourceOri;

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


 function UFlickerObj(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd
    if isempty(vbl)
        vbl=0;
    end
    
    p=ParseInput(varargin{:});

    objContrasts = p.Results.objContrast;
    objMeans = p.Results.objMean;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    repeatObjSeq = p.Results.repeatObjSeq;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backSeed = p.Results.backSeed;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    backN = sum(backMode);
    contrastsN = size(objContrasts,2);

    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = contrastsN*backN*presentationLength* ...
        floor(movieDurationSecs/(contrastsN*backN*presentationLength));

    LoadHelperFunctions();

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    if (presentationLength < objJitterPeriod)
        objJitterPeriod = presentationLength;
    end
    if (size(objMeans,2) < size(objRect,1))
        objMeans = ones(1, size(objRect,1))*objMeans;
    end
    
try
    InitScreen(debugging);
    
    % make the background texture
    [x, y]  = meshgrid(1:stimSize+barsWidth);
    x = mod(floor(x/barsWidth),2);
    y = mod(floor(y/barsWidth),2);
    bars = x.*y + ~x.*~y;
    bars = bars*2*screen.gray*backContrast...
        + screen.gray*(1-backContrast);
    backTex = Screen('MakeTexture', screen.w, bars);

    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,stimSize);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = 1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of contrasts. If size(objContrasts,1)==1, then 
    % all checkers use the same contrast at any given point in time,
    % otherwise contrasts are randomly picked.
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    contrastSeq = ones(size(objContrasts,1), presentationsN);
    for i=1:size(objContrasts,1)
        contrastSeq(i,:) = randperm(S1, presentationsN);
        contrastSeq(i,:) = objContrasts(i,mod(contrastSeq(i,:), contrastsN)+1);
    end
    clear S1;
    
    % random seeds for the object sequence intensities, one per checker
    checkersN = size(objRect,1);
    S{checkersN} = {};
    for i=1:checkersN
        S{i} = RandStream('mcg16807', 'Seed',objSeed + i -1);
    end
    
    % for efficiency preallocate objSeq
    objSeq = ones(checkersN, objJumpsPerPeriod);
    normDistribution = ones(checkersN, objJumpsPerPeriod);

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % get a random order of all selected backgrounds
        backOrder = randperm(backStream, 4);
%backOrder
%backOrderArray(presentation, :)=backOrder;
        for back=1:4
            if (back==1)
                % Sets the objSeq that will be used in the next backN presentations
                if (~repeatObjSeq || presentation == 1)
                    for checker=1:checkersN
                        %                   objSeq(checker,:) = uint8(randn(S{checker}, 1, objJumpsPerPeriod)*screen.gray*checkContrast+screen.gray);
                        normDistribution(checker,:) = randn(S{checker}, 1, objJumpsPerPeriod);
                    end
                end
                % Do we use the same contrast for all checkers?
                if (size(objContrasts,1)>1)
                    checkContrast = contrastSeq(:, presentation);
                else
                    checkContrast(1:checkersN) = contrastSeq(1, presentation);
                end
                % convert the normDistribution to intensity values taken
                % the contrast and mean into account.
                for i=1:checkersN
                    if (checkContrast(i)==1)
                        objSeq(i,:) = uint8(normDistribution(i,:)>0)*255;
                    else
                        objSeq(i,:) = uint8(normDistribution(i,:)*checkContrast(i)*objMeans(i) + objMeans(i));
                    end
                end
                
            end
            
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
%            [presentation backOrder(back)];
%            [backOrder(back) backSeq(1:10)]
%normDistribution(:,1:10)
%objSeq(:, 1:10)
%[checkContrast backOrder(back)]
            JitteringBackTex_UniformFieldObjTest(backSeq, objSeq, ...
                waitframes, framesN, backTex, backAngle)
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



 function UFlickerObj(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd
    if isempty(vbl)
        vbl=0;
    end
    
    p=ParseInput(varargin{:});

    objContrasts = p.Results.objContrast;
    objMeans = p.Results.objMean;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    repeatObjSeq = p.Results.repeatObjSeq;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backTex = p.Results.backTexture;
    backSeed = p.Results.backSeed;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    backN = sum(backMode);
    contrastsN = size(objContrasts,2);

    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = contrastsN*backN*presentationLength* ...
        floor(movieDurationSecs/(contrastsN*backN*presentationLength));

    LoadHelperFunctions();

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    if (presentationLength < objJitterPeriod)
        objJitterPeriod = presentationLength;
    end
    if (size(objMeans,2) < size(objRect,1))
        objMeans = ones(1, size(objRect,1))*objMeans;
    end
    
try
    InitScreen(debugging);
    
    % make the background texture
    if (isempty(backTex))
        backTex = GetBarsTex(stimSize, barsWidth, screen, backContrast);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = 1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of contrasts. If size(objContrasts,1)==1, then 
    % all checkers use the same contrast at any given point in time,
    % otherwise contrasts are randomly picked.
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    contrastSeq = ones(size(objContrasts,1), presentationsN);
    for i=1:size(objContrasts,1)
        contrastSeq(i,:) = randperm(S1, presentationsN);
        contrastSeq(i,:) = objContrasts(i,mod(contrastSeq(i,:), contrastsN)+1);
    end
    clear S1;
    
    % random seeds for the object sequence intensities, one per checker
    checkersN = size(objRect,1);
    S{checkersN} = {};
    for i=1:checkersN
        S{i} = RandStream('mcg16807', 'Seed',objSeed + i -1);
    end
    
    % for efficiency preallocate objSeq
    objSeq = ones(checkersN, objJumpsPerPeriod);
    normDistribution = ones(checkersN, objJumpsPerPeriod);

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % get a random order of all selected backgrounds
        backOrder = randperm(backStream, 4);
%backOrder
%backOrderArray(presentation, :)=backOrder;
        for back=1:4
            if (back==1)
                % Sets the objSeq that will be used in the next backN presentations
                if (~repeatObjSeq || presentation == 1)
                    for checker=1:checkersN
                        %                   objSeq(checker,:) = uint8(randn(S{checker}, 1, objJumpsPerPeriod)*screen.gray*checkContrast+screen.gray);
                        normDistribution(checker,:) = randn(S{checker}, 1, objJumpsPerPeriod);
                    end
                end
                % Do we use the same contrast for all checkers?
                if (size(objContrasts,1)>1)
                    checkContrast = contrastSeq(:, presentation);
                else
                    checkContrast(1:checkersN) = contrastSeq(1, presentation);
                end
                % convert the normDistribution to intensity values taken
                % the contrast and mean into account.
                for i=1:checkersN
                    if (checkContrast(i)==1)
                        objSeq(i,:) = uint8(normDistribution(i,:)>0)*255;
                    else
                        objSeq(i,:) = uint8(normDistribution(i,:)*checkContrast(i)*objMeans(i) + objMeans(i));
                    end
                end
                
            end
            
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
%            [presentation backOrder(back)];
%            [backOrder(back) backSeq(1:10)]
%normDistribution(:,1:10)
%objSeq(:, 1:10)
%[checkContrast backOrder(back)]
            JitteringBackTex_UniformFieldObjTest(backSeq, objSeq, ...
                waitframes, framesN, backTex, backAngle)
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



function UFlickerObj2(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done

    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd
    if isempty(vbl)
        vbl=0;
    end
    
    p=ParseInput(varargin{:});

    objContrasts = p.Results.objContrast;
    objMeans = p.Results.objMean;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    repeatObjSeq = p.Results.repeatObjSeq;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backSeed = p.Results.backSeed;
    backTex = p.Results.backTexture;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    backN = sum(backMode);
    contrastsN = size(objContrasts,2);

    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = contrastsN*backN*presentationLength* ...
        floor(movieDurationSecs/(contrastsN*backN*presentationLength));

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    if (presentationLength < objJitterPeriod)
        objJitterPeriod = presentationLength;
    end
    if (size(objMeans,2) < size(objRect,1))
        objMeans = ones(1, size(objRect,1))*objMeans;
    end
    
try
    InitScreen(debugging);
    
    % make the background texture
    if (isempty(backTex))
        backTex = GetCheckersTex(stimSize, barsWidth, screen, backContrast);
    end
    
    % Define the background Destination Rectangle
    backRect = SetRect(0,0,stimSize, stimSize);
    backRect = CenterRect(backRect, screen.rect);
    
    % Define the source rectangles
    backSource = SetRect(0,0,stimSize,stimSize);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = 1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of contrasts. If size(objContrasts,1)==1, then 
    % all checkers use the same contrast at any given point in time,
    % otherwise contrasts are randomly picked.
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    contrastSeq = ones(size(objContrasts,1), presentationsN);
    for i=1:size(objContrasts,1)
        contrastSeq(i,:) = randperm(S1, presentationsN);
        contrastSeq(i,:) = objContrasts(i,mod(contrastSeq(i,:), contrastsN)+1);
    end
    clear S1;
    
    % random seeds for the object sequence intensities, one per checker
    checkersN = size(objRect,1);
    S{checkersN} = {};
    for i=1:checkersN
        S{i} = RandStream('mcg16807', 'Seed',objSeed + i -1);
    end
    
    % for efficiency preallocate objSeq
    objSeq = ones(checkersN, objJumpsPerPeriod);
    normDistribution = ones(checkersN, objJumpsPerPeriod);

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % get a random order of all selected backgrounds
        backOrder = randperm(backStream, 4);
%backOrder
%backOrderArray(presentation, :)=backOrder;
        for back=1:4
            if (back==1)
                % Sets the objSeq that will be used in the next backN presentations
                if (~repeatObjSeq || presentation == 1)
                    for checker=1:checkersN
                        %                   objSeq(checker,:) = uint8(randn(S{checker}, 1, objJumpsPerPeriod)*screen.gray*checkContrast+screen.gray);
                        normDistribution(checker,:) = randn(S{checker}, 1, objJumpsPerPeriod);
                    end
                end
                % Do we use the same contrast for all checkers?
                if (size(objContrasts,1)>1)
                    checkContrast = contrastSeq(:, presentation);
                else
                    checkContrast(1:checkersN) = contrastSeq(1, presentation);
                end
                % convert the normDistribution to intensity values taken
                % the contrast and mean into account.
                for i=1:checkersN
                    if (checkContrast(i)==1)
                        objSeq(i,:) = uint8(normDistribution(i,:)>0)*255;
                    else
                        objSeq(i,:) = uint8(normDistribution(i,:)*checkContrast(i)*objMeans(i) + objMeans(i));
                    end
                end
                
            end
            
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
%            [presentation backOrder(back)];
%            [backOrder(back) backSeq(1:10)]
%normDistribution(:,1:10)
%objSeq(:, 1:10)
%[checkContrast backOrder(back)]
            JitteringBackTex_UniformFieldObj(backSeq, objSeq, ...
                waitframes, framesN, backTex, backAngle)
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri;
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



 function UFlickerObj(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done
    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd
    if isempty(vbl)
        vbl=0;
    end
    
    p=ParseInput(varargin{:});

    objContrasts = p.Results.objContrast;
    objMeans = p.Results.objMean;
    objJitterPeriod = p.Results.objJitterPeriod;
    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    repeatObjSeq = p.Results.repeatObjSeq;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterPeriod = p.Results.backJitterPeriod;
    backAngle = p.Results.angle;
    backSeed = p.Results.backSeed;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    debugging = p.Results.debugging;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    backN = sum(backMode);
    contrastsN = size(objContrasts,2);

    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = contrastsN*backN*presentationLength* ...
        floor(movieDurationSecs/(contrastsN*backN*presentationLength));

    LoadHelperFunctions();

    % if by any reason backJitterPeriod or objjitterPeriod are bigger than
    % presentationLength is because I forgot to input the right parameters,
    % fix it
    if (presentationLength < backJitterPeriod)
        backJitterPeriod = presentationLength;
    end
    if (presentationLength < objJitterPeriod)
        objJitterPeriod = presentationLength;
    end
    if (size(objMeans,2) < size(objRect,1))
        objMeans = ones(1, size(objRect,1))*objMeans;
    end
    
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
    
    % Define the source rectangles
    backSource = SetRect(stimSize/2,0,3/2*stimSize,1);
    backSourceOri = backSource;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    framesPerSec = 60/waitframes;
    backJumpsPerPeriod = round(backJitterPeriod*framesPerSec);
    objJumpsPerPeriod = round(objJitterPeriod*framesPerSec);

    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, backJumpsPerPeriod);
    forwardJumps = 1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:backJumpsPerPeriod;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', backSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, backJumpsPerPeriod)-2;
    backStream = RandStream('mcg16807', 'Seed', backSeed);
    clear S1
    
    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength)/backN;
    
    
    framesN = uint32(presentationLength*60);

    % make a random sequence of contrasts. If size(objContrasts,1)==1, then 
    % all checkers use the same contrast at any given point in time,
    % otherwise contrasts are randomly picked.
    S1 = RandStream('mcg16807', 'Seed',objSeed);
    contrastSeq = ones(size(objContrasts,1), presentationsN);
    for i=1:size(objContrasts,1)
        contrastSeq(i,:) = randperm(S1, presentationsN);
        contrastSeq(i,:) = objContrasts(i,mod(contrastSeq(i,:), contrastsN)+1);
    end
    clear S1;
    
    % random seeds for the object sequence intensities, one per checker
    checkersN = size(objRect,1);
    S{checkersN} = {};
    for i=1:checkersN
        S{i} = RandStream('mcg16807', 'Seed',objSeed + i -1);
    end
    
    % for efficiency preallocate objSeq
    objSeq = ones(checkersN, objJumpsPerPeriod);
    normDistribution = ones(checkersN, objJumpsPerPeriod);

    % Animationloop:
    for presentation = 1:presentationsN
        % Background Drawing
        % ------------------

        % get a random order of all selected backgrounds
        backOrder = randperm(backStream, 4);
%backOrderArray(presentation, :)=backOrder;
        for back=1:4
            if (back==1)
                % Sets the objSeq that will be used in the next backN presentations
                if (~repeatObjSeq || presentation == 1)
                    for checker=1:checkersN
                        %                   objSeq(checker,:) = uint8(randn(S{checker}, 1, objJumpsPerPeriod)*screen.gray*checkContrast+screen.gray);
                        normDistribution(checker,:) = randn(S{checker}, 1, objJumpsPerPeriod);
                    end
                end
                if (size(objContrasts,1)>1)
                    checkContrast = contrastSeq(:, presentation);
                else
                    checkContrast(1:checkersN) = contrastSeq(1, presentation);
                end
                for i=1:checkersN
                    if (checkContrast(i)==1)
                        objSeq(i,:) = uint8(normDistribution(i,:)>0)*255;
                    else
                        objSeq(i,:) = uint8(normDistribution(i,:)*checkContrast(i)*objMeans(i) + objMeans(i));
                    end
                end
                
            end
            
            background = backMode(backOrder(back));
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the backStream
                backSeq = randi(backStream, 3, 1, backJumpsPerPeriod)-2;
            else
                backSeq = jitterSeq(backOrder(back),:);
            end
            
%            [presentation backOrder(back)];
%            [backOrder(back) backSeq(1:10)]
%            normDistribution(:,1:10);
%objSeq(:, 1:10)
%[checkContrast backOrder(back)]
            JitteringBackTex_UniformFieldObjTest(backSeq, objSeq, ...
                waitframes, framesN, backTex, backAngle)
            % Previous function DID modify backSource. Recenter it to prevent
            % too much sliding of the texture.
            % Is not perfect and sliding will still take place but will be
            % slower and hopefully will be ok
            backSource = mod(backSource, 2*barsWidth)+backSourceOri.*[1 0 1 0];
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (~debugging)
        CreateStimuliLogWrite(p);
    end
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end



