function TNF2Wrapper(meanContrast, contrast)
%   modify as needed

InitScreen(0)
Add2StimLogList();
%commonFlags = ['resetFixationSeed', 1, 'blocksN', 1, 'repeatsPerBlock', 1];
[lumSeq, contrastSeq] = GetLumAndContrast(meanContrast, contrast);

TNF2(contrastSeq, lumSeq, 'blocksN', 10, 'repeatsPerBlock', 10, ...
    'resetFixationSeed', 1);

FinishExperiment();
end

function [lumSeq, contrastSeq] = GetLumAndContrast(meanContrast, contrast)
    stimSeq = [0 1 2 3 4 5 0 2 4 0 3 5 1 3 0 4 1 4 2 5 2 0 5 3 1 5 5 4 4 3 3 2 2 1 1 0];
    
    lumSeq = round((mod(stimSeq, 3)-1)*127*meanContrast+127);
    contrastSeq = floor(stimSeq/3)*contrast;
end