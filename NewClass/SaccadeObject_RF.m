function SaccadeObject_RF(objSize, saccadeSize, timeInSeconds)
    % objSize: in pixels, probably 12*PIXELS_PER_100_MICRONS
    % saccadeSize: in pixesl, probably PIXELS_PER_100_MICRONS/2
    % timeInSeconds: how long to measure the RF for, typically 600s
Add2StimLogList();
RF('checkerSizeX', PIXELS_PER_100_MICRONS/2, 'checkerSizeY', objSize, ...
    'stimSize', [objSize+saccadeSize objSize], ...
    'noiseType', 'gaussian', 'movieDurationSecs', timeInSeconds);
FinishExperiment();
