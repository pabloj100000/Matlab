function NaturalScene(texture, imageSize, varargin)
    global screen
try
    p=ParseInput(varargin{:});

%    texture = p.Results.texture;
%    imageSize = p.Results.imageSize;        % [x y]
    rfSize = p.Results.rfSize;              % size in pixels of a tipical RF
    scanSize = p.Results.scanSize;          % [x y] Size of sub Image to scan (in rfSizes)
    saccadeSize = p.Results.saccadeSize;    % in RF units
    sourceRectOri = p.Results.sourceRect;

    % Define source and dest rectangles
    destRectOri = SetRect(0, 0, imageSize(2), imageSize(1));
    destRectOri = CenterRectOnPoint(destRectOri, screen.center(1), screen.center(2));
    
    saccade = [1 0 1 0]*rfSize;
    shift = [0 1 0 1]*rfSize;

    % make a FEM sequence
    seed = 1;
    randomStream = RandStream('mcg16807', 'Seed', seed);
    FEM = randi(randomStream, 3, 60, 2)-2;
    FEM(60, :) = - (sum(FEM) - FEM(60, :));

    for shiftIndex = 0:scanSize(2)-1
        sourceRect = sourceRectOri + shiftIndex * shift;
        for saccadeIndex = 0:saccadeSize:saccadeSize*scanSize(1)-1
            destR1 = destRectOri + floor(saccadeIndex/scanSize(1))*saccade + mod(saccadeIndex, scanSize(1))*saccade;
            for frame = 0:59
                destRect = destR1 + FEM(frame+1);
% {
                Screen('DrawTexture', screen.w, texture, ...
                    sourceRect, destRect, 0, 0);
                Screen('Flip', screen.w);
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
    p.addParamValue('pdStim', 100, @(x) isnumeric(x));
    p.addParamValue('rfSize', 16, @(x)x>0);
    p.addParamValue('scanSize', [12 4], @(x) size(x,1)==1 && size(x, 2) == 2 && all(all(x>0)));
    p.addParamValue('saccadeSize', 3, @(x) x>0);
    p.addParamValue('sourceRect', [0 0 767 767], @(x) length(x)==4)
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end




