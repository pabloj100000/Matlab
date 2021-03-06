function [objSeed] = UFlickerObj_Implementation(varargin)
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

    p.addParamValue('pdStim', 3, @(x) x>0);
    p.addParamValue('stimSize', screenH, @(x) x>0);
    p.addParamValue('backPeriod', 2, @(x) x>0);
    p.addParamValue('presentationLength', 10, @(x) x>0);
    p.addParamValue('objContrast', .03, @(x) all(x>=0 & x<=1));
    p.addParamValue('objMean', 127, @(x) x>=0 & x<=255);
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('backTexture', [], @(x) isnumeric(x));
    
    p.parse(varargin{:});
    

    pdStim = p.Results.pdStim;
    stimSize = p.Results.stimSize;
    backPeriod = p.Results.backPeriod;
    presentationLength = p.Results.presentationLength;
    objContrast = p.Results.objContrast;
    objMean = p.Results.objMean;
    objSeed = p.Results.objSeed;
    backTexture = p.Results.backTexture;
    %}

    InitScreen(0);
    Add2StimLogList();

    % Constants, move them to the inputParser as needed
    centerSize = 192;
    waitframes = 1;
    barsWidth = 8;
    backContrast = 1;
    objRect = GetRects(centerSize, screen.center);

    % get the background texture
    if (isempty(backTexture))
        temp =  GetCheckersTex(stimSize+barsWidth, barsWidth, backContrast);
        backTexture = temp{1};
        clear temp;
    end
    
    % get the back rect
    backDest = GetRects(stimSize, screen.center);
    backSourceOri = SetRect(0, 0, stimSize, stimSize);
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

    for frame=0:waitframes:framesN-1        
        % Change the background every revBackFrames
        if (mod(frame, revBackFrames)==0)
            backSource = backSourceOri + ...
                mod(floor(frame/revBackFrames), 2)*barsWidth*[1 0 1 0];
        end
        
        Screen('FillRect', screen.w, screen.gray);
        
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
        
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
        Screen('FillRect', screen.w, [0 0 0 0]);
        
        % Fill circular 'dstRect' region with an alpha value of 255:
        Screen('FillOval', screen.w, [0 0 0 255], backDest);
        
        % Enable DeSTination alpha blending and reenalbe drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

        % display background texture
        Screen('DrawTexture', screen.w, backTexture, backSource, ...
            backDest, 0, 0);

        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        % Draw the object
        color = uint8(randn(stream1,1)*objContrast*objMean+objMean);
        Screen('FillRect', screen.w, color, objRect);

        % Photodiode box
        % --------------
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)

        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        if (KbCheck)
            break
        end
    end
    
    objSeed = stream1.State;
    FinishExperiment()
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..
end

