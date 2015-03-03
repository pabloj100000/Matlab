function FlashingRect()
% Obj Parameters
objSizeH = 800;
objSizeV = 1*PIXELS_PER_100_MICRONS;

switchingTime = 0.5;        % in seconds

%LoadHelperFunctions();
try
    AssertOpenGL;
    KbName('UnifyKeyNames');

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
        [w screenRect]=Screen('OpenWindow',screenNumber, black);
%        [w screenRect]=Screen('OpenWindow',screenNumber, gray, [0 0 400 400]);
        HideCursor();
        Priority(1);
    else
        [w screenRect]=Screen('OpenWindow',screenNumber, black);
    end

    
    objRect = SetRect(0, 0, objSizeH, objSizeV);
    objRect = CenterRect(objRect, screenRect);
    
    % Query duration of monitor refresh interval:
    %ifi=Screen('GetFlipInterval', w);

    vbl = Screen('Flip', w);
    vblOld = vbl;
    
    color = [0 0 0];
    % Animationloop:
    Help{1} = 'Esc: quit stimulus';
    Help{2} = 'a: make bar wider';
    Help{3} = 'd: make bar narrower';
    Help{4} = 'w: make bar taller';
    Help{5} = 's: make bar shorter';
    Help{6} = 'use arrows to move the bar';
    screen.w = w;
%    DrawMultiLineComment(screen, Help, 'x0', 300)
    DrawMultiLineComment(screen, Help, 'x0', 300, 'y0', 300, 'color', [255 255 255])
    Screen('Flip', w)

    [width height] = Screen('WindowSize', max(Screen('Screens')));
    
    % prevent keystrokes from writing onto script
    ListenChar(2);
    while 1
        if KbCheck
            pause(0.2);
            break
        end
    end
    while 1
        if (vbl - vblOld > switchingTime)
            color = 255 - color;
            vblOld = vbl;
        end
        Screen('FillRect', w, color, objRect);
        vbl = Screen('Flip', w);
        
        [keyIsPressed, ~, keyCode] = KbCheck;
        
        increase_width = KbName('a');
        decrease_width = KbName('d');
        increase_height = KbName('w');
        decrease_height = KbName('s');
        move_right = KbName('rightarrow');
        move_left = KbName('leftarrow');
        move_up = KbName('uparrow');
        move_down = KbName('downarrow');
        escape = KbName('escape');
        
        if keyCode(increase_width)
            if objRect(3)-objRect(1) < width
                objRect = objRect + [0 0 1 0];
            end
        elseif keyCode(decrease_width)
            if objRect(3)-objRect(1) > 1
                objRect = objRect - [0 0 1 0];
            end
        elseif keyCode(increase_height)
            if objRect(4) - objRect(2) < height
                objRect = objRect + [0 0 0 1];
            end
        elseif keyCode(decrease_height)
            if objRect(4) - objRect(2) > 2
                objRect = objRect - [0 0 0 1];
            end
        elseif keyCode(move_right)
            if objRect(3) < width
                objRect = objRect + [1 0 1 0];
            end
        elseif keyCode(move_left)
            if objRect(1) > 0
                objRect = objRect - [1 0 1 0];
            end
        elseif keyCode(move_up)
            if objRect(2) > 1
                objRect = objRect - [0 1 0 1];
            end
        elseif keyCode(move_down)
            if objRect(4) < height
                objRect = objRect + [0 1 0 1];
            end
        elseif keyCode(escape)
            break

        elseif keyIsPressed
            DrawMultiLineComment(screen, {'Letter not recognized', ...
                'use a,s,d,w, arrows, and escape'}, 'x0', 300, 'y0', 300, 'color', [255 255 255]);            
        end
    end;
    % allow keystrokes to writing onto script
    ListenChar();
    ListenChar(1);

    Priority(0);
    ShowCursor();
    Screen('CloseAll');    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    clear Screen
    ListenChar();
    ListenChar(1);
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
