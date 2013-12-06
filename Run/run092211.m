% Experiment finished running on: 09-Sep-2011 12:40:38
% ComputerName: hr-ozuysal-1201722562.stanford.edu
% Experiment finished running on: 01-Aug-2011 15:49:45
function run092211()
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
% {
    %1000
    pause(.2)
    RF();

    for i=1:5
        % 1000
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
    % }    

        %1000
        pause(.2)
        UFlickerObj_loop1('presentationLength', 200, 'backPeriod', 2)
    end
    
    pause(.2)
    UFlickerObj_loop1('presentationLength', 200, 'backPeriod', 2, ...
        'objContrast', [.0025 .005 .01 .02 .04])%, 'pdStim', 109)

    %1000
    pause(.2)
    Sensitization('repeats', 50);
    
    %400
    pause(.2)
    StableObject('backPattern',1);

    FinishExperiment();
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
end %try..catch..

end
