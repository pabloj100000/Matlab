function ShowGaussianNatSceneWrapper()
global screen
try
    Add2StimLogList();
    Wait2Start()
    
    % Edit this parameters as needed
    % Experiment runs for length(imIndex)*(PresentationLength1 +
    % PresentationLength2)*trialsN
    contrast = 1;
    cellSize = 1*round(PIXELS_PER_100_MICRONS/2);
    nextSeed = 1;
    imIndex = 2:11;
    trialsN = 10;
    PresentationLength1 = 10;    % each trial of the same image has a different seed
    PresentationLength2 = 1;    % each trial of the same image has the same seed
    path = '';
    
    % do all computation upfront to prevent dropping frames in between images.
    [allMeans, allVariances, checkers] = ...
        GaussianizeImageSet(path, imIndex, cellSize, 1, contrast);
    for trial=1:trialsN
        % show each image for a rather long time, useful for computing
        % models early/late and comparing them
        for i=1:length(imIndex)
            presentationLength = PresentationLength1;
            framesPerSec = round(screen.rate/screen.waitframes);
            framesN = presentationLength*framesPerSec;

            if i==1
                seed = nextSeed;
                nextSeed = ShowCorrelatedGaussianCheckers(checkers, framesN,...
                    allMeans(i,:), allVariances(i,:,:), contrast, seed);
            else
                ShowCorrelatedGaussianCheckers(checkers, framesN,...
                    allMeans(i,:), allVariances(i,:,:), contrast, seed);
            end
            
            if (KbCheck)
                break
            end
        end
        
        % useful for analyzing saccades
        for i=1:length(imIndex)
            presentationLength = PresentationLength2;
            framesN = presentationLength*framesPerSec;

            seed = 1;
            ShowCorrelatedGaussianCheckers(checkers, framesN,...
                allMeans(i,:), allVariances(i,:,:), contrast, seed);
            if (KbCheck)
                break
            end
        end
        if (KbCheck)
            break
        end
    end
    
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end



