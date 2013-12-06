function im = LoadIm(file, newMean, newContrast)
    % load the image in file and changes it so that it will have the given
    % mean and contrast
    Add2StimLogList();
    
    % load file
    if (exist(file)==2)
        im0 = imread(file);
    else
        error ["file ", file, " does not exist or is not in the path"];
    end
    
    % convert it to 1D
    im1 = mean(im0, 3);
    im2 = reshape(im1, 1, size(im1,1)*size(im1,2));
    
    % change pixel intensity to have zero mean and sigma = 1
    oldMean = mean(im2);
    oldSigma = std(im2);
    im2 = im2 - oldMean;
    im2 = im2/oldSigma;
    
    % change pixel intensities to have meanIntensity and contrast
    if (newContrast >1)
        newContrast = newContrast/100;
    end
    
    newSigma = newMean*newContrast;
    im2 = im2*newSigma + newMean;

    % Change back to 2D array
    im = uint8(reshape(im2, size(im1,1), size(im1,2)));
end
