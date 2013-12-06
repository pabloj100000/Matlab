function  TemporalNaturalFlicker(objSeq, backReverseFreq, ...
    waitframes, varargin)
    global screen

    p=ParseInput(varargin{:});

    objRect = p.Results.objRect;

    backContrast = p.Results.backContrast;
    backAngle = p.Results.angle;
    backTex = p.Results.backTexture;
    backPhase = p.Results.backPhase;
    
    barsWidth = p.Results.barsWidth;
    stimSize = p.Results.stimSize;
    almostBlack = p.Results.almostBlack;

try
    InitScreen(0);
    Add2StimLogList();
   
    % make stimSize a round number of barsWidth
    stimSize = barsWidth*floor(stimSize/barsWidth);
    
    % make the background texture
    if (isempty(backTex))
        clearBackTexFlag = 1;
        backTex = GetCheckersTex(stimSize/barsWidth, 1, backContrast);
    else
        clearBackTexFlag = 0;
    end
    
    % Define the background Destination Rectangle
    backSource = SetRect(0, 0, stimSize/barsWidth, stimSize/barsWidth);
    backDest1 = SetRect(0,0,stimSize, stimSize);
    backDest1 = CenterRect(backDest1, screen.rect-barsWidth*[1/2 1/2 1/2 1/2]);
    backDest2 = CenterRect(backDest1, screen.rect+barsWidth*[1/2 -1/2 1/2 -1/2]);
    
    if backPhase==1
        tempDest = backDest2;
        backDest2 = backDest1;
        backDest1 = tempDest;
        clear tempDest
    end
    
    % Define the PD box
    pd = DefinePD();

    updateRate = screen.rate/waitframes;
    updateTime = 1/updateRate-1/screen.rate/2;
    backFrames = fix(updateRate/backReverseFreq/2);
    framesN = length(objSeq);
        
    for frame=0:framesN-1
        if (mod(frame, 2*backFrames)==0 || backFrames==inf)
            % reverse background
            backDest = backDest1;
        elseif (mod(frame, backFrames)==0)
            backDest = backDest2;
        end
        
        Screen('FillRect', screen.w, screen.gray, screen.rect);
        
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
        
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        %        Screen('FillRect', screen.w, [0 0 0 0], backDest);
        Screen('FillRect', screen.w, [0 0 0 0], screen.rect);
        
        % Fill circular 'dstRect' region with an alpha value of 255:
        Screen('FillOval', screen.w, [0 0 0 255], backDest);
        
        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        
        % Draw 2nd grating texture, but only inside alpha == 255 circular
        % aperture, and at an angle of 90 degrees:
        Screen('DrawTexture', screen.w, backTex{1}, backSource, backDest, backAngle,0)
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        % Object Drawing
        % --------------
        color = objSeq(frame+1);
        % test(frame+1+(presentation-1)*presentationFrames)=color;
        
        Screen('FillRect', screen.w, color, objRect);

        % Photodiode box
        % --------------
        if (frame==0 || mod(frame, backFrames)==0)
            Screen('FillOval', screen.w, screen.white, pd);
        else
            Screen('FillOval', screen.w, color/2+almostBlack, pd);
        end
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime , 1);
        
        if (KbCheck)
            break
        end
        
    end
    
%    SaveBinary(test, 'uint8');
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

function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);

    % Object related
    p.addParamValue('objRect', rect, @(x) size(x,1)==4 || size(x,2)==4);
    
    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('angle', 0, @(x) isnumeric(x));
    p.addParamValue('backPhase', 0, @(x) x==0 || x==1);
    
    % General
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('stimSize', screenY, @(x) x>0);
    p.addParamValue('almostBlack', 30, @(x) x>=0 && x<=255);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

