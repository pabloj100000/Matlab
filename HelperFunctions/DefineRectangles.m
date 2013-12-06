function [rectangles rectanglesN]= DefineRectangles(checkerSize, size, ...
    upperLeft)
    % Usage: DefineRectangles(20, [700 700], [0 0])
    % Devide a portion of the screen defined by the "upperLeft" pixel and
    % "size(1)" pixels vertical and "size(2)" pixels wide into
    % squares of size "checkerSize"
    % UpperLeft are coordinates with respect to the whole screen. NOT with
    % respect to the area filled with checkers (otherwise they will always
    % be [0 0])
    % 
    % if checkerSize == -1 a checker of 'size' is returned
    Add2StimLogList();
    
    if (checkerSize == -1)
        rectanglesN = 1;
        rectangles  = [upperLeft upperLeft + size];
    else
    
        NumHBoxes=ceil(size(1)/checkerSize);
        NumVBoxes=ceil(size(2)/checkerSize);

        rectanglesN = NumHBoxes * NumVBoxes;

        % Define the rectangles array 4xNumber of total checkers
        rectangles=zeros(4,rectanglesN);

        % if user defined a screenSize then the left and top pixels of the
        % 1st square are not 0
        startX = upperLeft(1);
        startY = upperLeft(2);

        m1 = ones(NumVBoxes,1)*(startX:checkerSize:(startX + NumHBoxes*checkerSize-checkerSize));
        rectangles(1,:) = reshape(m1',1,rectanglesN)';
        rectangles(3,:) = rectangles(1,:) + checkerSize;
        m1 = ones(NumHBoxes,1)*(startY:checkerSize:startY + NumVBoxes*checkerSize-checkerSize);
        rectangles(2,:) = reshape(m1,1,rectanglesN);
        rectangles(4,:) = rectangles(2,:) + checkerSize;
    end
end

