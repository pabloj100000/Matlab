function CenterHiDens(version)
% Obj Parameters
switch version
    case 1
        
    case 2
        width = 1.75;  % in mm
        height = 2.0; % in mm
        e_size = 70; % in um
        e_distance = 180; % in um
        
end

% Change all distances to pixels per 100um
width = width * PIXELS_PER_100_MICRONS * 10;
height = height * PIXELS_PER_100_MICRONS * 10;
e_size = e_size * PIXELS_PER_100_MICRONS/100;
e_distance = e_distance * PIXELS_PER_100_MICRONS/100;

try
    AssertOpenGL;
    KbName('UnifyKeyNames');

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to white and black.
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);

    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
        [w screenRect]=Screen('OpenWindow',screenNumber, black);
%        [w screenRect]=Screen('OpenWindow',screenNumber, gray, [0 0 400 400]);
        HideCursor();
        Priority(1);
    else
        [w screenRect]=Screen('OpenWindow',screenNumber, black);
    end
    
    mask = ones(1,4,5);
    electrode =  SetRect(0, 0, 1, 1)*e_size;

    % Center electrode in monitor
    electrode = CenterRect(electrode, screenRect);
for i=1:5    
    mask(:,:,i) = electrode;
end

    mask(:,:,1) = OffsetRect(electrode, -width/2, width/3/2);
    mask(:,:,2) = OffsetRect(electrode, -width/2, -width/3/2);
    mask(:,:,3) = OffsetRect(electrode, +width/2, 0);
    mask(:,:,4) = OffsetRect(electrode, +width/2, +width/3);
    mask(:,:,5) = OffsetRect(electrode, +width/2, -width/3);

    % Query duration of monitor refresh intervalZ
    %ifi=Screen('GetFlipInterval', w);

    vbl = Screen('Flip', w);
    
    color = [255 255 255];
    e_color = [0 0 0];

    % Animationloop:
    Help{1} = 'Esc: quit stimulus';
    Help{2} = 'z: make electrodes darker';
    Help{3} = 'x: make electrodes lighter';
    Help{4} = 'shift+z: make background darker';
    Help{5} = 'shift+x: make background lighter';

    screen.w = w;
    DrawMultiLineComment(screen, Help, 'x0', 300, 'y0', 300, 'color', [255 255 255]);
    Screen('Flip', w);

    [width height] = Screen('WindowSize', max(Screen('Screens')));
    
    
    % prevent keystrokes from writing onto script
%    ListenChar(2);
    while 1
        if KbCheck
            pause(0.2);
            break
        end
    end
    while 1
        Screen('FillRect', w, color);
        for i=1:size(mask,3)
            Screen('FillOval', w, e_color, mask(:,:,i));
        end
        
        vbl = Screen('Flip', w);
        
        [keyIsPressed, ~, keyCode] = KbCheck;
        
        increase_e_color = KbName('x');
        decrease_e_color = KbName('z');
        back_modifier = KbName('LeftShift');
        escape = KbName('escape');
        
        if keyCode(back_modifier)
            if keyCode(increase_e_color)
                if color(1) < 255
                    color = color + [1 1 1];
                end
            elseif keyCode(decrease_e_color)
                if color(1) > 0
                    color = color - [1 1 1];
                end
            end
        else
            if keyCode(increase_e_color)
                if e_color(1) < 255
                    e_color = e_color + [1 1 1];
                end
            elseif keyCode(decrease_e_color)
                if e_color(1) > 0
                    e_color = e_color - [1 1 1];
                end
            end
        end
        
        if keyCode(escape)
            break
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
%}