function run030311()
global pdStim screen

try
    CreateStimuliLogStart();
    
    
    % Define the rectangles
    [centerX, centerY] = Screen('WindowSize', max(Screen('Screens')));
    center1 =[centerX centerY]/2;
    objRect1 = GetRects(192, center1);
    
    
    InitScreen(0);

    %Wait2Start('debugging',1)
    % record for 1000 + 200*2 + 2000*2 + 4000 = 9400 seconds
    
    pdStim = 0;
    pause(1)
    RF( ...
        'movieDurationSecs', 1000, ...
        'barsWidth',16, ...
        'objContrast',1, ...
        'waitFrames', 1 ...
        );

    pause(1)
    pdStim = 1;
    texture = GetCheckersTex(512, 8, screen, 1);
    ContrastInformation( ...
        'presentationLength',1,  ...
        'movieDurationSecs', 600, ...
        'rects', objRect1, ...
        'backTexture', texture, ...
        'waitframes',1 ...
        );
    
    pause(1)
    BiMonoPhasicInformation( ...
        'presentationLength',1,  ...
        'movieDurationSecs', 9000, ...
        'rects', objRect1, ...
        'backTexture', texture, ...
        'waitframes',1 ...
        );
    
    CreateStimuliLogWrite();
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end
    
