function nextRun(length)

try
    Add2StimLogList();
    Wait2Start()

    RF('movieDurationSecs', 1600)
    pause(.2)
 
%    SaccadeObject_RF(12*PIXELS_PER_100_MICRONS, 0.5*PIXELS_PER_100_MICRONS, 600)
    pause(.2)
    
    % Stable object 
    objLums = ObjLums2();
    SaccadeObject('trialsPerBlock', length, 'objLums', objLums, 'blocksN',4);
    pause(.2)

%    SaccadeObject_RF(12*PIXELS_PER_100_MICRONS, 0.5*PIXELS_PER_100_MICRONS, 600)
%    TNF('peripheryStep',PIXELS_PER_100_MICRONS/2, 'checkersSize', PIXELS_PER_100_MICRONS/2);
     
    FinishExperiment();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..

end

function objLums = ObjLums1()
    barsN = 12;
    luminance = [0 31 64 127 255];
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
    barsN = 12;
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
