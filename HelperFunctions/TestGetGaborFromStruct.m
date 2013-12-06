function TestGetGaborFromStruct()
    global screen
    InitScreen(0)

    g.period = 100;
    g.sigma = 50;
    g.phase = 0;
    g.contrast=1;
    g.mean=127;

    g.tex = GetGaborFromStruct(g);
    g.mask = GetGaborMaskFromStruct(g);

    DisplayGaborStruct(g, [100 100])

    
    DisplayGaborStruct(g, [100 500])

    g.sigma = 20;
    g.tex = GetGaborFromStruct(g);
    g.mask = GetGaborMaskFromStruct(g);
    DisplayGaborStruct(g, [500 100])

    Screen('Flip', screen.w)
    pause(3)
    
    FinishExperiment
    
end

