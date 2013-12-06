function  TemporalNaturalFlicker2(objSeq, backReverseFreq, ...
    waitframes, varargin)
    % Identical to TemporalNaturalFlicker but incorporates 
    % grayMaskSize
    
    global screen

    p=ParseInput(varargin{:});

    objRect = p.Results.objRect;
    objShape = p.Results.objShape;
    
    backContrast = p.Results.backContrast;
    backAngle = p.Results.angle;
    backTex = p.Results.backTexture;
    backPhase = p.Results.backPhase;
    
    barsWidth = p.Results.barsWidth;
    stimSize = p.Results.stimSize;
    almostBlack = p.Results.almostBlack;
    grayMaskSize = p.Results.grayMaskSize;
    
try
    InitScreen(0);
    Add2StimLogList();
   
    % make stimSize a round number of barsWidth
    checkersN = floor(stimSize/barsWidth);
    stimSize = barsWidth*checkersN;
    
    % make the background texture
    if (isempty(backTex))
        clearBackTexFlag = 1;
        backTex = GetCheckersTex(checkersN+1, 1, backContrast);
    else
        clearBackTexFlag = 0;
    end
    
    % Define the background Destination Rectangle
    backSource1 = SetRect(0, 0, checkersN, checkersN);
    backSource2 = SetRect(1, 0, checkersN+1, checkersN);
    backDest = SetRect(0,0,stimSize, stimSize);
    backDest = CenterRect(backDest, objRect);
    
    grayMaskRect = SetRect(0, 0, grayMaskSize, grayMaskSize);
    grayMaskRect = CenterRect(grayMaskRect, objRect);
    
    if backPhase==1
        tempDest = backSource2;
        backSource2 = backSource1;
        backSource1 = tempDest;
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
            backSource = backSource1;
        elseif (mod(frame, backFrames)==0)
            backSource = backSource2;
        end
        
        % Object Drawing
        % --------------
        color = objSeq(frame+1);

        Screen('FillRect', screen.w, screen.gray, screen.rect);
        
        Screen('DrawTexture', screen.w, backTex{1}, backSource, backDest, backAngle,0)
        
                
        if (objShape)
            Screen('FillOval', screen.w, screen.gray, grayMaskRect);
            Screen('FillOval', screen.w, color, objRect);
        else
            Screen('FillRect', screen.w, screen.gray, grayMaskRect);
            Screen('FillRect', screen.w, color, objRect);
        end
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
    p.addParamValue('objShape', 0, @(x) isnumeric(x));
    
    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('angle', 0, @(x) isnumeric(x));
    p.addParamValue('backPhase', 0, @(x) x==0 || x==1);
    
    % General
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('stimSize', screenY, @(x) x>0);
    p.addParamValue('almostBlack', 30, @(x) x>=0 && x<=255);
    p.addParamValue('grayMaskSize', 30, @(x) x>0);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

