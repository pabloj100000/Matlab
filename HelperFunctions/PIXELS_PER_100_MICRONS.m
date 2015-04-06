function [pixelsX] = PIXELS_PER_100_MICRONS
    % Return how many pixels are equivalent to 100 microns on the retina.
    % This is done by measuring the square size that matches a known object
    % on the retinal plane. Currently I'm using the Low Density MEA that
    % measures from side to side ~710um (7 spaces of 100um + 10um
    % contacts). By overlaying a square of exactly the same size as the low
    % density MEA the computation is performed.
    Add2StimLogList();
    
    [width height] = Screen('WindowSize', max(Screen('Screens')));
    switch width
        case 640
            pixelsX = 12;
        case 800
            pixelsX = 14;
        case 1024
            pixelsX = 17;
        case 1280
            pixelsX = 22;
        case 1680
            pixelsX = 30;
        otherwise
            error('Pixels not defined. Change PIXELS_PER_100_MICRONS to include this resolution. Execute Screen(''WindowSize'',0) to learn your monitor''s resolution');
    end
    
end
