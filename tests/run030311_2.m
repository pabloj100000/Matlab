% File executed on: 03-Mar-2011 16:03:22
% List of default arguments:
% angle = 0
% backContrast = 1
% backJitterPeriod = 11
% backMode = 0  0  1  0
% backReverseFreq = 1
% backSeed = 2
% barsWidth = 8
% checkersN = 12
% checkersSize = 16  16
% color = 0
% debugging = 0
% distance = 5
% movieDurationSecs = 1600
% objCenterXY = 0  0
% objContrast = 0.05
% objJitterPeriod = 11
% objMean = 127
% objSeed = 1
% objSizeH = 192
% objSizeV = 192
% presentationLength = 10
% rects = 0    0  192  192
% repeatBackSeq = 0
% repeatObjSeq = 0
% sizeH = 0
% sizeV = 0
% stimSize = 512
% vbl = 0
% waitframes = 2

function run030311()
global pdStim screen

try
    CreateStimuliLogStart();
    
    
    % Define the rectangles
    [centerX, centerY] = Screen('WindowSize', max(Screen('Screens')));
    center1 =[centerX centerY]/2;
    objRect1 = GetRects(192, center1);
    
    
    Wait2Start();

    %Wait2Start('debugging',1)
    % record for 1000 + 200*2 + 2000*2 + 4000 = 9400 seconds
    
    pdStim = 0;
    pause(1)
    texture = GetCheckersTex(512, 8, screen, 1);
%{
    RF( ...
        'movieDurationSecs', 1000, ...
        'barsWidth',16, ...
        'objContrast',1, ...
        'waitFrames', 1 ...
        );

    pause(1)
    pdStim = 1;
    ContrastInformation( ...
        'presentationLength',1,  ...
        'movieDurationSecs', 9000, ...
        'rects', objRect1, ...
        'backTexture', texture, ...
        'waitframes',1 ...
        );
%}
    
    BiMonoPhasicInformation( ...
        'presentationLength',1,  ...
        'objContrast', .03, ...
        'movieDurationSecs', 7200, ...
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
