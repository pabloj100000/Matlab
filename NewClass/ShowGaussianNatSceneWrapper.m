function ShowGaussianNatSceneWrapper(presentationLength, resetSeed, ctrlFlag)
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
    path = '';
    outputSize = min(screen.size);
    
    if ctrlFlag
        imIndex = 1;
    end
    
    % do all computation upfront to prevent dropping frames in between images.
    [allMeans, allVariances, checkers] = ...
        GaussianizeImageSet(path, imIndex, cellSize, 1, contrast, outputSize);

    if ctrlFlag
        allMeans = ones(size(allMeans))*127;
        allVariances = ones(size(allVariances))*1;
        contrast=.1;
    end
    
    seed = nextSeed;
    
    for trial=1:trialsN
        % show each image for a rather long time, useful for computing
        % models early/late and comparing them
        for i=1:length(imIndex)
            framesPerSec = round(screen.rate/screen.waitframes);
            framesN = presentationLength*framesPerSec;

            if i==1 && ~resetSeed
                % if resetSeed, we are never executing this line and every
                % time will be using the same seed
                seed = nextSeed;
            end
            nextSeed = ShowCorrelatedGaussianCheckers(checkers, framesN,...
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



