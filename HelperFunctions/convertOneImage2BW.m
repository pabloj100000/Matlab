function convertOneImage2BW(image, outArea, showFlag, outputPath)
    % image,        a string with a partial or full path to the image
    % outArea,      [left top right bottom]
    % showFlag,     1/0
    % outputPath,   partial or full path to the output directory 
    % 1. Make image sizeOut pixels
    % 2. Make them grayscale, 8 bit.
    % 3. Meanless
    % 4.    I'm computing the contrast per pixel but not doing anything with
    %       it yet.
    Add2StimLogList();
    
    [~, name, ext] = fileparts(image);
    if strcmpi(ext, '.jpg')
        % load the image
        im = imread(image);

        % limit images to the give sizeOut
        if (min(outArea)==0)
            outArea = outArea+1;
        end
        tempIm = im(outArea(2):outArea(4), outArea(1):outArea(3), :);

        % convert to balck and white
        newIm = rgb2gray(tempIm);
        
        % subtract the mean. (Can not do it if format is unit8)
        newIm = uint8(int16(newIm) - mean(mean(newIm))+127);

        if (showFlag)
            figure(1)
            imshow(im)
            figure(2)
            imshow(newIm)
        end
        
        % Save the new image
        
        imwrite(newIm,[outputPath,'/',name, ext], 'Bitdepth', 8);
        
    end
end
