function StableObject_xxF(objColor, varargin)
    global screen
    
try
    InitScreen(0);
    Add2StimLogList();

    p=ParseInput(varargin{:});

    objRect = p.Results.rects;

    backContrast = p.Results.backContrast;
    backFreq = p.Results.backFreq;        % Freq for sequence repetition.

    backAngle = p.Results.angle;
    backTex = p.Results.backTexture;
    backSource = p.Results.backSource;
    backSeed = p.Results.backSeed;
    backStep = p.Results.backStep;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    vbl=0;
    
    
    % make the background texture
    if (isempty(backTex))
        clearBackTexFlag = 1;
        backTex = GetCheckersTex(stimSize/barsWidth, 1, backContrast);
        backSource = SetRect(0, 0, stimSize/barsWidth, stimSize/barsWidth);
    else
        clearBackTexFlag = 0;
    end
    
    % Define the background Destination Rectangle
    backDestOri = SetRect(0,0,stimSize, stimSize);
    backDestOri = CenterRect(backDestOri, screen.rect);
    
    % Define the PD box
    pd = DefinePD();

    updateRate = screen.rate/waitframes;
    updateTime = 1/updateRate-1/screen.rate/2;
    backFrames = fix(updateRate/backFreq);
    % if saccadding it might be necessary to change the presentation
    % Length to have an even number of backFrames
    presentationsN = presentationLength*backFreq;
    
    % Animationloop:
    for presentation = 1:presentationsN
        for frame=0:backFrames-1
            if (mod(frame, backFrames)==0)
                % reverse background
                S = RandStream('mcg16807', 'Seed', backSeed);
                backDest = backDestOri;
                pdFlag = 1;
            end
            backDest = backDest + backStep*(randi(S, 2)-1.5)*2*[1 0 1 0];
            Screen('FillRect', screen.w, screen.gray, screen.rect);
            
            % Disable alpha-blending, restrict following drawing to alpha channel:
            Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
            
            % Clear 'dstRect' region of framebuffers alpha channel to zero:
            %        Screen('FillRect', screen.w, [0 0 0 0], backDest);
            Screen('FillRect', screen.w, [0 0 0 0], screen.rect);
            
            % Fill circular 'dstRect' region with an alpha value of 255:
            Screen('FillOval', screen.w, [0 0 0 255], backDest);
            
            % Enable DeSTination alpha blending and reenalbe drawing to all
            % color channels. Following drawing commands will only draw there
            % the alpha value in the framebuffer is greater than zero, ie., in
            % our case, inside the circular 'dst2Rect' aperture where alpha has
            % been set to 255 by our 'FillOval' command:
            Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
            
            % Draw 2nd grating texture, but only inside alpha == 255 circular
            % aperture, and at an angle of 90 degrees:
            Screen('DrawTexture', screen.w, backTex{1}, backSource, backDest, backAngle,0)
            
            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            
            % Object Drawing
            % --------------
            Screen('FillRect', screen.w, objColor, objRect);
            
            % Photodiode box
            % --------------
            if (pdFlag)
                Screen('FillOval', screen.w, screen.white, pd);
                pdFlag=0;
            end
            
%            Screen('DrawText', screen.w, ['Presentation = ', num2str(presentation)], ...
%                40, 40);
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + updateTime , 1);
            
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (clearBackTexFlag)
        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', backTex{1});
    end
        
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    % In order to get a parameter back just use
    %   p.Resulst.parameter
    % In order to display all the parameters use
    %   disp 'List of all arguments:'
    %   disp(p.Results)
    %
    % General format to add inputs is...
    % p.addRequired('script', @ischar);
    % p.addOptional('format', 'html', ...
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);
    global screen
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = SCREEN_SIZE;
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);
    
    % Object related
    p.addParamValue('objSeeds', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objColor', 0, @(x) x>=0 && x<=255);
    p.addParamValue('objMean', 127, @(x) all(all(x>=0)) && all(all(x<=255)));
    p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);
    
    % Background related
    p.addParamValue('backSeed', 2, @(x)isnumeric(x));
    p.addParamValue('backMode', [0 0 1 0], @(x) size(x,1)==1 && size(x,2)==4);
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backFreq', .5, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('backSource', [], @(x) isnumeric(x));
    p.addParamValue('backDest', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backPattern', 1, @(x) x==0 || x==1);
    p.addParamValue('backStep', round(PIXELS_PER_100_MICRONS/10), @(x) isnumeric(x));
    p.addParamValue('angle', 0, @(x) isnumeric(x));
    
    % General
    p.addParamValue('stimSize', PIXELS_PER_100_MICRONS*42, @(x)x>0);
    p.addParamValue('presentationLength', 60, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(screen.rate/30), @(x)isnumeric(x)); 
    p.addParamValue('pdStim', 3, @(x) isnumeric(x));
        

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

