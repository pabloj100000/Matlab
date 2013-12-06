 function DiscriminationTask2(varargin)
    % peripherymode = 1     still background
    %               = 2     FEM background
    %               = 3     Saccading
    global screen
    
try
    p = ParseInput(varargin{:});
        
    % **********************************************************
    backObjectsN = p.Results.backObjectsN;

    expType = p.Results.gaborChangeType;
    gabor.size = p.Results.gSize;
    gabor.freq = p.Results.gFreq;
    gabor.sc = p.Results.gSc;
    gabor.phase = p.Results.gPhase;        % in radians, 2? = 0
    gabor.contrast = p.Results.gContrast;       % from 0 to 1
    gabor.tilt = 0;
    gabor.aspectratio = 1.0;

    % start two Quest structures, one for peripheral input and one for only central input
    tGuess = log(5);
    tGuessSd = 2;
    pThreshold=0.82;
    beta=3.5;delta=0.01;gamma=0.5;
    q = QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma, .1, 10);
    q.normlizedPdf = 1;
    q(2:6) = q;

    InitScreen();
    
    % Get the background checker's texture
    backtex(1) = GetRectsTex(backObjectsN);
    backtex(2) = GetRectsTex(backObjectsN);

    gLowC = gabor;
    gHiC = gabor;
    gLowC.contrast = 100;
    
    [fixation targetRects gabor.size] = PlaceFixationRect(backtex(1), gabor.size);%GetRects(11, screen.center);

    objOff = .016;
    objOn = .016;
    peripheryDelay = [-.016 0 .016 .032];
    STILL = 1;
    FEM = 2;
    SACCADE = 3;
    expType = 0;
    chunksN = 1;
    trialsPerChunk = 2;
    waitToAdjustFlag = 1;
    % Still periphery, low contrast
    
    k = GetKeys();

    for chunk=1:chunksN
        trialsN = trialsPerChunk;
        q(1) = updateQuest(q(1), gLowC, backtex, STILL, expType,...
            objOn, objOff, peripheryDelay, trialsN, fixation, targetRects, waitToAdjustFlag);
        
        q(2) = updateQuest(q(2), gLowC, backtex, FEM, expType,...
            objOn, objOff, peripheryDelay, trialsN, fixation, targetRects, waitToAdjustFlag);
        
        
        waitToAdjustFlag = 0;
        trialsN = 1;
        for i=1:trialsPerChunk
            order = randperm(4)+2;
            for j=1:4
                currentQuest = order(j);
                q(currentQuest) = updateQuest(q(currentQuest), gLowC, backtex, SACCADE, expType,...
                    objOn, objOff, peripheryDelay(j), trialsN, fixation, targetRects, waitToAdjustFlag);

                [keyisdown, ~, keyCode, ~] = KbCheck;
                if keyisdown && (keyCode(k.RIGHT_SHIFT) || keyCode(k.ESCAPE))
                    break
                end
                
            end
            [keyisdown, ~, keyCode, ~] = KbCheck;
            if keyisdown && (keyCode(k.RIGHT_SHIFT) || keyCode(k.ESCAPE))
                break
            end
        end
        [keyisdown, ~, keyCode, ~] = KbCheck;
        if keyisdown && (keyCode(k.RIGHT_SHIFT) || keyCode(k.ESCAPE))
            break
        end
        
        PlotQ(q)
    end
    %{
    % FEM periphery, low contrast
    q(2) = updateQuest(q(2), gLowC, backtex, FEM, expType,...
        objDelay, peripheryDelayF, trialsN, fixation, targetRects);

    % Saccading periphery ?t = -50ms, low contrast
    q(3) = updateQuest(q(3), gLowC, backtex, SACCADE, expType,...
        objDelay-.05, peripheryDelayF, trialsN, fixation, targetRects);

    % Saccading periphery ?t = -50ms, low contrast
    q(4) = updateQuest(q(4), gLowC, backtex, SACCADE, expType,...
        objDelay, peripheryDelayF, trialsN, fixation, targetRects);

        % Saccading periphery ?t = -50ms, low contrast
    q(5) = updateQuest(q(5), gLowC, backtex, SACCADE, expType,...
        objDelay+.05, peripheryDelayF, trialsN, fixation, targetRects);

        % Saccading periphery ?t = -50ms, low contrast
    q(6) = updateQuest(q(6), gLowC, backtex, SACCADE, expType,...
        objDelay+.1, peripheryDelayF, trialsN, fixation, targetRects);
%}
    ListenChar(0);
    
%    PlotQuests(q, [0 1]);

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    ListenChar(0);
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end
 
function q = updateQuest(q, gabor, backtex, peripheryMode, changeParamIndex,...
    objOn, objOff, peripheryDelay, trialsN, fixation, targetRects, waitToAdjustFlag, varargin)
    %   q, quest struct to be updated
    %   gabor, default gabor struct
    %   backtex, has to have 2 textures. Each one with some type of texture
    %       for saccading
    %   peripheryMode,  1 = STILL
    %                   2 = FEM
    %                   3 = SACCADE
    %   changeParamIndex,  which field from gabor is changed by Quest.
    %                      Starts at 1
    %   objDelay,       delay in seconds since trial start to show targets
    %   peripheryDelayF, delay in frames since targets go on to show
    %                   peripheral input. Can be negative, meaning that
    %                   periphery goes on before targets.
    %   trialsN,
    %   fixation,       has fields color and rect
    %   targetRects,    2 targets

    global screen
        
    p = ParseInput2(varargin{:});

    % other parameters
    updateTime = screen.ifi/2;%p.Results.updateTime;
    meanBackground = p.Results.meanBackground;
    % *************** Constants ******************
    keys = GetKeys;
    RIGHT = 2;
    LEFT = 1;

    gaborChange.sign = 1;
    % *************** End of Constants ******************

    % *************** Variables that need to be init ***********
    % Select screen with maximum id for output window:
    InitScreen()

    vbl = 0;
    abortFlag=0;

    % Initialize matrix with spec for 2 patches to start off
    % identically:
    mypars = repmat([gabor.phase+180, gabor.freq, gabor.sc, gabor.contrast, gabor.aspectratio, 0, 0, 0]', 1, 2);
    
    % Build a procedural gabor texture for a gabor with a support of tw x th
    % pixels, and a RGB color offset of 0.5 -- a 50% gray.
    gabortex = CreateProceduralGabor(screen.w, gabor.size, gabor.size, 1, -.0*[1 1 1 0]);

    % Preallocate array with destination rectangles:
    % This also defines initial gabor patch orientations, scales and location
    % for the very first drawn stimulus frame:
%    texrect = Screen('Rect', gabortex);
%    inrect = repmat(texrect', 1, 2);
    
%    dstRects = repmat(CenterRectOnPoint(texrect, screen.center(1), screen.center(2))', 1, 2);
    
    % Preallocate array with rotation angles:
%    rotAngles = zeros(1, 2);
    
%{
    objFrames = max(round(flashObjDuration/updateTime), 1);
    objDelayFrames = round(objDelay/updateTime/objFrames)*objFrames;
    peripheryDelayFrames = round(peripheryDelay/updateTime/objFrames)*objFrames
    peripheryDelayFrames = objDelayFrames + peripheryDelayFrames;
%}
    objOnFrames = max(round(objOn/screen.ifi), 1);
    objOffFrames = round(objOff/screen.ifi);
        
    % Abort writing onto the m-file while executing the expeirment.
    ListenChar(2);
    
    % show the fixation spot
    if waitToAdjustFlag
        if peripheryMode == 2
            % FEM
            WaitForUserToAdjust(backtex(1), fixation, targetRects);
        else
            % Still
            WaitForUserToAdjust([], fixation, targetRects);
        end
    end
    pause(.2)

    for i=1:trialsN        
        frame = 0;

        % Get recommended threshold.  Choose your favorite algorithm.
        tTest = [0 QuestQuantile(q)];	% Recommended by Pelli (1987), and still our favorite.
        tTest = tTest*(.9+rand()/5);   % add 10% noise to the suggested value;
        
        pedestalPatch = randi(2);      % pedestalPatch = 1=> left
        %                 2=> right
        
        
        if pedestalPatch == 2
            tTest = circshift(tTest, [0 1]);
        end
        
        [testpars testangle] = tTest2pars(changeParamIndex, tTest, mypars);
        
        objDelayFrames = (randi(3)+3)*(objOnFrames+objOffFrames);
        peripheryDelayFrames = round(peripheryDelay/screen.ifi) + objDelayFrames;

%        [objDelayFrames objOnFrames objOffFrames peripheryDelayFrames]
        while 1
            if peripheryMode==3 && frame == peripheryDelayFrames
                Screen('DrawTexture', screen.w, backtex(1), [], screen.rect, [], 0);
            elseif peripheryMode==2
                Screen('DrawTexture', screen.w, backtex(1), [], screen.rect, [], 0);
            else
                Screen('FillRect', screen.w, screen.backColor);
            end                
            
            
            % Draw masks behind gabors
            Screen('FillOval', screen.w, screen.backColor, targetRects);
            
                        
            % Enable alpha blending again
            Screen('BlendFunction', screen.w, GL_ONE, GL_ONE);

            % randomly choose params for the targets.
            if frame == objDelayFrames
                tempangle = testangle;
                temppars = testpars;
            elseif mod(frame, objOnFrames+objOffFrames)==0
                tempangle = rand*360*[1 1]';
                temppars = mypars;
            end
            

            % only show object for objOnFrames
            if mod(frame, objOnFrames+objOffFrames) < objOnFrames
                Screen('DrawTextures', screen.w, gabortex, [], targetRects, tempangle, [], [], [], [], kPsychDontDoRotation, temppars);
            end
            
            % Restore alpha blending to overwrite.
            Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
            
            % show the fixational spot
            Screen('FillOval', screen.w, fixation.color, fixation.rect);            
            

            % Flip
            vbl = Screen('Flip', screen.w, vbl + updateTime);

            frame = frame+1;

            % figure out which patch had the higest contrast
            % WHAT DO I DO IF THE PATCHES HAVE EQUAL CONTRAST?
            if (gaborChange.sign==-1)%pedestal>10^tTest)
                higestPatch = pedestalPatch;
            else
                higestPatch = 3 - pedestalPatch;
            end
            
            pause(.2)

            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if keyCode(keys.ESCAPE)
                % finish experiment
                return
                % Contrast higher on the LEFT and got it right?
            end
            if (keyIsDown && frame>objDelayFrames)
                if ((keyCode(keys.RIGHT) ||keyCode(keys.RIGHT_SHIFT)) && higestPatch==RIGHT) || ...
                        (keyCode(keys.DOWN) && higestPatch==RIGHT) || ...
                        (keyCode(keys.UP) && higestPatch==LEFT) || ...
                        ((keyCode(keys.LEFT) || keyCode(keys.LEFT_SHIFT)) && higestPatch==LEFT)
                    % got the contrast right
                    % Update the pdf
                    beep;
                    answer = 'Right';
                    q=QuestUpdate(q,tTest(pedestalPatch), true); % Add the new datum (actual test intensity and observer response) to the database.
                    break
                elseif ((keyCode(keys.RIGHT) || keyCode(keys.RIGHT_SHIFT)) && higestPatch==LEFT) || ...
                        ((keyCode(keys.LEFT) || keyCode(keys.LEFT_SHIFT)) && higestPatch==RIGHT) ||...
                        (keyCode(keys.DOWN) && higestPatch==LEFT) || ...
                        (keyCode(keys.UP) && higestPatch==RIGHT)
                    % got the contrast wrong
                    % Update the pdf
                    beep;
                    answer = 'Wrong';
                    q=QuestUpdate(q,tTest(pedestalPatch),false); % Add the new datum (actual test intensity and observer response) to the database.
                    break
                end
            end
        end
        
        if exist('answer', 'var')
            fprintf('trial %d\n', i);
            fprintf('\t%s, tTested = %f\n',answer, tTest(higestPatch))
        end
    end
    
    % Restore normal keyboard
end

function [temppars tempangle] = tTest2pars(changeParamIndex, tTest, mypars)
    % mypars = repmat(phase, freq, sc, contrast, aspectratio, 0, 0, 0]

    temppars = mypars;
    pedestal = tTest==0;
    nonpedestal = tTest~=0;

    if changeParamIndex
        tempangle = 45*[1 -1]';
    
        DiffSign = 1;
        switch changeParamIndex
            case 1
                newValues(nonpedestal) = exp(tTest)*DiffSign + newValues(pedestal);
            case 2
                newValues(nonpedestal) = exp(tTest)*DiffSign + newValues(pedestal);
            case 3
                newValues(nonpedestal) = exp(tTest)*DiffSign + newValues(pedestal);
            case 4
                newValues(nonpedestal) = exp(tTest)*DiffSign + newValues(pedestal);
        end
        temppars(changeParamIndex, :) = newValues;
    else
        tempangle = (exp(tTest)-1)*90/exp(2);
        tempangle(tempangle>90) = 90;
%        tempangle = [-45 45];
    end
    
    
end

function WaitForUserToAdjust(backtex, fixation, targetRects)
    global screen

    if ~isempty(backtex)
        Screen('DrawTexture', screen.w, backtex,[],screen.rect, [],0);
    end
    
    % Draw masks behind gabors
    Screen('FillOval', screen.w, screen.backColor, targetRects);
    
    Screen('FillOVal', screen.w, fixation.color, fixation.rect);
    Screen('Flip', screen.w);

    pause(1);
    
    k = GetKeys();
    while 1
        [keyisdown, ~, keyCode, ~] = KbCheck;
        if keyisdown && (keyCode(k.RIGHT_SHIFT) || keyCode(k.ESCAPE))
            break
        end
    end
end

%{
function meantex = GetMeanTex()
    global screen
%    array = ones(screen.rect(4), screen.rect(3))*screen.backColor;
    array = 0;%screen.backColor;
    meantex = Screen('MakeTexture', screen.w, array, [], [], 2);
end
%}

function [tex rect]= GetRectsTex(boxesN)
    global screen
    
    array = .5*ones(screen.rect(4), screen.rect(3));

    maximumSize = 100;
    if screen.backColor<.5
        minColor = 0;
        maxColor = 2*screen.backColor;
    else
        maxColor = 1;
        minColor = 2*screen.backColor-1;
    end
% {    
    for i=1:boxesN
        left = randi(screen.rect(4)-1);
        top = randi(screen.rect(3)-1);
        right = randi(min(screen.rect(4)-left, maximumSize))+left;
        bottom = randi(min(screen.rect(3)-top, maximumSize))+top;
        array(left:right, top:bottom) = rand();%color;
    end

    array = array*(maxColor-minColor)+minColor;
    
    tex = Screen('MakeTexture', screen.w, array, [], [], 2);
    Screen('DrawTexture', screen.w, tex, [], [], [], 0)
    Screen('Flip', screen.w);
%    pause(1)
    rect = Screen('Rect', tex)';
end


%{
function masktex = GetMaskTex(R)
    global screen
    
    % We create a Luminance+Alpha matrix for use as transparency mask:
    % Layer 1 (Luminance) is filled with luminance value 'gray' of the
    % background.
    transLayer=2;
%    R = RectHeight(rect')/2;
    [x,y] = meshgrid(-R:R, -R:R);
    maskblob = zeros(2*R+1, 2*R+1, transLayer);
%    maskblob=uint8(ones(2*R+1, 2*R+1, transLayer) * screen.backColor);
    % Layer 2 (Transparency aka Alpha) is filled with gaussian transparency
    % mask.
%    maskblob(:,:,transLayer)=uint8(round(255 - exp(-((x/xsd).^2)-((y/ysd).^2))*255));
    maskblob(:,:,transLayer)= R^2 < (x.^2)+(y.^2);
    
    % Build a single transparency mask texture
    masktex=Screen('MakeTexture', screen.w, maskblob);
end
%}

%{
function testGabor(gabortex, mypars)
    global screen
    
% Draw the gabor once, just to make sure the gfx-hardware is ready for the
% benchmark run below and doesn't do one time setup work inside the
% benchmark loop. The flag 'kPsychDontDoRotation' tells 'DrawTexture' not
% to apply its built-in texture rotation code for rotation, but just pass
% the rotation angle to the 'gabortex' shader -- it will implement its own
% rotation code, optimized for its purpose. Additional stimulus parameters
% like phase, sc, etc. are passed as 'auxParameters' vector to
% 'DrawTexture', this vector is just passed along to the shader. For
% technical reasons this vector must always contain a multiple of 4
% elements, so we pad with three zero elements at the end to get 8
% elements.
    Screen('Flip', screen.w)
    pause(1)
    
    Screen('FillRect', screen.w, 0);
    Screen('Flip', screen.w)
    pause(1)

    Screen('FillRect', screen.w, .5);
    Screen('Flip', screen.w)
    pause(1)
    Screen('FillRect', screen.w, 1);
    Screen('Flip', screen.w)
    pause(1)
    Screen('Flip', screen.w)
    pause(1)
%    Screen('Flip', screen.w)
%    Screen('FillRect', screen.w, 127);
    Screen('Flip', screen.w)
    pause(1)
%    Screen('FillRect', screen.w, .0);
    destRect = repmat(GetRects(100, screen.center-[screen.center(1)/2 0]), 2, 1);
    destRect(2,:) = destRect(2,:) + screen.center(1)*[1 0 1 0];

%    Screen('FillRect', screen.w, 0.5)%, [screen.center(1) 0 screen.rect(3) screen.rect(4)])
%    Screen('FillRect', screen.w, 0.5, [screen.center(1) 0 screen.rect(3) screen.rect(4)])
    Screen('FillRect', screen.w, .5);

    % Enable alpha blendin We switch it into additive mode which takes
    % source alpha into account:
    Screen('BlendFunction', screen.w, GL_ONE, GL_ONE);

    Screen('DrawTextures', screen.w, gabortex, [], destRect', [], [], [], [], [], kPsychDontDoRotation, mypars);
    
    % Restore blending to overwrite
    Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
    Screen('Flip', screen.w)
%    pause(3)
end
%}

function [fixation targetRects gaborSize] = PlaceFixationRect(backtex, gaborSize)
    global screen 

    k = GetKeys();
    
    targetRects = GetRects(gaborSize, screen.center-[0 200]);
    targetRects(2, :) = OffsetRect(targetRects, 0, 400);
    targetRects = targetRects';
    
    fixation.rect = GetRects(20, screen.center);
    fixation.rect(2,:) = GetRects(10, screen.center);
    fixation.rect = fixation.rect';
    
    fixation.color = zeros(3,2);
    fixation.color(:,2) = 255;
    

%{
    if screen.backColor==.5
        fixation.color = 0;
    else
        fixation.color = 1-screen.backColor;
    end
%}
    while 1
        [keyIsDown, ~, keyCode, ~] = KbCheck;
        if keyIsDown
            if keyCode(k.ESCAPE) || keyCode(k.RIGHT_SHIFT)
                break
            elseif keyCode(k.UP) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT) && ~keyCode(k.LEFT_CTRL)
                % change center of mass in the up direction
                targetRects = targetRects + [0 1 0 1]'*[1 1];
            elseif keyCode(k.DOWN) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT) && ~keyCode(k.LEFT_CTRL)
                % change center of mass in down
                targetRects = targetRects - [0 1 0 1]'*[1 1];
            elseif keyCode(k.RIGHT) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT) && ~keyCode(k.LEFT_CTRL)
                % change center of mass in right
                targetRects = targetRects - [1 0 1 0]'*[1 1];
            elseif keyCode(k.LEFT) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT) && ~keyCode(k.LEFT_CTRL)
                % change center of mass in left
                targetRects = targetRects + [1 0 1 0]'*[1 1];
                
            % If shift is pressed, change relative positioning of targets
            elseif keyCode(k.UP) && keyCode(k.LEFT_SHIFT)
                % change center of mass in the up direction
                if targetRects(2,1)<targetRects(2,2)
                    targetRects = targetRects + [0 1 0 1]'*[1 -1];
                end
            elseif keyCode(k.DOWN) && keyCode(k.LEFT_SHIFT)
                % change center of mass in down
                targetRects = targetRects + [0 1 0 1]'*[-1 1];
            elseif keyCode(k.RIGHT) && keyCode(k.LEFT_SHIFT)
                % change center of mass in right
                if targetRects(1,1)>targetRects(1,2)
                    targetRects = targetRects + [1 0 1 0]'*[-1 1];
                end
            elseif keyCode(k.LEFT) && keyCode(k.LEFT_SHIFT)
                % change center of mass in left
                targetRects = targetRects + [1 0 1 0]'*[1 -1];
            
            % If Alt is pressed, change fixation point
            elseif keyCode(k.UP) && keyCode(k.LEFT_ALT)
                % change center of mass in the up direction
                fixation.rect = fixation.rect+[0 1 0 1]'*ones(1, 2);
            elseif keyCode(k.DOWN) && keyCode(k.LEFT_ALT)
                % change center of mass in down
                fixation.rect = fixation.rect-[0 1 0 1]'*ones(1, 2);
            elseif keyCode(k.RIGHT) && keyCode(k.LEFT_ALT)
                % change center of mass in right
                fixation.rect = fixation.rect-[1 0 1 0]'*ones(1, 2);
            elseif keyCode(k.LEFT) && keyCode(k.LEFT_ALT)
                % change center of mass in left
                fixation.rect = fixation.rect+[1 0 1 0]'*ones(1, 2);
            
            % If Ctrl is pressed, change gabor size
            elseif keyCode(k.UP) && keyCode(k.LEFT_CTRL)
                % change center of mass in the up direction
                gaborSize = gaborSize+2;
                targetRects = GrowRect(targetRects', 1, 1)';
            elseif keyCode(k.DOWN) && keyCode(k.LEFT_CTRL)
                gaborSize = gaborSize-2;
                % change center of mass in down
                targetRects = GrowRect(targetRects', -1, -1)';
            elseif keyCode(k.RIGHT) && keyCode(k.LEFT_CTRL)
                gaborSize = gaborSize+2;
                % change center of mass in right
                targetRects = GrowRect(targetRects', 1, 1)';
            elseif keyCode(k.LEFT) && keyCode(k.LEFT_CTRL)
                gaborSize = gaborSize-2;
                % change center of mass in left
                targetRects = GrowRect(targetRects', -1, -1)';
            end
        end
        
        
        
        Screen('DrawTexture', screen.w, backtex);
        
        % Draw masks behind gabors
        %        Screen('DrawTexture', screen.w, masktex, [], targetRects);
        Screen('FillOval', screen.w, .5, targetRects);
        
        % Enable alpha blending again
        %        Screen('BlendFunction', screen.w, GL_ONE, GL_ONE);
        
        %        Screen('DrawTextures', screen.w, gaborTex, [], targetRects, [], [], [], [], [], kPsychDontDoRotation, mypars);
        
        % Restore alpha blending to overwrite.
        %        Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
        
        Screen('FillOVal', screen.w, fixation.color, fixation.rect);
        Screen('Flip', screen.w);
    end
    
    pause(.2)
end

function PlotQ(q)
    
    Qmean = zeros(size(q));
    Qsd = zeros(size(q));

    for i=1:size(q,1)
        Qmean(i, :) = QuestMean(q(i,:));
        Qsd(i, :) = QuestSd(q(i,:));
    end

    x = 1:6;
    axes('FontSize', 20)
%    axes( 'XLim', [0 .3]);
    
%    hold on
%    errorbar(-1, Qmean(1), Qsd(1), 'b', 'LineWidth',2)
%    errorbar(0, Qmean(1), Qsd(1), 'r', 'LineWidth',2)
    errorbar(x, Qmean, Qsd, 'b', 'LineWidth',2)
%    hold off

    legend('Control', 'Saccading');
    title(inputname(1));
    xlabel('Time (s)');
    ylabel('log(threshold)');
    
    
    drawnow;
end

function k = GetKeys()
    KbName('UnifyKeyNames');
    k.SPACE_BAR = KbName('space');
    k.ESCAPE = KbName('escape');
    k.RIGHT = KbName('RightArrow');
    k.LEFT = KbName('LeftArrow');
    k.UP = KbName('UpArrow');
    k.DOWN = KbName('DownArrow');
    k.LEFT_SHIFT = KbName('LeftShift');
    k.RIGHT_SHIFT = KbName('RightShift');
    k.LEFT_ALT = KbName('LeftAlt');
    k.LEFT_CTRL = KbName('LeftControl');
end


function InitScreen()
    global screen
    
    if isfield(screen, 'w')
        return
    end
    
    % Get the list of screens and choose the one with the highest screen number.
	% Screen 0 is, by definition, the display with the menu bar. Often when 
	% two monitors are connected the one without the menu bar is used as 
	% the stimulus display.  Chosing the display with the highest dislay number is 
	% a best guess about where you want the stimulus displayed.  
	screenNumber=max(Screen('Screens'));
    
    % Open a double-buffered fullscreen window with a gray (intensity =
    % 0.5) background and support for 16- or 32 bpc floating point framebuffers.
    PsychImaging('PrepareConfiguration');

    % This will try to get 32 bpc float precision if the hardware supports
    % simultaneous use of 32 bpc float and alpha-blending. Otherwise it
    % will use a 16 bpc floating point framebuffer for drawing and
    % alpha-blending, but a 32 bpc buffer for gamma correction and final
    % display. The effective stimulus precision is reduced from 23 bits to
    % about 11 bits when a 16 bpc float buffer must be used instead of a 32
    % bpc float buffer:
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
    
    % normalize colors between 0 and 1
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');

    % Finally open a window according to the specs given with above
    % PsychImaging calls, clear it to a background color of 0.5 aka 50%
    % luminance:
    screen.backColor = .5;
    [screen.w, screen.rect]=PsychImaging('OpenWindow',screenNumber, screen.backColor);

    
    % From here on, all color values should be specified in the range 0.0
    % to 1.0 for displayable luminance values. Values outside that range
    % are allowed as intermediate results, but the final stimulus image
    % should be in range 0-1, otherwise result will be undefined.
    
    [screen.rect(3) screen.rect(4)]=Screen('WindowSize', screen.w);
    screen.center = [screen.rect(3) screen.rect(4)]/2;

    % Enable alpha blending. We switch it into additive mode which takes
    % source alpha into account:
%    Screen('BlendFunction', screen.w, GL_ONE, GL_ONE);

    Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);

%{
	inc=0.5;
	
	% Compute one frame of a static grating: It has a total size of third
	% the screen size:
    s=min(screen.rect(3), screen.rect(4)) / 6;
	[x,y]=meshgrid(-s:s-1, -s:s-1);
	angle=30*pi/180; % 30 deg orientation.
	f=0.01*2*pi; % cycles/pixel
    a=cos(angle)*f;
	b=sin(angle)*f;
                
    % Build grating texture:
    m=sin(a*x+b*y);
    tex=Screen('MakeTexture', screen.w, m,[],[], 2);
%}
    screen.center = [screen.rect(3) screen.rect(4)]/2;
    screen.ifi = Screen('GetFlipInterval', screen.w);
    
    % Show the gray background:
    screen.vbl = Screen('Flip', screen.w);
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('gSize', 250, @(x) x>0);      % dimension of the two patches to discriminate
    p.addParamValue('gFreq', .02, @(x) x>0);      % higher freq gives more oscilations at a fixed size
    p.addParamValue('gSc', 25, @(x) x>0);         % bigger numbers give slower decay (bigger patches)
    p.addParamValue('gPhase', 0, @(x) x>=0);      % dimension of the two patches to discriminate
    p.addParamValue('gContrast', 100, @(x) x>=0 && x<=1);      % dimension of the two patches to discriminate
    p.addParamValue('gMean', .5, @(x) x>=0 && g<=255);      % dimension of the two patches to discriminate
    p.addParamValue('gaborChangeType', 1, @(x) x>0);
    
    % other parameters
    p.addParamValue('backMaskSize', 150, @(x) isnumeric(x)); % dimension of the gray screen masking checkers where the targets are
    p.addParamValue('pedestal', 150, @(x) isnumeric(x));
    p.addParamValue('meanBackground', 127, @(x) x>=0 && x<=255);

    % Once it works well, change it back to the commented line
    %p.addParamValue('objDelays', 0:.1:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('objDelays', [0 .1 .3]+.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('flashObjDuration', .032, @(x) x>0); % how long will the patches be presented for (in seconds)
    p.addParamValue('backObjectsN', 1000, @(x) x>0);    % how many points per delay do you want to use to estimate the contrast.
    p.addParamValue('trialsN', 2, @(x) x>0);    % How many times to present peripheral stimulation and no peripheral stimulation. Each one of these
                                                % conditions is compossed
                                                % of trialsPerDelay *
                                                % objDelaysN
                                                
    p.addParamValue('trialsPerDelay', 2, @(x) x>0);    
    
    p.parse(varargin{:});
end

function p = ParseInput2(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    
    % other parameters
    p.addParamValue('meanBackground', .5, @(x) x>=0 && x<=255);

    % Once it works well, change it back to the commented line
    %p.addParamValue('objDelays', 0:.1:.5, @(x) size(x,1)==1 && size(x,2)>=1);   % times after the background reversal at which the objects will appear (in seconds)
    p.addParamValue('updateTime', .05, @(x) x>0);    
    p.addParamValue('peripheryDelayFs', [.6 .5 .7], @(x) size(x,1)==1 && all(x>=0));   % times after trial start where periphery will do something (will actuall do something only in saccading trials)
    p.addParamValue('flashObjDuration', .2, @(x) x>0); % how long will the patches be presented for (in seconds)
    p.addParamValue('trialsN', 2, @(x) x>0);    % How many times to present peripheral stimulation and no peripheral stimulation. Each one of these
                                                % conditions is compossed
                                                % of trialsPerDelay *
                                                % objDelaysN
                                                
    
    p.parse(varargin{:});
end
