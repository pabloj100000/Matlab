function DiscriminationTaskWrapper()
    % **********************************************************
    % Get the background checker's texture
    backtex = GetRectsTex(backObjectsN);

    backtex(2) = GetMeanTex();

end