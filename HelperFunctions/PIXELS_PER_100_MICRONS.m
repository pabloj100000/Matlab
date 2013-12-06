function [pixelsX] = PIXELS_PER_100_MICRONS
    Add2StimLogList();
    
    [width height] = Screen('WindowSize', max(Screen('Screens')));
    switch width
        case 640
            pixelsX = 12;
        case 800
            pixelsX = 14;
        case 1024
            pixelsX = 18;
        case 1280
            pixelsX = 22;
        case 1680
            pixelsX = 30;
        otherwise
            error('Pixels not defined. Change PIXELS_PER_100_MICRONS to include this resolution. Execute Screen(''WindowSize'',0) to learn your monitor''s resolution');
    end
    
end
