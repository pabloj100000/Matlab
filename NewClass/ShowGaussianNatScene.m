function seed = ShowGaussianNatScene(contrast, imNumber, impath, presentationLength, ...
    cellSize, seed, scramble)
% scramble: 0, no scramble
%           1, scramble means
%           2, scramble changes
%           3, scramble both mean and changes together
%           4, scramble both mean and changes but indepdendently
global screen 
try
    InitScreen(0)
    Add2StimLogList();

    % Gaussianize the image
    [cellsMean, variances, checkers] = ...
        GaussianizeImageSet(impath, imNumber, cellSize, 1, contrast);

    variances = reshape(variances, size(variances,2), size(variances,3));
    
    % this might be useful. Allows to scramble different statistics of the
    % checkers. Pass scramble = 0 to do nothing
    if scramble
        [cellsMean, variances] = ...
            ScrambleImages(cellsMean, varianceUp, varianceLeft, scramble);
    end
        
    framesPerSec = round(screen.rate/screen.waitframes);
    framesN = presentationLength*framesPerSec;
    
%    seeds = zeros(1, size(ch,2));

    seed = ShowCorrelatedGaussianCheckers(checkers, framesN, cellsMean, ...
        variances, contrast, seed);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end

function [scrambledMean, scrambledVarianceUp, scrambledVarianceLeft] = ...
        ScrambleImages(cellMeans1D, varianceUp1D, varianceLeft1D, scramble)
    % all images are 1D and depending on scramble flag I might want to
    % scramble their values.
    % scramble: bit 0, scramble means
    %           bit 1, scramble varianceUp1D
    %           bit 2, scramble varianceLeft1D
    %           bit 3, scramble varianceUp1D independently
    %           bit 4, scramble varianceLeft1D independently
    % bit 1 and 3 are not designed to be used simultaneously
    % bit 2 and 4 are not designed to be used simultaneously
    scrambledMean = cellMeans1D;
    scrambledVarianceUp = varianceUp1D;
    scrambledVarianceLeft = varianceLeft1D;
    
    checkersN = length(scrambledMean);
    bits = de2bi(scramble, 5);
    
    firstPermutation = randperm(checkersN);
    for bit=0:4
        % looping through all the bits
        if bits(bit+1)
            % if bit is set, do the corresponding computation
            % if not just coninue
            switch (bit)
                % do corresponding caluclation for current bit
                case 0
                    scrambledMean = cellMeans1D(firstPermutation);
                case 1
                    scrambledVarianceUp = varianceUp1D(firstPermutation);
                case 2
                    scrambledVarianceLeft = varianceLeft1D(firstPermutation);
                case 3
                    scrambledVarianceUp = varianceUp1D(randperm(checkersN));
                case 4
                    scrambledVarianceLeft = varianceLeft1D(randperm(checkersN));
            end
        end
    end
end


