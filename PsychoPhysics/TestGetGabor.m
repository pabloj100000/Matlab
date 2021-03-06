function TestGetGabor()
    global screen
    InitScreen(0)
    Screen(screen.w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    g.size = 200;
    g.period = 200;
    g.sigma = 50;
    g.phase = 0;
    g.contrast = 1;
    g.mean = 127;

    g = GetGaborTex(g);

    DisplayGaborStruct(g, [100 100])

    g = GetGaborTex(g);
    
    DisplayGaborStruct(g, [800 500])

%    g = killGaborTex(g);
    
    g.size = 200;
    g.period = 40;
    g.sigma = 50;
    g.phase = 0;
    g.contrast = 1;
    g.mean = 127;
    g = GetGaborTex(g);
    DisplayGaborStruct(g, [500 300])

    Screen('Flip', screen.w)
    pause(3)
    
    FinishExperiment
    
end

