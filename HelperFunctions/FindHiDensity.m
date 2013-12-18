function FindHiDensity()
% Obj Parameters
objSizeH = 1.5*PIXELS_PER_100_MICRONS;
objSizeV = 1.2*PIXELS_PER_100_MICRONS;
objDistV = 6*PIXELS_PER_100_MICRONS;
objDistH = 0;               % in pixels

switchingTime = 0.5;        % in seconds

%LoadHelperFunctions();
try
    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to white and black.
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	gray=floor((white+black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
		gray=white / 2;
    end

    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
        [w screenRect]=Screen('OpenWindow',screenNumber, gray);
%        [w screenRect]=Screen('OpenWindow',screenNumber, gray, [0 0 400 400]);
        HideCursor();
        Priority(1);
    else
        [w screenRect]=Screen('OpenWindow',screenNumber, gray);
    end

    
    objRect1 = SetRect(0, 0, objSizeH, objSizeV);
    objRect1 = CenterRect(objRect1, screenRect);
    objRect2 = OffsetRect(objRect1, objDistH/2, objDistV/2);
    objRect1 = OffsetRect(objRect1, -objDistH/2, -objDistV/2);
    
    % Query duration of monitor refresh interval:
    ifi=Screen('GetFlipInterval', w);

    vbl = Screen('Flip', w);
    vblOld = vbl;
    
    color = [0 0 0];
    % Animationloop:
    while ~KbCheck %#ok<AND2>
        if (vbl - vblOld > switchingTime)
            color = 255 - color;
            vblOld = vbl;
        end
        Screen('FillRect', w, color, objRect1);
        Screen('FillRect', w, color, objRect2);
        vbl = Screen('Flip', w);
        
    end;

    Priority(0);
    ShowCursor();
    Screen('CloseAll');    
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
