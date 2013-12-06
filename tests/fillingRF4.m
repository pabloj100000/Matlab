function fillingRF4()
% The idea is to see whether cells in the center are modulated by the
% similarity between center and background.
% I will have the screen divided in center and object.
% Each one will be a grating of a given spatial frequency.
% At each frame both grating are going to have zero mean and intensities
% drawn from a gaussian distribution (each grating has its own contrast but
% giving intensity I1 for odd bars of one of the gratings, even bars have
% intensity I2 = mean-I1)
% Each one of the bars can be presented either verticaly or horizontaly
% making 4 different environments V-V, V-H, H-V, H-H (back-obj).
% The whole idea is to test whether firing in V-V > H-V and H-H > V-H
debugging=0;

% Obj Parameters
barsWidth=16;
objContrast = 5;
backContrast = 35;
objBarsN = 10;
backBarsN = objBarsN + 2*16;                     % BackBarsN = objBarsN+2*evenNumber
objSize = objBarsN*barsWidth;
backSize = backBarsN*barsWidth;     % will be ceiled to accomodate an integer number of checkers

seed = 1;
waitframes = 1;
movieDurationSecs=1600; % Abort demo after 20 seconds.
switchingTime = movieDurationSecs/8;

LoadHelperFunctions();
try
    screen = InitScreen(debugging);
    
    % Define object texture parameters. I am changing the obj size to
    % incorporate an integer number of squares.
    objRect = SetRect(0,0,objSize, objSize);
    objRect = CenterRect(objRect, screen.rect);

    % Define Back texture parameters. I am changing the back size to
    % incorporate an integer number of squares.
    backRect = SetRect(0,0,backSize, backSize);
    backRect = CenterRect(backRect, screen.rect);

    backBars = 1:backBarsN;
    backBars = mod(backBars, 2)*2-1;
    objBars = 1:objBarsN;
    objBars = mod(objBars, 2)*2-1;
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % Start the random generator
    randn('seed', seed);
    
    % Define some needed variables
    frame = 0;

    % We run at most 'framesN' frames if user doesn't abort via
    % keypress.
    framesN = movieDurationSecs*60;

    % background will be changing every 'switchingFrame' frames
    switchingFrame = 60*switchingTime;
    
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
%    vbl=Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs), ' secs']);
vbl=0;    
    % Animationloop:
    while (frame < framesN) & ~KbCheck %#ok<AND2>

        if (mod(frame, switchingFrame)==0)
            index =  mod( floor(frame/ switchingFrame), 4);
            switch index
                case 0
                    % starting vertical background, vert Object
                    seed = randn('seed');
                    backAngle = 0;
                    objAngle = 0;
                case 1
                    % starting horizontal background
                    randn('seed', seed);
                    backAngle = 90;
                    objAngle = 0;
                case 2
                    % starting horizontal background
                    randn('seed', seed);
                    backAngle = 0;
                    objAngle = 90;
                case 3
                    % starting horizontal background
                    randn('seed', seed);
                    backAngle = 90;
                    objAngle = 90;
            end
        end

        % pick intensity from a normal distribution
        Int = randn();
        
        % make the back texture
        backColor = backContrast*backBars*Int+screen.gray;
        backTex  = Screen('MakeTexture',screen.w, backColor);
    
        % Display back texture
        Screen('DrawTexture',screen.w, backTex, [], backRect, backAngle, 0);
        clear backTex

        
        % CENTER REGION
        % ------ ------
        % Make and display obj texture
        objColor = objContrast*objBars*Int+screen.gray;
        objTex  = Screen('MakeTexture',screen.w, objColor);
        Screen('DrawTexture',screen.w, objTex, [], objRect, objAngle, 0);

        % After drawing, we can discard the noise checkTexture.
        Screen('Close', objTex);

        % PD
        % --
        % Draw the PD box
        if (mod(frame, 60)==0)
            Screen('FillRect',screen.w, screen.white, pd);
        else
            Screen('FillRect',screen.w, screen.gray, pd);
        end
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip',screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;

    Priority(0);
    ShowCursor();
    Screen('CloseAll');

    if (exist('checkerSeq', 'var'))
        'Saving seq to memory' %#ok<NOPRT>
        SaveBinary(checkerSeq, 'uint8');
        SaveBinary(backSeq, 'uint8');
    end
    
    if (frame >= framesN)   % if it got here without any key being pressed
        empty=[];
        CreateStimuliLog(empty, mfilename);
    end
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    clear Screen
    Screen('CloseAll');
    Priority(0);
    ShowCursor();
    psychrethrow(psychlasterror);
end %try..catch..
end

function LoadHelperFunctions()
    % load Helper functions
    oldDir = pwd;
    cd ..
    cd('HelperFunctions');
    addpath(genpath(pwd));
    cd(oldDir)
end

function screen = InitScreen(debugging)
    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to screen.white and black.
    screen.white=WhiteIndex(screenNumber);
    screen.black=BlackIndex(screenNumber);

    % Round screen.gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	screen.gray=floor((screen.white+screen.black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined screen.gray. It isn't strictly neccessary in this demo:
    if screen.gray == screen.white
		screen.gray=screen.white / 2;
    end

    % Open a double buffered fullscreen window with a screen.gray background:
    if (screenNumber == 0)
        if (debugging)
%            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray, [0 0 400 400]);
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
        else
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
            HideCursor();
        end
        Priority(1);
    else
        [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray);
    end
    
        % Query duration of monitor refresh interval:
    screen.ifi=Screen('GetFlipInterval', screen.w);

end

