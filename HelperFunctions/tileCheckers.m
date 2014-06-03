function checkers = tileCheckers(checkersNinX, checkersNinY, sizeX, sizeY,...
    xLeftMargin, yTopMargin, distanceX, distanceY)
% Generate a 2D array with checkers (something that could be used with for
% example FillRect, having N checkers). 
Add2StimLogList();

% For example, you might want to run something like
checkersN = checkersNinX*checkersNinY;
centerX = mod((0:checkersN-1), checkersNinX)*distanceX + xLeftMargin+sizeX/2;
centerY = floor((0:checkersN-1)/checkersNinX)*distanceY + yTopMargin+sizeY/2;

checkers = ones(4, length(centerX));
checkers(1,:) = centerX-sizeX/2;
checkers(2,:) = centerY-sizeY/2;
checkers(3,:) = centerX+sizeX/2;
checkers(4,:) = centerY+sizeY/2;

end
