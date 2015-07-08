function InitScreen(debugging, width, height, rate, varargin)
    % Initializes the Screen.
    % The idea here is that you can call this function from within a given
    % stimulus where the 2nd parameter might or might no be defined. If it
    % is defined this function does nothing but if it is not defined then
    % this function initializes the screen.
    
    global screen
    
    p = ParseInput(varargin{:});
    backColor = p.Results.backColor;

    Add2StimLogList();
    if (isfield(screen, 'w'))
        return
    end

    % write which function initialized the screen. So that we know when to
    % close it.
    s = dbstack('-completenames');
    screen.callingFunction = s(length(s)).file;

    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screen.screenNumber=max(Screen('Screens'));

    % if Nominal rate is 0, (running from a laptop) Psychtoolbox is failing
    % to initialize the screen because there are synchronization problems. I
    % don't care about those problems when running in my laptop. Experiment
    % would never be run under those conditions. Force it to start anyway
    screen.rate = Screen('NominalFrameRate', screen.screenNumber);
    if screen.rate==0
        Screen('Preference', 'SkipSyncTests',1);
    else
        Screen('Resolution', screen.screenNumber, width, height, rate);
    end

    % Find the color values which correspond to white and black.
    screen.white=WhiteIndex(screen.screenNumber);
    screen.black=BlackIndex(screen.screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	screen.gray=floor((screen.white+screen.black)/2);
    screen.backColor = backColor;
    
    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if screen.gray == screen.white
		screen.gray=screen.white / 2;
    end
    
    % Open a double buffered fullscreen window with a gray background:
    if (screen.screenNumber == 0)
        if (debugging)
            [screen.w screen.rect]=Screen('OpenWindow',screen.screenNumber, backColor, [10 10 400 400]);
        else
            [screen.w screen.rect]=Screen('OpenWindow',screen.screenNumber, backColor);
            HideCursor();
        end
        Priority(1);
    else
        [screen.w screen.rect]=Screen('OpenWindow',screen.screenNumber, backColor);
    end

    %    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    [screen.center(1,1) screen.center(2,1)] = WindowCenter(screen.w);%[screenX screenY]/2;
    
    % Query duration of monitor refresh interval:
    screen.ifi=Screen('GetFlipInterval', screen.w);

    if screen.rate==0
        screen.rate = 100;
        screen.ifi=.01;
    end
    
    screen.waitframes = round(.03*screen.rate);

    if mod(screen.rate,2)
        answer = questdlg(['Screen Rate is a non (', num2str(screen.rate), ...
            'Hz). Do you want to continue or abort?'], 'Frame Rate', 'Abort', 'Continue', 'Abort');
        if strcmp(answer, 'Abort')
            error('Change the monitor rate');
        end
    end

    [screen.size(1) screen.size(2)] = Screen('WindowSize', max(Screen('Screens')));
    
    screen.vbl = 0;
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('backColor', 127, @(x) x>=0 && x<=255);      % dimension of the two patches to discriminate
    
    p.parse(varargin{:});
end
