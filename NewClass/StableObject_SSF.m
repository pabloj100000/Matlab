function StableObject_SSF(varargin)
    global screen
    
try
    
    InitScreen(0);
    Add2StimLogList();

    p=ParseInput(varargin{:});

    objColors = p.Results.objColors;
    objRect = p.Results.rects;

    backContrast = p.Results.backContrast;
    backReverseFreq = p.Results.backReverseFreq;        % for reversing
    backJitterFreq = p.Results.backJitterFreq;
    backAngle = p.Results.angle;
    backTex = p.Results.backTexture;
    
    stimSize = p.Results.stimSize;
    presentationLength = p.Results.presentationLength;
    barsWidth = p.Results.barsWidth;
    waitframes = p.Results.waitframes;
    
    vbl=0;
 
    
    % make the background texture
    if (isempty(backTex))
        clearBackTexFlag = 1;
        backTex = GetCheckersTex(stimSize/barsWidth, 1, backContrast);
        backSource = SetRect(0, 0, stimSize/barsWidth, stimSize/barsWidth);
    else
        clearBackTexFlag = 0;
    end
    
%        'backFreq', backJitterFreq, ...
    commonArguments = {...
        'rects', objRect, ...
        'angle', backAngle, ...
        'backTexture', backTex, ...
        'backSource', backSource, ...
        'stimSize', stimSize, ...
        'presentationLength', presentationLength, ...
        'barswidth', barsWidth, ...
        'waitframes', waitframes};

    
    % Animationloop:
    for presentation = 1:2
        for colorIndex = 1:length(objColors)
            color = objColors(colorIndex);

            SxxArguments = [commonArguments];
            StableObject_Sxx(color, SxxArguments{:})

            xSxArguments = [commonArguments];
            StableObject_xSx(color, xSxArguments{:});
            
            xxFArguments = [commonArguments];
            StableObject_xxF(color, xxFArguments{:});
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    if (clearBackTexFlag)
        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', backTex{1});
    end
        
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objSeed, stimSize, objSizeH, objSizeV,
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
    global screen
    p  = inputParser;   % Create an instance of the inputParser class.

    [screenX, screenY] = SCREEN_SIZE;
    rect =  CenterRectOnPoint([0 0 12 12]*PIXELS_PER_100_MICRONS, screenX/2, screenY/2);
    
    % Object related
    p.addParamValue('objSeeds', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objColors', [0 64 128 255], @(x) all(all(x>=0)) && all(all(x<=255)));
    p.addParamValue('objMean', 127, @(x) all(all(x>=0)) && all(all(x<=255)));
    p.addParamValue('rects', rect, @(x) size(x,1)==4 || size(x,2)==4);
    
    % Background related
    p.addParamValue('backSeed', 2, @(x)isnumeric(x));
    p.addParamValue('backMode', [0 0 1 0], @(x) size(x,1)==1 && size(x,2)==4);
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backJitterFreq', .5, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));
    p.addParamValue('backDest', GetRects(screenY, [screenX screenY]/2), @(x) isnumeric(x) && size(x,2)==4);
    p.addParamValue('backPattern', 1, @(x) x==0 || x==1);
    p.addParamValue('angle', 0, @(x) isnumeric(x));
    
    % General
    p.addParamValue('stimSize', PIXELS_PER_100_MICRONS*42, @(x)x>0);
    p.addParamValue('presentationLength', 60, @(x)x>0);
    p.addParamValue('movieDurationSecs', 60*3*2, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('barsWidth', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(screen.rate/30), @(x)isnumeric(x)); 
    p.addParamValue('pdStim', 3, @(x) isnumeric(x));
        

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

