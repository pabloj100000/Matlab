function objSeed = selectedRF(checkers, sizes, noiseType, varargin)
%   center is in screen pixels
%   objSize is in screen pixels
%   noiseType:  0, binary checkers
%               1, gaussian checkers
%               2, 1/f checkers
%   USage:  selectedRF([100 100], 200)
%           selectedRF(CenterOnChecker(14, 18, 'checkSize', PIXELS_PER_100_MICRONS), 100)
%           selectedRF(CenterOnChecker(-1, -1), 1200)   center of
%           the screen
global screen
    
try
    Add2StimLogList();

    % process Input variables
    p = ParseInput(varargin{:});

    waitframes = p.Results.waitframes;
    objSeed = p.Results.objSeed;
    objContrast = p.Results.objContrast;
    shape = p.Results.shape;
    presentationLength = p.Results.presentationLength;
        
    % start the stimulus
    InitScreen(0)
    pd = DefinePD();

    objRects = Checkers2Rects(checkers, sizes);
    
    framesN = fix(presentationLength*screen.rate/waitframes);
    updateTime = waitframes/screen.rate - 1/screen.rate/2;
    
    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', objSeed);
    checkersN = length(sizes);
    colors = zeros(1,checkersN);

    for frame=0:framesN-1
        switch noiseType
            case 0
                colors = ones(3,1)*(rand(randomStream, 1, checkersN)>.5)*screen.white;
            case 1
                colors = ones(3,1)*(randn(randomStream, 1, checkersN))*(objContrast+1)*screen.gray;
            case 2                
        end
        
        if (shape)
            Screen('FillOval', screen.w, colors, objRects);
        else
            Screen('FillRect', screen.w, colors, objRects);
        end
                
        % Photodiode box
        % --------------
        if (mod(frame, floor(screen.rate/waitframes))==0)
            pdColor = 255;
        else
            pdColor = colors(1)/5;
        end
        
        Screen('FillOval', screen.w, pdColor, pd);
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + updateTime , 1);

        if (KbCheck)
            break
        end
    end

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    [~, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rate = Screen('NominalFrameRate', max(Screen('Screens')));
    if (rate==0)
        rate=100;
    end
    
    % Object related
    p.addParamValue('objSeed', 1, @(x) isnumeric(x) && size(x,1)==1 );
    p.addParamValue('objContrast', .2, @(x) x>=0 && x<=1);
    p.addParamValue('shape', 0, @(x) isnumeric(x));

    % Background related
    p.addParamValue('backContrast', 1, @(x)x>=0 && x<=1);
    p.addParamValue('backReverseFreq', 1, @(x) x>=0);
    p.addParamValue('backTexture', [], @(x) iscell(x));

    % General
    p.addParamValue('stimSize', screenY, @(x)x>0);
    p.addParamValue('distance', [10000 14*200:-200:0]*PIXELS_PER_100_MICRONS/100, @(x) x>0);
    p.addParamValue('presentationLength', 600, @(x)x>0);
    p.addParamValue('trialsN', 2);
    p.addParamValue('checkersSize', PIXELS_PER_100_MICRONS/2, @(x)x>0);
    p.addParamValue('waitframes', round(rate/30), @(x)isnumeric(x));         
    p.addParamValue('repeatCenter', 1, @(x) isnumeric(x));         

    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
