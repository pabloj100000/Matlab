function TestGaussianNatScene2(contrast)
try
    InitScreen(0)
    Add2StimLogList();

    w_im = imread('peppers.png');
    figure(1)
    imshow(w_im)
    
    
    [cellMeans, changeUp, changeLeft]=GaussianNatScene2(w_im, 11, 1);

    figure(2)
    imshow(uint8(cellMeans));

    % Generate checkers, output has to be of size (4,checkersN)
    ch = tileCheckers(size(cellMeans,2), size(cellMeans,1), 11, 11, 0, 0, 11, 11);

    % convert cellMeans, changeUp, changeLeft to 1D
    cellMeansB = reshape(cellMeans', 1, size(cellMeans,1)*size(cellMeans,2));
    changeUpB = reshape(changeUp', 1, size(changeUp,1)*size(changeUp,2));
    changeLeftB = reshape(changeLeft', 1, size(changeLeft,1)*size(changeLeft,2));
    changes = [changeUpB];%; changeLeftB];
    
%    seeds = zeros(1, size(ch,2));
    ShowCorrelatedGaussianCheckers(ch, 10000, cellMeansB, changes, contrast);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
