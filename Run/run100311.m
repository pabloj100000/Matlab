function run100311()
    % 1600 + 1000 + 2*1600 + 7200 + 800 = 13800

try

    objRect = GetRects(192, [512 384] );
    stimSize = 768;
    barsWidth = 8;
    
    Wait2Start()
% {
    %1600
    pause(.2)
    RF('movieDurationSecs', 1600);
    
    %1000
    pause(.2)
    Sensitization('repeats', 50);

    for i=1:2
        % 1600
        pause(.2)
        UflickerObj( ...
            'objContrast',[0 .24 .12 .03 .0075 .06 1 .015], ...
            'rects', objRect, ...
            'backMode', [0 0 1 0], ...
            'backPattern', 1, ...
            'barsWidth', barsWidth, ...
            'stimSize', stimSize, ...
            'pdStim', 110, ...
            'backReverseFreq', .5, ...
            'backJitterPeriod', 200, ...
            'objJitterPeriod', 200, ...
            'presentationLength', 200, ...
            'movieDurationSecs', 1600 ...
            );
    end
    
    %800
    pause(.2)
    StableObject2('backPattern',1);

    %7200
    ContrastPhaseInformation( ...
        'objContrasts', [.015 .03 .06 .12 .24], ...
        'objCheckerSize', 192, ...
        'backPattern', 1, ...
        'backCheckerSize', barsWidth, ...
        'objFreq', 10, ...
        'presentationLength', 17, ...
        'movieDurationSecs', 7200, ...
        'objRect', objRect ...
        );
        

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception);
end %try..catch..

end
