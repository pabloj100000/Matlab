function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    RF;
    pause(.2)
    
    CheckerPhases;
    pause(.2)
    
    ShowGaussianNatScene('trialsN', 100, 'presentationLength', 2);
    pause(.2)
    
    ShowGaussianNatScene('trialsN', 10, 'presentationLength', 2, 'resetSeed', 1);
    pause(.2)
    
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end



