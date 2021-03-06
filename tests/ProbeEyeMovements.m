function ProbeEyeMovements()
    % This is a wrapper function to call EyeMovements (below in this file).
    % EyeMovements will combine Saccades with FEM on a given texture to 
    % see if I obtain gating effects.
    % As of 08-15-11, each call to EyeMovements will span 200 1second
    % trials with 4 saccade positions at a given contrast and spatial
    % frequency.
    % The call to EyeMovements is inside 3 loops, 1st one changes contrast,
    % 2nd one changes spatial frequency and last one repeats everything
    % twice.
    % All combinations of contrast and spatial frequency last
    % 4*4*200s = 3200s and the whole experiment lasts 6400s

    % Texture's size passed to EyeMovements has to be 1024 by 768.
    % Along with the texture, you need to pass an array with as many
    % saccade positions as wanted ('saccade', with size = (2 n))
    % It will jump from one saccade position to the next one in random
    % order, Saccading into the same position is not allowed. 
    % FEM can be always the same sequence or a different one every time
    % depending on repeatFEM value (defaults to 0)
    
    global screen
    InitScreen(0);

    for trial=1:2
        for i=0:3
            spatialPeriod = 16*2^i;
            saccade = spatialPeriod/4*[0 1 2 3; 0 0 0 0];
            for j=0:3
                contrast = .03*2^j;
                checkers = GetCheckers(1024, 768, spatialPeriod/2, contrast, screen.gray);
                tex = Screen('MakeTexture', screen.w, checkers);
                EyeMovements(tex, 'saccade', saccade, 'presentationsN', 200)    % 200 presentations, about 50 trials of each of the 4 phases.
                Screen('Close', tex)
                pause(.2)
                
                if (KbCheck)
                    break
                end
            end
            if (KbCheck)
                break
            end
        end
    end
    
    FinishExperiment();
end

function EyeMovements(texture, varargin)

    global screen
    p=ParseInput(varargin{:});

    saccade = p.Results.saccade;    % in RF units
    pdStim = p.Results.pdStim;
    repeatFEM = p.Results.repeatFEM;
    presentationsN = p.Results.presentationsN;
%    sourceRectOri = p.Results.sourceRect;
%    destRect = p.Results.destRect;
    sourceRectOri = SetRect(0, 0, 1023, 767);
    destRect = SetRect(0, 0, 1023, 767);
    waitframes = 2;
    vbl = 0;

    framesPerSaccade = 60/waitframes;

    % Define dest rectangles and mask rectangles
    maskRect = GetRects(768, screen.center);
    
    % init FEM sequence
    seed = 1;
    randomFEMStream = RandStream('mcg16807', 'Seed', seed);
    if (repeatFEM)
        FEM = randi(randomFEMStream, 3, framesPerSaccade, 2)-2;
        FEM(framesPerSaccade, :) = - (sum(FEM) - FEM(framesPerSaccade, :));
    else
        FEM = ones(1, framesPerSaccade);
    end

    % init Saccades
    oldSaccadeIndex = 0;
    currentSaccadeIndex = 0;
    randomSaccadeStream = RandStream('mcg16807', 'Seed', seed);

    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end    

    Screen('TextSize', screen.w, 24);
    
    for presentation = 1:presentationsN
        % chose the new saccade position randomly.
        while (oldSaccadeIndex == currentSaccadeIndex)
            currentSaccadeIndex = randi(randomSaccadeStream, size(saccade,2), 1);
        end
        oldSaccadeIndex = currentSaccadeIndex;      % once it gets out of the while loop,
                                                    % make them equal again
                                                    % for next presentation
        
        sourceRect0 = sourceRectOri + [saccade(:, currentSaccadeIndex)' saccade(:, currentSaccadeIndex)'];
        if (~repeatFEM)
            FEM = randi(randomFEMStream, 3, framesPerSaccade, 2)-2;
            FEM(framesPerSaccade, :) = - (sum(FEM) - FEM(framesPerSaccade, :));
        end
        
        for frame = 0:framesPerSaccade-1
            sourceRect = sourceRect0 + FEM(frame+1);
            
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
            
            % Draw texture, but only inside alpha == 255 circular
            % aperture
            Screen('DrawTexture', screen.w, texture, ...
                sourceRect, destRect, 0, 0);

            % Draw all crossHairs
            DrawCrossHairs(saccade + screen.center'*ones(1, size(saccade,2)))
            
            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            % Photodiode box
            % --------------
            DisplayStimInPD2(pdStim, pd, frame, 60, screen)
            
            
%{
            Screen('DrawText', screen.w, ['Hori step: ',num2str(horiCenter+1), '/', num2str(scanSize(1))], 20,10, screen.black);
            Screen('DrawText', screen.w, ['Vert step: ',num2str(shiftIndex), '/', num2str(scanSize(2))], 20,40, screen.black);
            Screen('DrawText', screen.w, ['Repeat: ',num2str(1), '/', num2str(1)], 20,70, screen.black);
%}            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
            %}
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
end


function p =  ParseInput(varargin)
% Generates a structure with all the parameters

    p  = inputParser;   % Create an instance of the inputParser class.

%    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
%    center = [screenX screenY]/2;

    % General
    %p.addParamValue('sourceRect', [0 0 1023 767], @(x) length(x)==4);
    %p.addParamValue('destRect', [0 0 1023 767], @(x) length(x)==4);
    p.addParamValue('saccade', [0 16 -16; 0 0 0], @(x) isnumeric(x) && size(x,1)==2);
    p.addParamValue('pdStim', 107, @(x) isnumeric(pdStim));
    p.addParamValue('repeatFEM', 0, @(x) x==0 || x==1);
    p.addParamValue('presentationsN', 1000, @(x) isnumeric(x));

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end



