function [colors] = GetColors(Luminance, checkersN)
    % Given values for Luminance, return colors that are arrays
    % of size (3, checkersN) with the color of each checker.
    % The idea is that the mean value of the checkers in colors will be
    % Luminance. This will allow me for example to say Luminance=127.5 and
    % in this case, colors will be 127
    % and half 128.
    L1 = floor(Luminance);
    L2 = ceil(Luminance);
    
    if L1==L2
        colors = ones(3, checkersN)*L1;
        return
    end
    
    %n11 + n12 = checkersN
    % n11*L1 + n12*L2 = Luminance(1)
%    n11 = checkersN*(L2-Luminance(1))/(L2-L1);
    n12 = round(checkersN*(Luminance-L1)/(L2-L1));
    
    colors = ones(3,checkersN)*L1;
    if n12
        colors(:, 1:checkersN/n12:checkersN) = L2;
    end
    mean(colors(:))

end