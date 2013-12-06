function q = LuminanceDiscriminationTask2(varargin)
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
    p.addParamValue('pedestal', 135, @(x) x>=0);
    
    % other parameters
    p.addParamValue('backMaskSize', 150, @(x) isnumeric(x)); % dimension of the gray screen masking checkers where the targets are

    % Once it works well, change it back to the commented line
    %p.addParamValue('objDelays', 0:.1:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('objDelays', [.5 .75 1], @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('flashObjDuration', .032, @(x) x>0); % how long will the patches be presented for (in seconds)
    p.addParamValue('checkerSize', 64, @(x) x>0);   % dimension of background checkers
    p.addParamValue('trialsPerDelay', 20, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    p.addParamValue('trialsN', 2, @(x) x>0);    % How many times to present peripheral stimulation and no peripheral stimulation. Each one of these
                                                % conditions is compossed
                                                % of trialsPerDelay *
                                                % objDelaysN
                                                
    p.addParamValue('meanBackground', 127, @(x) x>0 && x<255);    
    
    p.parse(varargin{:});
    
    % gabor parameters
    objSize = p.Results.objSize;
    pedestal = p.Results.pedestal;
    
    % other parameters
    backMaskSize = p.Results.backMaskSize;
    objDelays = p.Results.objDelays;
    flashObjDuration = p.Results.flashObjDuration;
    trialsPerDelay = p.Results.trialsPerDelay;
    trialsN = p.Results.trialsN;
    meanBackground = p.Results.meanBackground;

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
    InitScreen(0, 'backColor', meanBackground);
    Screen('Flip', screen.w)
    
    vbl = 0;
    abortFlag=0;

    % **********************************************************
    % Get the background checker's texture
    lines =  GetLines(screen, 100, 5, 150);
    
    % Get object texture
    [gaussTex] = GetGaussianDisk(objSize, meanBackground);

    % Make all necessary rectangles

    % Get Mask Texture    
%    backSource = SetRect(0, 0, checkersN(1), checkersN(2));
%    backDest = SetRect(0,0,stimSize(1),stimSize(2));
%    backDest = CenterRectOnPoint(backDest, screen.center(1), screen.center(2));
    
    % Get 2 rectangles for the fixation point
    if meanBackground==127
        fixationColor = 0;
    else
        fixationColor = 255-meanBackground;
    end
    [fixationRect objCenters] = PlaceFixationRect(lines, fixationColor);%GetRects(11, screen.center);
    objDest = GetRects([objSize objSize], objCenters)';
    % center backDest so that fixational point will be on a white checker.
%    backDest = backDest - mod(fixationRect, checkerSize)+0*checkerSize/2*[1 1 1 1];

    markerSize = 10;
    targetMarkers = GetRects(markerSize*[1 1], objCenters)';
    if (backMaskSize>0)
        backMask = GetRects(backMaskSize*[1 1], objCenters)';
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
    q(2) = q;
        
    % show the fixation spot
    pause(.2);
    for trials=1:trialsN
        for k=1:2
            condition = k;       % condition = 1, peripheral stimulation
                                                % condition = 2, no
                                                % peripheral stimulation
            WaitForUserToAdjust(condition, fixationRect, lines, backMaskSize, backMask);
 %            WaitForUserToAdjust(screen, condition, fixationRect, backTexture, backSource, backDest, backMaskSize, backMask);
            for j=1:trialsPerDelay
     
                objDelayFrame = objDelayFrames(randi(objDelayN));
                framesN = objDelayFrame + flashObjFrames;
                
                % Get recommended threshold.  Choose your favorite algorithm.
                tTest = QuestQuantile(q(condition));	% Recommended by Pelli (1987), and still our favorite.
                tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
                tTest = max(minPhysicalThresh, tTest);    % make sure is no smaller than minPhysicalContrast
                tTest = min(maxPhysicalThresh, tTest);    % make sure is no bigger than minPhysicalContrast
                
                pedestalPatch = randi(2, 1, 1);      % pedestalPatch = 1=> left
                %                 2=> right
                
                % transform tTest onto a luminance
                testedLuminance = round(exp(tTest)*DiffSign+pedestal);
                
                colors(1:3,1:2) = pedestal;
                if pedestalPatch==1
                    colors(:, 2) = testedLuminance;
                else
                    colors(:, 1) = testedLuminance;
                end
                
                for frame = 0:framesN
                    
                    % display background texture if necessary
                    if (condition==1)
                        DrawLines(lines)
                    end
                    
                    if (backMaskSize>0)
                        Screen('FillOval', screen.w, meanBackground, backMask);
                    end
                    
                    % show the fixation spot
                    Screen('FillOval', screen.w, fixationColor, fixationRect);
                    
                    % Show Target spots
%                    Screen('FillOval', screen.w, 150, targetMarkers)
                    % show targets only for flashObjFrames
                    if (objDelayFrame < frame && frame < objDelayFrame+flashObjFrames)
                        DisplayObj(colors, objDest, gaussTex)
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
                            q(condition)=QuestUpdate(q(condition),tTest, true); % Add the new datum (actual test intensity and observer response) to the database.
                            break
                        elseif ((keyCode(RIGHT_BTN) || keyCode(RIGHT_SHIFT)) && higestPatch==LEFT) || ...
                                ((keyCode(LEFT_BTN) || keyCode(LEFT_SHIFT)) && higestPatch==RIGHT) ||...
                                (keyCode(DOWN_BTN) && higestPatch==LEFT) || ...
                                (keyCode(UP_BTN) && higestPatch==RIGHT)
                            % got the contrast wrong
                            % Update the pdf
                            answer = 'Wrong';
                            q(condition)=QuestUpdate(q(condition),tTest,false); % Add the new datum (actual test intensity and observer response) to the database.
                            break
                        end
                    end
                end
                
                if (abortFlag)
                    break
                end
                
                fprintf('trial %d, delay %d\n', i, j);
                fprintf('\t%s, tTested = %f, testedLuminance = %f\n',answer, tTest, testedLuminance)
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

function WaitForUserToAdjust(condition, fixationRect, lines, backMaskSize, backMask)
    global screen
    
    if (condition==1)
        DrawLines(lines)
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


function [fixationRect objCenters] = PlaceFixationRect(lines, fixationColor)
    global screen 
    ESCAPE = KbName('escape');
    UP = KbName('UpArrow');
    DOWN = KbName('DownArrow');
    LEFT = KbName('LeftArrow');
    RIGHT = KbName('RightArrow');
    LEFT_SHIFT = KbName('LeftShift');
    RIGHT_SHIFT = KbName('RightShift');
    CTRL = KbName('LeftControl');
    LEFT_ALT = KbName('LeftAlt');
    objCenters = [screen.center;screen.center];
    fixationRect = GetRects(10, screen.center);
    color = zeros(3,2);
    color(:,2)=255;

    while 1
        [keyIsDown, ~, keyCode, ~] = KbCheck;
        if keyIsDown
            if keyCode(ESCAPE) || keyCode(RIGHT_SHIFT)
                break
            elseif keyCode(UP) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in the up direction
                objCenters = objCenters+[0 1;0 1];
            elseif keyCode(DOWN) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in down
                objCenters = objCenters-[0 1;0 1];
            elseif keyCode(RIGHT) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in right
                objCenters = objCenters-[1 0;1 0];
            elseif keyCode(LEFT) && ~keyCode(LEFT_SHIFT) && ~keyCode(LEFT_ALT)
                % change center of mass in left
                objCenters = objCenters+[1 0;1 0];
                
            % If shift is pressed, change relative positioning of targets
            elseif keyCode(UP) && keyCode(LEFT_SHIFT)
                % change center of mass in the up direction
                if objCenters(1,2)<objCenters(2,2)
                    objCenters = objCenters+[0 1;0 -1];
                end
            elseif keyCode(DOWN) && keyCode(LEFT_SHIFT)
                % change center of mass in down
                objCenters = objCenters-[0 1;0 -1];
            elseif keyCode(RIGHT) && keyCode(LEFT_SHIFT)
                % change center of mass in right
                if objCenters(1,1)>objCenters(2,1)
                    objCenters = objCenters-[1 0;-1 0];
                end
            elseif keyCode(LEFT) && keyCode(LEFT_SHIFT)
                % change center of mass in left
                objCenters = objCenters+[1 0;-1 0];
            
            % If Ctrl is pressed, change fixation point
            elseif keyCode(UP) && keyCode(LEFT_ALT)
                % change center of mass in the up direction
                fixationRect = fixationRect+[0 1 0 1];
            elseif keyCode(DOWN) && keyCode(LEFT_ALT)
                % change center of mass in down
                fixationRect = fixationRect-[0 1 0 1];
            elseif keyCode(RIGHT) && keyCode(LEFT_ALT)
                % change center of mass in right
                fixationRect = fixationRect-[1 0 1 0];
            elseif keyCode(LEFT) && keyCode(LEFT_ALT)
                % change center of mass in left
                fixationRect = fixationRect+[1 0 1 0];
            end
        end
        DrawLines(lines)
        Screen('DrawText', screen.w, 'Adjust Fixational Spot with keypad', 0, 20, 0, 127);
        Screen('FillOVal', screen.w, fixationColor, fixationRect);
        rects = GetRects([100 100], objCenters);
        Screen('FillOval', screen.w, color, rects');
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
%        DrawLines(lines)
%        Screen('Flip', screen.w);
    end
end

function DrawLines(lines)
    global screen
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

function DisplayObj(colors, objDest, gaussTex)
    global screen
    Screen('FillOval', screen.w, colors, objDest);
    Screen('BlendFunction',screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('DrawTextures', screen.w, gaussTex, [], objDest);
end
