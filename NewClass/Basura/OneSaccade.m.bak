function OneSaccade(texture, varargin)
    % Combines saccade with FEM on a given texture.
    % Texture has to be 1024 x 768 pixels
    % The idea is to record from one cell in all possible positions of the
    % texture's scanSize to infer what the population of cells might be
    % doing during the saccade. The FEM sequence as well as the saccade
    % vector are always the same.
    global screen
try
    p=ParseInput(varargin{:});

    rfSize = p.Results.rfSize;              % size in pixels of a tipical RF
    scanSize = p.Results.scanSize;          % [x y] Size of sub Image to scan (in rfSizes)
    saccadeSize = p.Results.saccadeSize;    % a number in RF units, corresponds to a latteral saccade
    pdStim = p.Results.pdStim;
    trialsN = p.Results.trialsN;
    
    [screenW screenH] = SCREEN_SIZE;
    sourceRectOri = SetRect(0,0,screenH, screenH;%SetRect(0, 0, imSize(2)-1, imSize(1)-1);
    destRect = GetRects(screenH, screen.center);
    waitframes = 2;
    vbl = 0;

    framesPerSaccade = screen.rate;
    
    % Define dest rectangles and mask rectangles
    maskRect = GetRects(screenH, screen.center);
    
    HoriShift = [1 0 1 0]*rfSize;
    VertShift = [0 1 0 1]*rfSize;

    % make a FEM sequence
    seed = 1;
    randomStream = RandStream('mcg16807', 'Seed', seed);
    FEM = randi(randomStream, 3, framesPerSaccade, 2)-2;
    FEM(framesPerSaccade, :) = - (sum(FEM) - FEM(framesPerSaccade, :));
    
    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    Screen('TextSize', screen.w, 24);
    
    for trial = 1:trialsN
        for VertIndex = 0:scanSize(2)-1
            sourceRectTemp0 = sourceRectOri + VertIndex * VertShift;
            for HoriIndex = 0:scanSize(1)-1
                horiCenter = floor(HoriIndex*saccadeSize/scanSize(1)) + ...
                    mod(HoriIndex*saccadeSize, scanSize(1));
                sourceRectTemp1 = sourceRectTemp0 + (horiCenter)*HoriShift;
                
                for frame = 0:framesPerSaccade-1
                    sourceRect = sourceRectTemp1 + FEM(frame+1);
                    
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
                    
                    % Restore alpha blending mode for next draw iteration:
                    Screen('Blendfunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    
                    % Photodiode box
                    % --------------
                    DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)
                    
                    
                    Screen('DrawText', screen.w, ['Hori step: ',num2str(horiCenter+1), '/', num2str(scanSize(1))], 20,10, screen.black);
                    Screen('DrawText', screen.w, ['Vert step: ',num2str(VertIndex+1), '/', num2str(scanSize(2))], 20,40, screen.black);
                    Screen('DrawText', screen.w, ['Trial: ',num2str(trial), '/', num2str(trialsN)], 20,70, screen.black);
                    
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
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    FinishExperiment()
catch
    CleanAfterError()
    psychrethrow(psychlasterror);
end
end


function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, contrastSeed, stimSize, objSizeH, objSizeV,
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

    % General
%    p.addParamValue('texture', [], @(x) size(x,1)==1 && size(x, 2) == 1);
    p.addParamValue('rfSize', PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('scanSize', [12 4], @(x) size(x,1)==1 && size(x, 2) == 2 && all(all(x>0)));
    p.addParamValue('saccadeSize', 3, @(x) x>0);
%    p.addParamValue('sourceRect', [0 0 767 767], @(x) length(x)==4);
    p.addParamValue('pdStim', 108, @(x) isnumeric(pdStim));
    p.addParamValue('repeatFEM', 1, @(x) x==0 || x==1);
    p.addParamValue('trialsN', 100, @(x) x>0);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end




