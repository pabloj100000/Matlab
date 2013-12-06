function nextSeed = StableObject(varargin)
    % this proceure will mimic saccade and jitters.
    % The random jitter sequence comes in through 'jitter' which also sets
    % the framesN = length(jitter). At the beginning of every jitter a
    % saccade is simulated by choosing a new texture out of 'textures'.
    % MaskTex defines how opaque or transparent the center is.
    %
    % objMode lets you select between different object modes
    %   mode 0:     center mode is identical to background
    %   mode 1:     center is somewhat transparent/opaque as defined by the
    %               mask that would be used.
    %   mode 2:     center is uniform filed of constant intensity given by
    %               objColor.
global screen pdStim vbl
    
try
        
%    CreateStimuliLogStart();
    p=ParseInput(varargin{:});

    objSeed  = p.Results.objSeed;
    objRect = p.Results.rects;
    
    backMode = logical(p.Results.backMode);
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backTex = p.Results.backTexture;
    
    backSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;

    if (isempty(pdStim))
        pdStim=0;
    end
    
    if (isempty(vbl))
        vbl=0;
    end
    
    InitScreen(0);
    
    % make the background texture if not defined
    if (isempty(backTex))
        backTex = GetCheckersTex(backSize, barsWidth, screen, backContrast);
        clearBackTexFlag = 1;
    else
        clearBackTexFlag = 0;
    end
  
    
    objSize = objRect(3)-objRect(1);
    halfBackSize = backSize/2;
    maskTex = GetMaskTexture(halfBackSize, objSize, screen, [0]);

        
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    

    backgroundsN = sum(backMode);
    presentationsN = floor(movieDurationSecs/presentationLength/backgroundsN);
    framesPerSec = 60/waitframes;
    framesN = presentationLength*framesPerSec;
    
    % make the Still, the reversing and the random jitter background
    jitterSeq(4,:)=zeros(1, framesN);
    forwardJumps = 1:framesPerSec/backReverseFreq:framesN;
    backJumps = framesPerSec/backReverseFreq/2+1:framesPerSec/backReverseFreq:framesN;
    jitterSeq(3,forwardJumps)=   barsWidth;
    jitterSeq(3,backJumps)=   -barsWidth;
    S1 = RandStream('mcg16807', 'Seed', objSeed);
    jitterSeq(1,:)=randi(S1, 3, 1, framesN)-2;
    clear S1
    randBackStream = RandStream('mcg16807', 'Seed', objSeed);
    backOrderStream = RandStream('mcg16807', 'Seed', objSeed);
        
%    destRectOri = [0 0 2*halfImageSize-1 2*halfImageSize-1];
    backRectOri = GetRects(backSize, [screen.rect(3) screen.rect(4)]/2);
    objRect = GetRects(objSize, [screen.rect(3) screen.rect(4)]/2);
    
    % define some constants
    angle = 0;    
    Screen('TextSize', screen.w,12);
    
    for presentation=1:presentationsN
        backRect = backRectOri;
        
        backOrder = randperm(backOrderStream, 4);
        color = 255/3*mod(presentation-1, 4);
        for back=1:4
            background = backMode(backOrder(back));
            % Do we have to skip this background?
            if (background==0)
                continue
            end
            if (backOrder(back)==2)
                % generate the new random jitter out of the objStream
                jitter = randi(randBackStream, 3, 1, framesN)-2;
            else
                jitter = jitterSeq(backOrder(back),:);
            end
            
            for frame = 0:framesN-1    % for every frame
                backRect = backRect + jitter(frame+1)*[1 0 1 0];
                
                % Draw background
                % ---- ----------
                Screen('FillRect', screen.w, screen.gray, screen.rect);
                % Disable alpha-blending, restrict following drawing to alpha channel:
                Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                
                % Clear 'dstRect' region of framebuffers alpha channel to zero:
                Screen('FillRect', screen.w, [0 0 0 0], screen.rect);
                
                % Fill circular 'backRectOri' region with an alpha value of 255:
                Screen('FillOval', screen.w, [0 0 0 255], backRectOri);
                
                % Enable DeSTination alpha blending and reenalbe drawing to all
                % color channels. Following drawing commands will only draw there
                % the alpha value in the framebuffer is greater than zero, ie., in
                % our case, inside the circular 'dst2Rect' aperture where alpha has
                % been set to 255 by our 'FillOval' command:
                Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                
                % Draw texture, but only inside alpha == 255 circular
                % aperture:
                Screen('DrawTexture', screen.w, backTex{1}, [], backRect, angle, 0);

                % Restore alpha blending mode for next draw iteration:
                Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                
                % object Drawing
                % ------ -------
                % Draw 2nd texture
                Screen('FillRect', screen.w, color, objRect);
                
                
                % Photodiode box
                % ---------- ---
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
        if (KbCheck)
            break
        end
    end
    
    if (clearBackTexFlag)
        Screen('Close', backTex{1});
    end
    Screen('Close', maskTex{1});
    
    CreateStimuliLogWrite();

catch
    
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..

end
