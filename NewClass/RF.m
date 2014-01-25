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
    checkerSizeX = p.Results.checkerSizeX;
    checkerSizeY = p.Results.checkerSizeY;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    noise.type = p.Results.noiseType;
try
    InitScreen(0);
    Add2StimLogList();

    checkersN_H = ceil(stimSize(1)/checkerSizeX);
    checkersN_V = ceil(stimSize(2)/checkerSizeY);
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H*checkerSizeX, checkersN_V*checkerSizeY);
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    pd = DefinePD();
   

    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    whiteFrames = round(screen.rate/waitframes);
    framesN = uint32(floor(movieDurationSecs*screen.rate/waitframes/whiteFrames)*whiteFrames);

    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', seed);

    % Define some needed variables
    
    Screen('FillRect', screen.w, screen.gray);

    % Animationloop:
    RandomCheckers(framesN, waitframes, checkersN_V, checkersN_H, objContrast,...
        randomStream, pd, whiteFrames, objRect, noise);

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function [exitFlag] = RandomCheckers(framesN, waitframes, checkersV, checkersH, ...
    objContrast, randomStream, pd, whiteFrames, objRect, noise)
    global screen

    
    for frame = 0:framesN-1

        
        % Make a new obj texture
        if (strcmp(noise.type, 'binary'));
            objColor = (rand(randomStream, checkersV, checkersH)>.5)*2*screen.gray*objContrast...
                + screen.gray*(1-objContrast);
        elseif (strcmp(noise.type, 'gaussian'))
            objColor = randn(randomStream, checkersV, checkersH)*screen.gray*.15 ...
                + screen.gray;
        end
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
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS*[1 1], @(x) all(size(x)==[1 2]) && all(x>0));
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('checkerSizeX', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('checkerSizeY', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('waitframes', round(.033*frameRate), @(x)isnumeric(x)); 
    p.addParamValue('objCenterXY', [0 0], @(x) all(size(x) == [1 2]));
    p.addParamValue('pdStim', 0, @(x) isnumeric(x));
    p.addParamValue('noiseType', 'binary', @(x) strcmp(x,'binary') || ...
        strcmp(x,'gaussian'));
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

