function PeripheryRF()
    global screen
try
        
    InitScreen(0);
    Add2StimLogList();

    object.size = 192;
    object.center = screen.center;
    object.color = 0;
    object.mode = 0;

    presentationLength = 300;
    
    nextSeed = OneTrial(object, 1, presentationLength);
%{
    object.color = 255;
    OneTrial(object, 1, presentationLength);
    object.color = 0;
    OneTrial(object, nextSeed, presentationLength);
    object.color = 255;
    OneTrial(object, nextSeed, presentationLength);
%}    
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function seed = OneTrial(object, seed, movieDurationSecs)
    % object is a structure with the following fields. In the future it
    % might accept several objects.
        % center
        % size
        % mode: 0 (square), 1 (circle)
        % color:
        
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    global screen

    
    % Define the obj Destination Rectangle
    object.rect = GetRects(object.size, object.center);   

    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    updateDelay = screen.ifi*round(.03/screen.ifi);
    framesN = uint32(movieDurationSecs/updateDelay);

    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', seed);

    % Define some needed variables
    
    Screen('FillRect', screen.w, screen.gray);

    % Animationloop:
    BinaryCheckers(framesN, updateDelay, randomStream, object);

    seed = randomStream.State;    
end

function BinaryCheckers(framesN, updateDelay, randomStream, object)
    global screen

    pd = DefinePD();
    framesPerSec = round(1/updateDelay);
%{
    exitFlag = -1;
    frame = 0;
    checkersH=1; checkersV=1;
    %}

    for frame = 0:framesN-1
        
        % CENTER REGION
        % ------ ------
        
        % Make a new obj texture
        peripheryColor = randn(randomStream)*screen.gray*.35+screen.gray;
        %(rand(randomStream, checkersH, checkersV)>.5)*2*screen.gray*objContrast...
        %                + screen.gray*(1-objContrast);
        %            objTex  = Screen('MakeTexture', screen.w, objColor);
        
        % display last texture
        %            Screen('DrawTexture', screen.w, objTex, [], [], 0, 0);%screen.rect, 0, 0);
        Screen('FillRect', screen.w, peripheryColor);
        
        if object.mode==0
            Screen('FillRect', screen.w, object.color, object.rect);
        else
            Screen('FillOval', screen.w, object.color, object.rect);
        end
        
        % We have to discard the noise checkTexture.
        %            Screen('Close', objTex);
        
        if mod(frame, framesPerSec)==0
            Screen('FillOval', screen.w, 255, pd)
        else
            Screen('FillOval', screen.w, 0, pd)
            
        end
        
        
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        screen.vbl = Screen('Flip', screen.w, screen.vbl + updateDelay - screen.ifi/2);
        if (KbCheck)
            break
        end
    end;
    
end

%{
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

    p.addParamValue('objContrast', 1, @(x) x>=0 && x<=1);
    p.addParamValue('seed', 1, @(x) isnumeric(x));
    p.addParamValue('movieDurationSecs', 1000, @(x)x>0);
    p.addParamValue('stimSize', 32*PIXELS_PER_100_MICRONS, @(x)x>0);
    p.addParamValue('debugging', 0, @(x)x>=0 && x <=1);
    p.addParamValue('checkerSize', PIXELS_PER_100_MICRONS, @(x) x>0);
    p.addParamValue('waitframes', round(.033*MonitorFrameRate), @(x)isnumeric(x)); 
    p.addParamValue('objCenterXY', [0 0], @(x) size(x) == [1 2]);
    p.addParamValue('pdStim', 0, @(x) isnumeric(x));
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
%}
