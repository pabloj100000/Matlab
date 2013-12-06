function RF_NoCenter(newCenter, checkSize, varargin)
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    global screen objRect pd

    p=ParseInput(varargin{:});

    objContrast = p.Results.objContrast;
    seed  = p.Results.seed;
    movieDurationSecs = p.Results.movieDurationSecs;
    stimSize = p.Results.stimSize;
    checkerSize = p.Results.checkerSize;
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    pdStim = p.Results.pdStim;

try
    InitScreen(0);
    Add2StimLogList();

    checkersN_H = ceil(stimSize/checkerSize);
    checkersN_V = checkersN_H;
    
    % Define the obj Destination Rectangle
    objRect = SetRect(0,0, checkersN_H, checkersN_V)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);
    objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));

    % Define the PD box
    if exist('pd', 'var')==0 || isempty(pd)
        pd = DefinePD();
    end
   

    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = uint32(movieDurationSecs*screen.rate);

    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', seed);

    % Define some needed variables
    
    Screen('FillRect', screen.w, screen.gray);

    % Animationloop:
    BinaryCheckers(framesN, waitframes, checkersN_V, checkersN_H, objContrast, randomStream, pdStim, newCenter, checkSize);

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
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
        frameRate=60;
    end
    
    p.addParamValue('objContrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('movieDurationSecs', 1000, @(x)x>0);
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('checkerSize', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('waitframes', round(.033*framerate), @(x)isnumeric(x)); 
    p.addParamValue('objCenterXY', [0 0], @(x) size(x) == [1 2]);
    p.addParamValue('pdStim', 0, @(x) isnumeric(x));
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

function [exitFlag] = BinaryCheckers(framesN, waitframes, checkersV, checkersH, objContrast, randomStream, pdStim, checkCenter, checkSize)
    global screen objRect pd

    Add2StimLogList();
    exitFlag = -1;
    frame = 0;

    newCheck = SetRect(0, 0, checkSize, checkSize);
    newCheck = CenterRectOnPoint(newCheck, checkCenter(1), checkCenter(2))
    
    for frame = 0:framesN-1

        if (mod(frame, waitframes)==0)
            % CENTER REGION
            % ------ ------

            % Make a new obj texture
            objColor = (rand(randomStream, checkersH, checkersV)>.5)*2*screen.gray*objContrast...
                + screen.gray*(1-objContrast);
            objTex  = Screen('MakeTexture', screen.w, objColor);
            
            % display last texture
            Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
            
            Screen('FillRect', screen.w, screen.gray, newCheck);
        
            % We have to discard the noise checkTexture.
            Screen('Close', objTex);
        end
        

        % PD
        % --
        % Draw the PD box
        DisplayStimInPD2(pdStim, pd, frame, screen.rate, screen)
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + 0.5 * screen.ifi, 1);
        if (KbCheck)
            break
        end
    end;
    
    if (frame >= framesN)
        exitFlag = 1;
    end
end



