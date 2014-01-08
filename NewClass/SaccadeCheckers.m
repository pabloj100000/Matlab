function SaccadeCheckers(varargin)
global screen
try    

    p=ParseInput(varargin{:});
    Add2StimLogList;
    
    presentationLength = p.Results.presentationLength;
    backReverseFreq = p.Results.backReverseFreq;
    waitframes = p.Results.waitframes;
    seed = p.Results.seed;
    rwStepSize = p.Results.rwStepSize;
    saccadeSize = p.Results.saccadeSize;
    objSize = p.Results.objSize;
    checkersSize = p.Results.checkersSize;
    pdMode = p.Results.pdMode;
    repeatFEM = p.Results.repeatFEM;
    
    objIndex = p.Results.objIndex;
    objMax = p.Results.objMax;
    objMin = p.Results.objMin;
    periIndex = p.Results.periIndex;
    periMax = p.Results.periMax;
    periMin = p.Results.periMin;
    
    InitScreen(0);

    % Generate the textures.
    folder = '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/'; % my laptop's path
    if (~isdir(folder))
        folder = '/Users/baccuslab/Desktop/stimuli/Pablo/Images/'; % D239 stimulus desktop's path
    end
    
    % generate 2 arrays, one for the center, one for the periphery. Then
    % I'm going to combine both arrays into just one and generate a single
    % texture out of them.
    if (periIndex >=0)
        peripheryIm = imread([folder, 'image', num2str(periIndex),'.jpg']);
    else
        checkersN = 32*PIXELS_PER_100_MICRONS/checkersSize;
        peripheryIm = GetCheckers(checkersN, checkersN, checkersSize);
    end
    peripheryIm = adjustLuminance(peripheryIm, periMin, periMax);
    
    if (objIndex >=0)
        objIm = imread([folder, 'image', num2str(objIndex),'.jpg']);
    else
        checkersN = 32*PIXELS_PER_100_MICRONS/checkersSize;
        objIm = GetCheckers(checkersN, checkersN, checkersSize);
    end
    objIm = adjustLuminance(objIm, objMin, objMax);

    % mix both peripheryIm and objIm
    im = MixArrays(objIm, peripheryIm, objSize, saccadeSize);
    
    texture = Screen('makeTexture', screen.w, im);
    
    destRect = SetRect(0, 0, size(peripheryIm, 1), size(peripheryIm,2));
    destRect = CenterRect(destRect, screen.rect);

    clear im objIm peripheryIm;

    backFrames = round(screen.rate/backReverseFreq/2/waitframes/2)*2;
    framesN = round(presentationLength*screen.rate/waitframes);
    framesN = round(framesN/backFrames)*backFrames;

    % init random seed generator
    randStream = RandStream('mcg16807', 'Seed', seed);

    pd = DefinePD;
    if (pdMode==1)
        pdWhiteFrame = 2*backFrames;
    else
        pdWhiteFrame = framesN;
    end
    
    offset = saccadeSize/2;

    for frame=0:framesN-1
        if (mod(frame, 2*backFrames)==0)
            offset = saccadeSize/2;
        elseif (mod(frame, backFrames)==0)
            offset = -saccadeSize/2;
        end
        
        if (repeatFEM && mod(frame, 2*backFrames)==0)
            randStream.reset;
        end
        
        step = (randi(randStream, 2)-1.5)*rwStepSize;
        offset = offset + step;
        
        % display last texture
        Screen('DrawTexture', screen.w, texture, [], destRect + offset*[1 0 1 0], 0, 0);
        

        if (mod(frame, pdWhiteFrame)==0)
            color=255;
        else
            color = screen.gray + 20*step;
        end
        
        Screen('FillOval', screen.w, color, pd);
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes-.5) * screen.ifi);

        if (KbCheck)
            break
        end
    end

    % We have to discard the noise checkTexture.
    Screen('Close', texture);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

function array = GetCheckers(checkersX, checkersY, checkersSize)
    [x, y] = meshgrid(1:checkersX*checkersSize, 1:checkersY*checkersSize);
    
    array = mod(floor(x/checkersSize) + floor(y/checkersSize),2)*255;    
end

function newImage = MixArrays(obj, peri, objSize, saccadeSize)
    center = size(peri)/2;
    newImage = peri;
    startX = center(1)-objSize/2-saccadeSize/2;
    endX = center(1)+objSize/2+saccadeSize/2;
    startY = center(2) - objSize/2;
    endY = center(2) + objSize/2;
    newImage(startX:endX, startY:endY) = obj(startX:endX, startY:endY);
end

function Im = adjustLuminance(Im, v_min, v_max)
    Im = double(Im);
    oldMax = max(Im(:));
    oldMin = min(Im(:));
    Im = (Im-oldMin)*(v_max-v_min)/(oldMax-oldMin) + v_min;
    Im = uint8(Im);
end

function p =  ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    frameRate = Screen('NominalFrameRate', max(Screen('Screens')));
    if frameRate==0
        frameRate=100;
    end
    
    p.addParamValue('objContrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('rwStepSize', 1, @(x) x>=0);
    p.addParamValue('presentationLength', 200, @(x)x>0);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS/2, @(x) x>0);
    p.addParamValue('waitframes', round(.03*frameRate), @(x)isnumeric(x)); 
    p.addParamValue('pdMode', 0, @(x) x==0 || x==1);
    p.addParamValue('center', [16.5 16.5], @(x) all(size(x)==[1 2]) && all(isnumeric(x)));
    p.addParamValue('saccadeSize', .5*PIXELS_PER_100_MICRONS, @(x) x>=0);
    p.addParamValue('objSize', 12*PIXELS_PER_100_MICRONS, @(x) x>=0);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
                                                                %x==-1, uses checkers
    p.addParamValue('magnification', 1, @(x) x>=0);
    p.addParamValue('repeatFEM', 1, @(x) x==0 || x==1);     % x==1, every period has the same FEM sequence
    p.addParamValue('centerShape', 1, @(x) x==0 || x==1);   % x==1, rectangle center, x==0, circles + square mask
    p.addParamValue('objIndex', 6, @(x) isnumeric(x));
    p.addParamValue('objMin', 0, @(x) x>=0 && x<=255);
    p.addParamValue('objMax', 255, @(x) x>=0 && x<=255);
    p.addParamValue('periIndex', 5, @(x) x>=0 || x==-1);   %x>=5 pulls an image
    p.addParamValue('periMin', 0, @(x) x>=0 && x<=255);
    p.addParamValue('periMax', 255, @(x) x>=0 && x<=255);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

