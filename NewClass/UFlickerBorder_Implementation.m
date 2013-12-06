function [objSeed] = UFlickerBorder_Implementation(varargin)
%{
    pdStim, ...
    backPeriod, presentationLength, objContrast, objMean, objSeed
    %}
    %   I'm recoding UFlickerObj from scratch to see if there is any stupid
%   mistake in the code.
    global screen vbl pd
    
try
    if isempty(vbl)
        vbl=0;
    end
% {
    p  = inputParser;   % Create an instance of the inputParser class.
    [screenW screenH] = SCREEN_SIZE;
    p.addParamValue('pdStim', 111, @(x) x>0);
    p.addParamValue('stimSize', screenH, @(x) x>0);
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('backPeriod', 2, @(x) x>0);
    p.addParamValue('presentationLength', 200, @(x) x>0);
    p.addParamValue('objContrast', .06, @(x) all(x>=0 & x<=1));
    p.addParamValue('objMean', 127, @(x) x>=0 & x<=255);
    p.addParamValue('checkerSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('backTexture', [], @(x) isnumeric(x));
    p.addParamValue('borderPosition', .5, @(x) x>=0 && x<=1);   % fractional unit.
                        % 0 means no checkers, 1 means checkers everywhere
                        % according to stimSize
    
    p.parse(varargin{:});
    

    pdStim = p.Results.pdStim;
    stimSize = p.Results.stimSize;
    backPeriod = p.Results.backPeriod;
    presentationLength = p.Results.presentationLength;
    objContrast = p.Results.objContrast;
    objMean = p.Results.objMean;
    checkerSize = p.Results.checkerSize;
    objSeed = p.Results.objSeed;
    backTexture = p.Results.backTexture;
    borderPosition = p.Results.borderPosition;
    objSize = p.Results.objSize;
    %}

    InitScreen(0);
    Add2StimLogList();

    % Constants, move them to the inputParser as needed
    waitframes = 1;
    backContrast = 1;

    % get the background texture
    if (isempty(backTexture))
        temp =  GetCheckersTex(stimSize+checkerSize, checkerSize, backContrast);
        backTexture = temp{1};
        clear temp;
        killtextureFlag=1;
    else
        killtextureFlag=0;
    end
    
    % get the back rect
    backSourceOri = SetRect(0, 0, stimSize, stimSize);
    backDest = GetRects(stimSize, screen.center);
    
    % Change borderPOsition from fractional coordinates to pixels
    borderPosition = stimSize*borderPosition+backDest(2);

    % Get the rest of the rectangles needed.
    maskRect = backDest;
    maskRect(2) = borderPosition;
    objDest = GetRects(objSize, screen.center);
    
    if borderPosition < objDest(2)
        % do nothing
    elseif borderPosition < objDest(4)
        objDest(2)=borderPosition;
    else
        objDest = GetRects(0, [1 1]);
    end
        
    backSource = zeros(1,4);
    
    % Init all random streams
    stream1 = RandStream('mcg16807', 'Seed', objSeed);
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    framesPerSec = screen.rate;
    framesN = presentationLength*framesPerSec;
    revBackFrames = backPeriod*framesPerSec/2;

    Screen('FillRect', screen.w, screen.gray);
    Screen('Flip', screen.w);
    
    for frame=0:waitframes:framesN-1        
        % Change the background every revBackFrames
        if (mod(frame, revBackFrames)==0)
            backSource = backSourceOri + ...
                mod(floor(frame/revBackFrames), 2)*checkerSize*[1 0 1 0];
        end
        
        % display background texture
        Screen('DrawTexture', screen.w, backTexture, backSource, ...
            backDest, 0, 0);

        % Draw a mask in the lower part of the screen to cover checkers
        % below border
        Screen('FillRect', screen.w, screen.gray, maskRect);
        
        % Draw the object
        color = uint8(randn(stream1,1)*objContrast*objMean+objMean);
        Screen('FillRect', screen.w, color, objDest);

        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)

        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        if (KbCheck)
            break
        end
    end
    
    if killtextureFlag
        Screen('Close', backTexture);
    end
    
    objSeed = stream1.State;
    FinishExperiment()
    

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception);
end %try..catch..
end

