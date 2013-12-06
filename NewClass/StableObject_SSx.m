function StableObject_SSx(varargin)
    global screen
    
    p=ParseInput(varargin{:});

    objColors = p.Results.objColors;
    objRect = p.Results.rects;

    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backAngle = p.Results.angle;
    backTex = p.Results.backTexture;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    vbl=0;
try
    
    InitScreen(0);
    Add2StimLogList();
    
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
    backDestIndex = 0;
    
    % Define the PD box
    pd = DefinePD();

    updateRate = screen.rate/waitframes;
    updateTime = 1/updateRate-1/screen.rate/2;
    backFramesOri = fix(updateRate/backReverseFreq/2);
    % if saccadding it might be necessary to change the presentation
    % Length to have an even number of backFrames
    presentationFrames = 2*backFramesOri*fix(updateRate*presentationLength/backFramesOri/2);
    presentationsN = 2;
    
    % Animationloop:
    for presentation = 1:presentationsN
        for colorIndex = 1:4
            color = objColors(colorIndex);
            for background = 1:2
                if mod(background, 2)==1
                    backFrames = inf;
                    pdFlag = 1;
                    backDest = backDestOri+backDestIndex*barsWidth*[1 0 1 0];
                    backDestIndex = mod(backDestIndex+1,2);
                else
                    backFrames = backFramesOri;
                end
                
                for frame=0:presentationFrames-1
                    if (mod(frame, 2*backFrames)==0)
                        % reverse background
                        backDest = backDestOri+backDestIndex*barsWidth*[1 0 1 0];
                        backDestIndex = mod(backDestIndex+1,2);
                        pdFlag = 1;
                    elseif (mod(frame, 2*backFrames)==backFrames-1)
                        backDest = backDestOri+backDestIndex*barsWidth*[1 0 1 0];
                        backDestIndex = mod(backDestIndex+1,2);
                        pdFlag = 1;
                    end
                    
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
                    Screen('FillRect', screen.w, color, objRect);
                    
                    % Photodiode box
                    % --------------
                    if (pdFlag)
                        Screen('FillOval', screen.w, screen.white, pd);
                        pdFlag=0;
                    end
                    
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

    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = SCREEN_SIZE;
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);
    
    % Object related
    p.addParamValue('objSeeds', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objColors', [0 64 128 255], @(x) all(all(x>=0)) && all(all(x<=255)));
    p.addParamValue('objMean', 127, @(x) all(all(x>=0)) && all(all(x<=255)));
    p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);
    
    % Background related
    p.addParamValue('backSeed', 2, @(x)isnumeric(x));
    p.addParamValue('backMode', [0 0 1 0], @(x) size(x,1)==1 && size(x,2)==4);
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('backDest', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backPattern', 1, @(x) x==0 || x==1);
    p.addParamValue('angle', 0, @(x) isnumeric(x));
    
    % General
    p.addParamValue('stimSize', PIXELS_PER_100_MICRONS*42, @(x)x>0);
    p.addParamValue('presentationLength', 60, @(x)x>0);
    p.addParamValue('movieDurationSecs', 60*3*2, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(Screen('NominalFrameRate', max(Screen('Screens')))/30), @(x)isnumeric(x)); 
    p.addParamValue('pdStim', 3, @(x) isnumeric(x));
        

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

