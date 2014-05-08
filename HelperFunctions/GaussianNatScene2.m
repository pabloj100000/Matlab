function [cellsMean, changeUp, changeLeft] = ...
    GaussianNatScene2(originalImage, cellSize, movementSize)
% From a given natural scene, return 3 different images.
%   cellsMean, the mean seen by a cell under the original image.
%   changeUp,  the LP a cell will see by a moving the image up by movementSize
%   changeLeft, idem changeUp but to the left

debugFlag=0;

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
changeUp = cellsMean(:, 1+movementSize:end) -...
    cellsMean(:, 1:end-movementSize);

changeLeft = cellsMean(1+movementSize:end, :) -...
    cellsMean(1:end-movementSize, :);

% now limit all images cellsMean, changeUp, changeDown to be the same
% size
sizes = [size(cellsMean); size(changeUp); size(changeLeft)];
finalSize = min(sizes);

% Generate arrays with the cell centers
centersX = 1:cellSize:finalSize(1);
centersY = 1:cellSize:finalSize(2);


cellsMean = cellsMean(centersX, centersY);
changeUp = changeUp(centersX, centersY);
changeLeft = changeLeft(centersX, centersY);

if debugFlag
    figure(1)
    imshow(originalImage)
    figure(2)
    imshow(cellsMean)
end
end