function RF(varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    global screen

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    seed  = p.Results.seed;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    checkerSize = p.Results.checkerSize;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;

try
    InitScreen(0);
    Add2StimLogList();

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    pd = DefinePD();
   

    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    whiteFrames = round(screen.rate/waitframes);
    framesN = uint32(floor(movieDurationSecs*screen.rate/waitframes/whiteFrames)*whiteFrames)

    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', seed);

    % Define some needed variables
    
    Screen('FillRect', screen.w, screen.gray);

    % Animationloop:
    BinaryCheckers(framesN, waitframes, checkersN_V, checkersN_H, objContrast,...
        randomStream, pd, whiteFrames, objRect);

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function [exitFlag] = BinaryCheckers(framesN, waitframes, checkersV, checkersH, ...
    objContrast, randomStream, pd, whiteFrames, objRect)
    global screen

    
    for frame = 0:framesN-1

        
        % Make a new obj texture
        objColor = (rand(randomStream, checkersH, checkersV)>.5)*2*screen.gray*objContrast...
            + screen.gray*(1-objContrast);
        objTex  = Screen('MakeTexture', screen.w, objColor);
        
        % display last texture
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
        
        % We have to discard the noise checkTexture.
        Screen('Close', objTex);
        

        % PD
        % --
        if (mod(frame, whiteFrames)==0)
            color = 255;
        else
            color = objColor(1,1)/2+screen.gray/2;
        end
        
        % Draw the PD box
        Screen('FillOval', screen.w, color, pd);
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes-.5) * screen.ifi);

        if (KbCheck)
            break
        end
    end
    
    if (frame >= framesN)
        exitFlag = 1;
    end
end



function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
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

    frameRate = Screen('NominalFrameRate', max(Screen('Screens')));
    if frameRate==0
        frameRate=100;
    end
    
    p.addParamValue('objContrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('movieDurationSecs', 1000, @(x)x>0);
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('checkerSize', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('waitframes', round(.033*frameRate), @(x)isnumeric(x)); 
    p.addParamValue('objCenterXY', [0 0], @(x) size(x) == [1 2]);
    p.addParamValue('pdStim', 0, @(x) isnumeric(x));
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

