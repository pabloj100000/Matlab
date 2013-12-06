function ProbeEyeMovements2(varargin)
global screen vbl pd
try
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenW screenH] = SCREEN_SIZE;
    
    p.addParamValue('pdStim', 112, @(x) x>0);
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('stimSize', screenH, @(x) x>0);
    p.addParamValue('backPeriod', 2, @(x) x>0);
    p.addParamValue('presentationLength', 4, @(x) x>0);
    p.addParamValue('trialsN', PIXELS_PER_100_MICRONS, @(x) x>0);             % per contrast
    p.addParamValue('objContrasts', [.03 .06 .12 .24 1], @(x) all(x>=0 & x<=1));
    p.addParamValue('objSeed', 1, @(x) isnumeric(x));
    p.addParamValue('backTexture', [], @(x) isnumeric(x));
    p.addParamValue('repeatFEM', 1, @(x) x==0 || x==1);
    
    p.parse(varargin{:});
    

    pdStim = p.Results.pdStim;
    objSize = p.Results.objSize;
    stimSize = p.Results.stimSize;
    backPeriod = p.Results.backPeriod;
    presentationLength = p.Results.presentationLength;
    trialsN = p.Results.trialsN;
    objContrasts = p.Results.objContrasts;
    objSeed = p.Results.objSeed;
    backTexture = p.Results.backTexture;
    repeatFEM = p.Results.repeatFEM;
    
    checkerSize = 8;
    % Get background texture
    if (isempty(backTexture))
        checkersN = round(stimSize/checkerSize)+2;
        backTexture = GetCheckersTex(checkerSize*checkersN, checkerSize, 1);
    end
    
    % Define the PD
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end

    % Define rectangles to use
    objSourceRect = SetRect(0, 0, objSize, objSize);
    objDestRect = GetRects(objSize, screen.center);
    backSourceRect = SetRect(0,0,stimSize, stimSize);
    backDestRect = GetRects(stimSize, screen.center);

    % Define dest rectangles and mask rectangles
    maskRect = GetRects(stimSize, screen.center);
    offset = 0;
    
    % how many frames?
    framesN = presentationLength*screen.rate;

    % Saccades frames
    saccade1Frame = screen.rate*backPeriod/2;    
    
    
    if (repeatFEM)
        % I want each repeat of the FEM to probe all phases of the object.
        % For that, I'm going to have the jitter to start each time at a
        % different phase. I have to take into account the total offset
        % that the FEM itself introduces

        % init the random generator
        randomStream = RandStream('mcg16807', 'Seed', objSeed);

        % pull the FEM sequence to be used
        FEM = randi(randomStream, 3, 1, framesN)-2;

        % Figure out if repeating the same FEM over and over again will
        % cover all possible phases of the stimulus. If that happens just
        % leave the sequence as is, if not, fix it.
        totalShift = sum(FEM);
        leftOver = mod(checkerSize, sum(FEM));
        if (GCD(checkerSize, leftOver)==1)
            % do nothing, the sequence is good as is.
        else
            % make first step 0 for the time being
            FEM(1, 1)=0;
            FEM_Offset = sum(FEM);
            
            firstStep = 1-FEM_Offset;
            
            FEM(1, 1)=firstStep;
            sum(FEM)
        end
    end
    
    for globalRepeat=1:2
        for j=1:size(objContrasts,2)
            % Compute delta so that checkers have Michelson contrast =
            % objContrast(j)
            delta = objContrasts(j)*screen.gray;
            
            % reset randomStream so that all contrasts follow the same
            % random sequence, only necessary if not repeating the same FEM
            % over an over again
            if ~repeatFEM
                randomStream = RandStream('mcg16807', 'Seed', objSeed);
            end
            
            for trial = 1:trialsN                
                for i=0:framesN-1
                    if mod(i, saccade1Frame)==0
                        saccadeJump = checkerSize;
                    else
                        saccadeJump = 0;
                    end
                    
                    if repeatFEM
                        FEMjump = FEM(i+1);
                    else
                        FEMjump = randi(randomStream, 3, 1, 1)-2;
                    end
                    
                    offset = mod(offset+saccadeJump+FEMjump, 2*checkerSize);
                    
                    % Disable alpha-blending, restrict following drawing to alpha channel:
                    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [0 0 0 1]);
                    
                    % Clear 'dstRect' region of framebuffers alpha channel to zero:
                    Screen('FillRect', screen.w, screen.gray*[1 1 1 0], screen.rect);
                    
                    % Fill circular 'dstRect' region with an alpha value of 255:
                    Screen('FillOval', screen.w, [0 0 0 255], maskRect);
                    
                    % Enable DeSTination alpha blending and reenalbe drawing to all
                    % color channels. Following drawing commands will only draw there
                    % the alpha value in the framebuffer is greater than zero, ie., in
                    % our case, inside the circular 'dst2Rect' aperture where alpha has
                    % been set to 255 by our 'FillOval' command:
                    Screen('Blendfunction', screen.w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                    
                    Screen('DrawTexture', screen.w, backTexture{1}, backSourceRect+ offset*[1 0 1 0], backDestRect, 0, 0);
                    
                    % Start by filling the screen with values of 0 so that the sum
                    % later on works fine. Otherwise it starts summing from 127 or
                    % whatever value the screen had.
                    Screen('FillRect', screen.w, 0, objDestRect);
                    
                    % Enable alpha-blending, set it to a blend equation useable for linear
                    % superposition with alpha-weighted source. This allows to linearly
                    % superimpose gabor patches in the mathematically correct manner, should
                    % they overlap. Alpha-weighted source means: The 'globalAlpha' parameter in
                    % the 'DrawTextures' can be used to modulate the intensity of each pixel of
                    % the drawn patch before it is superimposed to the framebuffer image, ie.,
                    % it allows to specify a global per-patch contrast value:
                    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE);
                    
                    Screen('FillRect', screen.w, screen.gray-delta, objDestRect);
                    Screen('DrawTexture', screen.w, backTexture{1}, objSourceRect+ offset*[1 0 1 0], objDestRect, 0, 0, [], 2*delta);
                    
                    % Restore alpha blending mode for next draw iteration:
                    Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    
                    % Photodiode box
                    % --------------
                    DisplayStimInPD2(pdStim, pd, i, screen.rate, screen)
                    
                    vbl = Screen('Flip', screen.w, vbl + 0.5 * screen.ifi);
                    
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
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..
end
