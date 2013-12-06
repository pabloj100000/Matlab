function q = FreqDiscriminationTask(varargin)
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
    p.addParamValue('sigma', 5, @(x) x>0);         % gaussian standard deviation in pixels
    p.addParamValue('phase', 0, @(x) x>0);          % phase, 0->1
    p.addParamValue('contrast', .15, @(x) all(x>=0 & x<=1)); % contrast of the reference patch
    p.addParamValue('pedestal', 5, @(x) x>=0);     % spatial frequency
    
    % other parameters
    p.addParamValue('stimSize', [], @(x) x>0);      % area occupied by background checkers
    p.addParamValue('backMaskSize', 356, @(x) isnumeric(x)); % dimension of the gray screen covering part of the checkers
    p.addParamValue('deltaX', 128, @(x) x>0);       % Distance of each patch to the fixation point (pixels)

    % Once it works well, change it back to the commented line
    %p.addParamValue('objDelays', 0:.1:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('objDelays', [0 .1 .3], @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('flashObjDuration', .032, @(x) x>0); % how long will the patches be presented for (in seconds)
    p.addParamValue('checkerSize', 64, @(x) x>0);   % dimension of background checkers
    p.addParamValue('saccadeDelay', [], @(x) all(x>=0));    % how long will it take since the observer presses a button to the new background reversal.
                                                            % by default is an exponential series
    p.addParamValue('trialsPerDelay', 20, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    p.addParamValue('updatePlot', 0, @(x) x==0||x==1);    
    
    p.parse(varargin{:});
    
    % gabor parameters
    objSize = p.Results.objSize;
    sigma = p.Results.sigma;
    phase = p.Results.phase;
    stimSize = p.Results.stimSize;
    contrast = p.Results.contrast;
    pedestal = p.Results.pedestal;      % lambda, spatial frequency
    
    % other parameters
    backMaskSize = p.Results.backMaskSize;
    deltaX = p.Results.deltaX;
    objDelays = p.Results.objDelays;
    flashObjDuration = p.Results.flashObjDuration;
    checkerSize = p.Results.checkerSize;
    saccadeDelay = p.Results.saccadeDelay;
    trialsPerDelay = p.Results.trialsPerDelay;
    updatePlot = p.Results.updatePlot;
    % *************** Constants ******************
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    RIGHT_BTN = KbName('RightArrow');
    LEFT_BTN = KbName('LeftArrow');
    DOWN_BTN = KbName('DownArrow');
    LEFT_SHIFT = KbName('LeftShift');
    RIGHT_SHIFT = KbName('RightShift');
    RIGHT = 2;
    LEFT = 1;
    minPhysicalThresh = log(.1);
    maxPhysicalThresh = log(25-pedestal);
    DiffSign = 1;               % if 1, you are going to be building the right part
                                % of the psychometric function.
                                % if 0, you will be building the left part
                                % of the psychometric function
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
    
    % Get gaussian mask
    gaussTex = GetGaussianDisk(objSize, screen.gray);
    gaussRect = Screen('Rect', gaussTex);
    
    % Get object texture
    x = -.5:1/objSize:.5;
    sin1 = sin(x*pedestal*2*pi)*contrast*screen.gray+screen.gray;
    pedestalTex = Screen('MakeTexture', screen.w, sin1);
    pedestalRect = Screen('Rect', pedestalTex);

    % Make all necessary rectangles
    objDest = GetRects(objSize, screen.center-[deltaX 0])';
    objDest(:,2) = GetRects(objSize, screen.center+[deltaX 0])';

    % Get Mask Texture    
    backSource = SetRect(0, 0, checkersN(1), checkersN(2));
    backDest = SetRect(0,0,stimSize(1),stimSize(2));
    backDest = CenterRectOnPoint(backDest, screen.center(1), screen.center(2));

    if backMaskSize>0
        backMask = GetRects(backMaskSize, screen.center-[deltaX 0])';
        backMask(:,2) = GetRects(backMaskSize, screen.center+[deltaX 0]);
    end
    
    % Get 2 rectangles for the fixation point
    fixationLength = 11;
    fixationRect = GetRects(11, screen.center);
    if backMaskSize>2*deltaX
        fixationColor = 0;
    else
        fixationColor = 127;
    end
    %fixationRect(:,1) = CenterRectOnPoint(SetRect(0,0, fixationLength, 1), screen.center(1), screen.center(2))';
    %fixationRect(:,2) = CenterRectOnPoint(SetRect(0, 0, 1, fixationLength), screen.center(1), screen.center(2));
    
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
    tGuess = log(10);
    tGuessSd = 2;
    pThreshold=0.82;
    beta=3.5;delta=0.01;gamma=0.5;
    q = QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma, .1, 10);
    q.normlizedPdf = 1;
    q(1, 2:objDelayN)=q;
    
    % Display grating before starting
    Screen('DrawTexture', screen.w, backTexture, backSource+shift*[1 0 1 0], ...
        backDest, 0, 0);
    if backMaskSize>0
        Screen('FillOval', screen.w, screen.gray, backMask);
    end
    % show the fixation spot
    Screen('FillOval', screen.w, fixationColor, fixationRect);  
    Screen('FillRect', screen.w, 127, [0 0 600, 60]);
    Screen('TextSize', screen.w, 16);
    Screen('DrawText', screen.w, 'Frequency Task', 0, 0, 0, 127);
    Screen('DrawText', screen.w, 'Your job is to select the lowest spatial frequency patch in each trial', 0, 20, 0, 127);
    Screen('DrawText', screen.w, 'You have to select the patch with 10 lines, the other patch will have more', 0, 40, 0, 127);
    Screen('Flip', screen.w);
    while (~KbCheck)
    end
    pause(.2);
    
    for i=1:trialsPerDelay
        delayOrder = randperm(objDelayN);
        for j=1:objDelayN
        
            objDelayFrame = objDelayFrames(delayOrder(j));
            saccadeFrame = saccadeDelayFrames(randi(saccadeDelayN, 1, 1));
            framesN = saccadeFrame + objDelayFrame + flashObjFrames;
            
            % Get recommended threshold.  Choose your favorite algorithm.
            tTest = QuestQuantile(q(delayOrder(j)));	% Recommended by Pelli (1987), and still our favorite.
            tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
            tTest = max(minPhysicalThresh, tTest);    % make sure is no smaller than minPhysicalContrast
            tTest = min(maxPhysicalThresh, tTest);    % make sure is no bigger than minPhysicalContrast

            pedestalPatch = randi(2, 1, 1);      % pedestalPatch = 1=> left 
                                                 %                 2=> right

            % transform tTest onto a spatial frequency
            intendedLambda = exp(tTest)*DiffSign+pedestal;

            if (abs(intendedLambda) < .001)
                intendedLambda = pedestal;
            elseif (intendedLambda < pedestal)
                error 'intendedLambda was smaller than 0';
            end

            sin1 = sin(x*intendedLambda*2*pi)*contrast*screen.gray+screen.gray;
            testTex = Screen('MakeTexture', screen.w, sin1);
            
            if pedestalPatch==1
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
                
                if backMaskSize>0
                    Screen('FillOval', screen.w, screen.gray, backMask);
                end
                % show the fixation spot
                Screen('FillOval', screen.w, fixationColor, fixationRect);  

                % {
                if (objDelayFrame + saccadeFrame < frame && frame < objDelayFrame+flashObjFrames + saccadeFrame)


                    Screen('DrawTextures', screen.w, objTextures, pedestalRect, objDest);
                    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    Screen('DrawTextures', screen.w, gaussTex, gaussRect, objDest);
                    Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
                end
                vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                %}
                
            end
            
            % {
            
            % figure out which patch had the higest contrast
            % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
            if (DiffSign==1)%pedestal>10^tTest)
                higestPatch = pedestalPatch;
            else
                higestPatch = 3 - pedestalPatch;
            end
            
            beep;
            pause(.2);
            while 1
                [keyIsDown, ~, keyCode, ~] = KbCheck;
                if (keyIsDown)
                    if keyCode(ESCAPE)
                        % finish experiment
                        abortFlag=1;
                        break
                        % Contrast higher on the LEFT_BTN and got it right?
                    elseif ((keyCode(RIGHT_BTN) || keyCode(RIGHT_SHIFT)) && higestPatch==RIGHT) || ...
                            ((keyCode(LEFT_BTN) || keyCode(LEFT_SHIFT)) && higestPatch==LEFT)
                        % got the contrast right
                        % Update the pdf
                        answer = 'Right';
                        q(delayOrder(j))=QuestUpdate(q(delayOrder(j)),tTest, true); % Add the new datum (actual test intensity and observer response) to the database.
                        break
                    elseif ((keyCode(RIGHT_BTN) || keyCode(RIGHT_SHIFT)) && higestPatch==LEFT) || ...
                            ((keyCode(LEFT_BTN) || keyCode(LEFT_SHIFT)) && higestPatch==RIGHT) ||...
                            keyCode(DOWN_BTN)
                        % got the contrast wrong
                        % Update the pdf
                        answer = 'Wrong';
                        q(delayOrder(j))=QuestUpdate(q(delayOrder(j)),tTest,false); % Add the new datum (actual test intensity and observer response) to the database.
                        break
                    end
                end
            end
            fprintf('trial %d, delay %d\n', i, j);
            fprintf('\t%s, tTested = %f, intendedLambda = %f\n',answer, tTest, intendedLambda)

            %}
            if (abortFlag)
                break
            end
        end
        if (abortFlag)
            break
        end
        if updatePlot && mod(i, updatePlot)==0
            errorbar(objDelays, QuestMean(q), QuestSd(q), 'LineWidth',2)
            drawnow
        end
    end


% Ask Quest for the final estimate of threshold.
for i=1:objDelayN
    t=QuestMean(q(i));		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
    sd=QuestSd(q(i));
    fprintf('TW %d\tFinal threshold estimate (mean±sd) is %.2f ± %.2f\n',i,t,sd);
    fprintf('\tcorresponding contrast is %.2f\n', exp(t)*DiffSign+pedestal);
end
    % Restore normal keyboard
    ListenChar(0);
     
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    ListenChar(0);
    CleanAfterError();
    rethrow(exception);
    psychrethrow(psychlasterror);
end %try..catch..
end
