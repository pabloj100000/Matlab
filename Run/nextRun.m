function nextRun()

try
    Add2StimLogList();
    Wait2Start()

    % Stable object 
    StableObject4('trialsPerBlock', 2);
    pause(.2)
    
    % Stable object but probing low luminance in periphery
    StableObject4('periAlpha', .5, 'periLum', 0, 'trialsPerBlock', 2);
    pause(.2)

    % Stable object but probing hi luminance in periphery
    StableObject4('periAlpha', .5, 'periLum', 255, 'trialsPerBlock', 2);
    pause(.2)

    % Stable object but probing if periphery uses on/off pathway
    StableObject4('checkersSize', 768, 'trialsPerBlock', 2);
    pause(.2)
    
    DisplayTextures()
    pause(.2)
%}
    MessageScreen('StartRF')
    RF('movieDurationSecs', 1000)

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end
