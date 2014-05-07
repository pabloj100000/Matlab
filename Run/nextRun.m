function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    RF('movieDurationSecs', 1000)
    pause(.2)

    TNF2Wrapper('
    
    StableObject2('barsWidth', PIXELS_PER_100_MICRONS*.5)
    pause(.2)
    
    TNF_Gaussian([-1;-1], 1200,0, 'presentationLength', 100, 'config',5, 'trialsN',2)
    pause(.2)

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end


function lumSeq = GetLumSeq()
    repeats = 100;
    L = [32 64 128 256]-1;
    
    lumSeq = ones(1, repeats*length(L)^2);
    for i=1:repeats
        lumSeq((i-1)*length(L)^2+1:i*length(L)^2) = [L(1) L(2) L(3) L(4) L(1) L(3) L(1) L(4) L(2) L(4) L(4) L(3) L(3) L(2) L(2) L(1)];
    end
end

