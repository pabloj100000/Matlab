function FindLowDensity()
% Obj Parameters
objSizeH = 106;
objSizeV = 106;
%{
objContrast = 1%.25;


% Gray Rectangles parameters
padSizeV = 60;
padSizeH = 43;
objPadN = 2;
objPadsDist = 92;           % if HD array and objPadN = 2, should be around 92
deltaY = 8;
deltaX = 10;
%}

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

    
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screenRect);
    
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
        Screen('FillRect', w, color, objRect);
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
