function objSeed = TNF_BackContrast(checkers, sizes, maskMode, varargin)
%   center is in screen pixels
%   objSize is in screen pixels
%   USage:  TNF_BackContrast([1;1], 200, 0)
%           TNF_BackContrast[-1;-1], 200, 0)   center of
%           the screen
global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});

    waitframes = p.Results.waitframes;
    objSeed = p.Results.objSeed;
    shape = p.Results.shape;
    presentationLength = p.Results.presentationLength;
    checkersSize = p.Results.checkersSize;
    backContrastN = p.Results.backContrastN;
    backReverseFreq = p.Results.backReverseFreq;
    stimSize = p.Results.stimSize;
    trialsN = p.Results.trialsN;
    repeatCenterFlag = p.Results.repeatCenter;
    objContrast = p.Results.objContrast;
        
    objRects = Checkers2Rects(checkers, sizes);
    % start the stimulus
%    InitScreen(0)
    Add2StimLogList();

    % get the background texture
    stimSize = 2*checkersSize*floor(stimSize/checkersSize/2);
    backContrast = 1./(2.^(0:backContrastN-1));
    contrastN = length(backContrast);
    checkersN = floor(stimSize/checkersSize);
    backTex{contrastN} = 1;
    for i=1:contrastN
        backTex(i) = GetCheckersTex(checkersN+1, 1, backContrast(i));
    end
    
    % I want framesN to have an even number of background reversals
    % 
    backFrames = fix(screen.rate/waitframes/backReverseFreq/2);
    framesN = fix(presentationLength*screen.rate/waitframes);
    framesN = backFrames*fix(framesN/backFrames);
    
    for trial = 0:trialsN-1
        phase = mod(trial,2);
        if (trial==0 || ~repeatCenterFlag)
            % grab the natural stimulus
            objSeq = GetPinkNoise(trial*framesN+1, framesN, objContrast, screen.gray, 0);
        end
        
        for i=1:contrastN
           
            % i=0:  backFreq  = 0, still background
            % i=1:  backFreq != 0, saccading background
            TemporalNaturalFlicker2(objSeq, backReverseFreq, waitframes, ...
                backTex(i), checkersN, phase, stimSize, 0, maskMode, ...
                shape,objRects);
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
        

    % After drawing, we have to discard the noise checkTexture.
    for i=1:contrastN
        Screen('Close', backTex{i});
    end
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function  TemporalNaturalFlicker2(objSeq, backReverseFreq, ...
    waitframes, backTex, checkersN, backPhase, stimSize, ...
    maskSize, maskMode, objShape, objRects)
    % Identical to TemporalNaturalFlicker but incorporates 
    % grayMaskSize
    
    global screen
    
try
    InitScreen(0);
    Add2StimLogList();
           
    % Define the background Destination Rectangle
    rectsCenter = mean(objRects,2)';
    backSource1 = SetRect(0, 0, checkersN, checkersN);
    backSource2 = SetRect(1, 0, checkersN+1, checkersN);
    backDest = SetRect(0,0,stimSize, stimSize);
    backDest = CenterRect(backDest, rectsCenter);
    
    grayMaskRect = SetRect(0, 0, maskSize, maskSize)'*ones(1, length(rectsCenter));
%    grayMaskTemplate = SetRect(0, 0, maskSize, maskSize)'*ones(1, length(rectsCenter));
    for i=1:size(objRects,2)
        if maskMode==1
            % each maskRect gets centered around its corresponding object
            grayMaskRect(:, i) = CenterRect(grayMaskRect(:,1)', objRects(:,i)')';
%            grayMaskRect(:, i) = CenterRect(grayMaskTemplate(:,1)', objRects(:,i)')';
        else
            % each maskRect gets centered around the rectsCenter, there is
            % effectively just one mask but I'm doing this to avoid
            % recoding
            grayMaskRect(:, i) = CenterRect(grayMaskRect(:,1)', rectsCenter)';
%            grayMaskRect(:, i) = CenterRect(grayMaskTemplate(:,1)', rectsCenter)';
        end
    end
    if backPhase==1
        tempDest = backSource2;
        backSource2 = backSource1;
        backSource1 = tempDest;
        clear tempDest
    end
    
    % Define the PD box
    pd = DefinePD();
    almostBlack = 30;
    
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
        
        Screen('DrawTexture', screen.w, backTex{1}, backSource, backDest, 0,0)
        
                
        if (objShape)
            Screen('FillOval', screen.w, screen.gray, grayMaskRect);
            Screen('FillOval', screen.w, color, objRects);
        else
            Screen('FillRect', screen.w, screen.gray, grayMaskRect);
            Screen('FillRect', screen.w, color, objRects);
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
            
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [~, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objContrast', .1, @(x) x>=0 && x<=1);
    p.addParamValue('shape', 0, @(x) isnumeric(x));

    % Background related
    p.addParamValue('backContrastN', 8, @(x) isnumeric(x));
%    p.addParamValue('backContrast', [.125 .25 .5 1], @(x)all(x)>=0 && all(x)<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));

    % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('presentationLength', 200, @(x)x>0);
    p.addParamValue('trialsN', 4);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         
    p.addParamValue('repeatCenter', 0, @(x) isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
