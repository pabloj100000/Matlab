   function GatingFinder(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % v.contrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % v.objCenterXY, backContrast, backReverseFreq, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    global vbl screen pd
    Add2StimLogList();
    if isempty(vbl)
        vbl=0;
    end

try    
    InitScreen(0);
    Add2StimLogList();

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
    
    objSeed = 1;
    
    [dummy stimSize] = SCREEN_SIZE;
    backContrast = 1;
    
    v.backMode = 1;
    v.meanIntensity = screen.gray;
    v.backAngle = 0;
    v.backSize = 40;
    v.centerMode = 0;
    v.backFreq = 1;
    v.diameter = 12*PIXELS_PER_100_MICRONS;
    v.contrast = .5;
    v.waitframes = 1;
    text = fieldnames(v);
    
    % Redefine the stimSize     to incorporate an integer number of bars
    stimSize = .8*stimSize;%ceil(stimSize*.8 /PIXELS_PER_100_MICRONS)*PIXELS_PER_100_MICRONS;

    
    % make the background texture
    backTex = GetCheckersTex(stimSize/(PIXELS_PER_100_MICRONS/4), 1, backContrast);
%    backTex{6} = GetBarsTex(stimSize(PIXELS_PER_100_MICRONS/4), 1, backContrast);
    
    % Define the background Destination Rectangle
    backRectOri = SetRect(0,0,stimSize, stimSize);
    backRectOri = CenterRect(backRectOri, screen.rect);

    objRect = SetRect(0,0,v.diameter, v.diameter);
    objRect = CenterRect(objRect, screen.rect);
    [v.objCenter(1), v.objCenter(2)] = RectCenter(objRect);

    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
            
    %Restart a random stream per checker per contrast, all with the same
    %seed
    randStream = RandStream('mcg16807', 'Seed', objSeed);
    

    exitFlag = 0;
       
    selection = 1;
    %      Animationloop: 
    ListenChar(2);
     while 1         
        % preallocate objSeq for speed
        framesN = uint32(screen.rate/v.backFreq);
        if framesN>2*screen.rate       % if v_backFreq=0
            framesN=screen.rate;
        end
        objSeq = zeros(1, framesN);
        
        if (v.centerMode)
            objSeq = uint8(randn(randStream, 1, framesN)*v.meanIntensity*v.contrast+v.meanIntensity);
        else
            objSeq(1:floor(framesN/2)-1) = v.meanIntensity*(1-v.contrast);
            objSeq(floor(framesN/2):end) = v.meanIntensity*(1+v.contrast);
        end
        
        if (v.contrast==1)
            % Convert noise to binary
            objSeq = (objSeq>v.meanIntensity)*255;
        end

        backSource = SetRect(0,0,v.backSize,v.backSize);

        for frame=0:v.waitframes:framesN-1
            Screen('FillRect', screen.w, screen.gray, [1 1 300 30]);
            Screen(screen.w,'TextSize', 18);
            Screen(screen.w, 'DrawText', [text{selection}, ' = ', num2str(v.(text{selection}))],1,1, screen.black );
            
            if frame==0
                backRect = backRectOri;
            elseif frame==round(screen.rate/v.backFreq/2)
                backRect = backRectOri+(stimSize/v.backSize)*[1 0 1 0];
            end
            
            % display the background
            Screen('DrawTexture', screen.w, backTex{1}, backSource, backRect, v.backAngle,0)
            
            % display checker
            Screen('FillOval', screen.w, objSeq(1, frame+1), objRect)
            
            % Photodiode box
            % --------------
            Screen('FillOval', screen.w, objSeq(1, frame+1), pd)
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (v.waitframes - 0.5) * screen.ifi);
            
            
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if (keyIsDown)
                if keyCode(ESCAPE)
                    exitFlag = 1;
                    break
                elseif keyCode(SPACEBAR)
                    % change mode
                    pause(0.2);
                    selection = mod(selection, length(text)) + 1;
                    if (strcmp(text{selection}, 'barsWidth'))
                        selection = selection+1;
                    end
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

            end
        
%            backSource = mod(backSource, 2*barsWidth)+backSourceOri;
        end
        if exitFlag
            break;
        end
    end
    ListenChar();
    FinishExperiment();
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    ListenChar();
    CleanAfterError();
    rethrow(exception);
    psychrethrow(psychlasterror);
end %try..catch..
end

function v = ChangeSelection(selection, v, UpDown, delayFlag)
    text = fieldnames(v);

    switch text{selection}
        case 'contrast'
            v.contrast = v.contrast + .01*UpDown;
            if v.contrast < 0
                v.contrast = 0;
            elseif v.contrast > 1
                v.contrast = 1;
            end
        case 'diameter'   % change v.diameter
            v.diameter = v.diameter + UpDown * 1;
        case 'objCenter'   % change v.objCenter
            % delayFlag is 1 if pressed Up/Down arrows and is 0 if
            % left/right arrows
            if (delayFlag)
                v.objCenter = v.objCenter + [0 1]*UpDown;
            else
                v.objCenter = v.objCenter + [1 0]*UpDown;
            end
        case 'backMode'   % change v.backMode
            if (v.backFreq)
                   v.backMode = 0;
                v.backFreq = 0;
            else
                v.backFreq = 1;
                v.backMode = 1;
            end
        case 'meanIntensity'  % hange v.meanIntensity
            v.meanIntensity = v.meanIntensity + UpDown * 1;
            if (v.meanIntensity < 0)
                v.meanIntensity = 0;
            elseif (v.meanIntensity > 255)
                v.meanIntensity = 255;
            end
        case 'backAngle'  % hange v.backAngle
            v.backAngle = v.backAngle + UpDown * 1;
            if (mod(v.backAngle, 360      )==0 )
                v.backAngle = 0;
            end
        case 'backSize'  % back tex
            v.backSize = v.backSize + UpDown/10;
            [w h] = SCREEN_SIZE;
            if v.backSize > .8*h/(PIXELS_PER_100_MICRONS/4)
                v.backSize = .8*h/(PIXELS_PER_100_MICRONS/4);
            elseif v.backSize <0
                v.backSize = 1;
            end
        case 'centerMode'
            v.centerMode=mod(v.centerMode+1,2);
        case 'backFreq'
            v.backFreq = v.backFreq + UpDown*.1;
            if v.backFreq == 0
                v.backMode = 0;
            elseif v.backFreq <0
                v.backFreq = 0;
            else
                v.backMode = 1;
            end
        case 'waitframes'
            v.waitframes = v.waitframes + UpDown;
            if v.waitframes <1
                v.waitframes = 1;
            end
    end
    if (delayFlag && selection~=3)
        pause(0.5);
    end
end

