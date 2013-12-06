function q = ContrastDiscriminationTask(varargin)
% PSychophysics expeirment for UFlicker. The oberserver is presented with a
% fixation point. Then the background moves and at some variable time
% defined by objDelays the two patches appear on either side of the 
% fixation point. THe task is to identify the highest contrast one and the
% response is input through either Left or Right arrow
%
% There are many Quest procedures in parallel, one for each objDelay. The
% Point of Subjective Equality (PSE) is computed for each delay.

global screen

try
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('objSize', 100, @(x) x>0);      % dimension of the two patches to discriminate
    p.addParamValue('lambda', 10, @(x) x>0);        % # of pixels per cycle
    p.addParamValue('sigma', 10, @(x) x>0);         % gaussian standard deviation in pixels
    p.addParamValue('phase', 0, @(x) x>0);          % phase, 0->1
    p.addParamValue('pedestal', .05, @(x) all(x>=0 & x<=1)); % contrast of the reference patch
    % other parameters
    p.addParamValue('stimSize', [], @(x) x>0);      % area occupied by background checkers
    p.addParamValue('backMaskSize', 512, @(x) x>0); % dimension of the gray screen covering part of the checkers
    p.addParamValue('deltaX', 128, @(x) x>0);       % Distance of each patch to the fixation point (pixels)

    % Once it works well, change it back to the commented line
    %    p.addParamValue('objDelays', 0:.05:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('objDelays', 0, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('flashObjDuration', .05, @(x) x>0); % how long will the patches be presented for (in seconds)
    p.addParamValue('checkerSize', 64, @(x) x>0);   % dimension of background checkers
    p.addParamValue('saccadeDelay', [], @(x) all(x>=0));    % how long will it take since the observer presses a button to the new background reversal.
                                                            % by default is an exponential series
    p.addParamValue('trialsPerDelay', 20, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    
    p.parse(varargin{:});
    
    % gabor parameters
    objSize = p.Results.objSize;
    lambda = p.Results.lambda;
    sigma = p.Results.sigma;
    phase = p.Results.phase;
    stimSize = p.Results.stimSize;
    pedestal = p.Results.pedestal;
    % other parameters
    backMaskSize = p.Results.backMaskSize;
    deltaX = p.Results.deltaX;
    objDelays = p.Results.objDelays;
    flashObjDuration = p.Results.flashObjDuration;
    checkerSize = p.Results.checkerSize;
    saccadeDelay = p.Results.saccadeDelay;
    trialsPerDelay = p.Results.trialsPerDelay;
    % *************** Constants ******************
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    RIGHT_BTN = KbName('RightArrow');
    LEFT_BTN = KbName('LeftArrow');
    RIGHT = 2;
    LEFT = 1;
    CORRECT = 0;
    INCORRECT = ~CORRECT;
    zKey = KbName('z');

    % *************** End of Constants ******************
    % *************** Variables that need to be init ***********
    if (isempty(stimSize))
        InitScreen(0);
        stimSize = screen.center*2;
    end
    vbl = 0;
    abortFlag=0;
    shift = 0;

    % **********************************************************
    % Get the background checker's texture
    checkersN = stimSize/checkerSize;
    temp =  GetCheckersTex(checkersN+1, 1, 1);
    backTexture = temp{1};
    clear temp;
    
    % Get object texture
    pedestalTex = GetGaborText2(objSize, lambda, sigma, phase, pedestal);
    
    % Make all necessary rectangles
    objDest = GetRects(objSize, screen.center-[deltaX 0])';
    objDest(:,2) = GetRects(objSize, screen.center+[deltaX 0])';
    objSource = Screen('Rect', pedestalTex);

    % Get Mask Texture
    
    backSource = SetRect(0, 0, checkersN(1), checkersN(2));
    backDest = SetRect(0,0,stimSize(1),stimSize(2));
    backDest = CenterRectOnPoint(backDest, screen.center(1), screen.center(2));

    backMask = GetRects(backMaskSize, screen.center);

    fixationLength = 11;
    fixationRect1 = SetRect(0,0, fixationLength, 1);
    fixationRect2 = SetRect(0, 0, 1, fixationLength);
    fixationRect1 = CenterRectOnPoint(fixationRect1, screen.center(1), screen.center(2));
    fixationRect2 = CenterRectOnPoint(fixationRect2, screen.center(1), screen.center(2));
    
    if isempty(saccadeDelay)
        saccadeDelay = 0.1*2.^(0:3);
    end
    saccadeDelayFrames = round(saccadeDelay*60);
    objDelayFrames = round(objDelays/screen.ifi);
    flashObjFrames = round(flashObjDuration/screen.ifi);
    saccadeDelayN = length(saccadeDelayFrames);
    objDelayN = length(objDelayFrames);
    
    % Abort writing onto the m-file while executing the expeirment.
    ListenChar(2);

    % start as many Quest structures q as bojDelayN in the experiment
    tGuess = log10(pedestal);
    tGuessSd = 1;
    pThreshold=0.82;
    beta=3.5;delta=0.01;gamma=0.5;
    q = cell(1, objDelayN);
    for i=1:objDelayN
        q{i}=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
        q{i}.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
    end
    
    for i=1:trialsPerDelay
        delayOrder = randperm(objDelayN);
        for j=1:objDelayN
        
            objDelayFrame = objDelayFrames(delayOrder(j));
            saccadeFrame = saccadeDelayFrames(randi(saccadeDelayN, 1, 1));
            framesN = saccadeFrame + objDelayFrame + flashObjFrames;
            
            % Get recommended level.  Choose your favorite algorithm.
            tTest=QuestQuantile(q{delayOrder(j)});	% Recommended by Pelli (1987), and still our favorite.
            tTest = min(0, tTest);
            pedestalPatch = randi(2, 1, 1);      % pedestalPatch = 1=> left 
                                                 %                 2=> right

            fprintf('tTest=%f, 10^tTest=%f\n',tTest, 10^tTest)
            
            testTex = GetGaborText2(objSize, lambda, sigma, phase, 10^tTest);
            if pedestalPatch==LEFT
                objTextures = [pedestalTex testTex];
            else
                objTextures = [testTex pedestalTex];
            end
            
            for frame = 0:framesN
                if (frame==saccadeFrame)
                    shift = mod(shift+1, 2);
                end
                % display background texture
                Screen('DrawTexture', screen.w, backTexture, backSource+shift*[1 0 1 0], ...
                    backDest, 0, 0);
                
                Screen('FillRect', screen.w, screen.gray, backMask);
                
                % show the fixation spot
                Screen('FillRect', screen.w, 0, fixationRect1);
                Screen('FillRect', screen.w, 0, fixationRect2);
                % {
%                if (objDelayFrame + saccadeFrame < frame && frame < objDelayFrame+flashObjFrames + saccadeFrame)
                    Screen('DrawTextures', screen.w, objTextures, objSource, objDest);
%                end
                vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                %}
                
            end
            
            Screen('Close', testTex);
            
            % {
            
            % figure out which patch had the higest contrast
            % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
            if (pedestal>10^tTest)
                higestPatch = pedestalPatch;
            else
                higestPatch = 3 - pedestalPatch;
            end
            
            while 1
                [keyIsDown, ~, keyCode, ~] = KbCheck;
                if (keyIsDown)
                    if keyCode(ESCAPE)
                        % finish experiment
                        abortFlag=1;
                        break
                        % Contrast higher on the LEFT_BTN and got it right?
                    elseif keyCode(zKey)
                        break
                    elseif (keyCode(RIGHT_BTN) && higestPatch==RIGHT) || ...
                            (keyCode(LEFT_BTN) && higestPatch==LEFT)
                        % got the contrast right
                        % Update the pdf
                        q{delayOrder(j)}=QuestUpdate(q{delayOrder(j)},tTest, CORRECT); % Add the new datum (actual test intensity and observer response) to the database.
                        break
                    elseif (keyCode(RIGHT_BTN) && higestPatch==LEFT) || ...
                            (keyCode(LEFT_BTN) && higestPatch==RIGHT)
                        % got the contrast wrong
                        % Update the pdf
                        q{delayOrder(j)}=QuestUpdate(q{delayOrder(j)},tTest,INCORRECT); % Add the new datum (actual test intensity and observer response) to the database.
                        break
                    end
                end
            end
            %}
            if (abortFlag)
                break
            end
        end
        if (abortFlag)
            break
        end
    end


% Ask Quest for the final estimate of threshold.
for i=1:objDelayN
    t=QuestMean(q{i});		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
    sd=QuestSd(q{i});
    fprintf('TW %d\tFinal threshold estimate (mean±sd) is %.2f ± %.2f\n',i,t,sd);
end
    % Restore normal keyboard
    ListenChar(0);
     
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    ListenChar(0);
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..
end