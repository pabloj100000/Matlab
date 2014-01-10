function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    % Stable object 
    StableObject5('trialsPerBlock', 2);
    pause(.2)

    
    RF('movieDurationSecs', 1000)
    pause(.2)
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end
