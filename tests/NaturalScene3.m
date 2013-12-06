function NaturalScene(texture, destRectOri, varargin)
    global screen
try
    p=ParseInput(varargin{:});

%    texture = p.Results.texture;
%    imageSize = p.Results.imageSize;        % [x y]
    rfSize = p.Results.rfSize;              % size in pixels of a tipical RF
    scanSize = p.Results.scanSize;          % [x y] Size of sub Image to scan (in rfSizes)
    saccadeSize = p.Results.saccadeSize;    % in RF units
    sourceRectOri = p.Results.sourceRect;
    pdStim = p.Results.pdStim;

    % Define dest rectangles and mask rectangles
    maskRect = GetRects(768, screen.center);
    
    saccade = [1 0 1 0]*rfSize;
    shift = [0 1 0 1]*rfSize;

    % make a FEM sequence
    seed = 1;
    randomStream = RandStream('mcg16807', 'Seed', seed);
    FEM = randi(randomStream, 3, 30, 2)-2;
    FEM(30, :) = - (sum(FEM) - FEM(30, :));

    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
    
    waitframes = 2;
    vbl = 0;

    Screen('TextSize', screen.w, 24);
    
    for shiftIndex = 0:scanSize(2)-1
        sourceRect = sourceRectOri + shiftIndex * shift;
        for saccadeIndex = 0:saccadeSize:saccadeSize*scanSize(1)-1
            horiCenter = floor(saccadeIndex/scanSize(1)) + mod(saccadeIndex, scanSize(1));
            destR1 = destRectOri + (horiCenter)*saccade;

            for frame = 0:29
                destRect = destR1 + FEM(frame+1);

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
                DisplayStimInPD2(pdStim, pd, frame, 60, screen)

            
                Screen('DrawText', screen.w, ['Hori step: ',num2str(horiCenter+1), '/', num2str(scanSize(1))], 20,10, screen.black);
                Screen('DrawText', screen.w, ['Vert step: ',num2str(shiftIndex), '/', num2str(scanSize(2))], 20,40, screen.black);
                Screen('DrawText', screen.w, ['Repeat: ',num2str(1), '/', num2str(1)], 20,70, screen.black);
                
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
    %{
    % some definitions needed for the natural scene stimuli
    objSize = 192;
    imSize = 768;
    textures = LoadAllTextures(0, '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/');
    maskTex = GetMaskTexture(imSize/2, objSize, screen, [6 12 18 24]);
    objSeed = 3;
    S1 = RandStream('mcg16807', 'Seed', objSeed);
    jitter = randi(S1, 3, 1, 60)-2;
    clear S1

    % Natural scene version of the ski doesn't dissapear. (800 secs total)
    objMode = 2;
    presentationsN = 400;
    pdStim = pdStim + 1;
    %pause(1)
    objSeed = JitterAllTextures(textures, maskTex, objSeed, ...
        presentationsN, jitter, objSize, imSize/2, objMode);


    % Natural scene version of gating with weak centers.
    %pause(1)
    pdStim = pdStim+1;
    objMode = 1;
    presentationsN = 7200;
    objSeed = JitterAllTextures(textures, maskTex, objSeed, ...
        presentationsN, jitter, objSize, imSize/2, objMode);
%} 
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
%    p.addParamValue('imageSize', [768 768], @(x) isnumeric(x) && all(all(x>0)));
%    p.addParamValue('texture', [], @(x) size(x,1)==1 && size(x, 2) == 1);
    p.addParamValue('rfSize', 16, @(x)x>0);
    p.addParamValue('scanSize', [12 4], @(x) size(x,1)==1 && size(x, 2) == 2 && all(all(x>0)));
    p.addParamValue('saccadeSize', 3, @(x) x>0);
    p.addParamValue('sourceRect', [0 0 767 767], @(x) length(x)==4);
    p.addParamValue('pdStim', 107, @(x) isnumeric(pdStim));
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end




