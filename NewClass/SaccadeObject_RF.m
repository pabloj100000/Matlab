function SaccadeObject_RF(objSize, saccadeSize)

Add2StimLogList();
RF('checkerSizeX', PIXELS_PER_100_MICRONS/2, 'checkerSizeY', objSize, ...
    'stimSize', [objSize+saccadeSize objSize], ...
    'noiseType', 'gaussian');
FinishExperiment();
