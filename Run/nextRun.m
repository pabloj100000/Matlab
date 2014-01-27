function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    RF('movieDurationSecs', 1000)
    pause(.2)

    SaccadeObject_RF(12*PIXELS_PER_100_MICRONS, 0.5*PIXELS_PER_100_MICRONS, 600)
    pause(.2)
    
    % Stable object 
    SaccadeObject('trialsPerBlock', 110);
    pause(.2)

    pause(.2)
    
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end
