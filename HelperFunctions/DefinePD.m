function pd = DefinePD()
    Add2StimLogList();
    
    %    [screenX, screenY] = Screen('WindowSize', max(Screen('Screens')));
    [windowSizeX windowSizeY] = Screen('WindowSize', max(Screen('Screens')));
    pd = SetRect(0,0, 10*PIXELS_PER_100_MICRONS, 10*PIXELS_PER_100_MICRONS);
    pd = CenterRectOnPoint(pd, windowSizeX*.94, windowSizeY*.16);
end
