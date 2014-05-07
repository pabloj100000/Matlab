function TestGaussianNatScene()
try
    InitScreen(0)
    Add2StimLogList();

    w_im = imread('peppers.png');
    figure(1)
    imshow(w_im)
    
    FEM_x = randi(3, 1, 1000)-2;
    FEM_y = randi(3, 1, 1000)-2;
%    FEM_x = int8(FEM_x - mean(FEM_x));
%    FEM_y = int8(FEM_y - mean(FEM_y));
    
    [cellMeans, cellSTDs]=GaussianNatScene(w_im, 11, FEM_x, FEM_y);

    figure(2)
    imshow(uint8(cellMeans));

    % Generate checkers, output has to be 4*checkersN
    ch = tileCheckers(size(cellMeans,2), size(cellMeans,1), 11, 11, 0, 0, 11, 11);

    % convert cellMeans and cellSTDs to 1D
    cellMeansB = reshape(cellMeans', 1, size(cellMeans,1)*size(cellMeans,2));
    cellSTDsB = reshape(cellSTDs', 1, size(cellMeans,1)*size(cellMeans,2));
    
    
    seeds = randi(200, 1, size(ch,2));
%    seeds = zeros(1, size(ch,2));
    ShowGaussianCheckers(ch, 1000, cellMeansB, cellSTDsB, seeds);
    FinishExperiment();
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
