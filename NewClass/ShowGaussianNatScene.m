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

    % Load image from DB
    if (isempty(impath))
        impath = '/Users/jadz/Documents/Notebook/Matlab/Natural Images DB/RawData/cd01A';
    end
    imList = dir([impath,'/*LUM.mat']);
    struct = load([impath, '/',imList(imNumber).name]);
    w_im = struct.LUM_Image;
    w_im = w_im*2^8/max(w_im(:));

    % Gaussianize the image
    [cellMeans, varianceUp, varianceLeft]=GaussianizeImage(w_im, cellSize, 1);

    % Generate checkers, output has to be of size (4,checkersN)
    ch_vert = size(cellMeans,1);
    ch_hori = size(cellMeans,2);
    %ch_offset = screen.center - size(cellMeans)*cellSize/2;
    ch_offset = [0 0];
    ch = tileCheckers(ch_hori, ch_vert, cellSize, cellSize, ch_offset(1),...
        ch_offset(2), cellSize, cellSize);
    %{
        %%%%%%%%%% This is used to turn on/off parts of the code and
        explain stimulus generation %%%%%%%%%%%
    example =0;
    switch example
        case 0
            % just the mean
            varianceUp = varianceUp*0;
            varianceLeft = varianceLeft*0;
        case 1
            % only Up change, around gray mean
            cellMeans = ones(size(cellMeans))*127;
            varianceLeft = varianceLeft*0;
        case 2
            % only Left change, around gray mean
            cellMeans = ones(size(cellMeans))*127;
            varianceUp = varianceUp*0;
        case 3
            % Only some checkers, correct mean, zero contrast
            varianceUp = varianceUp*0;
            varianceLeft = varianceLeft.*0;
            filter = zeros(size(varianceLeft));
            filter(1:25:size(cellMeans,1), 1:25:size(cellMeans,2))=1;
            cellMeans = cellMeans.*filter;
        case 4
            % Only some checkers, correct mean, correct contrast
            varianceUp = varianceUp*0;
            filter = zeros(size(varianceLeft));
            filter(1:25:size(cellMeans,1), 1:25:size(cellMeans,2))=1;
            cellMeans = 0 + filter*127;
            varianceLeft = varianceLeft.*filter;
    end
        %}

    % convert cellMeans, varianceUp, varianceLeft to 1D
    cellMeans1D = reshape(cellMeans', 1, size(cellMeans,1)*size(cellMeans,2));
    varianceUp1D = reshape(varianceUp', 1, size(varianceUp,1)*size(varianceUp,2));
    varianceLeft1D = reshape(varianceLeft', 1, size(varianceLeft,1)*size(varianceLeft,2));

    % this might be useful. Allows to scramble different statistics of the
    % checkers. Pass scramble = 0 to do nothing
    [cellMeans1D, varianceUp1D, varianceLeft1D] = ...
        ScrambleImages(cellMeans1D, varianceUp1D, varianceLeft1D, scramble);
    
    % Normalize both means and variances
    variances = normalizeVariance(varianceUp1D, varianceLeft1D);
    cellMeans1D = normalizeMeans(cellMeans1D, variances, contrast);
    
    framesPerSec = round(screen.rate/screen.waitframes);
    framesN = presentationLength*framesPerSec;
    
%    seeds = zeros(1, size(ch,2));
    ShowCorrelatedGaussianCheckers(ch, framesN, cellMeans1D, variances, contrast, seed);
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

function [variances] = normalizeVariance(varianceUp1D, varianceLeft1D)
% Each checker follows a gaussian distribution with mean given by
% scrambleMean (?) and variance given by:
% ?^2*(varianceLeft + varianceUp)*contrast^2
% such that
% Contrast = sigma/? = sqrt(varianceLeft + varianceUp)*contrast
% I want to normalize those variances such that the total contrast
% is always between 0 and contrast, therefore I am normalizing
% variance to be between 0 and 1.
maxVar = max(abs(varianceLeft1D)+abs(varianceUp1D));
variances = [varianceUp1D; varianceLeft1D]/maxVar;

end

function cellMeans1D = normalizeMeans(cellMeans1D, variances, contrast)
% normalize meas such that mean +3*mean*SD*contrast < 255 for every checker
% or mean*(1+3*SD*contrast)<255
% or mean < 255/(1+3*SD*contrast)
oldMax = max(cellMeans1D);
while max(cellMeans1D .*  (1+3*sqrt(sum(variances))*contrast))>255;
    % reduce maximum mean
    cellMeans1D = cellMeans1D * .95;
end

newMax = max(cellMeans1D);
[oldMax newMax]
end