function StableObject4(varargin)
    global screen
try
    InitScreen(0)
    Add2StimLogList();

    %%%%%%%%%%%%%% Input Parser Starts here %%%%%%%%%%%%%%%%
    p  = inputParser;   % Create an instance of the inputParser class.

    p.addParamValue('objLums', [0 127 255]);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    p.addParamValue('stimSize', 768, @(x) x>0);
    p.addParamValue('blocksN', 2, @(x) x>0);
    p.addParamValue('trialsPerBlock', 50, @(x) x>0);
    p.addParamValue('saccadeRate', 1, @(x) x>0);   % in Hz
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>0);   % in Hz
    p.addParamValue('periLum', 0, @(x) x>=0 && x<=255);
    p.addParamValue('periAlpha', 1, @(x) x>=0);

    p.parse(varargin{:});

    objLums = p.Results.objLums;
    checkersSize = p.Results.checkersSize;
    stimSize = p.Results.stimSize;
    blocksN = p.Results.blocksN;
    trialsPerBlock = p.Results.trialsPerBlock;
    saccadeRate = p.Results.saccadeRate;
    objSize = p.Results.objSize;
    periLum = p.Results.periLum;
    periAlpha = p.Results.periAlpha;
    
    %%%%%%%%%%%%%% Input Parser Ends %%%%%%%%%%%%%%%%
    % Define some variables
    
    
    % adjust stimSize to be an integer number of checkers
    stimSize = floor(stimSize/checkersSize/2)*checkersSize*2;
    if (stimSize<1.5*objSize)
        stimSize = 768;
    end
    
    % Define the rectangles
    periDestRect = SetRect(0, 0, stimSize, stimSize);
    periDestRect = CenterRect(periDestRect, screen.rect);
    periSourceRect = SetRect(0, 0, stimSize/checkersSize, stimSize/checkersSize);
    
    objDestRect = SetRect(0, 0, objSize, objSize);
    objDestRect = CenterRect(objDestRect, screen.rect);
    
    texture = GetCheckersTex(stimSize/checkersSize+1, 1);
    
    pd = DefinePD;
    
    waitFrames = 2;
    framesPerSaccade = screen.rate/saccadeRate/waitFrames;
    if (mod(framesPerSaccade,2));
        framesPerSaccade = framesPerSaccade+1;
    end
    
    for block=1:blocksN
        for i=1:length(objLums)
            objLum = objLums(i);
            for trial = 1:trialsPerBlock
                for frame=1:framesPerSaccade;
                    if (frame==1)
                        offset = [0 0 0 0];
                    elseif (frame==framesPerSaccade/2+1)
                        offset = [1 0 1 0];
                    end
                    
                    % enable alpha blending
                    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    
                    % Draw peri luminance values
                    Screen('FillRect', screen.w, periLum, periDestRect);
                    
                    % draw peri textures
                    Screen('DrawTexture', screen.w, texture{1}, periSourceRect + offset, periDestRect, 0, 0, periAlpha);
                    
                    % disable alpha blending
                    Screen('BlendFunction', screen.w, GL_ONE, GL_ZERO);
                    
                    % draw center
                    Screen('FillRect', screen.w, objLum, objDestRect);
                    
                    
                    if (frame==1)
                        pdColor = 255;
                    else
                        pdColor = 255/2;
                    end
                    
                    Screen('FillOval', screen.w, pdColor, pd);
                    screen.vbl = Screen('Flip', screen.w, screen.vbl+(waitFrames-.5)*screen.ifi);
                    
                    
                    if (KbCheck())
                        break
                    end
                end
                if (KbCheck())
                    break
                end
            end
            if (KbCheck())
                break
            end
        end
        if (KbCheck())
            break
        end
    end
    
    Screen('Close', texture{1});
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

