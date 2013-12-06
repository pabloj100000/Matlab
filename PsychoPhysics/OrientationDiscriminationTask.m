function q = OrientationDiscriminationTask(varargin)
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
    p.addParamValue('sigma', 15, @(x) x>0);         % gaussian standard deviation in pixels
    p.addParamValue('phase', 0, @(x) x>0);          % phase, 0->1
    p.addParamValue('contrast', .15, @(x) all(x>=0 & x<=1)); % contrast of the reference patch
    p.addParamValue('pedestal', 0, @(x) x>=0);
    
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
    lambda = p.Results.lambda;
    sigma = p.Results.sigma;
    phase = p.Results.phase;
    stimSize = p.Results.stimSize;
    contrast = p.Results.contrast;
    pedestal = p.Results.pedestal;
    
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
    minPhysicalThresh = log(1/90);
    maxPhysicalThresh = log(90);
    DiffSign = 1;
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
    [gaborTex contrast] = GetGaborText2(objSize, lambda, sigma, phase, contrast);
    objTextures = [gaborTex gaborTex];

    % Make all necessary rectangles
    objDest = GetRects(objSize, screen.center-[deltaX 0])';
    objDest(:,2) = GetRects(objSize, screen.center+[deltaX 0])';
    objSource = Screen('Rect', gaborTex);

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
    Screen('FillRect', screen.w, 127, [0 0 500, 40]);
    Screen('TextSize', screen.w, 16);
    Screen('DrawText', screen.w, 'Orientation Task', 0, 0, 0, 127);
    Screen('DrawText', screen.w, 'Your job is to select the tilted patch (not the vertical one) in each trial', 0, 20, 0, 127);
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
            tTest=QuestQuantile(q(delayOrder(j)));	% Recommended by Pelli (1987), and still our favorite.
            tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
            tTest = max(minPhysicalThresh, tTest);    % make sure is no smaller than minPhysicalContrast
            tTest = min(maxPhysicalThresh, tTest);    % make sure is no bigger than minPhysicalContrast

            pedestalPatch = randi(2, 1, 1);      % pedestalPatch = 1=> left 
                                                 %                 2=> right

            % transform tTest onto an orientation
            intendedOrientation = exp(tTest)*DiffSign+pedestal;
            if (abs(intendedOrientation) < pedestal+.001)
                intendedOrientation = pedestal;
            elseif (intendedOrientation < 0)
                error 'intendedOrientation was smaller than 0';
            end
            
            sign = (randi(2, 1)-1.5)*2;
            if pedestalPatch==1
                orientations = [0 sign*intendedOrientation];
            else
                orientations = [-intendedOrientation*sign 0];
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

                    % Disable alpha-blending, restrict following drawing to alpha channel:
                    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);

                    % Clear 'dstRect' region of framebuffers alpha channel to zero:
                    Screen('FillRect', screen.w, [0 0 0 0], screen.rect);

                    % Fill circular 'dstRect' region with an alpha value of 255:
                    Screen('FillOval', screen.w, [0 0 0 255], objDest);

                    % Enable DeSTination alpha blending and reenalbe drawing to all
                    % color channels. Following drawing commands will only draw there
                    % the alpha value in the framebuffer is greater than zero, ie., in
                    % our case, inside the circular 'dst2Rect' aperture where alpha has
                    % been set to 255 by our 'FillOval' command:
                    Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

                    Screen('DrawTextures', screen.w, objTextures, objSource, objDest, orientations);

                    % Restore alpha blending mode for next draw iteration:
                    Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                end
                vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                %}
                
            end
            
            % {
            
            % figure out which patch had the higest contrast
            % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
            if (DiffSign==-1)%pedestal>10^tTest)
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
            fprintf('\t%s, tTested = %f, intendedOrientation = %f, sign = %d\n',answer, tTest, intendedOrientation, sign)

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
