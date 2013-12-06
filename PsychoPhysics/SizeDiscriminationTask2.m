function q = SizeDiscriminationTask2(varargin)
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
    p = ParseInput(varargin{:});
        
    % gabor parameters
    pedestal = p.Results.pedestal;
    changeType = p.Results.changeType;
    
    % other parameters
    backMaskSize = p.Results.backMaskSize;
    linesN = p.Results.linesN;
    deltaX = p.Results.deltaX;
    deltaY = p.Results.deltaY;
    objDelays = p.Results.objDelays;
    flashObjDuration = p.Results.flashObjDuration;
    trialsPerDelay = p.Results.trialsPerDelay;
    trialsN = p.Results.trialsN;
    updatePlot = p.Results.updatePlot;
    % *************** Constants ******************
    KbName('UnifyKeyNames');
    ESCAPE = KbName('escape');
    RIGHT_BTN = KbName('RightArrow');
    LEFT_BTN = KbName('LeftArrow');
    UP_BTN = KbName('UpArrow');
    DOWN_BTN = KbName('DownArrow');
    LEFT_SHIFT = KbName('LeftShift');
    RIGHT_SHIFT = KbName('RightShift');
    RIGHT = 2;
    LEFT = 1;
    minPhysicalThresh = log(1);
    maxPhysicalThresh = log(255-pedestal);
    DiffSign = 1;
    % *************** End of Constants ******************
    % *************** Variables that need to be init ***********
    InitScreen(0);
    stimSize = screen.center*2;
    
    vbl = 0;
    abortFlag=0;

    % **********************************************************
    % Get the background checker's texture
    lines =  GetLines(screen, linesN, 5, 150);

    % Define default gabor
    gabor.period = 32;   % in pixels
    gabor.sigma = 50;       % std of gaussian envelope, in pixels
    gabor.phase = 0;        % in radians, 2? = 0
    gabor.contrast=1;       % from 0 to 1
    gabor.mean=127;         % from 0 to 255
    gabor.tex = GetGaborFromStruct(gabor);      % uses parameters above, if anyone
                                            % changes call this again
    gabor.mask = GetGaborMaskFromStruct(gabor); % uses gabor.sigma (if it changes,
                                            % call this again)

    % Make all necessary rectangles
    objCenters = [screen.center-[deltaX/2 deltaY/2];...
        screen.center+[deltaX/2 deltaY/2]];

    if backMaskSize>0
        backMask = GetRects(backMaskSize, screen.center-[deltaX/2 deltaY/2])';
        backMask(:,2) = GetRects(backMaskSize, screen.center+[deltaX/2 deltaY/2]);
    end
    
    % Get 2 rectangles for the fixation point
    fixationRect = PlaceFixationRect(screen);%GetRects(11, screen.center);
    % center backDest so that fixational point will be on a white checker.
    fixationColor = 0;
    
    objDelayFrames = round(objDelays/screen.ifi);
    flashObjFrames = round(flashObjDuration/screen.ifi);
    objDelayN = length(objDelayFrames);
    
    % Abort writing onto the m-file while executing the expeirment.
    ListenChar(2);

    % start two Quest structures, one for peripheral input and one for only central input
    tGuess = log(5);
    tGuessSd = 2;
    pThreshold=0.82;
    beta=3.5;delta=0.01;gamma=0.5;
    q = QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma, .1, 10);
    q.normlizedPdf = 1;
    q(1, 2) = q;
        
    % show the fixation spot
    pause(.2);
    for trials=1:trialsN
        conditionOrder = randperm(2);
        for k=1:2
            condition = conditionOrder(k);      % condition = 1, peripheral stimulation
                                                % condition = 2, no
                                                % peripheral stimulation
            WaitForUserToAdjust(screen, condition, fixationRect, lines, backMaskSize, backMask);
 %            WaitForUserToAdjust(screen, condition, fixationRect, backTexture, backSource, backDest, backMaskSize, backMask);
            for i=1:trialsPerDelay
                delayOrder = randperm(objDelayN);
                for j=1:objDelayN
                    
                    objDelayFrame = objDelayFrames(delayOrder(j));
                    framesN = objDelayFrame + flashObjFrames;
                    
                    % Get recommended threshold.  Choose your favorite algorithm.
                    tTest = QuestQuantile(q(condition));	% Recommended by Pelli (1987), and still our favorite.
                    tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
                    tTest = max(minPhysicalThresh, tTest);    % make sure is no smaller than minPhysicalContrast
                    tTest = min(maxPhysicalThresh, tTest);    % make sure is no bigger than minPhysicalContrast
                    
                    pedestalPatch = randi(2);      % pedestalPatch = 1=> left
                                                   %                 2=> right
                    
                    % transform tTest onto a luminance
                    tTest = [0 tTest];   % 0 is tTest value that corresponds to pedestal
                    
                    if pedestalPatch == 2
                        circshift(tTest, 1);
                    end
                   
                    for frame = 0:framesN
                        
                        % display background texture if necessary
                        if (condition==1)
                            DrawLines(screen, lines)
                        end
                        
                        if (backMaskSize>0)
                            Screen('FillOval', screen.w, screen.gray, backMask);
                        end
                        
                        % show the fixation spot
                        Screen('FillOval', screen.w, fixationColor, fixationRect);
                        
                        % show targets only for flashObjFrames
                        if (objDelayFrame < frame && frame < objDelayFrame+flashObjFrames)
                            DisplayObj(gabor, tTest, changeType, objCenters)
                        end
                        
                        % Flip
                        vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                        Screen('BlendFunction',screen.w, GL_ONE, GL_ZERO);
                        
                    end
                    
                    % figure out which patch had the higest contrast
                    % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
                    if (DiffSign==-1)%pedestal>10^tTest)
                        higestPatch = pedestalPatch;
                    else
                        higestPatch = 3 - pedestalPatch;
                    end
                    
                    beep;
                    pause(.2)
                    while 1
                        [keyIsDown, ~, keyCode, ~] = KbCheck;
                        if (keyIsDown)
                            if keyCode(ESCAPE)
                                % finish experiment
                                abortFlag=1;
                                break
                                % Contrast higher on the LEFT_BTN and got it right?
                            elseif ((keyCode(RIGHT_BTN) ||keyCode(RIGHT_SHIFT)) && higestPatch==RIGHT) || ...
                                    (keyCode(DOWN_BTN) && higestPatch==RIGHT) || ...
                                    (keyCode(UP_BTN) && higestPatch==LEFT) || ...
                                    ((keyCode(LEFT_BTN) || keyCode(LEFT_SHIFT)) && higestPatch==LEFT)
                                % got the contrast right
                                % Update the pdf
                                answer = 'Right';
                                q(condition)=QuestUpdate(q(condition),tTest(pedestalPatch), true); % Add the new datum (actual test intensity and observer response) to the database.
                                break
                            elseif ((keyCode(RIGHT_BTN) || keyCode(RIGHT_SHIFT)) && higestPatch==LEFT) || ...
                                    ((keyCode(LEFT_BTN) || keyCode(LEFT_SHIFT)) && higestPatch==RIGHT) ||...
                                    (keyCode(DOWN_BTN) && higestPatch==LEFT) || ...
                                    (keyCode(UP_BTN) && higestPatch==RIGHT)
                                % got the contrast wrong
                                % Update the pdf
                                answer = 'Wrong';
                                q(condition)=QuestUpdate(q(condition),tTest(pedestalPatch),false); % Add the new datum (actual test intensity and observer response) to the database.
                                break
                            end
                        end
                    end
                    fprintf('trial %d, delay %d\n', i, j);
                    fprintf('\t%s, tTested = %f\n',answer, tTest)
                    
                    %}
                    if (abortFlag)
                        break
                    end
                end
                if (abortFlag)
                    break
                end
                
                if updatePlot && mod(i, updatePlot)==0
                    errorbar(objDelays, QuestMean(q(condition)), QuestSd(q(condition)), 'LineWidth',2)
                    drawnow
                end
            end
            if (abortFlag)
                break
            end
        end
        if (abortFlag)
            break
        end
    end
    % Ask Quest for the final estimate of threshold.
    for k=1:2
        t=QuestMean(q(k));		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
        sd=QuestSd(q(k));
        fprintf('TW %d\tFinal threshold estimate (mean?sd) is %.2f ? %.2f\n',i,t,sd);
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

function WaitForUserToAdjust(screen, condition, fixationRect, lines, backMaskSize, backMask)
    if (condition==1)
        DrawLines(screen, lines)
    end
    if (backMaskSize>0)
        Screen('FillOval', screen.w, screen.gray, backMask);
    end
    Screen('FillOval', screen.w, 0, fixationRect); 
    Screen('FillRect', screen.w, 127, [0 0 500, 40]);
    Screen('TextSize', screen.w, 16);
    Screen('DrawText', screen.w, 'Luminance Task', 0, 0, 0, 127);
    Screen('DrawText', screen.w, 'Your job is to select the highest luminance patch in each trial', 0, 20, 0, 127);
    Screen('Flip', screen.w);
    pause(.5)
    while (~KbCheck)
    end
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('objSize', 100, @(x) x>0);      % dimension of the two patches to discriminate
    p.addParamValue('pedestal', 135, @(x) x>=0);
    p.addParamValue('changeType', 1, @(x) x>0);
    
    % other parameters
    p.addParamValue('backMaskSize', 150, @(x) isnumeric(x)); % dimension of the gray screen masking checkers where the targets are
    p.addParamValue('deltaX', 0, @(x) x>0);       % horizontal Distance between targets
    p.addParamValue('deltaY', 128, @(x) x>0);       % vertical distance between targets

    % Once it works well, change it back to the commented line
    %p.addParamValue('objDelays', 0:.1:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('objDelays', [0 .1 .3]+.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('flashObjDuration', .032, @(x) x>0); % how long will the patches be presented for (in seconds)
    p.addParamValue('linesN', 60, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    p.addParamValue('trialsN', 2, @(x) x>0);    % How many times to present peripheral stimulation and no peripheral stimulation. Each one of these
                                                % conditions is compossed
                                                % of trialsPerDelay *
                                                % objDelaysN
                                                
    p.addParamValue('trialsPerDelay', 20, @(x) x>0);    
    p.addParamValue('updatePlot', 0, @(x) x==0||x==1);    
    
    p.parse(varargin{:});
end

function fixationRect = PlaceFixationRect(screen)
    ESCAPE = KbName('escape');
    while 1
        [keyIsDown, ~, keyCode, ~] = KbCheck;
        if (keyIsDown && keyCode(ESCAPE))
            break
        end
        [x y] = GetMouse();
        fixationRect = GetRects(11, [x y]);
        Screen('FillOVal', screen.w, 0, fixationRect);
        Screen('Flip', screen.w);
    end
end

function lines = GetLines(screen, linesN, minWidth, maxWidth)
    % each line is defined by fromH, fromV, toH, toV, penWidth, color
    lines = zeros(linesN, 6);
    for i=1:linesN
        
        edge1 = randi(4);
        edge2 = mod(edge1+randi(3)-1,4)+1;
        if edge1 == edge2
            error('edge1 == edge2');
        end
        switch (edge1)
            case 1
                % start at bottom of screen
                lines(i, 1) = randi(screen.rect(3));
                lines(i, 2) = screen.rect(4);
            case 2
                % start at left of screen
                lines(i, 1) = 0;
                lines(i, 2) = randi(screen.rect(4));
            case 3
                % start at top of screen
                lines(i, 1) = randi(screen.rect(3));
                lines(i, 2) = 0;
            case 4
                % start at right of screen
                lines(i, 1) = screen.rect(3);
                lines(i, 2) = randi(screen.rect(3));
        end

        switch (edge2)
            case 1
                % start at bottom of screen
                lines(i, 3) = randi(screen.rect(3));
                lines(i, 4) = screen.rect(4);
            case 2
                % start at left of screen
                lines(i, 3) = 0;
                lines(i, 4) = randi(screen.rect(4));
            case 3
                % start at top of screen
                lines(i, 3) = randi(screen.rect(3));
                lines(i, 4) = 0;
            case 4
                % start at right of screen
                lines(i, 3) = screen.rect(3);
                lines(i, 4) = randi(screen.rect(3));
        end

%        lines(i, 3) = randi(screen.rect(3));
%        lines(i, 4) = randi(screen.rect(4));
        lines(i, 5) = randi(maxWidth-minWidth)+minWidth;
        lines(i, 6) = randi(255);
%        DrawLines(screen, lines)
%        Screen('Flip', screen.w);
    end
end

function DrawLines(screen, lines)
    for i=1:size(lines,1)
        Screen('DrawLine', screen.w, lines(i,6), lines(i,1), lines(i,2), lines(i,3), lines(i,4), lines(i,5))
    end
end

function testDisplayObj(screen, objDest, gaussTex)
    ESCAPE = KbName('escape');
    colors = ones(3,2)*135;
    for i=1:20
        colors(:,2) = 135+i;
        DisplayObj(screen, colors, objDest, gaussTex)
        Screen('Flip', screen.w);
        while 1
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if (keyIsDown && keyCode(ESCAPE))
                pause(.5)
                break
            end

        end
    end
end

function DisplayObj(gabor, tTest, changeType, objCenters)
    % loop through all values in tTest and if tTest != 0, change the value
    % of the gabor, also if type changes gabor.sigma, redo gabor.mask.
%    global screen
    
    for i=1:size(tTest,2)
        DisplayGaborStruct(gabor, objCenters(:, i))
    end
end
