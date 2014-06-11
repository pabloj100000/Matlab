function [cellsMean, gradientUp, gradientLeft] = ...
    GaussianizeImage(originalImage, cellSize, movementSize, contrast,...
    outputSize)
% From a given image (may be a natural scene), returns 3 arrays which can 
% simulate something similar to the scene undergoing FEM but where each
% pixel is actually gaussian.
%   cellsMean,  the mean seen by a cell of size 'cellSize' 
%               under the original image.
%   gradients,  the LP a cell will see by a moving the image up by
%               movementSize
%   
% It also returns 'checkers', a 4 x checkerN array (the format that Screen
% 'FillRect' expects.
% The idea is that the command:
%
%   Screen('FillRect', screen.w, ones(3, 1)*cellsMean, checkers)
%
% will display the image with the means.
global screen

debugFlag=0;
Add2StimLogList();

% convolve w_im with a square of size 'cellSize'
h = fspecial('average', cellSize);
smallImage = originalImage(1:outputSize, 1:outputSize);
%smallImage = originalImage(1:cellSize*outputSize, 1:cellSize*outputSize);
filteredImage = uint8(imfilter(smallImage, h));

cellsMean = mean(filteredImage, 3);

% Each pixel in the image represents a cell of the given size, but those
% cells are extremely near to each other, they overlap a lot.
% I am only going to take tiling patches such that each point in the image
% belongs to one and only one cell.
% I'm going to move those cells according to FEM_x, FEM_y and extract the
% mean and sd of each cell

% subtract from filteredImage a shifted version
gradientLeft = cellsMean(:, 1+movementSize:end) -...
    cellsMean(:, 1:end-movementSize);

gradientUp = cellsMean(1+movementSize:end, :) -...
    cellsMean(1:end-movementSize, :);

% now limit all images cellsMean, gradientUp, changeDown to be the same
% size
sizes = [size(cellsMean); size(gradientUp); size(gradientLeft)];
finalSize = min(sizes);

% Downsample the image to be only a given number of cells in x, y
% Generate arrays with the cell centers
centersX = 1:cellSize:finalSize(1);
centersY = 1:cellSize:finalSize(2);


cellsMean = cellsMean(centersX, centersY);
gradientUp = gradientUp(centersX, centersY);
gradientLeft = gradientLeft(centersX, centersY);

% output arrays are 1D for the mean and gradients and checkers is 4 x
% checkersN, this is the format that Screen('FillRect') expects.

% Normalize gradients such that max gradient is 1 after combining Up and
% Left
[gradientUp, gradientLeft] = normalizeGradient(gradientUp, gradientLeft);
% Normalize means such that luminance are constrained to 0 and 255
cellsMean = normalizeMeans(cellsMean, gradientUp, gradientLeft, contrast);


if debugFlag
    figure(1)
    imshow(originalImage)
    figure(2)
    imshow(cellsMean)
end
end


function [gradientUp, gradientLeft] = normalizeGradient(gradientUp, gradientLeft)
% Each checker follows a gaussian distribution with mean given by
% scrambleMean (?) and gradient given by:
% ?^2*(gradientLeft + gradientUp)*contrast^2
% such that
% Contrast = sigma/? = sqrt(gradientLeft + gradientUp)*contrast
% I want to normalize those gradients such that the total contrast
% is always between 0 and contrast, therefore I am normalizing
% gradient to be between 0 and 1.
maxVar = max(abs(gradientLeft(:))+abs(gradientUp(:)));
gradientUp = gradientUp/maxVar;
gradientLeft = gradientLeft/maxVar;
end

function cellMeans = normalizeMeans(cellMeans, gradientUp, gradientLeft, contrast)
% normalize meas such that mean +3*mean*SD*contrast < 255 for every checker
% or mean*(1+3*SD*contrast)<255
% or mean < 255/(1+3*SD*contrast)
cellMeans1D = cellMeans(:);
gradients1D = abs(gradientUp(:))+abs(gradientLeft(:));

while max(cellMeans1D .*  (1+3*sqrt(gradients1D)*contrast))>255;
    % reduce maximum mean
    cellMeans1D = cellMeans1D * .95;
    cellMeans = cellMeans * .95;
end
end