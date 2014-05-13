function seed = ShowGaussianNatScene(contrast, imNumber, impath, presentationLength, ...
    cellSize, seed)
global screen 
try
    cellSize
    
    InitScreen(0)
    Add2StimLogList();
    
    if (isempty(impath))
        impath = '/Users/jadz/Documents/Notebook/Matlab/Natural Images DB/RawData/cd01A';
    end
    imList = dir([impath,'/*LUM.mat']);
    struct = load([impath, '/',imList(imNumber).name]);
    w_im = struct.LUM_Image;
    w_im = w_im*2^8/max(w_im(:));
%    w_im = imread('peppers.png');
    
    [cellMeans, changeUp, changeLeft]=GaussianNatScene2(w_im, cellSize, cellSize);

    % Generate checkers, output has to be of size (4,checkersN)
    ch_vert = size(cellMeans,1);
    ch_hori = size(cellMeans,2);
    ch_offset = screen.center - size(cellMeans)*cellSize/2;
    ch_offset = [0 0];
    ch = tileCheckers(ch_hori, ch_vert, cellSize, cellSize, ch_offset(1),...
        ch_offset(2), cellSize, cellSize);

    % convert cellMeans, changeUp, changeLeft to 1D
    cellMeansB = reshape(cellMeans', 1, size(cellMeans,1)*size(cellMeans,2));
    changeUpB = reshape(changeUp', 1, size(changeUp,1)*size(changeUp,2));
    changeLeftB = reshape(changeLeft', 1, size(changeLeft,1)*size(changeLeft,2));
    changes = [changeUpB; changeLeftB];
    
    framesN = presentationLength*screen.rate/screen.waitframes;
    
%    seeds = zeros(1, size(ch,2));
    ShowCorrelatedGaussianCheckers(ch, framesN, cellMeansB, changes, contrast, seed);
    FinishExperiment();

catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception)
end %try..catch..
end
