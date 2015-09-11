function rect = GetRect(selection)
% Define a few commonly used rectangles
% pd, HIDens_v3, etc
% GetRect returns a rectangle matching the full screen if nothing matches
% 'selection'

Add2StimLogList();

[windowSizeX windowSizeY] = Screen('WindowSize', max(Screen('Screens')));

rect = SetRect(0, 0, windowSizeX, windowSizeY);
if strcmpi(selection, 'pd')
    
    %    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rect = SetRect(0,0, 10*PIXELS_PER_100_MICRONS, 10*PIXELS_PER_100_MICRONS);
    rect = CenterRectOnPoint(rect, windowSizeX*.94, windowSizeY*.16);
    return
end
if strcmpi(selection, 'HiDens_v3')
    %    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    rect = SetRect(0,0, 2*10*PIXELS_PER_100_MICRONS, 1.75*10*PIXELS_PER_100_MICRONS);
    rect = CenterRectOnPoint(rect, windowSizeX/2, windowSizeY/2);
    return
end
