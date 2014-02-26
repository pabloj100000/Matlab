function nextRun(length)

try
    Add2StimLogList();
    Wait2Start()

    RF('movieDurationSecs', 1600)
    pause(.2)
 
    SaccadeObject_RF(12*PIXELS_PER_100_MICRONS, 0.5*PIXELS_PER_100_MICRONS, 600)
    pause(.2)
    
    % Stable object 
    objLums = ObjLums1();
    SaccadeObject('trialsPerBlock', length, 'objLums', objLums, 'blocksN',4);
    pause(.2)

    SaccadeObject_RF(12*PIXELS_PER_100_MICRONS, 0.5*PIXELS_PER_100_MICRONS, 600)
    TNF('peripheryStep',PIXELS_PER_100_MICRONS/2, 'checkersSize', PIXELS_PER_100_MICRONS/2);
     
    objLums = ObjLums2();
    SaccadeObject('trialsPerBlock', length/2, 'objLums', objLums, 'blocksN',4);
    pause(.2)

    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end

function objLums = ObjLums1()
    barsN = 24;
    luminanceN = 5;
    stepsN = luminanceN-1;
    meanLum = 127;
    maxLum = 2*meanLum;

    % I want to go roughly from 127 (mean) to the maximum luminance (255)
    % in luminanceN/2 steps. Therefore 127*b^(N/2) = 255 and from this I
    % have b^(N/2) = 255/127 and N/2*log(b) = log(2) and log(b) =
    % log(2)*2/N and b = exp(log(2)*2/N)
    newBase = exp(log(2)*2/stepsN);      % one of the 2 comes from 255/127, the other cause I want half the steps above mean and half below the mean
    
    logMaxLum = log(maxLum)/log(newBase);
    logMeanLum = log(127)/log(newBase);
    logDelta = (logMaxLum-logMeanLum)/(stepsN/2);

    luminance = logMaxLum-stepsN*logDelta:logDelta:logMaxLum;
    luminance = round(newBase.^luminance);
    
    objectsN=length(luminance);
    objLums = ones(1, barsN, objectsN);
    bars = ones(1, barsN);
    
    for i=1:objectsN
        objLums(1, :, i) = bars*luminance(i);    
    end
    objLums(1, 1, :) = 127;
    objLums(1, barsN, :) = 127;
end

function objLums = ObjLums2()
    barsN = 24;
    colors = [-127 -63 -31 -15 -7 -3 -1 0 1 3 7 15 31 63 127];
    objectsN = length(colors);
    objLums = ones(1, barsN, objectsN);
    bars = ones(1, barsN);
    bars(barsN/2+1:end)=-1;
    bars(1)=0;
    bars(barsN)=0;
    
    for i=1:objectsN
        color = colors(i);
        objLums(1, :, i) = round(bars*color+127);    
    end
end
