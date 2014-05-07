function [cellsMean, cellsSTD] = GaussianNatScene(originalImage, cellSize, FEM_x, FEM_y)
% Change a natural scene by its equivalent gaussian form.
% By this I mean replacing every square of size 'cellSize' by its
% equivalent gaussian distribution under eye movements described by FEM_x
% and FEM_y
%
% outptu:   two 2D arrays, one with the mean and one with the contrast of
% each patch

debugFlag=0;

% convolve w_im with a square of size 'cellSize'
h = fspecial('average', cellSize);
filteredImage = uint8(imfilter(originalImage, h));

% Each pixel in the image represents a cell of the given size, but those
% cells areextremely near to each other, they overlap a lot.
% I am only going to take tiling patches such each point in the image
% belongs to one and only one cell.
% I'm going to move those cells according to FEM_x, FEM_y and extract the
% mean and sd of each cell

% integrate FEM_x and FEM_y to get maximum displacement of each cell in
% each direction. This is needed to prevent cells from falling off the
% edges of the image
cumSumX = cumsum(FEM_x);
cumSumY = cumsum(FEM_y);
leftX = min(cumSumX);
rightX = max(cumSumX);
upY = min(cumSumY);
downY = max(cumSumY);

% Generate arrays with the cell centers
centersX = abs(leftX)+1:cellSize:size(originalImage,1)-rightX-1;
centersY = abs(upY)+1:cellSize:size(originalImage,2)-downY-1;

% init array to hold shifted version of original image
FEM = uint8(ones(length(centersX),length(centersY), length(FEM_x)));

% generated the 3D array 
for i=1:length(FEM_x)
    FEM(:,:,i) = filteredImage(centersX + cumSumX(i), centersY + cumSumY(i));
end

% for each cell, extract the mean and the contrast
cellsMean = mean(FEM, 3);
cellsSTD = std(double(FEM), 0, 3)./cellsMean;

if debugFlag
    figure(1)
    imshow(originalImage)
    figure(2)
    imshow(filteredImage)
end
end