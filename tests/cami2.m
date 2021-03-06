function cami
% Parameters
lineWidth = 32;
squareSize = 100;
rectSize = 700;
angle = 0;

movieDurationSecs=20; % Abort demo after 20 seconds.
texsize=300; % Half-Size of the grating image.

try
    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'));

    % Find the color values which correspond to white and black.
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	gray=round((white+black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
		gray=white / 2;
    end

    % Open a double buffered fullscreen window with a gray background:
    if (screenNumber == 0)
%        [w screenRect]=Screen('OpenWindow',screenNumber, gray, [0 0 400 400]);
        [w screenRect]=Screen('OpenWindow',screenNumber, gray);
    else
        [w screenRect]=Screen('OpenWindow',screenNumber, gray);
    end
    
    % Create one single static grating image:
    % MK: We only need a single texture row (i.e. 1 pixel in height) to
    % define the whole grating! If srcRect in the Drawtexture call below is
    % "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows. This 1 pixel height saves memory
    % and memory bandwith, ie. potentially faster.
    [x,y]=meshgrid(1:rectSize, 1);
    grating=mod(floor(x/lineWidth), 2)*white;


    % Store grating in texture:
    gratingtex=Screen('MakeTexture', w, grating);

    % Create a single gaussian transparency mask and store it to a texture:
    mask    = ones(rectSize, rectSize, 2) * gray;
    [x,y]   = meshgrid(1:rectSize, 1:rectSize);
    maskX   = mod(floor(x/squareSize), 2);
    maskY   = mod(floor(y/squareSize), 2);
    maskZ   = white * ((maskX .* maskY) + (1-maskX) .* (1-maskY));
    mask(:, :, 2)=maskZ(:,:);
    masktex=Screen('MakeTexture', w, mask);
    clear x y mask maskX maskY %maskZ
    
    % Definition of the drawn rectangle on the screen:
    dstRect=SetRect(0,0, rectSize, rectSize);
    dstRect=CenterRect(dstRect, screenRect);

    % Query duration of monitor refresh interval:
    ifi=Screen('GetFlipInterval', w);

    waitframes = 1;
    waitduration = waitframes * ifi;


    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl=Screen('Flip', w);

    % We run at most 'movieDurationSecs' seconds if user doesn't abort via
    % keypress.
    vblendtime = vbl + movieDurationSecs;
    i=0;

    % Animationloop:
    square1 = SetRect(0, 0, 20, 10);
    square1 = CenterRect(square1, screenRect);
    
    Screen('FillRect', w, black);

    Screen('FillRect', w, [255 0 0], square1);
    Screen('Flip', w);

    while ~KbCheck %#ok<AND2>

    end;

    Priority(0);
    Screen('CloseAll');

catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    clear Screen
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end %try..catch..
