function [width height] = SCREEN_SIZE
    Add2StimLogList();
    [width height] = Screen('WindowSize', max(Screen('Screens')));
end
