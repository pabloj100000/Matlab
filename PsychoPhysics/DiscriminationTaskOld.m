function q = DiscriminationTask(varargin)
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
    gaborChange.type = p.Results.gaborChangeType;
    gabor.size = p.Results.gSize;
    gabor.period = p.Results.gPeriod;
    gabor.sigma = p.Results.gSigma;
    gabor.phase = p.Results.gPhase;        % in radians, 2? = 0
    gabor.contrast = p.Results.gContrast;       % from 0 to 1
    gabor.mean = p.Results.gMean;         % from 0 to 255
    gabor.tex = p.Results.gTex;      % uses parameters above, if anyone
    
    % other parameters
    backMaskSize = p.Results.backMaskSize;
    linesN = p.Results.linesN;
    objDelays = p.Results.objDelays;
    meanBackground = p.Results.meanBackground;
    flashObjDuration = p.Results.flashObjDuration;
    trialsPerDelay = p.Results.trialsPerDelay;
    trialsN = p.Results.trialsN;
    updatePlot = p.Results.updatePlot;

                                            % changes call this again
    % *************** Constants ******************
    keys = GetKeys;
    RIGHT = 2;
    LEFT = 1;
    minPhysicalThresh = log(1);
    maxPhysicalThresh = log(255-pedestal);
    gaborChange.sign = 1;
    % *************** End of Constants ******************

    % *************** Variables that need to be init ***********
    InitScreen(0, 'backColor', meanBackground);
    Screen(screen.w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    vbl = 0;
    abortFlag=0;

    % **********************************************************
    % Get the background checker's texture
    lines =  GetLines(linesN, 5, 150);

    % Get 2 rectangles for the fixation point
    [fixation targetCenters] = PlaceFixationRect(lines);%GetRects(11, screen.center);
    
    backMask = GetRects(gabor.size*[1 1], targetCenters)';
    
    % make pedestal's gabor
    if isempty(gabor.tex)
        gabor = GetGaborTex(gabor);
    end
    
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
        for k=1:2
            condition = k;      % condition = 1, peripheral stimulation
                                                % condition = 2, no
                                                % peripheral stimulation
            WaitForUserToAdjust(condition, fixation, lines, backMask);
 
            for i=1:trialsPerDelay
                objDelayFrame = objDelayFrames(randi(objDelayN));
                framesN = objDelayFrame + flashObjFrames;
                
                % Get recommended threshold.  Choose your favorite algorithm.
                tTest = QuestQuantile(q(condition));	% Recommended by Pelli (1987), and still our favorite.
                tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
                
                pedestalPatch = randi(2);      % pedestalPatch = 1=> left
                %                 2=> right
pedestalPatch = 1;                
                % transform tTest onto a luminance
                tTest = [0 tTest];   % 0 is tTest value that corresponds to pedestal
                
                if pedestalPatch == 2
                    tTest = circshift(tTest, [0 1]);
                end
                
                for frame = 0:framesN
                    
                    % display background texture if necessary
                    if (condition==1)
                        DrawLines(lines)
                    end
                    
                    if (backMaskSize>0)
                        Screen('FillOval', screen.w, screen.gray, backMask);
                    end
                    
                    % show the fixational spot
                    Screen('FillOval', screen.w, fixation.color, fixation.rect);
                    
                    % show targets only for flashObjFrames
                    if (objDelayFrame < frame && frame < objDelayFrame+flashObjFrames)
                        DisplayTargets(gabor, tTest, gaborChange, targetCenters)
                    end
                    
                    % Flip
                    vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                    
                end
                
                % figure out which patch had the higest contrast
                % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
                if (gaborChange.sign==-1)%pedestal>10^tTest)
                    higestPatch = pedestalPatch;
                else
                    higestPatch = 3 - pedestalPatch;
                end
                
                pause(.2)
                while 1
                    [keyIsDown, ~, keyCode, ~] = KbCheck;
                    if (keyIsDown)
                        if keyCode(keys.ESCAPE)
                            % finish experiment
                            abortFlag=1;
                            break
                            % Contrast higher on the LEFT_BTN and got it right?
                        elseif ((keyCode(keys.RIGHT_BTN) ||keyCode(keys.RIGHT_SHIFT)) && higestPatch==RIGHT) || ...
                                (keyCode(keys.DOWN_BTN) && higestPatch==RIGHT) || ...
                                (keyCode(keys.UP_BTN) && higestPatch==LEFT) || ...
                                ((keyCode(keys.LEFT_BTN) || keyCode(keys.LEFT_SHIFT)) && higestPatch==LEFT)
                            % got the contrast right
                            % Update the pdf
                            answer = 'Right';
                            q(condition)=QuestUpdate(q(condition),tTest(pedestalPatch), true); % Add the new datum (actual test intensity and observer response) to the database.
                            break
                        elseif ((keyCode(keys.RIGHT_BTN) || keyCode(keys.RIGHT_SHIFT)) && higestPatch==LEFT) || ...
                                ((keyCode(keys.LEFT_BTN) || keyCode(keys.LEFT_SHIFT)) && higestPatch==RIGHT) ||...
                                (keyCode(keys.DOWN_BTN) && higestPatch==LEFT) || ...
                                (keyCode(keys.UP_BTN) && higestPatch==RIGHT)
                            % got the contrast wrong
                            % Update the pdf
                            answer = 'Wrong';
                            q(condition)=QuestUpdate(q(condition),tTest(pedestalPatch),false); % Add the new datum (actual test intensity and observer response) to the database.
                            break
                        end
                    end
                end
                
                if (abortFlag)
                    break
                end
                
                fprintf('trial %d\n', i);
                fprintf('\t%s, tTested = %f\n',answer, tTest(higestPatch))
            end
            if (abortFlag)
                break
            end
        end
        if (abortFlag)
            break
        end
        close all
        PlotQuests(q, [0 1]);
    end
    % Ask Quest for the final estimate of threshold.
    for k=1:2
        t=QuestMean(q(k));		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
        sd=QuestSd(q(k));
        fprintf('TW %d\tFinal threshold estimate (mean?sd) is %.2f ? %.2f\n',i,t,sd);
        fprintf('\tcorresponding contrast is %.2f\n', exp(t)*gaborChange.sign+pedestal);
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
end %try..catch..
end

function WaitForUserToAdjust(condition, fixation, lines, backMask)
    global screen
    
    if (condition==1)
        DrawLines(lines)
    end
    Screen('FillOval', screen.w, screen.gray, backMask);
    Screen('FillOval', screen.w, fixation.color, fixation.rect); 
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
    p.addParamValue('gSize', 200, @(x) x>0);      % dimension of the two patches to discriminate
    p.addParamValue('gPeriod', 40, @(x) x>0);      % dimension of the two patches to discriminate
    p.addParamValue('gSigma', 50, @(x) x>0);      % dimension of the two patches to discriminate
    p.addParamValue('gPhase', 0, @(x) x>=0);      % dimension of the two patches to discriminate
    p.addParamValue('gContrast', 1, @(x) x>=0 && x<=1);      % dimension of the two patches to discriminate
    p.addParamValue('gMean', 127, @(x) x>=0 && g<=255);      % dimension of the two patches to discriminate
    p.addParamValue('gTex', [], @(x) isnumeric(x));
    p.addParamValue('gaborChangeType', 1, @(x) x>0);
    
    % other parameters
    p.addParamValue('backMaskSize', 150, @(x) isnumeric(x)); % dimension of the gray screen masking checkers where the targets are
    p.addParamValue('pedestal', 150, @(x) isnumeric(x));
    p.addParamValue('meanBackground', 127, @(x) x>=0 && x<=255);

    % Once it works well, change it back to the commented line
    %p.addParamValue('objDelays', 0:.1:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('objDelays', [0 .1 .3]+.0, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
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

function [fixation targetCenters] = PlaceFixationRect(lines)
    global screen 
    ESCAPE = KbName('escape');
    UP = KbName('UpArrow');
    DOWN = KbName('DownArrow');
    LEFT = KbName('LeftArrow');
    RIGHT = KbName('RightArrow');
    LEFT_SHIFT = KbName('LeftShift');
    RIGHT_SHIFT = KbName('RightShift');
    %CTRL = KbName('LeftControl');
    LEFT_ALT = KbName('LeftAlt');
    targetCenters = [screen.center;screen.center];
    fixation.rect = GetRects(10, screen.center);
    if screen.backColor==127
        fixation.color = 0;
    else
        fixation.color = 255-screen.backColor;
    end
    color = zeros(3,2);
    color(:,2)=255;

    while 1
        [keyIsDown, ~, keyCode, ~] = KbCheck;
        if keyIsDown
            if keyCode(ESCAPE) || keyCode(RIGHT_SHIFT)
                break
            elseif keyCode(UP) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in the up direction
                targetCenters = targetCenters+[0 1;0 1];
            elseif keyCode(DOWN) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in down
                targetCenters = targetCenters-[0 1;0 1];
            elseif keyCode(RIGHT) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in right
                targetCenters = targetCenters-[1 0;1 0];
            elseif keyCode(LEFT) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in left
                targetCenters = targetCenters+[1 0;1 0];
                
            % If shift is pressed, change relative positioning of targets
            elseif keyCode(UP) && keyCode(LEFT_SHIFT)
                % change center of mass in the up direction
                if targetCenters(1,2)<targetCenters(2,2)
                    targetCenters = targetCenters+[0 1;0 -1];
                end
            elseif keyCode(DOWN) && keyCode(LEFT_SHIFT)
                % change center of mass in down
                targetCenters = targetCenters-[0 1;0 -1];
            elseif keyCode(RIGHT) && keyCode(LEFT_SHIFT)
                % change center of mass in right
                if targetCenters(1,1)>targetCenters(2,1)
                    targetCenters = targetCenters-[1 0;-1 0];
                end
            elseif keyCode(LEFT) && keyCode(LEFT_SHIFT)
                % change center of mass in left
                targetCenters = targetCenters+[1 0;-1 0];
            
            % If Ctrl is pressed, change fixation point
            elseif keyCode(UP) && keyCode(LEFT_ALT)
                % change center of mass in the up direction
                fixation.rect = fixation.rect+[0 1 0 1];
            elseif keyCode(DOWN) && keyCode(LEFT_ALT)
                % change center of mass in down
                fixation.rect = fixation.rect-[0 1 0 1];
            elseif keyCode(RIGHT) && keyCode(LEFT_ALT)
                % change center of mass in right
                fixation.rect = fixation.rect-[1 0 1 0];
            elseif keyCode(LEFT) && keyCode(LEFT_ALT)
                % change center of mass in left
                fixation.rect = fixation.rect+[1 0 1 0];
            end
        end
        DrawLines(lines)
        Screen('DrawText', screen.w, 'Adjust Fixational Spot with keypad', 0, 20, 0, 127);
        Screen('FillOVal', screen.w, fixation.color, fixation.rect);
        rects = GetRects([100 100], targetCenters);
        Screen('FillOval', screen.w, color, rects');
        Screen('Flip', screen.w);

    
    end
end

function lines = GetLines(linesN, minWidth, maxWidth)
    % each line is defined by fromH, fromV, toH, toV, penWidth, color
    global screen
    
    lines = zeros(linesN, 6);
    if screen.backColor<screen.gray
        colorRange = 2*screen.backColor;
    else
        colorRange = 2*(255-screen.backColor);
    end
    
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

        lines(i, 5) = randi(maxWidth-minWidth)+minWidth;
        lines(i, 6) = randi(2*colorRange+1)-colorRange+screen.backColor;
    end
end

function DrawLines(lines)
    global screen
    for i=1:size(lines,1)
        Screen('DrawLine', screen.w, lines(i,6), lines(i,1), lines(i,2), lines(i,3), lines(i,4), lines(i,5))
    end
end

function k = GetKeys()
    KbName('UnifyKeyNames');
    k.ESCAPE = KbName('escape');
    k.RIGHT_BTN = KbName('RightArrow');
    k.LEFT_BTN = KbName('LeftArrow');
    k.UP_BTN = KbName('UpArrow');
    k.DOWN_BTN = KbName('DownArrow');
    k.LEFT_SHIFT = KbName('LeftShift');
    k.RIGHT_SHIFT = KbName('RightShift');
end

function DisplayTargets(gabor, tTest, gaborChange, targetCenters)
    % loop through all values in tTest and if tTest != 0, change the value
    % of the gabor, also if type changes gabor.sigma, redo gabor.mask.
%    global screen
    
    for i=1:2
        if (tTest(i)==0)
            [targetCenters(i, :) gabor.size gabor.sigma]
            DisplayGabor(gabor, targetCenters(i, :));
        else
            gabor2 = newGabor(gabor, tTest(i), gaborChange);
            [targetCenters(i, :) gabor2.size gabor2.sigma]
            DIsplayGabor(gabor2, targetCenters(i, :));
            killGaborTex(gabor2);
        end
    end
end

function gabor2 = newGabor(gabor, tTest, gaborChange)
    gabor2 = gabor;
    switch gaborChange.type
        case 1
           % gabor.size = p.Results.gSize;
           gabor2.size = round(exp(tTest)*2*gaborChange.sign+gabor.size);
           gabor2.sigma = gabor2.size/4;
        case 2
           % gabor.period = p.Results.gPeriod;
           gabor2.period = round(exp(tTest)*gaborChange.sign+gabor.size);
%                tTest = max(minPhysicalThresh, tTest);    % make sure is no smaller than minPhysicalContrast
%                tTest = min(maxPhysicalThresh, tTest);    % make sure is no bigger than minPhysicalContrast
           % gabor.sigma = p.Results.gSigma;
           % gabor.phase = p.Results.gPhase;        % in radians, 2? = 0
           % gabor.contrast = p.Results.gContrast;       % from 0 to 1
           % gabor.mean = p.Results.gMean;         % from 0 to 255
           % gabor.tex = p.Results.gTex;      % uses parameters above, if
           % anyone
    end
    
    gabor2.tex = [];
    gabor2 = GetGaborTex(gabor2);
end
