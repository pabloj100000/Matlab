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

    global vbl screen backRect backSource objRect pd
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
    InitScreen(0);
    Add2StimLogList();
    
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
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    framesPerSec = screen.rate;
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
    
    
    framesN = uint32(presentationLength*screen.rate);

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
                DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)
                
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
    
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end



