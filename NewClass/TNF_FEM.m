function [seed] = TNF_FEM(varargin)
% center is TNF and periphery follows FEM
global screen
    
try
    % process Input variables
    p = ParseInput(varargin{:});
    waitframes = p.Results.waitframes;
    seed = p.Results.seed;
    shape = p.Results.shape;
    presentationLength = p.Results.presentationLength;
    checkersSize = p.Results.checkersSize;
    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;
    stimSize = p.Results.stimSize;
    trialsN = p.Results.trialsN;
    objContrast = p.Results.objContrast;
    peripheryStep = p.Results.peripheryStep;
    objSize = p.Results.objSize;
    

    % start the stimulus
    InitScreen(0)
    Add2StimLogList();

    % get the background texture
    checkersN = floor(stimSize/checkersSize)+2;         % make two checkers bigger than what will be seen
    stimSize = checkersSize * (checkersN);
    [X, Y] = meshgrid(1:checkersN, 1:checkersN);
    Z = mod(X+Y+1,2)*screen.white;
    checkerTexture = Screen('MakeTexture', screen.w, Z);
        
    objRect = SetRect(0, 0, objSize, objSize);
    objRect = CenterRect(objRect, screen.rect);

    backDestOri = SetRect(0,0,stimSize, stimSize);
%    backDestOri = OffsetRect(backDestOri,screen.rect(1)+2*checkersSize,screen.rect(1)+2*checkersSize)  
    backDestOri = CenterRect(backDestOri, screen.rect);
    backDestOri = OffsetRect(backDestOri, -checkersSize, -checkersSize);

    % Define the source rectangle
    peripherySource = SetRect(0,0,checkersN, checkersN);

    peripheryMask = SetRect(0,0,(checkersN-2)*checkersSize, (checkersN-2)*checkersSize);
    peripheryMask = CenterRect(peripheryMask, screen.rect);

    offsetPeriphery = 0;

    framesN = round(presentationLength*screen.rate/waitframes);

    % Get a random sequence representing FEM
    S1 = RandStream('mcg16807', 'Seed',seed);
    FEMSeq = randi(S1, 3, framesN, 1)-2;

    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    objSeq = GetPinkNoise(1, framesN, objContrast, screen.gray, 0);
    for trial = 0:trialsN-1
        
        for frame=0:framesN-1
            Screen('FillRect', screen.w, screen.gray);
            
            % Offset peripherySource randomly according to back Step
            offsetPeriphery = mod(offsetPeriphery + FEMSeq(frame+1)*peripheryStep, 2*checkersSize);
            
            peripheryDest = backDestOri + offsetPeriphery*[1 0 1 0];

            Screen('DrawTexture', screen.w, checkerTexture, peripherySource, peripheryDest, 0,0);
            
            Screen('FillRect', screen.w, objSeq(frame+1), objRect);
            
            % Draw PD
            if (frame==0)
                pdColor = 255;
            else
                pdColor = objSeq(frame+1);
            end
            
            Screen('FillOval', screen.w, pdColor, pd);
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
            if KbCheck
                break
            end
        end
        if (KbCheck)
            break
        end
    end
        
    seed = S1.State;

    % After drawing, we have to discard the noise checkTexture.
    Screen('Close', checkerTexture);

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
    p.addParamValue('objContrast', .1, @(x) x>=0 && x<=1);
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>=0);
    p.addParamValue('shape', 0, @(x) isnumeric(x));

    % Background related
    p.addParamValue('seed', 1, @(x) isnumeric(x) );
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('peripheryStep', 1, @(x) x>=0 && x<16);

    % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('presentationLength', 200, @(x)x>0);
    p.addParamValue('trialsN', 5);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         
    p.addParamValue('repeatCenter', 1, @(x) isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
