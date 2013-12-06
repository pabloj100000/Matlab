function run042811()
global pdStim screen

% Record for 1000 + 340 + 220 * 4 + 220* 5 + 200 *3 = 3920
try
    CreateStimuliLogStart();    

    Wait2Start('debugging',0)
    
    % Define the rectangles
    objRect = GetRects(192, screen.center);

    % 1000s
    pdStim = 0;

    pause(.2)
    RF( ...
        'movieDurationSecs', 1000, ...
        'barsWidth',16, ...
        'objContrast',1, ...
        'waitFrames', 1 ...
        );

    % 340s
    pdStim = pdStim+1;
    pause(.2)
    OMS_identifier_LD('presentationLength',20, 'barsWidth', 16);
    
    %%%%%% Testing information with different temporal freq in object %%%%%%
    % 220*4 = 880
    pause(.2)
    pdStim = pdStim+1;
    for objFreq = 5:5:20
        ContrastPhaseInformation(...
            'backContrast', 1, ...
            'objContrasts', [.06 1], ...
            'objCheckerSize', 192, ...
            'objFreq', objFreq, ...
            'stimSize', 512, ...
            'presentationLength', 11, ...
            'movieDurationSecs', 220, ...
            'objRect', objRect ...
            );
    end
    
    %%%%%% Testing information with different spatial freq in object %%%%%%
    % 220*5 = 1100
    pause(.2)
    pdStim = pdStim+1;
    sizes = [8 16 32 64 192];
    for checkSize = 1:5
        ContrastPhaseInformation(...
            'backContrast', 1, ...
            'objContrasts', [.06 1], ...
            'objCheckerSize', sizes(checkSize), ...
            'objFreq', 15, ...
            'stimSize', 512, ...
            'presentationLength', 11, ...
            'movieDurationSecs', 220, ...
            'objRect', objRect ...
            );
    end

    %%%%%%%%%%%%%%%%%%%%%% Changing contrast every 100s %%%%%%%%%%%%%%%%%%%

    % traditional Gatting Experiment switching contrast every 100s
    % reversing 100um Checkers in background
    % 200
    pdStim = pdStim+1;

    stimSize = 832;
    barsWidth = 16;
    backTex = GetCheckersTex(stimSize, barsWidth, screen, 1);
    pause(.2)

    UflickerObj( ...
        'objContrast', [.06 1], ...
        'rects', objRect, ...
        'backMode', [0 0 1 0], ...
        'backTexture', backTex, ...
        'barsWidth', barsWidth, ...
        'stimSize', stimSize, ...
        'backReverseFreq', 1, ...
        'backJitterPeriod', 100, ...
        'objJitterPeriod', 100, ...
        'presentationLength', 100, ...
        'movieDurationSecs', 200 ...
        );
    
    
    %%%%%%%%%%%%%%%%%%%%%% Changing contrast every 1s %%%%%%%%%%%%%%%%%%%


    % traditional Gatting Experiment switching contrast every 100s
    % reversing 100um Checkers in background
    % 200
    pdStim = pdStim+1;
    stimSize = 832;
    barsWidth = 16;
    backTex = GetCheckersTex(stimSize, barsWidth, screen, 1);
    pause(.2)
    UflickerObj( ...
        'objContrast', [.06 1], ...
        'rects', objRect, ...
        'backMode', [0 0 1 0], ...
        'backTexture', backTex, ...
        'barsWidth', barsWidth, ...
        'stimSize', stimSize, ...
        'backReverseFreq', 1, ...
        'backJitterPeriod', 1, ...
        'objJitterPeriod', 1, ...
        'presentationLength', 1, ...
        'movieDurationSecs', 200 ...
        );

    %%%%%%%%%%%%%%%%    % Sky doesn't dissapear experiment  %%%%%%%%%%%%%%%
    % 200s
    pause(.2)
    pdStim = pdStim+1;
    StableObject( ...
        'backMode', [0 0 1 0], ...
        'barsWidth', 16, ...
        'stimSize', stimSize, ...
        'backReverseFreq', 1, ...
        'presentationLength', 50, ...
        'movieDurationSecs', 200 ...
        );
%}    
    CreateStimuliLogWrite();

catch 
    FinishExperiment();
    psychrethrow(psychlasterror);
end %try..catch..
end
