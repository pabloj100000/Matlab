function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    path='/Users/baccuslab/Desktop/stimuli/Pablo/Natural Images DB/cd01A';
    ShowGaussianNatSceneWrapper(10, 'ctrlFlag',1, 'trialsN',1, 'path', path);
    pause(.2)
    
    ShowGaussianNatSceneWrapper(60, 'path', path, 'cellSize', 2);
    pause(.2)
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end



