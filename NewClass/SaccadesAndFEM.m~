function SaccadesAndFEM(varargin)
    % Two textures are rocked back and forth following FEM + saccades.
    % periIndex:    -1 uses checkers
    %               >=5 uses images
    % periAlpha:    between 0 and 1
    % periMeanLum:  between -127 and 127, is the deviation from gray.
    %
    % obj Parameters are the same except that center can not be checkers.
    %
    % Usage (interesting ones):
    % SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1)
    % SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'periIndex', -1)
    % SaccadesAndFEM('objAlpha', 0, 'periAlpha', 1, 'objMeanLum', -127)
    % SaccadesAndFEM('objAlpha', 1, 'periAlpha', 1, 'objMeanLum', -127, 'periMeanLum', 127)
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
    maskRadia = p.Results.maskRadia;
    checkersSize = p.Results.checkersSize;
    magnification = p.Results.magnification;
    pdMode = p.Results.pdMode;
    repeatFEM = p.Results.repeatFEM;
    center = p.Results.center;
    centerShape = p.Results.centerShape;
    
    objIndex = p.Results.objIndex;
    objAlpha = p.Results.objAlpha;
    objMeanLum = p.Results.objMeanLum;
    periIndex = p.Results.periIndex;
    periAlpha = p.Results.periAlpha;
    periMeanLum = p.Results.periMeanLum;



    % magnification is introduce to allow to stretch the textures. TO allo
    % stretching the textures without changing checker size and mask Size I
    % redefine their values
    checkersSize = checkersSize/magnification;
    maskRadia = maskRadia/magnification;
    saccadeSize = saccadeSize/magnification;
    
    InitScreen(0);
    % Enable alpha-blending, set it to a blend equation useable for linear
    % superposition with alpha-weighted source. This allows to linearly
    % superimpose gabor patches in the mathematically correct manner, should
    % they overlap. Alpha-weighted source means: The 'globalAlpha' parameter in
    % the 'DrawTextures' can be used to modulate the intensity of each pixel of
    % the drawn patch before it is superimposed to the framebuffer image, ie.,
    % it allows to specify a global per-patch contrast value:
    Screen('BlendFunction', screen.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    % Generate the textures.
    folder = '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/'; % my laptop's path
    if (~isdir(folder))
        folder = '/Users/baccuslab/Desktop/stimuli/Pablo/Images/'; % D239 stimulus desktop's path
    end
    
    objectIm = imread([folder, 'image', num2str(objIndex), '.jpg']) + objMeanLum;
    if (objAlpha<0)
        objectIm = (ojbectIm>screen.gray+objMeanLum)*255;
        objAlpha=1;
    end
    objectTex = maskMatrix(objectIm, maskRadia, saccadeSize, 1, centerShape);
    backTex = GetBackground(maskRadia-1, saccadeSize, periMeanLum, objMeanLum, centerShape); % the -1 is to avoid an edge problem. Take it out and see for yourself
    
    if (periIndex >=0)
        peripheryIm = imread([folder, 'image', num2str(periIndex),'.jpg']) + periMeanLum;
        if (periAlpha<0)
            peripheryIm = (peripheryIm>mean(peripheryIm(:))+periMeanLum)*255;
%            peripheryIm = (peripheryIm>screen.gray+periMeanLum)*255;
            periAlpha=1;
        end
    else
        peripheryIm = GetCheckers(objectIm, checkersSize);
    end
    peripheryTex = maskMatrix(peripheryIm, maskRadia, saccadeSize, 0, centerShape);

    clear objectIm peripheryIm checkersIm

    
    destRect = Screen('Rect', objectTex)*magnification;
    destRect = CenterRect(destRect, screen.rect);
    
    % Offset both screen.rect and destRect to be centered on "center"
    % since center is given in checkers corresponding to those of RF
    % mapping, stimulus is currently centered on the screen's center
    % which is [16.5 16.5]
    offset = (center-[16.5 16.5])*PIXELS_PER_100_MICRONS;
    destRect = OffsetRect(destRect,offset(1), offset(2));
    checkersRect = OffsetRect(screen.rect, offset(1), offset(2));
    
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
        Screen('DrawTexture', screen.w, backTex, [], checkersRect + offset*[1 0 1 0], 0, 0);
        Screen('DrawTexture', screen.w, objectTex, [], destRect + offset*[1 0 1 0], 0, 0, objAlpha);
        Screen('DrawTexture', screen.w, peripheryTex, [], destRect + offset*[1 0 1 0], 0, 0, periAlpha);
        

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
    Screen('Close', objectTex);
    Screen('Close', peripheryTex);
    Screen('Close', backTex);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

function array = GetCheckers(im, checkersSize)
    [x, y] = meshgrid(1:size(im,1), 1:size(im,2));
    
    array = mod(floor(x/checkersSize) + floor(y/checkersSize),2)*255;    
end

function backTex = GetBackground(radia, saccadeSize, periMeanLum, objMeanLum, centerShape)
    global screen

    width = screen.rect(3);
    height = screen.rect(4);
    [x, y] = meshgrid(1:width, 1:height);
    if (centerShape)
        mask = abs(x-width/2)>radia + saccadeSize/2 | abs(y-height/2)>radia;
    else
        mask = ((x-width/2-saccadeSize/2).^2 + (y-height/2).^2>radia^2);
        mask = mask.*((x-width/2+saccadeSize/2).^2 + (y-height/2).^2>radia^2);
        mask = mask.*((abs(x-width/2)>saccadeSize/2) | (abs(y-height/2)>radia));
    end
    % assign to center and periphery specific colors. Since colores
    % assigned to each mask can be anything in the range [0-255], I first
    % make one of the mask values -1
    mask = double(mask);
    mask(mask==0) = -1;
    mask(mask>0) = periMeanLum + screen.gray;
    mask(mask==-1) = objMeanLum + screen.gray;
    backTex = Screen('MakeTexture', screen.w, mask);
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
    p.addParamValue('maskRadia', 4*PIXELS_PER_100_MICRONS, @(x) x>=0);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
                                                                %x==-1, uses checkers
    p.addParamValue('magnification', 1, @(x) x>=0);
    p.addParamValue('repeatFEM', 1, @(x) x==0 || x==1);     % x==1, every period has the same FEM sequence
    p.addParamValue('centerShape', 1, @(x) x==0 || x==1);   % x==1, rectangle center, x==0, circles + square mask
    p.addParamValue('objIndex', 6, @(x) x>=0);
    p.addParamValue('objAlpha', .5, @(x) x>=-1 && x<=1);
    p.addParamValue('objMeanLum', 0, @(x) -127<=x && x<=127);
    p.addParamValue('periIndex', 5, @(x) x>=0 || x==-1);   %x>=5 pulls an image
    p.addParamValue('periAlpha', 1, @(x) x>=-1 && x<=1);
    p.addParamValue('periMeanLum', 0, @(x) -127<=x && x<=127);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

