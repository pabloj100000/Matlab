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

    gaborChange.sign = 1;
    % *************** End of Constants ******************

    % *************** Variables that need to be init ***********
    % Select screen with maximum id for output window:
    InitScreen()

    vbl = 0;
    abortFlag=0;

    % **********************************************************
    % Get the background checker's texture
    [backTex backDestRect] = GetRectsTex(1000);

    backTex(2) = GetMeanTex();
            
    % Initial stimulus params for the gabor patch:
    res = 1*[323 323];
    phase = 180;
    sc = 50.0;
    freq = .01;
    tilt = 0;
    contrast = 100.0;
    aspectratio = 1.0;

    % Initialize matrix with spec for 2 patches to start off
    % identically:
    mypars = repmat([phase+180, freq, sc, contrast, aspectratio, 0, 0, 0]', 1, 2);
    
    % Build a procedural gabor texture for a gabor with a support of tw x th
    % pixels, and a RGB color offset of 0.5 -- a 50% gray.
    gabortex = CreateProceduralGabor(screen.w, res(1), res(2), 1);

    testGabor(gabortex, mypars);
    
    [fixation targetRects] = PlaceFixationRect(backTex(1), gabortex, mypars);%GetRects(11, screen.center);

    % Preallocate array with destination rectangles:
    % This also defines initial gabor patch orientations, scales and location
    % for the very first drawn stimulus frame:
    texrect = Screen('Rect', gabortex);
    inrect = repmat(texrect', 1, 2);
    
    dstRects = repmat(CenterRectOnPoint(texrect, screen.center(1), screen.center(2))', 1, 2);
    
    % Preallocate array with rotation angles:
    rotAngles = zeros(1, 2);
        
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
            WaitForUserToAdjust(backTex(condition), fixation, targetRects);
 
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
%                    if (condition==1)
%                        Screen('DrawTexture', screen.w, backTex);
%                    else
                        Screen('DrawTexture', screen.w, backTex(condition), [], screen.rect, [], 0);
%                    end
                                                            
                    % changin alpha blending to overwrite.
                    Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);

                    % Draw masks behind gabors
                    Screen('FillOval', screen.w, 127, targetRects);

                    % Enable alpha blending again
                    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE);
                    
                    
                    % show targets only for flashObjFrames
                    if (objDelayFrame < frame && frame < objDelayFrame+flashObjFrames)
                        Screen('DrawTextures', screen.w, gabortex, [], targetRects, [], [], [], [], [], kPsychDontDoRotation, mypars);
                    end
                    
                    % show the fixational spot
                    Screen('FillOval', screen.w, fixation.color, fixation.rect);

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
                            % Contrast higher on the LEFT and got it right?
                        elseif ((keyCode(keys.RIGHT) ||keyCode(keys.RIGHT_SHIFT)) && higestPatch==RIGHT) || ...
                                (keyCode(keys.DOWN) && higestPatch==RIGHT) || ...
                                (keyCode(keys.UP) && higestPatch==LEFT) || ...
                                ((keyCode(keys.LEFT) || keyCode(keys.LEFT_SHIFT)) && higestPatch==LEFT)
                            % got the contrast right
                            % Update the pdf
                            answer = 'Right';
                            q(condition)=QuestUpdate(q(condition),tTest(pedestalPatch), true); % Add the new datum (actual test intensity and observer response) to the database.
                            break
                        elseif ((keyCode(keys.RIGHT) || keyCode(keys.RIGHT_SHIFT)) && higestPatch==LEFT) || ...
                                ((keyCode(keys.LEFT) || keyCode(keys.LEFT_SHIFT)) && higestPatch==RIGHT) ||...
                                (keyCode(keys.DOWN) && higestPatch==LEFT) || ...
                                (keyCode(keys.UP) && higestPatch==RIGHT)
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
    clear all
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function WaitForUserToAdjust(backTex, fixation, targetRects)
    global screen

    Screen('DrawTexture', screen.w, backTex,[],screen.rect, [],0);
    % changin alpha blending to overwrite.
    Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
    
    % Draw masks behind gabors
    Screen('FillOval', screen.w, 127, targetRects);
    
    % Enable alpha blending again
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE);

    Screen('FillOVal', screen.w, fixation.color, fixation.rect);
    Screen('Flip', screen.w);
    
    k = GetKeys();
    while 1
        [keyisdown, ~, keyCode, ~] = KbCheck;
        if keyisdown && (keyCode(k.RIGHT_SHIFT) || keyCode(k.ESCAPE))
            break
        end
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
                                                
    p.addParamValue('trialsPerDelay', 2, @(x) x>0);    
    p.addParamValue('updatePlot', 0, @(x) x==0||x==1);    
    
    p.parse(varargin{:});
end

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
    Screen('FillRect', screen.w, 1);
    Screen('Flip', screen.w)
    pause(1)
%    Screen('Flip', screen.w)
%    Screen('FillRect', screen.w, 127);
    Screen('Flip', screen.w)
    
    phase = 0;
    freq = .05;
    sc = 10.0;
    contrast = 100.0;
    aspectratio = 1.0;
    
    Screen('FillRect', screen.w, .0);
    Screen('DrawTexture', screen.w, gabortex, [], [], [], [], [], [], [], kPsychDontDoRotation,[phase, freq, sc, contrast, aspectratio, 0, 0, 0]);
    Screen('Flip', screen.w)
    pause(1)
end

function [fixation targetRects] = PlaceFixationRect(backTex, gaborTex, mypars)
    global screen 

    k = GetKeys();
    
    targetRects = Screen('Rect', gaborTex);
    targetRects = CenterRectOnPoint(targetRects, screen.center(1), screen.center(2))';
    targetRects(:,2) = targetRects(:,1);

    fixation.rect = GetRects(10, screen.center);
    
    if screen.backColor==.5
        fixation.color = 0;
    else
        fixation.color = 1-screen.backColor;
    end

    while 1
        [keyIsDown, ~, keyCode, ~] = KbCheck;
        if keyIsDown
            if keyCode(k.ESCAPE) || keyCode(k.RIGHT_SHIFT)
                break
            elseif keyCode(k.UP) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT)
                % change center of mass in the up direction
                targetRects = targetRects + [0 1 0 1]'*[1 1];
            elseif keyCode(k.DOWN) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT)
                % change center of mass in down
                targetRects = targetRects - [0 1 0 1]'*[1 1];
            elseif keyCode(k.RIGHT) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT)
                % change center of mass in right
                targetRects = targetRects - [1 0 1 0]'*[1 1];
            elseif keyCode(k.LEFT) && ~keyCode(k.LEFT_SHIFT) && ~keyCode(k.LEFT_ALT)
                % change center of mass in left
                targetRects = targetRects + [1 0 1 0]'*[1 1];
                
            % If shift is pressed, change relative positioning of targets
            elseif keyCode(k.UP) && keyCode(k.LEFT_SHIFT)
                % change center of mass in the up direction
                if targetRects(1,2)<targetRects(2,2)
                    targetRects = targetRects + [0 1 0 1]'*[1 -1];
                end
            elseif keyCode(k.DOWN) && keyCode(k.LEFT_SHIFT)
                % change center of mass in down
                targetRects = targetRects + [0 1 0 1]'*[-1 1];
            elseif keyCode(k.RIGHT) && keyCode(k.LEFT_SHIFT)
                % change center of mass in right
                if targetRects(1,1)>targetRects(2,1)
                    targetRects = targetRects + [1 0 1 0]'*[-1 1];
                end
            elseif keyCode(k.LEFT) && keyCode(k.LEFT_SHIFT)
                % change center of mass in left
                targetRects = targetRects + [1 0 1 0]'*[1 -1];
            
            % If Ctrl is pressed, change fixation point
            elseif keyCode(k.UP) && keyCode(k.LEFT_ALT)
                % change center of mass in the up direction
                fixation.rect = fixation.rect+[0 1 0 1];
            elseif keyCode(k.DOWN) && keyCode(k.LEFT_ALT)
                % change center of mass in down
                fixation.rect = fixation.rect-[0 1 0 1];
            elseif keyCode(k.RIGHT) && keyCode(k.LEFT_ALT)
                % change center of mass in right
                fixation.rect = fixation.rect-[1 0 1 0];
            elseif keyCode(k.LEFT) && keyCode(k.LEFT_ALT)
                % change center of mass in left
                fixation.rect = fixation.rect+[1 0 1 0];
            end
        end
        Screen('FillRect', screen.w, screen.backColor);
        Screen('DrawTexture', screen.w, backTex);

        % changin alpha blending to overwrite.
        Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
        
        % Draw masks behind gabors
        Screen('FillOval', screen.w, .5, targetRects);
        
        % Enable alpha blending again
        Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE);

        Screen('DrawTextures', screen.w, gaborTex, [], targetRects, [], [], [], [], [], kPsychDontDoRotation, mypars);
        Screen('FillOVal', screen.w, fixation.color, fixation.rect);
        Screen('Flip', screen.w);    
    end
end

function [tex rect]= GetRectsTex(boxesN)
    global screen
    
    array = .5*ones(screen.rect(4), screen.rect(3));

    maximumSize = 100;
    if screen.backColor<.5
        colorRange = screen.backColor;
    else
        colorRange = 1-screen.backColor;
    end
% {    
    for i=1:boxesN
        left = randi(screen.rect(4)-1);
        top = randi(screen.rect(3)-1);
        right = randi(min(screen.rect(4)-left, maximumSize))+left;
        bottom = randi(min(screen.rect(3)-top, maximumSize))+top;
        array(left:right, top:bottom) = rand();%color;
    end
    
    tex = Screen('MakeTexture', screen.w, array, [], [], 2);
%    Screen('DrawTexture', screen.w, tex, [], [], [], 0)
%    Screen('Flip', screen.w);
%    pause(1)
    rect = Screen('Rect', tex)';
end

function tex = GetLinesTex(linesN)
    % doesn't work, fix it latter.
    
    global screen
    
    array = ones(screen.rect(3), screen.rect(4));
    width = 10;

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
                left = randi(screen.rect(3));
                bottom = screen.rect(4);
            case 2
                % start at left of screen
                left = 1;
                bottom = randi(screen.rect(4));
            case 3
                % start at top of screen
                left = randi(screen.rect(3));
                bottom = 1;
            case 4
                % start at right of screen
                left = screen.rect(3);
                bottom = randi(screen.rect(3));
        end

        switch (edge2)
            case 1
                % start at bottom of screen
                right = randi(screen.rect(3));
                top = screen.rect(4);
            case 2
                % start at left of screen
                right = 1;
                top = randi(screen.rect(4));
            case 3
                % start at top of screen
                right = randi(screen.rect(3));
                top = 1;
            case 4
                % start at right of screen
                right = screen.rect(3);
                top = randi(screen.rect(3));
        end
        
        color = randi(2*colorRange+1)-colorRange+screen.backColor;
        array(left:right, top:bottom)=color;
    end
    tex = Screen('MakeTexture', screen.w, array);
    Screen('DrawTexture', screen.w, tex);
    Screen('Flip', screen.w)
    pause(3)
end


function k = GetKeys()
    KbName('UnifyKeyNames');
    k.ESCAPE = KbName('escape');
    k.RIGHT = KbName('RightArrow');
    k.LEFT = KbName('LeftArrow');
    k.UP = KbName('UpArrow');
    k.DOWN = KbName('DownArrow');
    k.LEFT_SHIFT = KbName('LeftShift');
    k.RIGHT_SHIFT = KbName('RightShift');
    k.LEFT_ALT = KbName('LeftAlt');
end

function meantex = GetMeanTex()
    global screen
%    array = ones(screen.rect(4), screen.rect(3))*screen.backColor;
    array = screen.backColor;
    meantex = Screen('MakeTexture', screen.w, array, [], [], 2);
end

function InitScreen()
    global screen
    
    % Get the list of screens and choose the one with the highest screen number.
	% Screen 0 is, by definition, the display with the menu bar. Often when 
	% two monitors are connected the one without the menu bar is used as 
	% the stimulus display.  Chosing the display with the highest dislay number is 
	% a best guess about where you want the stimulus displayed.  
	screenNumber=max(Screen('Screens'));
    
    % Open a double-buffered fullscreen window with a gray (intensity =
    % 0.5) background and support for 16- or 32 bpc floating point framebuffers.
    PsychImaging('PrepareConfiguration');

    lrect = [];
    rrect = [];
    
    % This will try to get 32 bpc float precision if the hardware supports
    % simultaneous use of 32 bpc float and alpha-blending. Otherwise it
    % will use a 16 bpc floating point framebuffer for drawing and
    % alpha-blending, but a 32 bpc buffer for gamma correction and final
    % display. The effective stimulus precision is reduced from 23 bits to
    % about 11 bits when a 16 bpc float buffer must be used instead of a 32
    % bpc float buffer:
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

    % normalize colors between 0 and 1
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange')

    % Finally open a window according to the specs given with above
    % PsychImaging calls, clear it to a background color of 0.5 aka 50%
    % luminance:
    [screen.w, screen.rect]=PsychImaging('OpenWindow',screenNumber, .5, lrect);
    screen.backColor = 0.5;

    
    % From here on, all color values should be specified in the range 0.0
    % to 1.0 for displayable luminance values. Values outside that range
    % are allowed as intermediate results, but the final stimulus image
    % should be in range 0-1, otherwise result will be undefined.
    
    [screen.rect(3) screen.rect(4)]=Screen('WindowSize', screen.w);
    screen.center = [screen.rect(3) screen.rect(4)]/2;

    % Enable alpha blending. We switch it into additive mode which takes
    % source alpha into account:
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE);

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

    screen.center = [screen.rect(3) screen.rect(4)]/2;
    screen.ifi = Screen('GetFlipInterval', screen.w);
    
    % Show the gray background:
    screen.vbl = Screen('Flip', screen.w);
end
