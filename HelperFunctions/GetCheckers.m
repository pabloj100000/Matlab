function checkers = GetCheckers(width, height, checkersWidth, contrast, mean)
    Add2StimLogList();
    [x, y]  = meshgrid(0:width-1, 0:height-1);
    x = mod(floor(x/checkersWidth),2);
    y = mod(floor(y/checkersWidth),2);
    checkers = x.*y + ~x.*~y;
    checkers = checkers*2*mean*contrast...
        + mean*(1-contrast);
end

