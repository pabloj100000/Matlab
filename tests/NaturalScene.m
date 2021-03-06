function NaturalScene(varargin)
    global screen
try
    p=ParseInput(varargin{:});

    InitScreen(0)

    % Generate texture with lines
    texture = GetBarsWithContrastsTex(48, screen, [.3 1]);
    texture = texture{1};
    % Generate the texture to work with
    imName = '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/NaturalScene.jpg';
    image = imread(imName);
 %   texture = Screen('MakeTexture', screen.w, image);

    % Define source and dest rectangles
    destRectOri = [0 0 size(image,2) size(image, 1)];
    destRectOri = CenterRectOnPoint(destRectOri, screen.center(1), screen.center(2));
    sourceRectOri = [0 0 size(image,2) size(image,1)];
    clear image
    
    % Define the horizontal saccades a vertical shift;
    rfSize = 16;            % cell's size order of magnitude in pixels
    scanSize = [12 4];       % Size of sub Image to scan (in rfSizes)

    saccadeSize = 3;        % in RF units
    shiftSize = 1;          % in RF units
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
                Screen('DrawTexture', screen.w, texture, ...
                    sourceRect, destRect, 0, 0);
                Screen('Flip', screen.w);
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

    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    
    % General
    p.addParamValue('stimSize', 768, @(x)x>0);
    p.addParamValue('presentationLength', 10, @(x)x>0);
    p.addParamValue('movieDurationSecs', 1600, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('waitframes', 1, @(x)isnumeric(x)); 
    p.addParamValue('vbl', 0, @(x)x>0);
    p.addParamValue('pdStim', 100, @(x) isnumeric(x));

    % Object related
    p.addParamValue('contrastSeed', 1, @(x) isnumeric(x));
    p.addParamValue('objContrasts', [.12 1], @(x) all(all(x>=0)) && all(all(x<=1)));
    p.addParamValue('objTexture', [], @(x) iscell(x));
    p.addParamValue('objRect', GetRects(192, [screenX screenY]/2), @(x) size(x,2)==4);
    p.addParamValue('objFreq', 10, @(x) x>0);
    p.addParamValue('objCheckerSize', 8, @(x) x>0);
    p.addParamValue('phaseSeq', [], @(x) isnumeric(x));
    
    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('backRect', GetRects(768, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backCheckerSize', 16, @(x) x>0);
    p.addParamValue('angle', 0, @(x) x>=0);
    p.addParamValue('backPattern', 0, @(x) x==0 || x==1);
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end




