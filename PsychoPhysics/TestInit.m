function TestInit()
    global screen
    InitScreen(0, 'backColor', 200)

    Screen('Flip', screen.w)
    pause(3)
    
    FinishExperiment
    
end

