function alphaTest3(varargin)
    % One image is the periphery (might be checkers or constant luminance)
    % and will be presented everywhere but when generating the texture I
    % will make pixels in a central mask transparent.
    % the other image is for the object and only pixels inside the mask are
    % opaque, outside teh mask are transparent.
    % By changing the global alpha in DisplayTexture I can change the
    % contrast of each one independently of the other.
    global screen
try    
    p=ParseInput(varargin{:});

    presentationLength = p.Results.presentationLength;
    waitframes = p.Results.waitframes;
    seed = p.Results.seed;
    rwStepSize = p.Results.rwStepSize;
    saccadeSize = p.Results.saccadeSize;
    maskRadia = p.Results.maskRadia;
    backReverseFreq = p.Results.backReverseFreq;
    peripheryIndex = p.Results.peripheryIndex;
    objectIndex = p.Results.objectIndex;
    alpha = p.Results.alpha;
    checkersSize = p.Results.checkersSize;
    magnification = p.Results.magnification;



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
    folder = '/Users/jadz/Documents/Notebook/Matlab/Stimuli/Images/';
    files = dir(folder);
    objectIm = imread([folder, files(objectIndex).name]);
    objectTex = maskMatrix(objectIm, maskRadia, saccadeSize, 1);
    if (peripheryIndex >=0)
        peripheryIm = imread([folder, files(peripheryIndex).name]);
    else
        peripheryIm = GetCheckersTex(objectIm, checkersSize);
    end
    peripheryTex = maskMatrix(peripheryIm, maskRadia, saccadeSize, 0);
    
    clear objectIm peripheryIm checkersIm

    
    destRect = Screen('Rect', objectTex)*magnification;
    destRect = CenterRect(destRect, screen.rect);

    framesN = round(presentationLength*screen.rate/waitframes);
    backFrames = round(screen.rate/backReverseFreq/2/waitframes/2)*2;
    
    % init random seed generator
    randStream = RandStream('mcg16807', 'Seed', seed);

    pd = DefinePD;
    offset = saccadeSize/2;

    for frame=0:framesN
        if (mod(frame, 2*backFrames)==0)
            offset = saccadeSize/2;
        elseif (mod(frame, backFrames)==0)
            offset = -saccadeSize/2;
        end
        
        step = (randi(randStream, 2)-1.5)*rwStepSize;
        offset = offset + step;
        
        % display last texture
%        Screen('DrawTexture', screen.w, objectTex, [], [], 0, 0);
        Screen('DrawTexture', screen.w, objectTex, [], destRect + offset*[1 0 1 0], 0, 0, alpha);
        Screen('DrawTexture', screen.w, peripheryTex, [], destRect + offset*[1 0 1 0], 0, 0);
        

        if (frame==0)
            color=255;
        else
            color = screen.gray + step;
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
    Screen('CloseAll');
    clear global
    clear global expLog
    clear global screen
    clear global StimLogList
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..end
end

function array = GetCheckersTex(im, checkersSize)
    [x, y] = meshgrid(1:size(im,1), 1:size(im,2));
    
    array = mod(floor(x/checkersSize) + floor(y/checkersSize),2)*255;    
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

    p.addParamValue('saccadeSize', 8*PIXELS_PER_100_MICRONS, @(x) x>=0);
    p.addParamValue('maskRadia', 4*PIXELS_PER_100_MICRONS, @(x) x>=0);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('peripheryIndex', 5, @(x) x>=5 || x==-1);   %x>=5 pulls an image
                                                                %x==-1, uses checkers
                                                                
    p.addParamValue('objectIndex', 5, @(x) x>=5);
    p.addParamValue('alpha', 0, @(x) x>=0 && x<=1);
    p.addParamValue('magnification', 1, @(x) x>=0);

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

