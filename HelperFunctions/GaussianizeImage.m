function [cellsMean, variances, checkers] = ...
    GaussianizeImage(originalImage, cellSize, movementSize, contrast)
% From a given image (may be a natural scene), return 3 different 1D arrays
% which along with checkers can generate these images:
%   cellsMean, the mean seen by a cell of size 'cellSize' 
%              under the original image.
%   varianceUp,  the LP a cell will see by a moving the image up by
%              movementSize
%   varianceLeft, idem varianceUp but to the left
%   
% It also returns 'checkers', a 4 x checkerN array (the format that Screen
% 'FillRect' expects.
% The idea is that the command:
%
%   Screen('FillRect', screen.w, ones(3, 1)*cellsMean, checkers)
%
% will display the image with the means.

debugFlag=0;
Add2StimLogList();

% convolve w_im with a square of size 'cellSize'
h = fspecial('average', cellSize);
filteredImage = uint8(imfilter(originalImage, h));

cellsMean = mean(filteredImage, 3);

% Each pixel in the image represents a cell of the given size, but those
% cells are extremely near to each other, they overlap a lot.
% I am only going to take tiling patches such that each point in the image
% belongs to one and only one cell.
% I'm going to move those cells according to FEM_x, FEM_y and extract the
% mean and sd of each cell

% subtract from filteredImage a shifted version
varianceLeft = cellsMean(:, 1+movementSize:end) -...
    cellsMean(:, 1:end-movementSize);

varianceUp = cellsMean(1+movementSize:end, :) -...
    cellsMean(1:end-movementSize, :);

% now limit all images cellsMean, varianceUp, changeDown to be the same
% size
sizes = [size(cellsMean); size(varianceUp); size(varianceLeft)];
finalSize = min(sizes);

% Downsample the image to be only a given number of cells in x, y
% Generate arrays with the cell centers
centersX = 1:cellSize:finalSize(1);
centersY = 1:cellSize:finalSize(2);


cellsMean = cellsMean(centersX, centersY);
varianceUp = varianceUp(centersX, centersY);
varianceLeft = varianceLeft(centersX, centersY);

% output arrays are 1D for the mean and variances and checkers is 4 x
% checkersN, this is the format that Screen('FillRect') expects.

% Generate checkers, output has to be of size (4,checkersN)
ch_vert = size(cellsMean,1);
ch_hori = size(cellsMean,2);
%ch_offset = screen.center - size(cellMeans)*cellSize/2;
ch_offset = [0 0];
checkers = tileCheckers(ch_hori, ch_vert, cellSize, cellSize, ch_offset(1),...
    ch_offset(2), cellSize, cellSize);

% convert cellMeans, varianceUp, varianceLeft to 1D
cellsMean = reshape(cellsMean', 1, size(cellsMean,1)*size(cellsMean,2));
varianceUp = reshape(varianceUp', 1, size(varianceUp,1)*size(varianceUp,2));
varianceLeft = reshape(varianceLeft', 1, size(varianceLeft,1)*size(varianceLeft,2));

% Normalize variances such that max variance is 1 after combining Up and
% Left
variances = normalizeVariance(varianceUp, varianceLeft);
% Normalize means such that luminance are constrained to 0 and 255
cellsMean = normalizeMeans(cellsMean, variances, contrast);


if debugFlag
    figure(1)
    imshow(originalImage)
    figure(2)
    imshow(cellsMean)
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