function UFlickerObjInverted(varargin)
    % wrapper to call JitteringBackTex_UniformFieldObjTest
    %
    % There are 4 different backgrounds. Each can be turned on/off by
    % setting clearing the corresponding bit in backMode array
    % backMode(1):    repeated random jitter, lasts backJitterPeriod
    %           all presentations have the same sequence
    % backMode(2):    random jitter, lasts backJitterPeriod
    %           every presentation has a different random sequence
    % backMode(3):    reversing @backReverseFreq
    % backMode(4):    still
    %
    % There are several obj rectangles (at least 1) passed through objRect
    % (an nx4 array describing the n rectangles).
    % Each rectangle can different contrasts passed through objContrasts,
    % an n x contrastN array. Each presentation will pick the contrasts 
    % randomly for each checker. Alternatively, objContrasts can be
    % 1xcontrastsN, in that case, each presentation picks the contrast
    % randomly but the same contrast is used for all checkers in that
    % presentation.
    %
    % Also, the random sequence in each checker can be repeated if
    % repeatObjSeq is set or they can all be different. Default behaviour
    % is, 'all presentations are different'.
    %
    % Internaly, I will work on backN 'presentations' at a time. I will
    % randomly pick an order for them and after displaying them all, I will
    % start again until presentationsN 'presentations' are done

    CreateStimuliLogStart()
    global vbl screen backRect backSource objRect pd pdStim
    
    if isempty(vbl)
        vbl=0;
    end
    
    if isempty(pdStim)
        pdStim=0;
    end
    
    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    objSize = p.Results.objSize;
    objCenter = p.Results.objCenter;
    objFreq = p.Results.objFreq;
    
    backContrast = p.Results.backContrast;
    backSeed = p.Results.backSeed;
    backSize = p.Results.backSize;
    
    presentationLength = p.Results.presentationLength;
    movieDurationSecs = p.Results.movieDurationSecs;
    waitframes = p.Results.waitframes;
    
    
    % Redefine exp time to have an even number of jitters
    movieDurationSecs = presentationLength* ...
        floor(movieDurationSecs/(presentationLength));

    
try
    InitScreen(0);
              
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    framesPerSec = 60/waitframes;
    objFrames = framesPerSec/objFreq;
        
    backRect = GetRects(backSize, screen.center);
    objRect = GetRects(objSize, objCenter);

    % We run at most 'presentationsN' if user doesn't abort via
    % keypress.
    presentationsN = uint32(movieDurationSecs/presentationLength);
    
    
    framesN = uint32(presentationLength*60);
    
    stream = RandStream('mcg16807', 'Seed',backSeed);
    
    % for efficiency preallocate objSeq
    delta = objContrast*screen.gray;
    
    % Animationloop:
    for presentation = 1:presentationsN
        objIndex = 0;
        for frame = 0:waitframes:framesN-1
            % Draw the background
            
            Screen('FillRect', screen.w, screen.gray);

            % Disable alpha-blending, restrict following drawing to alpha channel:
            Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
            
            % Clear 'dstRect' region of framebuffers alpha channel to zero:
            %        Screen('FillRect', screen.w, [0 0 0 0], backRect);
            Screen('FillRect', screen.w, [0 0 0 0], screen.rect);
            
            % Fill circular 'dstRect' region with an alpha value of 255:
            Screen('FillOval', screen.w, [0 0 0 255], backRect);
            
            % Enable DeSTination alpha blending and reenalbe drawing to all
            % color channels. Following drawing commands will only draw there
            % the alpha value in the framebuffer is greater than zero, ie., in
            % our case, inside the circular 'dst2Rect' aperture where alpha has
            % been set to 255 by our 'FillOval' command:
            Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                        
            % Fill background with gray
            color = uint8((randn(stream)*backContrast+1) * screen.gray);
            Screen('FillRect', screen.w, color, backRect);

            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            if (mod(frame, objFrames)==0)
                % change obj color
                objColor = (mod(objIndex, 2)*2-1)*delta + screen.gray;
                objIndex = objIndex+1;
            end
            
            % Draw object
            Screen('FillRect', screen.w, objColor, objRect)

            % Draw PD
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)

            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    CreateStimuliLogWrite(p);
    
    
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end


function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    screenCenter = [screenX screenY]/2;

    % General
    p.addParamValue('presentationLength', 50, @(x)x>0);
    p.addParamValue('movieDurationSecs', 3*3600, @(x)x>0);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    
    % Background related
    p.addParamValue('backContrast', .03, @(x)x>=0 && x<=1);
    p.addParamValue('backSeed', 1, @(x) isnumeric(x));
    p.addParamValue('backSize', 768, @(x) x>0);
 
    % Object related
    p.addParamValue('objContrast', 1, @(x) all(all(x>=0)) && all(all(x<=1)));
    p.addParamValue('objSize', 192, @(x) x>0);
    p.addParamValue('objCenter', screenCenter, @(X) size(x,1)==1 && size(x,2)==2);
    p.addParamValue('objFreq', 2, @(x) x>0);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end






