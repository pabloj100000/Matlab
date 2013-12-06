function run021311()
global pdStim screen

try
    CreateStimuliLogStart();
    
    
    % Define the rectangles
    [centerX, centerY] = Screen('WindowSize', max(Screen('Screens')));
    center1 =[centerX centerY]/2;
    objRect1 = GetRects(192, center1);
    
    diameters = ones(1,4)*192/2;
    centers = ones(4,1)*[488 416 488 416];
    centers = centers + 192/4* ...
        [-1 -1 -1 -1; ...
        -1 1 -1 1; ...
        1 -1 1 -1; ...
        1 1 1 1];
    objRects = GetRects(diameters, centers);
    %objRects = [objRect1; objRects];
    
    InitScreen(0);

    %Wait2Start('debugging',1)
    % record for 1000 + 200*2 + 2000*2 + 4000 = 9400 seconds
    
    pdStim = -1;
    
    
    pdStim = pdStim+1;
    pause(1)
    RF( ...
        'movieDurationSecs', 1000, ...
        'barsWidth',16, ...
        'objContrast',1, ...
        'waitFrames', 1 ...
        );
    
    backSeed = 2;
    sizesStream = RandStream('mcg16807', 'Seed', backSeed);
    angleStream = RandStream('mcg16807', 'Seed', backSeed+1);
    checkerSizeStream = RandStream('mcg16807', 'Seed', backSeed+2);
    
    N=10;
    time = 10;
    
    rectSizeSeq = randperm(sizesStream, N);
    rectSizeSeq = mod(rectSizeSeq, 5)+1;
    
    angleSeq = randperm(angleStream, N);
    angleSeq = mod(angleSeq, 4);
    
    checkerSizesSeq = randperm(checkerSizeStream, N);
    checkerSizesSeq = mod(checkerSizesSeq, 6)+1;
    
    texture{1} = GetCheckersTex(512, 2, screen, 1);
    texture{2} = GetCheckersTex(512, 4, screen, 1);
    texture{3} = GetCheckersTex(512, 8, screen, 1);
    texture{4} = GetCheckersTex(512, 16, screen, 1);
    texture{5} = GetCheckersTex(512, 32, screen, 1);
    texture{6} = GetCheckersTex(512, 64, screen, 1);
    
    for i=1:N
        
        objRect = GetRects(rectSizeSeq(i)*64, center1);
        backAngle = angleSeq(i)*90/5;
        
        
        UflickerObj2( ...
            'objContrast', .03, ...     % I put the contrasts in this order so that they will be shown (after randommization) in order of increasing contrast.
            'rects', objRect, ...
            'backMode', [0 0 1 0], ...
            'angle', backAngle, ...
            'backReverseFreq', 1, ...
            'backTexture', texture{checkerSizesSeq(i)}, ...
            'barsWidth', 2^checkerSizesSeq(i), ...
            'objJitterPeriod', time, ...
            'presentationLength', time, ...
            'movieDurationSecs', time ...
            );
    end
    
    CreateStimuliLogWrite();
catch
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end
    
