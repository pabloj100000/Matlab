function run072711()
global screen

%  Record for 402s three times, then
% Record for 1000 + 50 + 120 + 4*500 + 10800 = 14000
try

    objRect = GetRects(192, [512 384] );
    stimSize = 768;
    barsWidth = 8;
    
    Wait2Start()
    %%%%%%%%%%%%%%%%%%%%%% Changing contrast every 100s %%%%%%%%%%%%%%%%%%%
    % traditional Gatting Experiment switching contrast every 100s
    % reversing 100um Checkers in background
    % 500
% {
    pause(.2)
    UflickerObj( ...
        'objContrast', [.12 .35 .24 .06 .03], ...
        'rects', objRect, ...
        'backMode', [0 0 1 0], ...
        'backPattern', 1, ...
        'barsWidth', barsWidth, ...
        'stimSize', stimSize, ...
        'pdStim', 106, ...
        'backReverseFreq', .5, ...
        'backJitterPeriod', 200, ...
        'objJitterPeriod', 200, ...
        'presentationLength', 200, ...
        'movieDurationSecs', 1000 ...
        );
%}    
    %%%%%%%%%%%%%%%%%%%%%%% information experiment %%%%%%%%%%%%%%%%%%%%%%%%
    pause(.2)
    ContrastPhaseInfo()

% {
    pause(.2)
    RF();
    
    pause(.2)
    Sensitization();
%}        
    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..

end
