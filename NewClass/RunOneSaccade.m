function RunOneSaccade()
    global screen
    InitScreen(0);
    Add2StimLogList();
    
    im = imread('/Users/jadz/Documents/Notebook/Matlab/Stimuli/NaturalScenesBW/image1.jpg');
    tex = Screen('MakeTexture', screen.w, im);
    OneSaccade(tex, 'rfSize', 32);
    Screen('Close', tex)
    FinishExperiment();
end
