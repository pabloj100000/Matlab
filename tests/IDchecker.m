function IDchecker()

debugging=1;
r=5;
c=1;

% Obj Parameters
checkerSize = 16;
objContrast = 1;
checkersH = 32;
checkersV = 32;


seed = 1;
waitframes = 1;
movieDurationSecs=10; % Abort demo after 20 seconds.


LoadHelperFunctions();
try
    screen = InitScreen(debugging);
    
    % Define the obj Destination Rectangle
    
    objRect = SetRect(0,0, checkersH, checkersV)*checkerSize;
    objRect = CenterRect(objRect, screen.rect);

    
    % make a box with the size of one checker
    oneChecker = SetRect(0,0, checkerSize, checkerSize);
    oneChecker = CenterRect(oneChecker, screen.rect);
    % offset the checker to overlap checker (c, r) from igor
    shiftxy = checkerSize*([c r]-[checkersH checkersV]/2 + [.5 .5]);
    oneChecker = OffsetRect(oneChecker, shiftxy(1), shiftxy(2));
    
    % Define the PD box
    pd = SetRect(0,0, 100, 100);
    pd = CenterRectOnPoint(pd, screen.rect(3)*.95, screen.rect(4)*.15);
    
    % We run at most 'framesN' if user doesn't abort via
    % keypress.
    framesN = movieDurationSecs*60;

    % init random seed generator
    rand('seed', seed);
    
    % Define some needed variables
    
        
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl=Wait2Start(screen.w, debugging, ['Recotrd for ', num2str(movieDurationSecs), ' secs']);
    
    % Animationloop:
    exitFlag = -1;
    frame = 0;

    while (frame < framesN) & ~KbCheck %#ok<AND2>


        Screen('FillRect', screen.w, 20);
        
        % CENTER REGION
        % ------ ------
        % Make and display obj texture
        objColor = (rand(checkersH, checkersV)>.5)*2*screen.gray*objContrast...
            + screen.gray*(1-objContrast);
        objTex  = Screen('MakeTexture', screen.w, objColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);

        % After drawing, we have to discard the noise checkTexture.
        Screen('Close', objTex);

        % PD
        % --
        % Draw the PD box
        if (mod(frame, 60)==0)
            Screen('FillRect', screen.w, screen.white, pd);
        else
            Screen('FillRect', screen.w, screen.gray, pd);
        end

        % Make a gray box in checker (c, r), using coordinates from Igor.
        Screen('FillRect', screen.w, 127, oneChecker);
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', screen.w, vbl + (waitframes - 0.5) * screen.ifi);
        frame = frame + waitframes;
    end;
    if (frame >= framesN)
        exitFlag = 1;
    end

    Priority(0);
    ShowCursor();
    Screen('CloseAll');

    
    if (exitFlag==1)   % if it got here without any key being pressed
        empty=[];
        CreateStimuliLog(empty, mfilename);
    end
    
    shiftxy
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

    % Find the color values which correspond to white and black.
    screen.white=WhiteIndex(screenNumber);
    screen.black=BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	screen.gray=floor((screen.white+screen.black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if screen.gray == screen.white
		screen.gray=screen.white / 2;
    end

    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
        if (debugging)
            [screen.w screen.rect]=Screen('OpenWindow',screenNumber, screen.gray, [0 0 400 400]);
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


