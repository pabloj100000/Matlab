function UFlickerPsychophysics(varargin)
global screen

try
    p  = inputParser;   % Create an instance of the inputParser class.

    delta = 200;
    p.addParamValue('pdStim', 111, @(x) x>0);
    p.addParamValue('stimSize', 768, @(x) x>0);
    p.addParamValue('objSize', 80, @(x) x>0);
    p.addParamValue('backPeriod', 2, @(x) x>0);
    p.addParamValue('presentationLength', 200, @(x) x>0);
    p.addParamValue('objContrast', .06, @(x) all(x>=0 & x<=1));
    p.addParamValue('objMean', 127, @(x) x>=0 & x<=255);
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('backTexture', [], @(x) isnumeric(x));
    p.addParamValue('borders', [0:2/32:9/32 10/32:1/32:20/32], @(x) size(x,1)==1 && size(x,2)>0);
    p.addParamValue('leftCenter', [512-delta 384], @(x) dimsize(x,1)==1 && size(x,2)==2);
    p.addParamValue('rightCenter', [512+delta 384], @(x) dimsize(x,1)==1 && size(x,2)==2);
    p.addParamValue('backMaskSize', 500, @(x) x>0);
    p.addParamValue('deltaX', 120, @(x) x>0);
    
    p.parse(varargin{:});
    

    pdStim = p.Results.pdStim;
    stimSize = p.Results.stimSize;
    objSize = p.Results.objSize;
    backPeriod = p.Results.backPeriod;
    presentationLength = p.Results.presentationLength;
    objContrast = p.Results.objContrast;
    objMean = p.Results.objMean;
    objSeed = p.Results.objSeed;
    backTexture = p.Results.backTexture;
    borders = p.Results.borders;
    leftCenter = p.Results.leftCenter;
    rightCenter = p.Results.rightCenter;
    backMaskSize = p.Results.backMaskSize;
    deltaX = p.Results.deltaX;
    
    % *************** Constants ******************
    SPACEBAR = KbName('space');
    ESCAPE = KbName('escape');
    LEFTARROW = KbName('LeftArrow');
    UPARROW = KbName('UpArrow');
    RIGHTARROW = KbName('RightArrow');
    DOWNARROW = KbName('DownArrow');
    CHECKERSIZE = 8;
    % *************** End of Constants ******************
    % *************** Variables that need to be init ***********
    vbl = 0;
    abortFlag=0;
    shift = 0;
    % **********************************************************
    % Get the background checker's texture
    checkersN = stimSize/CHECKERSIZE;
    temp =  GetCheckersTex(checkersN+1, 1, 1);
    backTexture = temp{1};
    clear temp;
    
    % Get the object texture
    barsN = 10;
    barsSize = 8;
    temp = GetBarsTex(barsN, 1, 1);
    objTexture = temp{1};
    clear temp;
    
    % Make all necessary rectangles
    leftMask = GetRects(objSize, screen.center-[deltaX 0]);
    rightMask = GetRects(objSize, screen.center+[deltaX 0]);
    objSource = SetRect(0, 0, barsN, 1);
    
    backSource = SetRect(0, 0, checkersN, checkersN);
    backDest = GetRects(stimSize, screen.center);

    backMask = GetRects(backMaskSize, screen.center);

    length = 11;
    fixationRect1 = SetRect(0,0, length, 1);
    fixationRect2 = SetRect(0, 0, 1, length);
    fixationRect1 = CenterRectOnPoint(fixationRect1, screen.center(1), screen.center(2));
    fixationRect2 = CenterRectOnPoint(fixationRect2, screen.center(1), screen.center(2));
    
    framesN = backPeriod*60;
    % Get the grating 

    % Init random stream
    stream1 = RandStream('mcg16807', 'Seed', objSeed);

    while 1
        angle = (randi(stream1, 2, 1, 2)-1)*90;       % angle1, contrast1, angle2, contrast2
        contrast = randi(stream1, 2, 1, 2);       % angle1, contrast1, angle2, contrast2

        for frame = 0:framesN-1
            if (frame==60)
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
            %  ********* display right and left objects using
            %  alpha-blending *************            
            % Disable alpha-blending, restrict following drawing to alpha channel:
            Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
            % Clear 'dstRect' region of framebuffers alpha channel to zero:
            %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
            Screen('FillRect', screen.w, [0 0 0 0], leftMask);
            Screen('FillOval', screen.w, [0 0 0 0], rightMask);
            
            % Fill circular 'dstRect' region with an alpha value of 255:
            Screen('FillOval', screen.w, [0 0 0 255], leftMask);
            Screen('FillOval', screen.w, [0 0 0 255], rightMask);
            
            % Enable DeSTination alpha blending and reenalbe drawing to all
            % color channels. Following drawing commands will only draw there
            % the alpha value in the framebuffer is greater than zero, ie., in
            % our case, inside the circular 'dst2Rect' aperture where alpha has
            % been set to 255 by our 'FillOval' command:
            Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
            
            Screen('DrawTexture', screen.w, objTexture, objSource, leftMask, angle(1), 0);
            Screen('DrawTexture', screen.w, objTexture, objSource, rightMask, angle(2), 0);
            
            
            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            
%}
            vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
            
        end
        
        while 1
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if (keyIsDown)
                if keyCode(ESCAPE)
                    abortFlag=1;
                    break
                elseif keyCode(UPARROW)
                    'UP Arrow'
                    break
                elseif keyCode(LEFTARROW)
                    'left arrow'
                    break
                end
            end
        end
        if (abortFlag)
            break
        end
    end

     
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..
end
