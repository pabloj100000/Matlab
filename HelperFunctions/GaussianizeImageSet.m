function [allMeans, allGradientUp, allGradientLeft] = ...
    GaussianizeImageSet(s_path, imIndex, cellSize, movementSize, contrast, ...
    outputSize)
    % for each image that matches s_path and imIndex as in 
    % load([s_path, '/',imList(imIndex(i)).name]);
    %
    % run GaussianizeImage (which returns 1D means, varianceLeft,
    % varianceUp and checkers (a 4 x checkersN array)
    % and merge all 1D arrays onto a 2D array that has imageID on the first
    % dimension and the means/variances in the 2nd dimension
    Add2StimLogList();

    if isempty(s_path)
        s_path = '/Users/jadz/Documents/Notebook/Matlab/Natural Images DB/RawData/cd01A'
    end
    
    % get all the images in s_path of the form *LUM.mat
    imList = dir([s_path,'/*LUM.mat']);
    
    imagesN = length(imIndex);
    for i = 1:imagesN
        % Load image from DB
        struct = load([s_path, '/',imList(imIndex(i)).name]);
        w_im = struct.LUM_Image;
        w_im = w_im*2^8/max(w_im(:));

        % gaussianize the image
        [cellsMean, gradientUp, gradientLeft] = ...
            GaussianizeImage(w_im, cellSize, movementSize, contrast, outputSize);
        
        % Get all the gaussianized images onto one big array that has
        % images on the 1st axis
        if i==1
            allMeans = ones([imagesN size(cellsMean)]);
            allGradientUp = ones([imagesN size(gradientUp)]);
            allGradientLeft = ones([imagesN size(gradientLeft)]);
        end
        
        allMeans(i, :, :) = cellsMean;
        allGradientUp(i, :, :) = gradientUp(:, :);
        allGradientLeft(i, :, :) = gradientLeft(:, :);
    end
    