% Experiment finished running on: 09-Sep-2011 12:40:38
% ComputerName: hr-ozuysal-1201722562.stanford.edu
% Experiment finished running on: 01-Aug-2011 15:49:45
function run120111()

%   Record for 5500
try
    
    Wait2Start()
    %%%%%%%%%%%%%%%%%%%%%% Changing contrast every 100s %%%%%%%%%%%%%%%%%%%
    % traditional Gatting Experiment switching contrast every 100s
    % reversing 100um Checkers in background
% {
    %1000
    pause(.2)
    RF();
    
    %1000
    pause(.2)
    Sensitization('repeats', 50);
    
    %100
    pause(.2)
    OMS_identifier_LD;
    
    %3400
    pause(.2)
    UFlickerBorder;
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    psychrethrow(psychlasterror);
    rethrow(exception)
end %try..catch..

end
