function im = LoadImage(imPath, imMean, imContrast)

    im = imRead(imPath);
    oldMean = mean(im(:));
    
    im = im - oldMean;
    
    oldSTD = sqrt(mean(im.*im));
    
    im = im*imMean*imContrast/oldSTD + imMean;

    newMean = mean(im(:))
    
    sqrt(mean(im(:)-newMean).*(im(:)-newMean))/uint8(imMean)
    
%    im(1,1)=0;
%    im(1,2)=255;
    figure(1)
    imshow(im)
end
