function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    contrast = .1;
    path = '';
    presentationLength = 10;
    cellSize = round(PIXELS_PER_100_MICRONS/3);
    seed = 1;
    
    for i=1:2
        ShowGaussianNatScene(contrast, 2, path, presentationLength, cellSize, seed);
        pause(.2)
        
        ShowGaussianNatScene(contrast, 3, path, presentationLength, cellSize, seed);
        pause(.2)
        
        ShowGaussianNatScene(contrast, 4, path, presentationLength, cellSize, seed);
        pause(.2)
    end
    
    LuminanceChange

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end



